import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:okk/dynamic_assessment/feedback_engine.dart';

// --------------------------------------------------------
// AnimatedBackground：柔和的動畫背景（無圖片）
// --------------------------------------------------------
class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorTween;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 10));
    _colorTween = ColorTween(
      begin: Color(0xFFe0f7fa), // 柔和淺藍
      end: Color(0xFFffffff),   // 白色
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorTween,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_colorTween.value!, Color(0xFFf0f8ff)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        );
      },
    );
  }
}

// --------------------------------------------------------
// TreeNode 與 TreeGenerator (二元樹結構與生成)
// --------------------------------------------------------
class TreeNode {
  String uid;
  int index;
  TreeNode? left;
  TreeNode? right;
  double? x;
  double? y;
  TreeNode({required this.uid, required this.index});
}

class TreeGenerator {
  static TreeNode? generateBinaryTree(List<Map<String, dynamic>> scannedList) {
    if (scannedList.isEmpty) return null;
    scannedList.shuffle();
    List<TreeNode> nodes = scannedList.map((item) {
      return TreeNode(uid: item['uid'], index: item['index']);
    }).toList();

    Queue<TreeNode> queue = Queue<TreeNode>();
    TreeNode root = nodes[0];
    queue.add(root);
    int i = 1;
    while (i < nodes.length) {
      TreeNode current = queue.removeFirst();
      if (i < nodes.length) {
        current.left = nodes[i++];
        queue.add(current.left!);
      }
      if (i < nodes.length) {
        current.right = nodes[i++];
        queue.add(current.right!);
      }
    }
    return root;
  }
}

// --------------------------------------------------------
// TreeVisualization 與 _TreePainter (二元樹視覺化)
// --------------------------------------------------------
class TreeVisualization extends StatelessWidget {
  final TreeNode tree;
  final Set<String> visitedUids;
  final double rotationAngle;

  TreeVisualization({
    required this.tree,
    required this.visitedUids,
    required this.rotationAngle,
  });

  void _assignPositions(TreeNode? node, double x, double y, double offsetX) {
    if (node == null) return;
    node.x = x;
    node.y = y;
    double nextOffset = offsetX / 2;
    _assignPositions(node.left, x - nextOffset, y + 1, nextOffset);
    _assignPositions(node.right, x + nextOffset, y + 1, nextOffset);
  }

  void _centerTree(TreeNode root) {
    double minX = _findMinX(root);
    double maxX = _findMaxX(root);
    double treeWidth = maxX - minX;
    double offsetX = -(minX + treeWidth / 2.0);
    _adjustNodePositions(root, offsetX);
  }

  void _adjustNodePositions(TreeNode? node, double offsetX) {
    if (node == null) return;
    node.x = (node.x ?? 0) + offsetX;
    _adjustNodePositions(node.left, offsetX);
    _adjustNodePositions(node.right, offsetX);
  }

  double _findMinX(TreeNode node) {
    double m = node.x ?? 0;
    if (node.left != null) m = min(m, _findMinX(node.left!));
    if (node.right != null) m = min(m, _findMinX(node.right!));
    return m;
  }

  double _findMaxX(TreeNode node) {
    double m = node.x ?? 0;
    if (node.left != null) m = max(m, _findMaxX(node.left!));
    if (node.right != null) m = max(m, _findMaxX(node.right!));
    return m;
  }

  int _treeDepth(TreeNode? node) {
    if (node == null) return 0;
    return 1 + max(_treeDepth(node.left), _treeDepth(node.right));
  }

