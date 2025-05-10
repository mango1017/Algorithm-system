import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:okk/dynamic_assessment/feedback_engine.dart';
import 'package:okk/Tree logic/tree_logic_interface.dart';
import 'package:okk/Tree logic/binary_search_tree.dart';
import 'package:okk/Tree logic/avl_tree.dart';
import 'package:okk/Tree logic/binary_tree.dart';
import 'package:okk/Tree logic/red_black_tree.dart';
import 'package:okk/algorithm/bfs_algorithm.dart';
import 'package:okk/algorithm/dfs_algorithm.dart';

// --------------------------------------------------------
// ⚙️ DESIGN TWEAKS
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
  final primary      = Colors.indigo;
  final secondary    = const Color(0xFF69BDFD);
  final secondaryDark= const Color(0xFFA47DFF);
  final light        = Colors.grey.shade50;
  final dark         = Colors.grey.shade900;
}

// =============================================================
//  TreeType Enum
// =============================================================
enum TreeType { plain, bst, avl, redBlack }

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
// 🔽 其餘業務邏輯
// --------------------------------------------------------
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
  late final AudioPlayer _audioPlayer;
  GameState _state = GameState.preparation;



  TreeNode? _tree;
  TreeType? _treeType;
  TreeLogic? _logic;
  String? _algo;           // "深度優先搜尋" / "廣度優先搜尋"
  String? _traversalType;  // "前序"/"中序"/"後序"
  String _treeName() {
    switch (_treeType) {
      case TreeType.plain:
        return '二元樹';
      case TreeType.bst:
        return '二元搜尋樹';
      case TreeType.avl:
        return 'AVL 樹';
      case TreeType.redBlack:
        return '紅黑樹';
      default:
        return '（未選擇）';
    }
  }

  // NFC & 計時
  Timer? _timer;
  int _elapsed = 0;
  bool _scanning = false;
  final List<Map<String, dynamic>> _nfcForTree = [];
  final List<String> _nfcForTraversal = [];
  int _scanCount = 0;
  int _scanCountForTree = 0;

  // 評分
  bool _treeOK = false;
  double _score = 0;
  final List<Map<String, dynamic>> _errBuf = [];

  // Firestore
  final _colDefault = FirebaseFirestore.instance.collection('nfc_defaults');
  final _colScanned = FirebaseFirestore.instance.collection('nfc_scanned');
  StreamSubscription<QuerySnapshot>? _sub;
  List<Map<String, dynamic>> _scanInDB = [];

  // 走訪正解
  List<String> _correctUids = [];
  int _nextIdx = 0;
  bool _dialogShown = false;

  late final AnimationController _coinCtrl =
  AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _sub = _colScanned.snapshots().listen((s) {
      setState(() {
        _scanInDB = s.docs.map((d) => d.data() as Map<String, dynamic>).toList();
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    _coinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coinCtrl,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: const Text('深度與廣度演算法學習'),
          centerTitle: true,
          backgroundColor: _palette.primary,
        ),
        body: Stack(children: [
          AnimatedBackground(),
          _mainContent(),
        ]),
      ),
    );
  }

  Widget _mainContent() => Center(
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
  );

  Widget _stateView() {
    switch (_state) {
      case GameState.preparation:          return _prepView();
      case GameState.chooseTraversal:      return _chooseTraversalView();
      case GameState.scanningForTree:      return _scanTreeView();
      case GameState.showTree:             return _showTreeView();
      case GameState.scanningForTraversal: return _scanTravView();
      case GameState.result:               return _resultView();
    }
  }

  // ==================================================================
  // 1. Preparation：選樹型 & 演算法
  // ==================================================================
  Widget _prepView() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('選擇樹型', style: _headline(18)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: TreeType.values.map((t) => ChoiceChip(
            label: Text(
              switch (t) {
                TreeType.plain => '普通二元樹',
                TreeType.bst => '二元搜尋樹',
                TreeType.avl => 'AVL樹',
                TreeType.redBlack => '紅黑樹',
              },
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 12,
                color: t == _treeType ? Colors.white : _palette.dark,
              ),
            ),
            selected: t == _treeType,
            onSelected: (selected) => setState(() => _treeType = selected ? t : null),
            selectedColor: _palette.primary,
            backgroundColor: _palette.light,
          )).toList(),
        ),
        const SizedBox(height: 24),
        if (_treeType != null) ...[
          Text(
            '目前選擇的樹型：${switch (_treeType!) {
              TreeType.plain => '普通二元樹',
              TreeType.bst => '二元搜尋樹',
              TreeType.avl => 'AVL樹',
              TreeType.redBlack => '紅黑樹',
            }}',
            style: _headline(14, color: _palette.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
        Text(
          '請先選擇要練習的樹型與搜尋演算法。\n'
              '接著我們會讓您掃描一些 NFC 標籤來建構樹。',
          style: _headline(14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _treeType != null ? () => _onAlgo('深度優先搜尋') : null,
          style: _primaryButton(),
          child: const Text('深度優先搜尋'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _treeType != null ? () => _onAlgo('廣度優先搜尋') : null,
          style: _primaryButton(),
          child: const Text('廣度優先搜尋'),
        ),
      ],
    ),
    key: const ValueKey('prep'),
  );

  Widget _chooseTraversalView() => _card(
    Column(children: [
      Text('DFS 走訪方式', style: _headline(24)),
      const SizedBox(height: 16),
      Text('請選擇要驗證的 DFS 走訪順序：', style: _headline(14), textAlign: TextAlign.center),
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
    key: const ValueKey('traversal'),
  );

  Widget _scanTreeView() => _card(
    Column(children: [
      Text('已選擇：$_algo${_traversalType != null ? ' ($_traversalType)' : ''}', style: _headline(18)),
      const SizedBox(height: 16),
      Text('請掃描 NFC 來決定樹的節點數量。\n(此階段尚未開始計時)', style: _headline(14), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _scanning ? null : _scanNfcForTree,
          style: _primaryButton(),
          child: _scanning
              ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth:2))
              : const Text('掃描 NFC')),
      const SizedBox(height: 16),
      Text('已掃描節點數量：$_scanCount', style: _headline(14)),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _nfcForTree.isNotEmpty ? _generateTree : null,
        style: _primaryButton(),
        child: Text('生成${_treeName()}'),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _reset,
          style: _primaryButton(),
          child: const Text('重新選擇演算法')),
    ]),
    key: const ValueKey('traversal'),
  );

  Widget _showTreeView() => _card(
    Column(children: [
      Text('已生成的${_treeName()}', style: _headline(24)),
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
          ),
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
    key: const ValueKey('traversal'),
  );

  Widget _scanTravView() => _card(
    Column(children: [
      Text('已選擇：$_algo${_traversalType != null ? ' ($_traversalType)' : ''}', style: _headline(18)),
      const SizedBox(height: 16),
      Text('遊戲時間: $_elapsed 秒', style: _headline(14)),
      const SizedBox(height: 16),
      Text('請依照樹的走訪順序掃描 NFC。', style: _headline(14), textAlign: TextAlign.center),
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
          ),
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: _scanning ? null : _scanNfcForTraversal,
          style: _primaryButton(),
          child: _scanning
              ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth:2))
              : const Text('掃描 NFC')),
      const SizedBox(height: 16),
      Text('已掃描節點數量：$_scanCount', style: _headline(14)),
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
    key: const ValueKey('traversal'),
  );

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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Center(
            child: Text(
              _treeOK ? '恭喜！' : '結果分析',
              style: _headline(20, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('您的得分：${_score.toStringAsFixed(0)} / 100', style: _headline(18)),
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
    key: const ValueKey('traversal'),
  );

  // ==================================================================
  // 生成樹：依 TreeType new 對應邏輯實例
  // ==================================================================
  void _generateTree() {
    if (_algo == null || _treeType == null) {
      return _toast('請先選擇樹型與演算法', err: true);
    }
    switch (_treeType!) {
      case TreeType.plain:
        _logic = PlainTreeLogic();
        break;
      case TreeType.bst:
        _logic = BinarySearchTreeLogic();
        break;
      case TreeType.avl:
        _logic = AVLTreeLogic();
        break;
      case TreeType.redBlack:
        _logic = RedBlackTreeLogic();
        break;
    }
    _logic!.buildTreeFromNfc(_nfcForTree);
    _tree = _logic!.toTreeNode();
    setState(() => _state = GameState.showTree);
  }

  // ==================================================================
  // 開始走訪：統一呼叫 _logic 的 traverseX 方法
  // ==================================================================
  void _startTraversal() {
    setState(() {
      _state = GameState.scanningForTraversal;
      _nfcForTraversal.clear();
      _scanCount = 0;
      _score = 0;
      _treeOK = false;
    });

    if (_logic != null) {
      List<String> res;
      if (_algo == '廣度優先搜尋') {
        res = _logic!.traverseLevel();
      } else {
        res = {
          '前序':   _logic!.traversePre(),
          '中序':   _logic!.traverseIn(),
          '後序':   _logic!.traversePost(),
        }[_traversalType]!;
      }
      _correctUids = res;
      _nextIdx = 0;
    }

    _startTimer();
  }

  // ------------------------------------------------------------------
  // 卡片容器改用 Key
  // ------------------------------------------------------------------
  Widget _card(Widget child, { required Key key }) => Card(
    key: key,
    color: Colors.white.withOpacity(.9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 8,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

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

  Future<void> _scoreDialog() async {
    if (_dialogShown) return;
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
        _audioPlayer.play(AssetSource('ding.mp3'));
        _nextIdx++;
        _toast('掃描正確！UID: $uid');
      } else {
        _audioPlayer.play(AssetSource('buzz.mp3'));
        _errBuf.add({
          'userUid': uid,
          'expectedUid': exp,
          'timestamp': DateTime.now()
        });
        _toast('錯誤掃描已記錄', err: true);
      }
    } else {
      _audioPlayer.play(AssetSource('buzz.mp3'));
      _toast('掃描成功！UID: $uid');
    }
  }

  Future<void> _verify() async {
    if (_algo == null || _tree == null) {
      _toast('無法驗證，請確認已生成樹並選擇演算法', err: true);
      return;
    }
    if (_nfcForTraversal.isEmpty) {
      _toast('請先掃描至少一個 NFC 標籤以驗證結果', err: true);
      return;
    }

    // ← 3. 呼叫獨立演算法
    List<TreeNode> correctNodes;
    if (_algo == '廣度優先搜尋') {
      correctNodes = bfs(_tree!);
    } else {
      switch (_traversalType) {
        case '前序':
          correctNodes = dfsPre(_tree!);
          break;
        case '中序':
          correctNodes = dfsIn(_tree!);
          break;
        case '後序':
        default:
          correctNodes = dfsPost(_tree!);
      }
    }

    final correctUids = correctNodes.map((e) => e.uid).toList();
    _score = _calcScore(_nfcForTraversal, correctUids).toDouble();
    _treeOK = _score == 100;
    _stopTimer();
    await _scoreDialog();
    if (!mounted) return;
    setState(() => _state = GameState.result);

    if (_errBuf.isNotEmpty) {
      final asciiTree = generateAsciiTree(_tree!);
      final errLvl = computeErrorLevel(
        scoreChange: _calcScore(_nfcForTraversal, _correctUids).toDouble(),
        scoreSpan: _scoreSpan(_nfcForTraversal, _correctUids),
      );
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

  double _scoreSpan(List<String> user, List<String> correct) {
    final n = correct.length;
    final len = min(user.length, n);
    int curr = 0, maxSpan = 0;
    for (var i = 0; i < len; ++i) {
      if (user[i] == correct[i]) {
        curr++;
      } else {
        if (curr > maxSpan) maxSpan = curr;
        curr = 0;
      }
    }
    if (curr > maxSpan) maxSpan = curr;
    return (maxSpan / n) * 100;
  }

  int _calcScore(List<String> user, List<String> correct) {
    if (correct.isEmpty) return 0;
    final yes = _lcsLength(user, correct);
    final common = user.toSet().intersection(correct.toSet()).length;
    final no = common - yes;
    final count = user.where((u) => !correct.contains(u)).length;
    final denom = yes + no + count;
    final scoreChange = denom == 0 ? 0.0 : (yes / denom) * 100;
    final scoreSpan = _scoreSpan(user, correct);
    return ((scoreChange + scoreSpan) / 2).clamp(0, 100).round();
  }

  void _startTimer() {
    _elapsed = 0;
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _elapsed++));
  }

  void _stopTimer() => _timer?.cancel();

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
