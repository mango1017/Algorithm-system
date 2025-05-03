import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:okk/dynamic_assessment/feedback_engine.dart';

// --------------------------------------------------------
// ⚙️ DESIGN TWEAKS (keep logic intact)
// --------------------------------------------------------
// • 將所有主要內容限制在 max-width 600，確保大螢幕不會過度拉伸
// • 提取共用 PressStart2P 樣式與色票
// • 統一 ElevatedButton 風格 ← _primaryButton()
// • 所有捲動區加 Scrollbar & Padding
// --------------------------------------------------------

const double _kMaxContentWidth = 600;

final _palette = _AppPalette();

TextStyle _headline(double size, {Color? color}) => TextStyle(
  fontFamily: 'PressStart2P',
  fontSize: size,
  fontWeight: FontWeight.bold,
  color: color ?? _palette.dark,
);

ButtonStyle _primaryButton() => ElevatedButton.styleFrom(
  backgroundColor: _palette.primary,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  textStyle: const TextStyle(
      fontFamily: 'PressStart2P',
      fontWeight: FontWeight.bold,
      fontSize: 16),
);

class _AppPalette {
  final primary = Colors.indigo;
  final secondary = const Color(0xFF69BDFD);
  final secondaryDark = const Color(0xFFA47DFF);
  final light = Colors.grey.shade50;
  final dark = Colors.grey.shade900;
}

// --------------------------------------------------------
// AnimatedBackground：柔和漸層背景
// --------------------------------------------------------
class AnimatedBackground extends StatefulWidget {
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 10))
    ..repeat(reverse: true);
  late final Animation<Color?> _tween = ColorTween(
    begin: const Color(0xFFe0f7fa),
    end: Colors.white,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _tween,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_tween.value!, const Color(0xFFf0f8ff)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    ),
  );
}

// --------------------------------------------------------
// TreeNode / TreeGenerator
// --------------------------------------------------------
class TreeNode {
  TreeNode({required this.uid, required this.index});
  final String uid;
  final int index;
  TreeNode? left;
  TreeNode? right;
  double? x, y;
}

class TreeGenerator {
  static TreeNode? generate(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return null;
    list.shuffle();
    final nodes =
    list.map((e) => TreeNode(uid: e['uid'], index: e['index'])).toList();
    final q = Queue<TreeNode>()..add(nodes.first);
    var i = 1;
    while (i < nodes.length) {
      final cur = q.removeFirst();
      if (i < nodes.length) cur.left = nodes[i++];
      if (i < nodes.length) cur.right = nodes[i++];
      if (cur.left != null) q.add(cur.left!);
      if (cur.right != null) q.add(cur.right!);
    }
    return nodes.first;
  }
}

// --------------------------------------------------------
// TreeVisualization (+ painter)
// --------------------------------------------------------
class TreeVisualization extends StatelessWidget {
  const TreeVisualization(
      {super.key,
        required this.tree,
        required this.visitedUids,
        required this.rotation});
  final TreeNode tree;
  final Set<String> visitedUids;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    _layout(tree, 0, 0, 4);
    _center(tree);
    final d = _depth(tree);
    final minX = _minX(tree), maxX = _maxX(tree);
    final w = (maxX - minX).abs() * 40, h = d * 80;
    final sw = MediaQuery.of(context).size.width,
        sh = MediaQuery.of(context).size.height;
    final scale = min(sw / (w + 50), sh / (h + 100));
    final offsetX = sw / 2 - ((maxX + minX) / 2) * 40 * scale;