  @override
  Widget build(BuildContext context) {
    _assignPositions(tree, 0, 0, 4.0);
    _centerTree(tree);

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final depth = _treeDepth(tree);

    double minX = _findMinX(tree);
    double maxX = _findMaxX(tree);
    double treeWidth = (maxX - minX).abs() * 40;
    double treeHeight = depth * 80;

    double scaleX = screenWidth / (treeWidth + 50);
    double scaleY = screenHeight / (treeHeight + 100);
    double scale = min(scaleX, scaleY);

    double centerOffsetX = screenWidth / 2 - ((maxX + minX) / 2) * 40 * scale;

    return CustomPaint(
      size: Size(screenWidth, screenHeight),
      painter: _TreePainter(
        tree: tree,
        visitedUids: visitedUids,
        rotationAngle: rotationAngle,
        scale: scale,
        centerOffsetX: centerOffsetX,
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  final TreeNode tree;
  final Set<String> visitedUids;
  final double rotationAngle;
  final double scale;
  final double centerOffsetX;

  final double nodeRadius = 20.0;
  final double baseScaleFactor = 40.0;

  _TreePainter({
    required this.tree,
    required this.visitedUids,
    required this.rotationAngle,
    required this.scale,
    required this.centerOffsetX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdgesAndNodes(canvas, size, tree);
  }

  void _drawEdgesAndNodes(Canvas canvas, Size size, TreeNode node) {
    final Rect fullRect = Offset.zero & size;
    final Paint linePaint = Paint()
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF69BDFD), Color(0xFFA47DFF)],
      ).createShader(fullRect);

    if (node.left != null) {
      double px = (node.x ?? 0) * baseScaleFactor * scale + centerOffsetX;
      double py = (node.y ?? 0) * baseScaleFactor * scale;
      double lx = (node.left!.x ?? 0) * baseScaleFactor * scale + centerOffsetX;
      double ly = (node.left!.y ?? 0) * baseScaleFactor * scale;
      canvas.drawLine(Offset(px, py), Offset(lx, ly), linePaint);
      _drawEdgesAndNodes(canvas, size, node.left!);
    }
    if (node.right != null) {
      double px = (node.x ?? 0) * baseScaleFactor * scale + centerOffsetX;
      double py = (node.y ?? 0) * baseScaleFactor * scale;
      double rx = (node.right!.x ?? 0) * baseScaleFactor * scale + centerOffsetX;
      double ry = (node.right!.y ?? 0) * baseScaleFactor * scale;
      canvas.drawLine(Offset(px, py), Offset(rx, ry), linePaint);
      _drawEdgesAndNodes(canvas, size, node.right!);
    }
    double nx = (node.x ?? 0) * baseScaleFactor * scale + centerOffsetX;
    double ny = (node.y ?? 0) * baseScaleFactor * scale;
    bool visited = visitedUids.contains(node.uid);
    _drawNode(canvas, Offset(nx, ny), visited, node.index);
  }

  void _drawNode(Canvas canvas, Offset center, bool visited, int index) {
    Rect nodeRect = Rect.fromCircle(center: center, radius: nodeRadius);
    Paint fillPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.2,
        colors: [Color(0xFFC8F2FF), Color(0xFFA3E4FF), Color(0xFFE6C7FF)],
      ).createShader(nodeRect);
    canvas.drawCircle(center, nodeRadius, fillPaint);
    if (visited) {
      Paint glow = Paint()
        ..color = Colors.yellowAccent.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0;
      canvas.drawCircle(center, nodeRadius + 2, glow);
    }
    Paint border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, nodeRadius, border);

