import 'dart:async';
import 'dart:collection'; // 用於 BFS
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../NFC/nfc_tree_generator.dart';

enum GameState { preparation, playing, result }

class LearnAlgorithmPage extends StatefulWidget {
  @override
  _LearnAlgorithmPageState createState() => _LearnAlgorithmPageState();
}

class _LearnAlgorithmPageState extends State<LearnAlgorithmPage> {
  TreeNode? _randomTree;
  int _scannedNfcCount = 0;
  GameState _gameState = GameState.preparation;
  String? _searchAlgorithm;
  bool _isTreeValid = false;
  Timer? _timer;
  int _elapsedTime = 0;
  bool _isTimerRunning = false;
  bool _isScanning = false;
  List<String> _scannedNfcUids = []; // 儲存掃描的 UID 用於驗證演算法


// NFC 掃描並生成二元樹
  Future<void> _scanNfc() async {
    setState(() {
      _isScanning = true;
      _scannedNfcCount = 0;  // 重置節點數量
    });

    try {

      // 模擬實時掃描過程
      List<TreeNode> scannedNodes = [];
      int totalNodeCount = 0;  // 用於累積所有掃描到的節點數

      for (int i = 0; i < 10; i++) {
        TreeNode scannedTree = await BinaryTreeGenerator.generateBinaryTreeFromNFC();  // 模擬掃描NFC
        String uid = scannedTree.uid;  // 假設 TreeNode 有 UID 屬性
        scannedNodes.add(scannedTree);

        // 計算當前掃描到的樹的節點數
        int currentNodeCount = _countNodes(scannedTree);
        totalNodeCount += currentNodeCount;  // 累積節點數

        // 每掃描一個節點，更新總的節點數量
        setState(() {
          _randomTree = scannedTree;  // 設置當前掃描的樹
          _scannedNfcCount = totalNodeCount;  // 更新累計的節點數
          _scannedNfcUids.add(uid); // 將掃描的 UID 加入列表
        });

        // 彈出掃描成功對話框，顯示 UID
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("NFC 掃描成功"),
              content: Text("UID: $uid"),  // 顯示掃描到的 UID
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("確定"),
                ),
              ],
            );
          },
        );

        // 確保每次等待之後再進行下一次掃描
        await Future.delayed(Duration(seconds: 1));  // 模擬掃描等待時間
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NFC掃描失敗: ${e.toString()}')),
      );
    } finally {
      // 掃描結束時將狀態重置
      setState(() {
        _isScanning = false;  // 掃描結束，允許再次進行掃描
      });
    }
  }

  // DFS 深度優先搜尋
  List<TreeNode> _dfs(TreeNode? node) {
    List<TreeNode> result = [];
    if (node == null) return result;

    result.add(node); // 訪問節點
    result.addAll(_dfs(node.left)); // 遍歷左子樹
    result.addAll(_dfs(node.right)); // 遍歷右子樹

    return result;
  }

  // BFS 廣度優先搜尋
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

  int _countNodes(TreeNode? node) {
    if (node == null) return 0;
    return 1 + _countNodes(node.left) + _countNodes(node.right);
  }

  // 開始計時
  void _startTimer() {
    _elapsedTime = 0;
    _isTimerRunning = true;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
  }

  void _startGame() {
    if (_scannedNfcCount > 0) {
      setState(() {
        _gameState = GameState.playing;
      });
      _startTimer();
    }
  }

  // 選擇搜尋演算法
  void _chooseAlgorithm(String algorithm) {
    setState(() {
      _searchAlgorithm = algorithm;
      _gameState = GameState.result;
      if (_randomTree != null) {
        _isTreeValid = _validateTreeTraversal(algorithm);
      }
    });
    _stopTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isTreeValid ? '樹結構正確，符合 $algorithm！' : '樹結構不正確',
          style: GoogleFonts.pressStart2p(color: Colors.white),
        ),
        backgroundColor: _isTreeValid ? Colors.green : Colors.red,
      ),
    );
  }

  // 驗證走訪順序是否符合選擇的演算法
  bool _validateTreeTraversal(String algorithm) {
    List<TreeNode> traversalResult;
    if (algorithm == '深度優先搜尋') {
      traversalResult = _dfs(_randomTree);
    } else {
      traversalResult = _bfs(_randomTree);
    }

    List<String> traversalUids = traversalResult.map((node) => node.uid).toList();
    return _scannedNfcUids.join(',') == traversalUids.join(',');
  }

  void _resetGame() {
    _stopTimer();
    setState(() {
      _gameState = GameState.preparation;
      _randomTree = null;
      _searchAlgorithm = null;
      _isTreeValid = false;
      _elapsedTime = 0;
      _scannedNfcCount = 0;
      _scannedNfcUids.clear(); // 重置掃描 UID
    });
  }

  ButtonStyle _gameButtonStyle(Color backgroundColor) {
    return ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
      textStyle: GoogleFonts.pressStart2p(fontSize: 18),
      foregroundColor: Colors.black,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '學習演算法',
          style: GoogleFonts.pressStart2p(color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.home, color: Colors.black),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
                (route) => false,
          ),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/game_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_gameState == GameState.preparation)
                    _buildPreparationView()
                  else if (_gameState == GameState.playing)
                    _buildPlayingView()
                  else if (_gameState == GameState.result)
                      _buildResultView(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreparationView() {
    return Column(
      children: [
        Text(
          'NFC 掃描',
          style: GoogleFonts.pressStart2p(
            fontSize: 24,
            color: Colors.black,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.white,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: _isScanning ? null : _scanNfc,
          child: _isScanning ? CircularProgressIndicator() : Text('掃描 NFC'),
          style: _gameButtonStyle(Colors.yellowAccent),
        ),
        SizedBox(height: 16.0),
        Text(
          'NFC 掃描到的節點數量：$_scannedNfcCount',
          style: GoogleFonts.pressStart2p(fontSize: 18, color: Colors.black),
        ),
        SizedBox(height: 24.0),
        ElevatedButton(
          onPressed: _scannedNfcCount > 0 ? _startGame : null,
          child: Text('開始遊戲'),
          style: _gameButtonStyle(Colors.greenAccent),
        ),
      ],
    );
  }

  Widget _buildPlayingView() {
    return Column(
      children: [
        Text(
          '生成的二元樹',
          style: GoogleFonts.pressStart2p(
            fontSize: 24,
            color: Colors.black,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.white,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.0),
        Text(
          '遊玩時間: $_elapsedTime 秒',
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
        SizedBox(height: 16.0),
        if (_randomTree != null)
          Container(
              height: 400,
              child: TreeVisualization(tree: _randomTree!)
          )
        else
          Text(
            '未生成樹',
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        SizedBox(height: 24.0),
        Text(
          '選擇搜尋演算法:',
          style: GoogleFonts.pressStart2p(
            fontSize: 20,
            color: Colors.black,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.white,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              onPressed: () => _chooseAlgorithm('深度優先搜尋'),
              icon: Icon(Icons.search, size: 30, color: Colors.white),
              label: Text('DFS'),
              style: _gameButtonStyle(Colors.redAccent),
            ),
            ElevatedButton.icon(
              onPressed: () => _chooseAlgorithm('廣度優先搜尋'),
              icon: Icon(Icons.map, size: 30, color: Colors.white),
              label: Text('BFS'),
              style: _gameButtonStyle(Colors.blueAccent),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return Column(
      children: [
        Text(
          '遊戲結果',
          style: GoogleFonts.pressStart2p(
            fontSize: 24,
            color: Colors.black,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.white,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.0),
        Text(
          '遊玩時間: $_elapsedTime 秒',
          style: GoogleFonts.pressStart2p(fontSize: 18, color: Colors.black),
        ),
        SizedBox(height: 16.0),
        Text(
          _isTreeValid
              ? '二元樹符合 ${_searchAlgorithm!} 的要求！'
              : '二元樹不符合 ${_searchAlgorithm!} 的要求！',
          style: GoogleFonts.pressStart2p(
            fontSize: 18,
            color: _isTreeValid ? Colors.green : Colors.red,
          ),
        ),
        SizedBox(height: 24.0),
        ElevatedButton(
          onPressed: _resetGame,
          child: Text('重新開始'),
          style: _gameButtonStyle(Colors.purpleAccent),
        ),
      ],
    );
  }
}

// 繪製二元樹的可視化
class TreeVisualization extends StatelessWidget {
  final TreeNode tree;

  TreeVisualization({required this.tree});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _TreePainter(tree: tree),
    );
  }
}

class _TreePainter extends CustomPainter {
  final TreeNode tree;
  final double nodeRadius = 20.0;
  final double verticalSpacing = 70.0;
  final double horizontalSpacing = 30.0;

  _TreePainter({required this.tree});

  @override
  void paint(Canvas canvas, Size size) {
    if (tree != null) {
      _drawTree(canvas, tree, size.width / 2, nodeRadius + 10, size.width / 4);
    }
  }

  void _drawTree(Canvas canvas, TreeNode node, double x, double y, double xOffset) {
    final Paint nodePaint = Paint()..color = Colors.orange;
    final Paint linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    // 畫當前節點
    canvas.drawCircle(Offset(x, y), nodeRadius, nodePaint);

    // 繪製節點中的數值
    final TextSpan span = TextSpan(
      style: TextStyle(color: Colors.black, fontSize: 12.0),
      text: node.value.toString(),
    );
    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x - nodeRadius / 2, y - nodeRadius / 2));

    // 繪製左右子節點
    if (node.left != null) {
      canvas.drawLine(Offset(x, y + nodeRadius), Offset(x - xOffset, y + verticalSpacing - nodeRadius), linePaint);
      _drawTree(canvas, node.left!, x - xOffset, y + verticalSpacing, xOffset / 2);
    }

    if (node.right != null) {
      canvas.drawLine(Offset(x, y + nodeRadius), Offset(x + xOffset, y + verticalSpacing - nodeRadius), linePaint);
      _drawTree(canvas, node.right!, x + xOffset, y + verticalSpacing, xOffset / 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