    return CustomPaint(
      size: Size(sw, sh),
      painter: _TreePainter(tree, visitedUids, rotation, scale, offsetX,
          palette: _palette),
    );
  }

  // --- layout helpers ---
  void _layout(TreeNode? n, double x, double y, double off) {
    if (n == null) return;
    n
      ..x = x
      ..y = y;
    _layout(n.left, x - off / 2, y + 1, off / 2);
    _layout(n.right, x + off / 2, y + 1, off / 2);
  }

  void _center(TreeNode root) {
    final minX = _minX(root), maxX = _maxX(root);
    final off = -(minX + (maxX - minX) / 2);
    _shift(root, off);
  }

  void _shift(TreeNode? n, double off) {
    if (n == null) return;
    n.x = (n.x ?? 0) + off;
    _shift(n.left, off);
    _shift(n.right, off);
  }

  double _minX(TreeNode n) =>
      [
        n.x ?? 0,
        if (n.left != null) _minX(n.left!),
        if (n.right != null) _minX(n.right!)
      ].reduce(min);
  double _maxX(TreeNode n) =>
      [
        n.x ?? 0,
        if (n.left != null) _maxX(n.left!),
        if (n.right != null) _maxX(n.right!)
      ].reduce(max);
  int _depth(TreeNode? n) => n == null ? 0 : 1 + max(_depth(n.left), _depth(n.right));
}

class _TreePainter extends CustomPainter {
  _TreePainter(this.tree, this.visited, this.rot, this.scale, this.cx,
      {required this.palette});
  final TreeNode tree;
  final Set<String> visited;
  final double rot, scale, cx;
  final _r = 20.0, _step = 40.0;
  final _AppPalette palette;

  @override
  void paint(Canvas c, Size s) => _draw(c, s, tree);

  void _draw(Canvas c, Size s, TreeNode n) {
    final paintLine = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
          colors: [palette.secondary, palette.secondaryDark])
          .createShader(Offset.zero & s);

    // edges
    for (final child in [n.left, n.right]) {
      if (child == null) continue;
      c.drawLine(_p(n), _p(child), paintLine);
      _draw(c, s, child);
    }