    final textSpan = TextSpan(
      text: index.toString(),
      style: TextStyle(
        fontSize: 14,
        fontFamily: 'PressStart2P',
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) {
    return tree != oldDelegate.tree ||
        visitedUids.length != oldDelegate.visitedUids.length ||
        rotationAngle != oldDelegate.rotationAngle ||
        scale != oldDelegate.scale ||
        centerOffsetX != oldDelegate.centerOffsetX;
  }
}

// --------------------------------------------------------
// Enum 定義
// --------------------------------------------------------
enum GameState {
  preparation,
  scanningForTree,
  showTree,
  scanningForTraversal,
  result,
}

// --------------------------------------------------------
// LearnAlgorithmPage：主頁面
// --------------------------------------------------------
class LearnAlgorithmPage extends StatefulWidget {
  @override
  _LearnAlgorithmPageState createState() => _LearnAlgorithmPageState();
}

class _LearnAlgorithmPageState extends State<LearnAlgorithmPage>
    with SingleTickerProviderStateMixin {
  // 核心功能變數
  GameState _gameState = GameState.preparation;
  TreeNode? _randomTree;
  String? _searchAlgorithm;
  Timer? _timer;
  int _elapsedTime = 0;
  bool _isScanning = false;
  int _scanCountForTree = 0;
  List<Map<String, dynamic>> _scannedNfcForTree = [];
  List<String> _scannedNfcUidsForTraversal = [];
  int _scannedNfcCount = 0;
  bool _isTreeValid = false;
  double _score = 0.0;
  // 動態評量錯誤回饋
  List<Map<String, dynamic>> _errorFeedbackBuffer = [];

  final CollectionReference _defaultNfcCollection =
  FirebaseFirestore.instance.collection('nfc_defaults');
  final CollectionReference _scannedNfcCollection =
  FirebaseFirestore.instance.collection('nfc_scanned');
  StreamSubscription<QuerySnapshot>? _databaseSubscription;
  List<Map<String, dynamic>> _nfcScanData = [];

  List<String> _correctOrderUids = [];
  int _nextCorrectIndex = 0;
  bool _dialogShown = false;

  late AnimationController _coinRotationController;

  @override
  void initState() {
    super.initState();
    _startListeningToDatabase();
    _coinRotationController =
    AnimationController(vsync: this, duration: Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _databaseSubscription?.cancel();
    _timer?.cancel();
    _coinRotationController.dispose();
    super.dispose();
  }

  void _startListeningToDatabase() {
    _databaseSubscription =
        _scannedNfcCollection.snapshots().listen((snapshot) {
          List<Map<String, dynamic>> scans = snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          setState(() {
            _nfcScanData = scans;
          });
        });
  }

  Future<void> _deleteAllDocuments(CollectionReference collection) async {
    try {
      QuerySnapshot snapshot = await collection.get();
      if (snapshot.docs.isEmpty) return;
      await Future.wait(snapshot.docs.map((doc) => doc.reference.delete()));
    } catch (e) {
      _showMessage('刪除失敗，請稍後再試', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style:
          TextStyle(fontFamily: 'PressStart2P', color: Colors.white),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDatabaseUpdatesView() {
    return Card(
      color: Colors.white.withOpacity(0.8),
      margin: EdgeInsets.symmetric(vertical: 20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('使用者掃描資料：',
                style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'PressStart2P',
                    color: Colors.grey.shade700)),
            SizedBox(height: 16),
            _nfcScanData.isNotEmpty
                ? ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _nfcScanData.length,
              itemBuilder: (context, index) {
                final scan = _nfcScanData[index];
                return ListTile(
                  title: Text('UID: ${scan['uid']}',
                      style: TextStyle(
                          fontFamily: 'PressStart2P',
                          color: Colors.grey.shade800)),
                );
              },
            )
                : Text('目前沒有掃描資料。',
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'PressStart2P',
                    color: Colors.grey.shade700)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _deleteAllDocuments(_scannedNfcCollection);
                setState(() => _nfcScanData.clear());
                _showMessage('使用者掃描資料已清除');
              },
              child: Text('清除掃描資料'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding:
                EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)),
                textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PressStart2P'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 掃描 NFC 用於生成二元樹的邏輯
  Future<void> _scanNfcForTree() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        throw Exception('NFC 無法使用');
      }
      NFCTag? tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 10));
      if (tag != null) {
        String uid = tag.id ?? '未知 UID';
        await FlutterNfcKit.finish();
        bool isDuplicate = _scannedNfcForTree.any((e) => e['uid'] == uid);
        if (isDuplicate) {
          _showMessage("UID: $uid 已掃描過，請使用其他 NFC 標籤", isError: true);
        } else {
          _scanCountForTree++;
          _scannedNfcForTree.add({'uid': uid, 'index': _scanCountForTree});
          _scannedNfcCount = _scannedNfcForTree.length;
          await _scannedNfcCollection.add({'uid': uid});
          _showMessage("掃描成功！UID: $uid");
        }
      } else {
        await FlutterNfcKit.finish();
        _showMessage('未發現 NFC 標籤，請再試一次', isError: true);
      }
    } catch (e) {
      await FlutterNfcKit.finish();
      _showMessage('NFC 掃描失敗：$e', isError: true);
    } finally {
      setState(() {
        _isScanning = false;
      });
      // ※ 此處不再自動呼叫下一次掃描，讓使用者手動點擊按鈕
    }
  }

  // 掃描 NFC 用於遊玩走訪時的邏輯（手動觸發）
  Future<void> _scanNfcForTraversal() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });
    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        throw Exception('NFC 無法使用');
      }
      NFCTag? tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 10));
      if (tag != null) {
        String uid = tag.id ?? '未知 UID';
        await FlutterNfcKit.finish();
        _handleTraversalScan(uid);
      } else {
        await FlutterNfcKit.finish();
        _showMessage('未發現 NFC 標籤，請再試一次', isError: true);
      }
    } catch (e) {
      await FlutterNfcKit.finish();
      _showMessage('NFC 掃描失敗：$e', isError: true);
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _handleTraversalScan(String uid) async {
    _scannedNfcUidsForTraversal.add(uid);
    _scannedNfcCount = _scannedNfcUidsForTraversal.length;
    if (_nextCorrectIndex < _correctOrderUids.length) {
      String expectedUid = _correctOrderUids[_nextCorrectIndex];
      if (uid == expectedUid) {
        _nextCorrectIndex++;
        _showMessage("掃描正確！UID: $uid");
      } else {
        _errorFeedbackBuffer.add({
          'userUid': uid,
          'expectedUid': expectedUid,
          'timestamp': DateTime.now(),
        });
        _showMessage("錯誤掃描已記錄", isError: true);
      }
    } else {
      _showMessage("掃描成功！UID: $uid");
    }
  }

  Future<void> _verifyResult() async {
    if (_searchAlgorithm == null || _randomTree == null) {
      _showMessage('無法驗證，請確認已生成樹並選擇演算法',
          isError: true);
      return;
    }
    if (_scannedNfcUidsForTraversal.isEmpty) {
      _showMessage('請先掃描至少一個 NFC 標籤以驗證結果',
          isError: true);
      return;
    }
    // 取得正確走訪的節點（以 uid 表示）
    List<TreeNode> traversalResult =
    (_searchAlgorithm == '深度優先搜尋')
        ? _dfs(_randomTree)
        : _bfs(_randomTree);
    List<String> correctIndices =
    traversalResult.map((node) => node.index.toString()).toList();
    // 取得使用者走訪的節點（依 _scannedNfcForTree 中的 index）
    List<String> userIndices = _scannedNfcForTree
        .where((element) =>
        _scannedNfcUidsForTraversal.contains(element['uid']))
        .map((e) => e['index'].toString())
        .toList();

    _score = _calculateScore(
      _scannedNfcUidsForTraversal,
      traversalResult.map((node) => node.uid).toList(),
    ).toDouble();
    _isTreeValid = (_score == 100);
    _stopTimer();
    await _showScoreDialog();
    if (!mounted) return;
    setState(() => _gameState = GameState.result);
    // 動態評量：如果有錯誤回饋則提供 AI 建議
    if (_errorFeedbackBuffer.isNotEmpty) {
      String asciiTree = generateAsciiTree(_randomTree);
      String computedErrorLevel =
      computeErrorLevel(_score, _errorFeedbackBuffer);
      try {
        final aiFeedback = await generateAiFeedback(
          mode: 'dynamic',
          score: 0,
          userUids: userIndices,
          correctUids: correctIndices,
          algorithm: _searchAlgorithm!,
          treeVisualization: asciiTree,
          errorInfo: computedErrorLevel,
        );
        await _showTeachingAssistantDialog(aiFeedback);
      } catch (e) {
        _showMessage("無法獲取 AI 回饋，請稍後再試。", isError: true);
      }
    } else {
      debugPrint("無錯誤記錄，故不顯示回饋");
    }
  }

  int _calculateScore(List<String> userUids, List<String> correctUids) {
    if (userUids.isEmpty) return 0;
    int totalNodes = correctUids.length;
    double score = 0.0;
    double pointPerMatch = 100.0 / totalNodes;
    int minLen = min(userUids.length, correctUids.length);

    for (int i = 0; i < minLen; i++) {
      if (userUids[i] == correctUids[i]) {
        score += pointPerMatch;
      }
    }
    Map<String, int> userCount = {};
    Map<String, int> correctCount = {};
    for (var uid in userUids) {
      userCount[uid] = (userCount[uid] ?? 0) + 1;
    }
    for (var uid in correctUids) {
      correctCount[uid] = (correctCount[uid] ?? 0) + 1;
    }
    userCount.forEach((uid, count) {
      int allowed = correctCount[uid] ?? 0;
      int duplicates = count - allowed;
      if (duplicates > 0) {
        score -= duplicates * 5;
      }
    });
    int missingCount = correctUids.length - userUids.length;
    if (missingCount > 0) {
      score -= missingCount * 3;
    }
    if (score < 0) score = 0;
    if (score > 100) score = 100;
    return score.toInt();
  }

  void _startTimer() {
    _elapsedTime = 0;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() => _elapsedTime++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  List<TreeNode> _dfs(TreeNode? node) {
    List<TreeNode> result = [];
    if (node == null) return result;
    result.add(node);
    result.addAll(_dfs(node.left));
    result.addAll(_dfs(node.right));
    return result;
  }

  List<TreeNode> _bfs(TreeNode? root) {
    List<TreeNode> result = [];
    if (root == null) return result;
    Queue<TreeNode> queue = Queue<TreeNode>();
    queue.add(root);
    while (queue.isNotEmpty) {
      TreeNode node = queue.removeFirst();
      result.add(node);
      if (node.left != null) queue.add(node.left!);
      if (node.right != null) queue.add(node.right!);
    }
    return result;
  }

  // 顯示分數對話框（包含縮放動畫效果）
  Future<void> _showScoreDialog() async {
    if (_dialogShown) return;
    _dialogShown = true;

    String msg;
    if (_score == 100) {
      msg = '恭喜！走訪順序完全符合 $_searchAlgorithm！';
    } else if (_score == 0) {
      msg = '很可惜，順序幾乎不符合 $_searchAlgorithm。';
    } else {
      msg = '部分符合 $_searchAlgorithm，得分 ${_score.toStringAsFixed(0)}。';
    }
    _showMessage(msg);

    await showDialog(
      context: context,
      builder: (ctx) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: Duration(seconds: 1),
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              child: AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.95),
                title: Row(
                  children: [
                    if (_isTreeValid)
                      Icon(Icons.emoji_events, color: Colors.amber, size: 30)
                    else
                      SizedBox.shrink(),
                    SizedBox(width: 8),
                    Text(_isTreeValid ? "恭喜！" : "結果分析",
                        style: TextStyle(fontFamily: 'PressStart2P')),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        '您的得分：${_score.toStringAsFixed(0)} / 100',
                        style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'PressStart2P',
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _isTreeValid
                            ? '二元樹的走訪順序完全符合 $_searchAlgorithm！'
                            : '二元樹的走訪順序並非完全符合 $_searchAlgorithm。',
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'PressStart2P',
                            color: _isTreeValid ? Colors.green : Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '遊玩時間：$_elapsedTime 秒',
                        style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'PressStart2P',
                            color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('確認',
                        style: TextStyle(fontFamily: 'PressStart2P')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showTeachingAssistantDialog(String aiFeedback) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.red.shade100,
          title: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 30),
              SizedBox(width: 8),
              Text("小幫手的建議",
                  style: TextStyle(fontFamily: 'PressStart2P')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage("assets/assistant_robot.png"),
                  backgroundColor: Colors.transparent,
                ),
                SizedBox(height: 16),
                Text(
                  "嗨！我是您的教學助理 🤖",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PressStart2P'),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  aiFeedback,
                  style:
                  TextStyle(fontSize: 16, fontFamily: 'PressStart2P'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("了解了！",
                  style: TextStyle(fontFamily: 'PressStart2P')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onAlgorithmChosen(String algorithm) async {
    setState(() {
      _searchAlgorithm = algorithm;
      _gameState = GameState.scanningForTree;
      _scannedNfcForTree.clear();
      _scannedNfcUidsForTraversal.clear();
      _scanCountForTree = 0;
      _scannedNfcCount = 0;
      _randomTree = null;
      _score = 0.0;
      _isTreeValid = false;
      _elapsedTime = 0;
      _correctOrderUids.clear();
      _nextCorrectIndex = 0;
      _dialogShown = false;
      _errorFeedbackBuffer.clear();
    });
    await _loadDefaultNfcData();
  }

  // 載入預設的 NFC 資料，並依 uid 排序後指派編號
  Future<void> _loadDefaultNfcData() async {
    try {
      QuerySnapshot snapshot = await _defaultNfcCollection.get();
      List<Map<String, dynamic>> defaultData = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      // 依 uid 排序，確保順序固定
      defaultData.sort((a, b) => a['uid'].compareTo(b['uid']));
      int count = 0;
      for (var record in defaultData) {
        count++;
        _scannedNfcForTree.add({'uid': record['uid'], 'index': count});
      }
      setState(() {
        _scannedNfcCount = _scannedNfcForTree.length;
        // 掃描新 NFC 時，從目前最大的編號開始
        _scanCountForTree = count;
      });
      _showMessage("已自動載入 ${_scannedNfcForTree.length} 筆預設 NFC 資料");
    } catch (e) {
      _showMessage("載入預設 NFC 資料失敗", isError: true);
    }
  }

  void _generateTree() {
    if (_searchAlgorithm == null) {
      _showMessage('請先選擇演算法', isError: true);
      return;
    }
    if (_scannedNfcForTree.isEmpty) {
      _showMessage('請先掃描或載入至少一個 NFC 標籤來生成樹', isError: true);
      return;
    }
    _randomTree = TreeGenerator.generateBinaryTree(_scannedNfcForTree);
    setState(() => _gameState = GameState.showTree);
  }

  void _startTraversalScanning() {
    setState(() {
      _gameState = GameState.scanningForTraversal;
      _scannedNfcUidsForTraversal.clear();
      _scannedNfcCount = 0;
      _score = 0.0;
      _isTreeValid = false;
    });
    if (_randomTree != null) {
      List<TreeNode> traversalResult =
      (_searchAlgorithm == '深度優先搜尋')
          ? _dfs(_randomTree)
          : _bfs(_randomTree);
      _correctOrderUids =
          traversalResult.map((node) => node.uid).toList();
      _nextCorrectIndex = 0;
    }
    _startTimer();
  }

  void _resetGame() async {
    _stopTimer();
    await _deleteAllDocuments(_scannedNfcCollection);
    setState(() {
      _gameState = GameState.preparation;
      _searchAlgorithm = null;
      _randomTree = null;
      _elapsedTime = 0;
      _isTreeValid = false;
      _scannedNfcForTree.clear();
      _scannedNfcUidsForTraversal.clear();
      _scanCountForTree = 0;
      _scannedNfcCount = 0;
      _isScanning = false;
      _score = 0.0;
      _nfcScanData.clear();
      _correctOrderUids.clear();
      _nextCorrectIndex = 0;
      _dialogShown = false;
      _errorFeedbackBuffer.clear();
    });
  }

  ButtonStyle _gameButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'PressStart2P'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coinRotationController,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('深度與廣度演算法學習'),
            centerTitle: true,
            elevation: 4,
          ),
          body: Stack(
            children: [
              AnimatedBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        '學習演算法',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      _buildAnimatedStateView(_buildGameStateView()),
                      SizedBox(height: 32),
                      _buildDatabaseUpdatesView(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStateView(Widget child) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildGameStateView() {
    switch (_gameState) {
      case GameState.preparation:
        return _buildPreparationView();
      case GameState.scanningForTree:
        return _buildScanningForTreeView();
      case GameState.showTree:
        return _buildShowTreeView();
      case GameState.scanningForTraversal:
        return _buildScanningForTraversalView();
      case GameState.result:
        return _buildResultView();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildPreparationView() {
    return Card(
      key: ValueKey('preparation'),
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('選擇搜尋演算法',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PressStart2P',
                    color: Colors.grey.shade700)),
            SizedBox(height: 24),
            Text(
              '請選擇欲驗證的搜尋演算法。\n選擇後將進入 NFC 掃描以決定樹的節點數量。',
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'PressStart2P',
                  color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async => await _onAlgorithmChosen('深度優先搜尋'),
              child: Text('深度優先搜尋'),
              style: _gameButtonStyle(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async => await _onAlgorithmChosen('廣度優先搜尋'),
              child: Text('廣度優先搜尋'),
              style: _gameButtonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningForTreeView() {
    return Card(
      key: ValueKey('scanningForTree'),
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('目前選擇的演算法：$_searchAlgorithm',
                style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'PressStart2P',
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700)),
            SizedBox(height: 16),
            Text(
              '請掃描 NFC 來決定樹的節點數量，掃描完後請按下「掃描 NFC」進行下一次掃描。\n(此階段尚未開始計時)',
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'PressStart2P',
                  color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isScanning ? null : _scanNfcForTree,
              child: _isScanning
                  ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey.shade800),
                      strokeWidth: 2.0))
                  : Text('掃描 NFC'),
              style: _gameButtonStyle(),
            ),
            SizedBox(height: 16),
            Text('已掃描節點數量：$_scannedNfcCount',
                style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'PressStart2P',
                    color: Colors.grey.shade700)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _scannedNfcForTree.isNotEmpty ? _generateTree : null,
              child: Text('生成二元樹'),
              style: _gameButtonStyle(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetGame,
              child: Text('重新選擇演算法'),
              style: _gameButtonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  // 將生成二元樹的畫面包在固定高度的容器內，方便使用者操作捲動與縮放
  Widget _buildShowTreeView() {
    return Card(
      key: ValueKey('showTree'),
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('已生成的二元樹',
                style: TextStyle(
                    fontSize: 28,
                    fontFamily: 'PressStart2P',
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700)),
            SizedBox(height: 16),
            Container(
              height: 350,
              child: InteractiveViewer(
                boundaryMargin: EdgeInsets.all(100),
                minScale: 0.5,
                maxScale: 3.0,
                child: TreeVisualization(
                  tree: _randomTree!,
                  visitedUids: const {},
                  rotationAngle: _coinRotationController.value * 2 * pi,
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startTraversalScanning,
              child: Text('開始遊戲'),
              style: _gameButtonStyle(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetGame,
              child: Text('重新開始'),
              style: _gameButtonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningForTraversalView() {
    return Card(
      key: ValueKey('scanningForTraversal'),
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('目前選擇的演算法：$_searchAlgorithm',
                style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'PressStart2P',
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700)),
            SizedBox(height: 16),
            Text('遊戲時間: $_elapsedTime 秒',
                style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'PressStart2P',
                    color: Colors.grey.shade700)),
            SizedBox(height: 16),
            Text(
              '請依照樹的走訪順序掃描 NFC。\n掃描完成後按「驗證結果」進行結果評估。',
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'PressStart2P',
                  color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: InteractiveViewer(
                boundaryMargin: EdgeInsets.all(100),
                minScale: 0.5,
                maxScale: 3.0,
                child: TreeVisualization(
                  tree: _randomTree!,
                  visitedUids: _scannedNfcUidsForTraversal.toSet(),
                  rotationAngle: _coinRotationController.value * 2 * pi,
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isScanning ? null : _scanNfcForTraversal,
              child: _isScanning
                  ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey.shade800),
                      strokeWidth: 2.0))
                  : Text('掃描 NFC'),
              style: _gameButtonStyle(),
            ),
            SizedBox(height: 16),
            Text('已掃描節點數量：$_scannedNfcCount',
                style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'PressStart2P',
                    color: Colors.grey.shade700)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showNodeMappingDialog,
              child: Text('查看對照表'),
              style: _gameButtonStyle(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _scannedNfcUidsForTraversal.isNotEmpty ? _verifyResult : null,
              child: Text('驗證結果'),
              style: _gameButtonStyle(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetGame,
              child: Text('重新開始'),
              style: _gameButtonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  void _showNodeMappingDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          title: Row(
            children: [
              Icon(Icons.list_alt, color: Colors.blueGrey, size: 30),
              SizedBox(width: 8),
              Text("節點對照表", style: TextStyle(fontFamily: 'PressStart2P')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _scannedNfcForTree.map((node) {
                final idx = node['index'];
                final uid = node['uid'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text("節點 $idx => UID: $uid",
                      style: TextStyle(
                          fontSize: 14, fontFamily: 'PressStart2P')),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("關閉", style: TextStyle(fontFamily: 'PressStart2P')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultView() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: Duration(seconds: 1),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Card(
        key: ValueKey('result'),
        color: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isTreeValid
                    ? Icon(Icons.emoji_events, color: Colors.amber, size: 100)
                    : SizedBox.shrink(),
                SizedBox(height: 16),
                Text(
                  _isTreeValid ? "恭喜！" : "結果分析",
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily: 'PressStart2P',
                    fontWeight: FontWeight.bold,
                    color: _isTreeValid ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  '您的得分：${_score.toStringAsFixed(0)} / 100',
                  style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'PressStart2P',
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  _isTreeValid
                      ? '二元樹的走訪順序完全符合 $_searchAlgorithm！'
                      : '二元樹的走訪順序並非完全符合 $_searchAlgorithm。',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'PressStart2P',
                      color: _isTreeValid ? Colors.green : Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  '遊玩時間：$_elapsedTime 秒',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'PressStart2P',
                      color: Colors.grey.shade700),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _resetGame,
                  child: Text('重新開始遊戲'),
                  style: _gameButtonStyle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