    // node circle + label
    final center = _p(n);
    final paintNode = Paint()
      ..shader = const RadialGradient(colors: [
        Color(0xFFC8F2FF),
        Color(0xFFA3E4FF),
        Color(0xFFE6C7FF)
      ]).createShader(Rect.fromCircle(center: center, radius: _r));
    c.drawCircle(center, _r, paintNode);
    if (visited.contains(n.uid)) {
      c.drawCircle(
          center,
          _r + 2,
          Paint()
            ..color = Colors.yellowAccent.withOpacity(.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6);
    }
    c.drawCircle(
        center,
        _r,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    final tp = TextPainter(
      text: TextSpan(
          text: n.index.toString(),
          style: const TextStyle(fontFamily: 'PressStart2P', fontSize: 14)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  Offset _p(TreeNode n) =>
      Offset((n.x ?? 0) * _step * scale + cx, (n.y ?? 0) * _step * scale);

  @override
  bool shouldRepaint(covariant _TreePainter o) =>
      tree != o.tree || visited.length != o.visited.length;
}

// --------------------------------------------------------
// 🔽 其餘業務邏輯
// --------------------------------------------------------

// 🚩 新增：在原列舉中插入 chooseTraversal
enum GameState {
  preparation,
  chooseTraversal,
  scanningForTree,
  showTree,
  scanningForTraversal,
  result
}

class LearnAlgorithmPage extends StatefulWidget {
  @override
  State<LearnAlgorithmPage> createState() => _LearnAlgorithmPageState();
}

class _LearnAlgorithmPageState extends State<LearnAlgorithmPage>
    with SingleTickerProviderStateMixin {
  // === 原有狀態 & 變數 ===
  GameState _state = GameState.preparation;
  TreeNode? _tree;
  String? _algo;
  String? _traversalType; // 🚩 新增
  Timer? _timer;
  int _elapsed = 0;
  bool _scanning = false;
  int _scanCountForTree = 0;
  final List<Map<String, dynamic>> _nfcForTree = [];
  final List<String> _nfcForTraversal = [];
  int _scanCount = 0;
  bool _treeOK = false;
  double _score = 0;
  final List<Map<String, dynamic>> _errBuf = [];

  final _colDefault = FirebaseFirestore.instance.collection('nfc_defaults');
  final _colScanned = FirebaseFirestore.instance.collection('nfc_scanned');
  StreamSubscription<QuerySnapshot>? _sub;
  List<Map<String, dynamic>> _scanInDB = [];

  List<String> _correctUids = [];
  int _nextIdx = 0;
  bool _dialogShown = false;
  late final AnimationController _coinCtrl =
  AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  @override
  void initState() {
    super.initState();
    _sub = _colScanned.snapshots().listen((s) =>
        setState(() => _scanInDB =
            s.docs.map((d) => d.data() as Map<String, dynamic>).toList()));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    _coinCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // 🔽 UI 入口
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coinCtrl,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
            title: const Text('深度與廣度演算法學習'),
            centerTitle: true,
            elevation: 4,
            backgroundColor: _palette.primary),
        body: Stack(children: [
          AnimatedBackground(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    Text('學習演算法', style: _headline(32)),
                    const SizedBox(height: 40),
                    AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _stateView()),
                    const SizedBox(height: 32),
                    _buildDBView(),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // --------------------------------------------------
  // 🔽 GameState 對應的 View
  // --------------------------------------------------
  Widget _stateView() {
    switch (_state) {
      case GameState.preparation:
        return _prepView();
      case GameState.chooseTraversal:
        return _chooseTraversalView();
      case GameState.scanningForTree:
        return _scanTreeView();
      case GameState.showTree:
        return _showTreeView();
      case GameState.scanningForTraversal:
        return _scanTravView();
      case GameState.result:
        return _resultView();
    }
  }

  // ===== 1) 準備畫面 =====
  Widget _prepView() => _card(
    Column(children: [
      Text('選擇搜尋演算法', style: _headline(24, color: _palette.dark)),
      const SizedBox(height: 24),
      Text('請選擇欲驗證的搜尋演算法。\n若選擇 DFS 會再讓您挑選前中後序。',
          style: _headline(14, color: Colors.grey.shade700),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton(
          onPressed: () => _onAlgo('深度優先搜尋'),
          style: _primaryButton(),
          child: const Text('深度優先搜尋')),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: () => _onAlgo('廣度優先搜尋'),
          style: _primaryButton(),
          child: const Text('廣度優先搜尋')),
    ]),
    key: 'prep',
  );

  // ===== 1.5) DFS 走訪類型選擇 =====
  Widget _chooseTraversalView() => _card(
    Column(children: [
      Text('DFS 走訪方式', style: _headline(24, color: _palette.dark)),
      const SizedBox(height: 16),
      Text('請選擇要驗證的 DFS 走訪順序：',
          style: _headline(14, color: Colors.grey.shade700),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton(
          onPressed: () => _onTraversalType('前序'),
          style: _primaryButton(),
          child: const Text('前序 (Pre-order)')),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: () => _onTraversalType('中序'),
          style: _primaryButton(),
          child: const Text('中序 (In-order)')),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: () => _onTraversalType('後序'),
          style: _primaryButton(),
          child: const Text('後序 (Post-order)')),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _reset,
          style: _primaryButton(),
          child: const Text('返回上一頁')),
    ]),
    key: 'traversal',
  );

  // ===== 2) 掃描生成樹 =====
  Widget _scanTreeView() => _card(
    Column(children: [
      Text('已選擇：$_algo${_traversalType != null ? ' ($_traversalType)' : ''}',
          style: _headline(18)),
      const SizedBox(height: 16),
      Text('請掃描 NFC 來決定樹的節點數量。\n(此階段尚未開始計時)',
          style: _headline(14, color: Colors.grey.shade700),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _scanning ? null : _scanNfcForTree,
          style: _primaryButton(),
          child: _scanning
              ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('掃描 NFC')),
      const SizedBox(height: 16),
      Text('已掃描節點數量：$_scanCount',
          style: _headline(14, color: Colors.grey.shade700)),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _nfcForTree.isNotEmpty ? _generateTree : null,
          style: _primaryButton(),
          child: const Text('生成二元樹')),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _reset,
          style: _primaryButton(),
          child: const Text('重新選擇演算法')),
    ]),
    key: 'scanTree',
  );

  // ===== 3) 顯示樹 =====
  Widget _showTreeView() => _card(
    Column(children: [
      Text('已生成的二元樹', style: _headline(24)),
      const SizedBox(height: 16),
      SizedBox(
        height: 350,
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(100),
          minScale: .5,
          maxScale: 3,
          child: TreeVisualization(
              tree: _tree!,
              visitedUids: const {},
              rotation: _coinCtrl.value * 2 * pi),
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _startTraversal,
          style: _primaryButton(),
          child: const Text('開始遊戲')),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _reset,
          style: _primaryButton(),
          child: const Text('重新開始')),
    ]),
    key: 'showTree',
  );

  // ===== 4) 掃描走訪 =====
  Widget _scanTravView() => _card(
    Column(children: [
      Text('已選擇：$_algo${_traversalType != null ? ' ($_traversalType)' : ''}',
          style: _headline(18)),
      const SizedBox(height: 16),
      Text('遊戲時間: $_elapsed 秒',
          style: _headline(14, color: Colors.grey.shade700)),
      const SizedBox(height: 16),
      Text('請依照樹的走訪順序掃描 NFC。',
          style: _headline(14, color: Colors.grey.shade700),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      SizedBox(
        height: 220,
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(100),
          minScale: .5,
          maxScale: 3,
          child: TreeVisualization(
              tree: _tree!,
              visitedUids: _nfcForTraversal.toSet(),
              rotation: _coinCtrl.value * 2 * pi),
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _scanning ? null : _scanNfcForTraversal,
          style: _primaryButton(),
          child: _scanning
              ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('掃描 NFC')),
      const SizedBox(height: 16),
      Text('已掃描節點數量：$_scanCount',
          style: _headline(14, color: Colors.grey.shade700)),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _showMapping,
          style: _primaryButton(),
          child: const Text('查看對照表')),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _nfcForTraversal.isNotEmpty ? _verify : null,
          style: _primaryButton(),
          child: const Text('驗證結果')),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _reset,
          style: _primaryButton(),
          child: const Text('重新開始')),
    ]),
    key: 'scanTrav',
  );

  // ===== 5) 結果 =====
  Widget _resultView() => _card(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_palette.secondary, _palette.secondaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Center(
            child: Text(
              _treeOK ? '恭喜！' : '結果分析',
              style: _headline(20, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '您的得分：${_score.toStringAsFixed(0)} / 100',
          style: _headline(18, color: _palette.dark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _treeOK
              ? '二元樹走訪順序完全符合 $_algo${_traversalType != null ? ' ($_traversalType)' : ''}！'
              : '二元樹走訪順序並非完全符合 $_algo${_traversalType != null ? ' ($_traversalType)' : ''}，請再試一次。',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'PressStart2P',
            color: _treeOK ? Colors.green : Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _reset,
          style: _primaryButton(),
          child: const Text('再試一次'),
        ),
      ],
    ),
    key: 'result',
  );

  // --------------------------------------------------
  // 🔽 共用 Card 包裝
  // --------------------------------------------------
  Widget _card(Widget child, {required String key}) => Card(
    key: ValueKey(key),
    color: Colors.white.withOpacity(.9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 8,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  // ---- DB 更新清單 ----
  Widget _buildDBView() => Card(
    color: Colors.white.withOpacity(.8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('使用者掃描資料：', style: _headline(14)),
            const SizedBox(height: 12),
            _scanInDB.isNotEmpty
                ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scanInDB.length,
              itemBuilder: (_, i) => ListTile(
                  title: Text('UID: ${_scanInDB[i]['uid']}',
                      style:
                      _headline(12, color: Colors.grey.shade800))),
            )
                : Text('目前沒有掃描資料。',
                style: _headline(12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _deleteAllDocs(_colScanned);
                setState(() => _scanInDB.clear());
                _toast('使用者掃描資料已清除');
              },
              style: _primaryButton(),
              child: const Text('清除掃描資料'),
            ),
          ]),
    ),
  );

  // --------------------------------------------------
  // 🔽 其餘邏輯函式
  // --------------------------------------------------
  void _toast(String msg, {bool err = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg,
              style:
              const TextStyle(fontFamily: 'PressStart2P', color: Colors.white)),
          backgroundColor: err ? Colors.redAccent : Colors.green,
          duration: const Duration(seconds: 2)));

  Future<void> _deleteAllDocs(CollectionReference col) async {
    final snap = await col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  // --------------------------------------------------
  // 🔽 NFC 掃描
  // --------------------------------------------------
  Future<void> _scanNfcForTree() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      if (await FlutterNfcKit.nfcAvailability != NFCAvailability.available) {
        throw Exception('NFC 無法使用');
      }
      final tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 10));
      final uid = tag?.id ?? '未知 UID';
      await FlutterNfcKit.finish();
      if (_nfcForTree.any((e) => e['uid'] == uid)) {
        _toast('UID: $uid 已掃描過', err: true);
      } else {
        _scanCountForTree++;
        _nfcForTree.add({'uid': uid, 'index': _scanCountForTree});
        _scanCount = _nfcForTree.length;
        await _colScanned.add({'uid': uid});
        _toast('掃描成功！UID: $uid');
      }
    } catch (e) {
      await FlutterNfcKit.finish();
      _toast('NFC 掃描失敗：$e', err: true);
    } finally {
      setState(() => _scanning = false);
    }
  }

  Future<void> _scanNfcForTraversal() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      if (await FlutterNfcKit.nfcAvailability != NFCAvailability.available) {
        throw Exception('NFC 無法使用');
      }
      final tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 10));
      final uid = tag?.id ?? '未知 UID';
      await FlutterNfcKit.finish();
      _handleTraversal(uid);
    } catch (e) {
      await FlutterNfcKit.finish();
      _toast('NFC 掃描失敗：$e', err: true);
    } finally {
      setState(() => _scanning = false);
    }
  }

  // ===== 顯示得分對話框 =====
  Future<void> _scoreDialog() async {
    if (_dialogShown) return; // 避免重複彈窗
    _dialogShown = true;
    _toast(_score == 100
        ? '恭喜！走訪順序完全符合 $_algo${_traversalType != null ? ' ($_traversalType)' : ''}！'
        : _score == 0
        ? '很可惜，順序幾乎不符合 $_algo${_traversalType != null ? ' ($_traversalType)' : ''}。'
        : '部分符合 $_algo${_traversalType != null ? ' ($_traversalType)' : ''}，得分 ${_score.toStringAsFixed(0)}。');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(.95),
        title: Row(children: [
          if (_treeOK) const Icon(Icons.emoji_events, color: Colors.amber),
          const SizedBox(width: 8),
          Text(_treeOK ? '恭喜！' : '結果分析', style: _headline(14)),
        ]),
        content:
        Text('您的得分：${_score.toStringAsFixed(0)} / 100', style: _headline(18)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('確認')),
        ],
      ),
    );
  }

  // ===== AI 小幫手對話框 =====
  Future<void> _assistantDialog(String msg) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red.shade100,
        title: Row(children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber),
          const SizedBox(width: 8),
          Text('小幫手的建議', style: _headline(14)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/assistant_robot.png'),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 16),
              Text('嗨！我是您的教學助理 🤖',
                  style: _headline(14), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(msg,
                  style: _headline(12, color: Colors.grey.shade800),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解了！',
                style: TextStyle(fontFamily: 'PressStart2P')),
          ),
        ],
      ),
    );
  }

  void _handleTraversal(String uid) {
    _nfcForTraversal.add(uid);
    _scanCount = _nfcForTraversal.length;
    if (_nextIdx < _correctUids.length) {
      final exp = _correctUids[_nextIdx];
      if (uid == exp) {
        _nextIdx++;
        _toast('掃描正確！UID: $uid');
      } else {
        _errBuf
            .add({'userUid': uid, 'expectedUid': exp, 'timestamp': DateTime.now()});
        _toast('錯誤掃描已記錄', err: true);
      }
    } else {
      _toast('掃描成功！UID: $uid');
    }
  }

  // --------------------------------------------------
  // 🔽 驗證與計分
  // --------------------------------------------------
  Future<void> _verify() async {
    if (_algo == null || _tree == null) {
      _toast('無法驗證，請確認已生成樹並選擇演算法', err: true);
      return;
    }
    if (_nfcForTraversal.isEmpty) {
      _toast('請先掃描至少一個 NFC 標籤以驗證結果', err: true);
      return;
    }

    // 取正確順序
    List<TreeNode> correctNodes;
    if (_algo == '廣度優先搜尋') {
      correctNodes = _bfs(_tree);
    } else {
      switch (_traversalType) {
        case '前序':
          correctNodes = _dfsPre(_tree);
          break;
        case '中序':
          correctNodes = _dfsIn(_tree);
          break;
        case '後序':
        default:
          correctNodes = _dfsPost(_tree);
      }
    }

    final correctUids = correctNodes.map((e) => e.uid).toList();
    _score = _calcScore(_nfcForTraversal, correctUids).toDouble();
    _treeOK = _score == 100;
    _stopTimer();
    await _scoreDialog();
    if (!mounted) return;
    setState(() => _state = GameState.result);

    // AI Feedback (原邏輯)
    if (_errBuf.isNotEmpty) {
      final asciiTree = generateAsciiTree(_tree);
      final errLvl = computeErrorLevel(_score, _errBuf);
      try {
        final feedback = await generateAiFeedback(
          mode: 'dynamic',
          score: 0,
          userUids: _nfcForTraversal,
          correctUids: correctUids,
          algorithm: '$_algo${_traversalType != null ? ' ($_traversalType)' : ''}',
          treeVisualization: asciiTree,
          errorInfo: errLvl,
        );
        await _assistantDialog(feedback);
      } catch (_) {
        _toast('無法獲取 AI 回饋，請稍後再試。', err: true);
      }
    }
  }

  // --------------------------------------------------
  // 🔽 LCS 長度計算 + 評分邏輯
  // --------------------------------------------------
  int _lcsLength(List<String> a, List<String> b) {
    final m = a.length, n = b.length;
    if (m == 0 || n == 0) return 0;
    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (var i = 1; i <= m; ++i) {
      for (var j = 1; j <= n; ++j) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }
      }
    }
    return dp[m][n];
  }

  int _calcScore(List<String> user, List<String> correct) {
    if (correct.isEmpty) return 0; // 安全防呆

    // yes: LCS 長度
    final yes = _lcsLength(user, correct);

    // 在兩邊都出現的節點
    final common = user.toSet().intersection(correct.toSet()).length;

    // no: 順序錯誤；count: 多餘
    final no = common - yes;
    final count = user.where((u) => !correct.contains(u)).length;

    // Score_change
    final denom = yes + no + count;
    final scoreChange = denom == 0 ? 0.0 : (yes / denom) * 100;

    // Score_check
    final studentCheckTimes = user.length;
    final answerCheckTimes = correct.length;
    final scoreCheck = (studentCheckTimes / answerCheckTimes) * 100;

    // Final
    return ((scoreChange + scoreCheck) / 2).clamp(0, 100).round();
  }

  // --------------------------------------------------
  // 🔽 走訪
  // --------------------------------------------------
  List<TreeNode> _dfsPre(TreeNode? n) {
    if (n == null) return [];
    return [n, ..._dfsPre(n.left), ..._dfsPre(n.right)];
  }

  List<TreeNode> _dfsIn(TreeNode? n) {
    if (n == null) return [];
    return [..._dfsIn(n.left), n, ..._dfsIn(n.right)];
  }

  List<TreeNode> _dfsPost(TreeNode? n) {
    if (n == null) return [];
    return [..._dfsPost(n.left), ..._dfsPost(n.right), n];
  }

  List<TreeNode> _bfs(TreeNode? root) {
    if (root == null) return [];
    final q = Queue<TreeNode>()..add(root);
    final res = <TreeNode>[];
    while (q.isNotEmpty) {
      final n = q.removeFirst();
      res.add(n);
      if (n.left != null) q.add(n.left!);
      if (n.right != null) q.add(n.right!);
    }
    return res;
  }

  // --- Timer helpers ---
  void _startTimer() {
    _elapsed = 0;
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _elapsed++));
  }

  void _stopTimer() => _timer?.cancel();

  // --------------------------------------------------
  // 🔽 UI event helpers
  // --------------------------------------------------
  void _onAlgo(String a) async {
    setState(() {
      _algo = a;
      _traversalType = null;
      _resetVars();
      _state =
      a == '深度優先搜尋' ? GameState.chooseTraversal : GameState.scanningForTree;
    });
    if (a == '廣度優先搜尋') await _loadDefault();
  }

  void _onTraversalType(String t) async {
    setState(() {
      _traversalType = t;
      _state = GameState.scanningForTree;
    });
    await _loadDefault();
  }

  Future<void> _loadDefault() async {
    try {
      final snap = await _colDefault.get();
      final data = snap.docs
          .map((d) => d.data() as Map<String, dynamic>)
          .toList()
        ..sort((a, b) => a['uid'].compareTo(b['uid']));
      var idx = 0;
      for (final r in data) _nfcForTree.add({'uid': r['uid'], 'index': ++idx});
      setState(() {
        _scanCount = _nfcForTree.length;
        _scanCountForTree = idx;
      });
      _toast('已自動載入 ${_nfcForTree.length} 筆預設 NFC 資料');
    } catch (_) {
      _toast('載入預設 NFC 資料失敗', err: true);
    }
  }

  void _generateTree() {
    if (_algo == null) return _toast('請先選擇演算法', err: true);
    if (_algo == '深度優先搜尋' && _traversalType == null) {
      return _toast('請先選擇 DFS 走訪類型', err: true);
    }
    if (_nfcForTree.isEmpty) {
      return _toast('請先掃描或載入至少一個 NFC 標籤來生成樹', err: true);
    }
    _tree = TreeGenerator.generate(_nfcForTree);
    setState(() => _state = GameState.showTree);
  }

  void _startTraversal() {
    setState(() {
      _state = GameState.scanningForTraversal;
      _nfcForTraversal.clear();
      _scanCount = 0;
      _score = 0;
      _treeOK = false;
    });

    if (_tree != null) {
      List<TreeNode> res;
      if (_algo == '廣度優先搜尋') {
        res = _bfs(_tree);
      } else {
        switch (_traversalType) {
          case '前序':
            res = _dfsPre(_tree);
            break;
          case '中序':
            res = _dfsIn(_tree);
            break;
          case '後序':
          default:
            res = _dfsPost(_tree);
        }
      }
      _correctUids = res.map((e) => e.uid).toList();
      _nextIdx = 0;
    }
    _startTimer();
  }

  void _reset() async {
    _stopTimer();
    await _deleteAllDocs(_colScanned);
    setState(() {
      _state = GameState.preparation;
      _algo = null;
      _traversalType = null;
      _tree = null;
      _resetVars();
      _scanInDB.clear();
    });
  }

  void _resetVars() {
    _elapsed = 0;
    _treeOK = false;
    _nfcForTree.clear();
    _nfcForTraversal.clear();
    _scanCountForTree = 0;
    _scanCount = 0;
    _scanning = false;
    _score = 0;
    _correctUids.clear();
    _nextIdx = 0;
    _dialogShown = false;
    _errBuf.clear();
  }

  void _showMapping() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white.withOpacity(.95),
      title: Row(children: [
        const Icon(Icons.list_alt, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text('節點對照表', style: _headline(14))
      ]),
      content: SizedBox(
        width: 300,
        child: ListView(
          shrinkWrap: true,
          children: _nfcForTree
              .map((n) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('節點 ${n['index']} => UID: ${n['uid']}',
                style:
                _headline(12, color: Colors.grey.shade800)),
          ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'))
      ],
    ),
  );
}
