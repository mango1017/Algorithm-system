import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:DyAlgo/Tree logic/tree_logic_interface.dart';
import 'package:DyAlgo/Tree logic/binary_tree.dart';
import 'package:DyAlgo/Tree logic/binary_search_tree.dart' as bst;
import 'package:DyAlgo/Tree logic/avl_tree.dart' as avl;
import 'package:DyAlgo/Tree logic/red_black_tree.dart' as rb;
import 'package:DyAlgo/Tree logic/red_black_tree_visualization.dart';
import 'package:DyAlgo/algorithm/bfs_algorithm.dart';
import 'package:DyAlgo/algorithm/dfs_algorithm.dart';
import 'package:DyAlgo/Algorithm/challenge_generator.dart';
import 'package:DyAlgo/Algorithm/operation_challenge.dart' as oc;
import 'package:DyAlgo/dynamic_assessment/feedback_engine.dart';
import 'DSVisualizer.dart';


/// ============================================================
/// 基本樣式 / Palette
/// ============================================================
const double _kMaxContentWidth = 600;


/// 一個小卡片，顯示：演算法 / 走訪方式 / 階段 / 挑戰
class AlgorithmStatusCard extends StatelessWidget {
  final String algorithm;                  // 例如 "深度優先搜尋" 或 "廣度優先搜尋"
  final String? traversalType;             // 前序 / 中序 / 後序，廣度搜尋可傳 null
  final Phase phase;                       // 插入 / 刪除 / 走訪
  final oc.OperationChallenge? challenge;  // 如果沒有挑戰就傳 null

  const AlgorithmStatusCard({
    Key? key,
    required this.algorithm,
    this.traversalType,
    required this.phase,
    this.challenge,
  }) : super(key: key);

  String get _phaseText {
    switch (phase) {
      case Phase.insertion: return '插入階段';
      case Phase.deletion:  return '刪除階段';
      case Phase.traversal: return '走訪階段';
    }
  }



  @override
  Widget build(BuildContext context) {
    final state = LearnAlgorithmPage.of(context)!;

    // 取得已走訪的節點 index
// 取得已走訪的節點 index（先過濾掉那些不在 currentRaw 裡的 uid）
    List<int> visitedIndices = [];
    if (phase == Phase.traversal) {
      visitedIndices = state._visitedAttempts
          .where((uid) => state._currentRaw.any((e) => e['uid'] == uid))
          .map((uid) {
        final entry = state._currentRaw.firstWhere((e) => e['uid'] == uid);
        return entry['index'] as int;
      })
          .toList();
    }

    final firstIdx = visitedIndices.isNotEmpty ? visitedIndices.first : null;
    final lastIdx  = visitedIndices.isNotEmpty ? visitedIndices.last  : null;

    // 判斷是 Queue 還是 Stack
    final isQueue    = algorithm.contains('廣度');
    final headLabel  = isQueue ? '隊首' : '堆疊頂';
    final tailLabel  = isQueue ? '隊尾' : '堆疊底';

    return Card(
      color: Colors.white.withOpacity(.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 演算法
            Text('演算法：$algorithm', style: _headline(16, color: _palette.primary)),
            if (traversalType != null) ...[
              const SizedBox(height: 4),
              Text('走訪方式：$traversalType', style: _headline(14, color: _palette.primary)),
            ],
            const SizedBox(height: 6),
            // 階段
            Text('目前階段：$_phaseText', style: _headline(14, color: _palette.primary)),
            // 挑戰
            if (challenge != null) ...[
              const SizedBox(height: 6),
              Text(
                '挑戰：請${challenge!.kind == oc.OperationKind.insert ? '插入' : '刪除'} ${challenge!.count} 個節點',
                style: _headline(12, color: Colors.redAccent),
              ),
            ],

            // 只在普通二元樹的走訪階段顯示隊首／隊尾
            if (phase == Phase.traversal && state._treeType == TreeType.plain) ...[
              const Divider(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  firstIdx != null
                      ? '$headLabel：$firstIdx'
                      : '尚未走訪任何節點',
                  style: _headline(12, color: _palette.secondary),
                ),
              ),
              const SizedBox(height: 4),
              if (lastIdx != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$tailLabel：$lastIdx',
                    style: _headline(12, color: _palette.secondary),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppPalette {
  final primary = Colors.indigo;
  final secondary = const Color(0xFF69BDFD);
  final secondaryDark = const Color(0xFFA47DFF);
  final light = Colors.grey.shade50;
  final dark = Colors.grey.shade900;
}
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
      fontFamily: 'PressStart2P', fontWeight: FontWeight.bold, fontSize: 16),
);

/// ============================================================
/// TreeType 枚舉
/// ============================================================
enum TreeType { plain, bst, avl, redBlack }

/// ============================================================
/// 遊戲狀態列舉
/// ============================================================
enum GameState {
  preparation,
  chooseTraversal,
  scanningForTree,
  preview,
  showTree,
  result,
}

/// ============================================================
/// 內部 Phase：插入 / 刪除 / 走訪
/// ============================================================
enum Phase { insertion, deletion, traversal }

/// ============================================================
/// 柔和漸層背景
/// ============================================================
class AnimatedBackground extends StatefulWidget {
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: const Duration(seconds: 10))
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

/// ============================================================
/// 主頁面
/// ============================================================
class LearnAlgorithmPage extends StatefulWidget {
  @override
  State<LearnAlgorithmPage> createState() => _LearnAlgorithmPageState();

  static _LearnAlgorithmPageState? of(BuildContext context) =>
      context.findAncestorStateOfType<_LearnAlgorithmPageState>();
}

class _LearnAlgorithmPageState extends State<LearnAlgorithmPage>
    with SingleTickerProviderStateMixin {
  // Challenge 相關
  final ChallengeGenerator _gen = ChallengeGenerator();
  oc.OperationChallenge? _challenge;
  int _startingSize = 0;

  // ─────────────────── 新增的計分欄位 ───────────────────
  int _correctInsertions = 0;
  int _totalInsertions   = 0;
  int _correctDeletions  = 0;
  int _totalDeletions    = 0;




// 插入題答對/答錯回調
  void _onInsertAnswered(bool correct) {
    _totalInsertions++;
    if (correct) _correctInsertions++;
  }

// 刪除題答對回調（原本就有，保留）
  void _onDeleteAnswered(bool correct) {
    _totalDeletions++;
    if (correct) _correctDeletions++;
  }

  final CollectionReference _colLogs =
  FirebaseFirestore.instance.collection('learning_logs');

  /// 提示使用者進入插入／刪除／走訪前的對話框（移除「查看目前樹結構」按鈕）
  Future<void> _showPhaseDialog(String title, String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              title.contains('插入') ? Icons.download_rounded
                  : title.contains('刪除') ? Icons.upload_rounded
                  : Icons.visibility,
              color: _palette.primary,
            ),
            const SizedBox(width: 12),
            Text(title, style: _headline(18, color: _palette.primary)),
          ],
        ),
        content: Text(message, style: _headline(14), textAlign: TextAlign.center),
        actions: [
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: _palette.primary,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('開始', style: _headline(14, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }


  late final AudioPlayer _audio;
  GameState _state = GameState.preparation;
  Phase? _phase;

  final misStats = {
    MisCode.TMC: MisStat(),
    MisCode.NOM: MisStat(),
  };


  TreeNode? _tree;
  TreeType? _treeType;
  TreeLogic? _logic;
  String? _algo;
  String? _traversalType;

  final Set<String> _inTree = {};
  final Set<String> _visitedNodes = {};
  int _nextIndex = 1;
  List<Map<String, dynamic>> _currentRaw = [];

  List<String> _correctUids = [];
  int _nextIdx = 0;

  Timer? _timer;
  int _elapsed = 0;
  bool _scanning = false;
  final List<Map<String, dynamic>> _nfcForTree = [];
  int _scanCount = 0;

  bool _treeOK = false;
  double _score = 0;
  List<Map<String, dynamic>> _errBuf = [];
  final List<String> _visitedAttempts = [];

  final _colDefault = FirebaseFirestore.instance.collection('nfc_defaults');
  final _colScanned = FirebaseFirestore.instance.collection('nfc_scanned');
  StreamSubscription<QuerySnapshot>? _sub;
  List<Map<String, dynamic>> _scanInDB = [];

  bool _dialogShown = false;

  late final AnimationController _coinCtrl =
  AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  /// 將 TreeNode 轉成可被 JSON 編碼的 Map
  Map<String, dynamic> treeToJson(TreeNode? node) {
    if (node == null) return {};
    return {
      'uid':   node.uid,
      'index': node.index,
      'left':  node.left  != null ? treeToJson(node.left)  : null,
      'right': node.right != null ? treeToJson(node.right) : null,
    };
  }

  @override
  void initState() {
    super.initState();
    _audio = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _sub = _colScanned.snapshots().listen(
          (s) => setState(() => _scanInDB = s.docs.map((d) => d.data()).toList()),
    );
  }

  @override
  void dispose() {
    _detachListener();
    _sub?.cancel();
    _timer?.cancel();
    _coinCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  /// 視覺化元件：移除點擊回呼
  Widget _treeVis({required Set<String> visited}) {
    if (_treeType == TreeType.redBlack) {
      return RedBlackTreeVisualization(
        root: _tree!,
        visitedUids: visited,
      );
    } else {
      return TreeVisualization(
        tree: _tree!,
        visitedUids: visited,
      );
    }
  }

  void _attachListener() {
    if (_logic is ActionNotifiable) {
      (_logic as ActionNotifiable).addListener(_onTreeAction);
    }
  }

  void _detachListener() {
    if (_logic is ActionNotifiable) {
      (_logic as ActionNotifiable).removeListener(_onTreeAction);
    }
  }

  void _onTreeAction(TreeActionEvent e) {
    _toast(
      e.kind == OperationKind.insert
          ? '插入節點 ${e.uid}'
          : '刪除節點 ${e.uid}',
    );
    _checkChallenge();
  }


  /// ──────── 2. 查看樹結構 對話框 ────────
  void _showTreeDialog([BuildContext? parentCtx]) {
    final dialogContext = parentCtx ?? context;
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (treeCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text('目前樹結構', style: _headline(16, color: _palette.primary)),
        content: SizedBox(
          width: 300,
          height: 300,
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 2,
            child: _treeVis(visited: _visitedNodes),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(treeCtx).pop(),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coinCtrl,
      builder: (_, __) => Scaffold(
        body: Stack(children: [AnimatedBackground(), _mainContent()]),
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
              child: _stateView(),
            ),
            const SizedBox(height: 32),
            _buildDBView(),
          ]),
        ),
      ),
    ),
  );

  Widget _stateView() {
    switch (_state) {
      case GameState.preparation:
        return _prepView();
      case GameState.chooseTraversal:
        return _chooseTraversalView();
      case GameState.scanningForTree:
        return _scanTreeView();
      case GameState.preview:
        return _previewView();
      case GameState.showTree:
        return _showTreeView();
      case GameState.result:
        return _resultView();
    }
  }

  // 1. Preparation
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
          children: TreeType.values.map((t) {
            final label = {
              TreeType.plain: '普通二元樹',
              TreeType.bst: '二元搜尋樹',
              TreeType.avl: 'AVL 樹',
              TreeType.redBlack: '紅黑樹',
            }[t]!;
            return ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 12,
                  color: t == _treeType ? Colors.white : _palette.dark,
                ),
              ),
              selected: t == _treeType,
              onSelected: (sel) => setState(() => _treeType = sel ? t : null),
              selectedColor: _palette.primary,
              backgroundColor: _palette.light,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        if (_treeType != null) ...[
          Text(
            '目前選擇的樹型：${_treeName()}',
            style: _headline(14, color: _palette.primary),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          '請選擇樹型與搜尋演算法後，掃描 NFC 標籤以建構與走訪樹。',
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

  // 2. DFS 走訪方式
  Widget _chooseTraversalView() => _card(
    Column(
      children: [
        Text('DFS 走訪方式', style: _headline(24)),
        const SizedBox(height: 16),
        Text(
          '請選擇要驗證的 DFS 走訪順序：',
          style: _headline(14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ...['前序', '中序', '後序'].map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton(
            onPressed: () => _onTraversalType(t),
            style: _primaryButton(),
            child: Text(
              '$t (${t == '前序' ? 'Pre' : t == '中序' ? 'In' : 'Post'}-order)',
            ),
          ),
        )),
        ElevatedButton(
          onPressed: _reset,
          style: _primaryButton(),
          child: const Text('返回上一頁'),
        ),
      ],
    ),
    key: const ValueKey('choose_traversal'),
  );

  // 3. 掃描建樹 & NFC 互動
  Widget _scanTreeView() => _card(
    Column(
      children: [
        Text(
          '已選擇：$_algo${_traversalType != null ? ' ($_traversalType)' : ''}',
          style: _headline(18),
        ),
        const SizedBox(height: 16),
        Text(
          '請掃描 NFC 來決定樹的節點數量。\n(此階段尚未開始計時)',
          style: _headline(14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _scanning ? null : _scanNfcUnified,
          style: _primaryButton(),
          child: _scanning
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('掃描 NFC'),
        ),
        const SizedBox(height: 16),
        Text('已掃描節點數量：${_nfcForTree.length}', style: _headline(14)),
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
          child: const Text('重新選擇演算法'),
        ),
      ],
    ),
    key: const ValueKey('scan_tree'),
  );

  // 3.5. 預覽
  Widget _previewView() => _card(
    Column(
      children: [
        Text('請確認生成的${_treeName()}', style: _headline(24)),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(100),
            minScale: .5,
            maxScale: 3,
            child: _treeVis(visited: const {}),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              _state = GameState.showTree;
              _startTimer();
              _phase = (_treeType == TreeType.plain)
                  ? Phase.traversal
                  : (_challenge!.kind == oc.OperationKind.insert
                  ? Phase.insertion
                  : Phase.deletion);
              _nextIdx = 0;
              _visitedNodes.clear();
              _visitedAttempts.clear();
            });
            // 跳提示對話框
            if (_phase == Phase.insertion) {
              await _showPhaseDialog('📥 插入階段', '請掃描 NFC 插入新節點');
            } else if (_phase == Phase.deletion) {
              await _showPhaseDialog('📤 刪除階段', '請掃描 NFC 刪除節點');
            } else {
              await _showPhaseDialog('🔍 走訪階段', '請依正確走訪順序掃描 NFC');
            }
          },
          style: _primaryButton(),
          child: const Text('開始遊戲'),
        ),
      ],
    ),
    key: const ValueKey('preview'),
  );

// 4. 顯示樹 & NFC 互動
  Widget _showTreeView() => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '已生成的${_treeName()}',
          style: _headline(24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        AlgorithmStatusCard(
          algorithm:     _algo!,
          traversalType: _traversalType,
          phase:         _phase!,
          challenge:     _challenge,
        ),

        const SizedBox(height: 16),

        // 資料結構視覺化：Queue vs Stack，同步只顯示正確走訪過的節點
        if (_phase == Phase.traversal && _treeType == TreeType.plain) ...[
          Text(
            _algo!.contains('廣度') ? '佇列 (FIFO)' : '堆疊 (LIFO)',
            style: _headline(14, color: _palette.primary),
          ),
          const SizedBox(height: 8),

          Builder(builder: (ctx) {
            final state = LearnAlgorithmPage.of(ctx)!;
            final correctVisitedIndices = state._visitedNodes.map((uid) {
              return state._currentRaw
                  .firstWhere((e) => e['uid'] == uid)['index'] as int;
            }).toList();

            return DSVisualizer(
              isQueue: _algo!.contains('廣度'),
              items:   correctVisitedIndices,
            );
          }),
          const SizedBox(height: 16),
        ],

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 300),
          child: AspectRatio(
            aspectRatio: 1.2,
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20),
              minScale: .5,
              maxScale: 2,
              child: _treeVis(visited: _visitedNodes),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 掃描 NFC 按鈕
        ElevatedButton(
          onPressed: _scanning ? null : _scanNfcUnified,
          style: _primaryButton(),
          child: _scanning
              ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('掃描 NFC'),
        ),
        const SizedBox(height: 12),
        Text('目前節點數量：${_inTree.length}', style: _headline(14)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _verify,      style: _primaryButton(), child: const Text('驗證結果')),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _showMapping, style: _primaryButton(), child: const Text('節點對照表')),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _reset,       style: _primaryButton(), child: const Text('重新開始')),
      ],
    ),
    key: const ValueKey('show_tree'),
  );


  // 6. 結果畫面
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
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('您的得分：${_score.toStringAsFixed(0)} / 100',
            style: _headline(18)),
        const SizedBox(height: 12),
        Text(
          _treeOK
              ? '${_treeName()} 走訪順序完全正確！'
              : '走訪順序尚未完全正確，不要氣餒！',
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
    key: const ValueKey('result'),
  );

  /// 建樹 & 挑戰題
  void _generateTree() {
    if (_algo == null || _treeType == null) {
      return _toast('請先選擇樹型與演算法', err: true);
    }
    _detachListener();


    final copy = List<Map<String, dynamic>>.from(_nfcForTree)
      ..sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

    switch (_treeType!) {
      case TreeType.plain:
        _logic = PlainTreeLogic();
        _logic!.buildTreeFromNfc(copy);
        break;


      case TreeType.bst: {
        final bst.BinarySearchTreeLogic bstLogic = bst.BinarySearchTreeLogic();
        // 固定映射：先排序
        copy.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

        // 在這裡 inline 一個遞迴函式
        void buildRandom(List<Map<String, dynamic>> nodes) {
          if (nodes.isEmpty) return;
          // 選 pivot（避免首尾保證左右都有）
          final int pivotIndex = nodes.length > 2
              ? math.Random().nextInt(nodes.length - 2) + 1
              : math.Random().nextInt(nodes.length);
          final pivot = nodes[pivotIndex];
          bstLogic.insert(pivot['index'] as int, pivot['uid'] as String);
          // 左右子列遞迴
          buildRandom(nodes.sublist(0, pivotIndex));
          buildRandom(nodes.sublist(pivotIndex + 1));
        }

        // 呼叫建樹
        buildRandom(copy);
        _logic = bstLogic;
        break;
      }


      case TreeType.avl:
      // 1️⃣ 正常建立一棵平衡的 AVL（autoBalance = true）
        final avlLogic = avl.AVLTreeLogic();
        for (var i = 0; i < copy.length - 1; i++) {
          final e = copy[i];
          avlLogic.insert(e['index'] as int, e['uid'] as String);
        }
        // 2️⃣ 用最後一個節點強制造成「唯一 pivot 失衡」
        final extra = copy.last;
        avlLogic.insertUnbalanced(
          extra['index'] as int,
          extra['uid'] as String,
        );
        // 確保我們真的有 pivot，否則再隨機挑一個再 unbalance 一次
        if (avlLogic.findFirstUnbalancedNode() == null && copy.length > 1) {
          final retry = copy[math.Random().nextInt(copy.length - 1)];
          avlLogic.insertUnbalanced(
            retry['index'] as int,
            retry['uid'] as String,
          );
        }
        _logic = avlLogic;
        break;

      case TreeType.redBlack:
        _logic = rb.RedBlackTreeLogic();
        final rbLogic = _logic as rb.RedBlackTreeLogic;
        for (var e in copy) {
          rbLogic.insert(e['index'] as int, e['uid'] as String);
        }
        break;
    }

    _tree = _logic!.toTreeNode();
    _attachListener();

    if (_treeType != TreeType.plain) {
      final cat = {
        TreeType.bst:      oc.TreeCategory.bst,
        TreeType.avl:      oc.TreeCategory.avl,
        TreeType.redBlack: oc.TreeCategory.redBlack,
      }[_treeType]!;

      // 1️⃣ 原本隨機決定挑戰節點數
      _challenge = _gen.nextChallenge(cat);

      // 2️⃣ Clamp count to at most 2，並補上缺少的 category 參數
      _challenge = oc.OperationChallenge(
        category: cat,
        kind:     _challenge!.kind,
        count:    math.min(_challenge!.count, 2),
      );

      // 3️⃣ 記錄起始大小
      _startingSize = _logic!.size;
    } else {
      _challenge = null;
    }
    _inTree
      ..clear()
      ..addAll(_nfcForTree.map((e) => e['uid'] as String));
    _currentRaw = List<Map<String, dynamic>>.from(_nfcForTree);
    _nextIndex = _currentRaw.length + 1;
    _visitedNodes.clear();

    if (_algo == '廣度優先搜尋') {
      _correctUids = bfs(_tree!).map((e) => e.uid).toList();
    } else {
      _correctUids = {
        '前序': dfsPre(_tree!),
        '中序': dfsIn(_tree!),
        '後序': dfsPost(_tree!),
      }[_traversalType]!.map((e) => e.uid).toList();
    }

    setState(() => _state = GameState.preview);
  }


  /// Helpers：在 _currentRaw 中找出前驅/後繼的 index
  int _findPredecessorIndex(int target) {
    final indices = _currentRaw.map((e) => e['index'] as int).toList();
    indices.sort();
    int pred = -1;
    for (var idx in indices) {
      if (idx < target && idx > pred) pred = idx;
    }
    return pred;
  }
  int _findSuccessorIndex(int target) {
    final indices = _currentRaw.map((e) => e['index'] as int).toList();
    indices.sort();
    for (var idx in indices) {
      if (idx > target) return idx;
    }
    return -1;
  }


  /// BST 插入：二選一題（正確 + 誘答）
  /// ──────── 1. 前序／中序／後序 插入選擇題 ────────
  /// 第一層對話框：傳入全局 context，builder 拿到 dialogCtx
  Future<bool> _showBSTPlacementQuestionDialog(String uid, int newIndex) async {
    if (_currentRaw.isEmpty) return false;

    // 1️⃣ 計算正確父節點與方向
    final bst.BinarySearchTreeLogic bstLogic = _logic as bst.BinarySearchTreeLogic;
    final int correctParent  = bstLogic.findParentForInsertion(newIndex);
    final bool correctIsLeft = newIndex < correctParent;

    // 2️⃣ 準備「正確選項」與「干擾選項」
    final List<int> others = _currentRaw
        .map((e) => e['index'] as int)
        .where((i) => i != correctParent)
        .toList()
      ..shuffle();
    final Map<String, dynamic> wrong = others.isNotEmpty
        ? {'parent': others.first, 'isLeft': correctIsLeft}
        : {'parent': correctParent, 'isLeft': !correctIsLeft};
    final options = [
      {'parent': correctParent, 'isLeft': correctIsLeft},
      wrong,
    ]..shuffle();

    String? choice;

    // 3️⃣ 顯示對話框
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: Text('節點 $newIndex（UID: $uid）要插在哪裡？'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              final label = '掛到父節點 ${opt['parent']} 的'
                  '${opt['isLeft'] ? '左' : '右'}子樹';
              return RadioListTile<String>(
                title: Text(label),
                value: label,
                groupValue: choice,
                onChanged: (v) => setState(() => choice = v),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => _showTreeDialog(dialogCtx),
              child: const Text('查看樹結構'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: choice == null
                  ? null
                  : () {
                final sel = options.firstWhere((opt) {
                  final lbl = '掛到父節點 ${opt['parent']} 的'
                      '${opt['isLeft'] ? '左' : '右'}子樹';
                  return lbl == choice;
                });
                final ok = sel['parent'] == correctParent &&
                    sel['isLeft'] == correctIsLeft;
                _onInsertAnswered(ok); // 計分
                bstLogic.insert(newIndex, uid);
                if (ok) {
                  _toast('答對了！節點已正確插入。');
                } else {
                  _toast(
                    '答錯了…正確應掛到父節點 $correctParent 的'
                        '${correctIsLeft ? '左' : '右'}子樹',
                    err: true,
                  );
                }
                Navigator.of(dialogCtx).pop(ok);
              },
              child: const Text('確認'),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  /// BST 刪除：前驅 / 後繼 / 不需要替換 三選一
  Future<bool> _showBSTReplacementQuestionDialog(int targetIdx) async {
    // 1. 計算前驅與後繼索引
    final int pre = _findPredecessorIndex(targetIdx);
    final int suc = _findSuccessorIndex(targetIdx);


    TreeNode? _findNodeByIndex(TreeNode? root, int idx) {
      if (root == null) return null;
      if (root.index == idx) return root;
      return _findNodeByIndex(root.left, idx) ?? _findNodeByIndex(root.right, idx);
    }

    int _childrenCount(TreeNode? node) {
      if (node == null) return 0;
      int c = 0;
      if (node.left  != null) c++;
      if (node.right != null) c++;
      return c;
    }

    // 2. 建立「前驅」「後繼」「不需要替換」選項
    final options = <Map<String, dynamic>>[
      if (pre >= 0) {'label': '使用前驅節點 $pre', 'usePre': true},
      if (suc >= 0) {'label': '使用後繼節點 $suc', 'usePre': false},
      {'label': '不需要替換',      'usePre': null},
    ];

    String? choice;

    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('刪除節點 $targetIdx：要用哪個替換？'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              return RadioListTile<String>(
                title: Text(opt['label'] as String),
                value: opt['label'] as String,
                groupValue: choice,
                onChanged: (v) => setDlg(() => choice = v),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => _showTreeDialog(ctx),
              child: const Text('查看樹結構'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: choice == null
                  ? null
                  : () {
                final sel = options.firstWhere((opt) => opt['label'] == choice);
                final usePre = sel['usePre'] as bool?;
// 判斷正確性：兩子 → 應選前驅或後繼；否則 → 應選「不需要替換」
                final targetNode = _findNodeByIndex(_tree, targetIdx);
                final childCnt   = _childrenCount(targetNode);
                final bool twoChildren = (childCnt == 2);

                bool correct;
                if (twoChildren) {
                  correct = (usePre == true && pre >= 0) ||
                      (usePre == false && suc >= 0);
                } else {
                  correct = (usePre == null);
                }
                _onDeleteAnswered(correct);
                _applyDeleteAt(targetIdx, usePredecessor: usePre);
                _toast(
                  correct ? '答對了！已完成刪除。'
                      : '答錯了…已依你的選擇完成刪除',
                  err: !correct,
                );
                Navigator.of(ctx).pop(true);
              },
              child: const Text('確認'),
            ),
          ],
        ),
      ),
    );

    return ok ?? false;
  }



  /// AVL 旋轉：出題（LL / LR / RR / RL / 不需要旋轉）
  Future<void> _showAVLRotationQuestionDialog() async {
    final logic = _logic as avl.AVLTreeLogic;

    // 嘗試找 pivot；找不到代表已平衡
    int? pivot;
    String correctCase = 'NONE';
    try {
      pivot = logic.findFirstUnbalancedNode();
      correctCase = logic.determineRotationCase(pivot!);
    } catch (_) {
      // 保持 NONE
    }

    // 五個選項打亂順序
    final options = ['LL', 'LR', 'RR', 'RL', '不需要旋轉']..shuffle();
    String? choice;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return AlertDialog(
            title: Text(
                pivot == null
                    ? 'AVL 旋轉判斷'
                    : 'AVL 旋轉判斷 (pivot: $pivot)'
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    pivot == null
                        ? '目前樹已平衡，應選「不需要旋轉」'
                        : '節點 $pivot 不平衡，應做哪一種旋轉？'
                ),
                const SizedBox(height: 12),
                ...options.map((opt) => RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                  groupValue: choice,
                  onChanged: (v) => setDlg(() => choice = v),
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: choice == null
                    ? null
                    : () {
                  final bool correct =
                      (choice == '不需要旋轉' && correctCase == 'NONE') ||
                          (choice == correctCase);

                  // 單一重點通知
                  _toast(
                    correct
                        ? '答對了！${pivot == null ? "樹已平衡。" : "正確操作：$correctCase"}'
                        : '答錯了…正確是${correctCase == "NONE" ? "不需要旋轉" : correctCase}',
                    err: !correct,
                  );

                  // 答對且需要旋轉時，自動平衡並重繪
                  if (correct && pivot != null) {
                    logic.balanceAt(pivot);
                    setState(() {});  // 觸發畫面更新
                  }

                  Navigator.pop(ctx);
                },
                child: const Text('確認'),
              ),
            ],
          );
        },
      ),
    );
  }


  /// 無條件在 BST 刪除時跳出替換選擇題
  Future<bool> _showDeleteDialog(String uid) async {
    final targetMap = _currentRaw.firstWhere((e) => e['uid'] == uid);
    final int target = targetMap['index'] as int;

    if (_treeType == TreeType.bst) {
      final bool ok = await _showBSTReplacementQuestionDialog(target);
      if (!ok) {
        return false;
      }
      return true;
    } else {
      _applyDeleteAt(target, usePredecessor: null);
      _onDeleteAnswered(true);
      return true;
    }
  }


  // 加在 _applyDeleteAt 之前（檔案裡任意私有方法區即可）
  void _refreshAfterStructuralChange() {
    // 重新轉成可視樹
    _tree = _logic!.toTreeNode();
    // 依照目前演算法更新正確走訪序列
    _updateCorrectUids();
    // 更新畫面
    setState(() {});
  }



  void _applyDeleteAt(int target, {bool? usePredecessor}) {
    setState(() {
      // 1. 從 _currentRaw、_inTree 移除目標
      final targetMap = _currentRaw.firstWhere((e) => e['index'] == target);
      final targetUid = targetMap['uid'] as String;
      _currentRaw.removeWhere((e) => e['index'] == target);
      _inTree.remove(targetUid);

      // 2. (可選) 前驅／後繼替換
      if (usePredecessor != null) {
        final repIdx = usePredecessor
            ? _findPredecessorIndex(target)
            : _findSuccessorIndex(target);
        final repMap = _currentRaw.firstWhere((e) => e['index'] == repIdx);
        final repUid = repMap['uid'] as String;
        _currentRaw.removeWhere((e) => e['index'] == repIdx);
        _currentRaw.add({'uid': repUid, 'index': target});
      }

      // 3. 更新邏輯樹
      _detachListener();
      if (_treeType == TreeType.bst) {
        ( _logic as bst.BinarySearchTreeLogic ).delete(targetMap['uid'] as String);
      } else {
        _logic!.buildTreeFromNfc(_currentRaw);
      }
      _attachListener();

      // 4. 重新產生可視樹 & 走訪序列
      _tree = _logic!.toTreeNode();
      _updateCorrectUids();
    }); // <-- 這裡 setState
  }

  Future<void> _scanNfcUnified() async {
    // 印出目前階段，方便除錯
    print('🔍 [_scanNfcUnified] current phase: $_phase');

    if (_scanning) return;
    setState(() => _scanning = true);

    try {
      while (_scanning) {
        // 0. 檢查 NFC 是否可用
        if (await FlutterNfcKit.nfcAvailability != NFCAvailability.available) {
          _toast('NFC 無法使用', err: true);
          break;
        }

        NFCTag? tag;
        try {
          // 1. 呼叫 poll，等使用者貼卡或按取消
          tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 10));
        } catch (_) {
          // 使用者在系統對話框按「取消」或超時，跳出迴圈
          break;
        }

        // 如果沒讀到任何標籤，跳出
        if (tag == null) break;

        final String uid = tag.id;
        // 2. 成功拿到 tag 後，再關閉會話
        await FlutterNfcKit.finish();

        // ─────────── 根據目前階段處理掃描結果 ───────────

        // 3a. 掃描建樹階段
        if (_state == GameState.scanningForTree) {
          if (_nfcForTree.any((e) => e['uid'] == uid)) {
            _toast('此節點已掃過', err: true);
          } else {
            final newIdx = _nextIndex++;
            _nfcForTree.add({'uid': uid, 'index': newIdx});
            await _colScanned.add({'uid': uid, 'index': newIdx});
            setState(() => _scanCount = _nfcForTree.length);
            _toast('新增節點 $newIdx');
          }
          // 等待 3 秒避免重複掃描
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }

        // 3b. 插入階段
        if (_phase == Phase.insertion) {
          if (_inTree.contains(uid)) {
            _toast('此節點已存在於樹中', err: true);
            _audio.play(AssetSource('buzz.mp3'));
          } else {
            final int newIdx = _nextIndex; // 暫存編號
            bool proceed = true;

            // BST 插入題
            if (_treeType == TreeType.bst) {
              proceed = await _showBSTPlacementQuestionDialog(uid, newIdx);
            }
            if (!proceed) {
              _toast('已取消插入');
              await Future.delayed(const Duration(seconds: 3));
              continue;
            }

            // 真正插入 raw data
            _nextIndex++;
            _currentRaw.add({'uid': uid, 'index': newIdx});
            _inTree.add(uid);

            // 更新邏輯樹
            _detachListener();
            if (_treeType == TreeType.bst) {
              ( _logic as bst.BinarySearchTreeLogic ).insert(newIdx, uid);
            } else if (_treeType == TreeType.avl) {
              ( _logic as avl.AVLTreeLogic ).insertUnbalanced(newIdx, uid);
            } else {
              _logic!.buildTreeFromNfc(_currentRaw);
            }
            _attachListener();
            _refreshAfterStructuralChange();

            // AVL 旋轉題
            if (_treeType == TreeType.avl) {
              final pivot = ( _logic as avl.AVLTreeLogic ).findFirstUnbalancedNode();
              if (pivot != null) {
                await _showAVLRotationQuestionDialog();
              }
            }

            _audio.play(AssetSource('ding.mp3'));
            _toast('插入完成');

            _checkChallenge();
          }
          // 等待 3 秒避免重複掃描
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }

        // 3c. 刪除階段
        if (_phase == Phase.deletion) {
            if (!_inTree.contains(uid)) {
              _toast('此節點不在樹中', err: true);
              _audio.play(AssetSource('buzz.mp3'));
            } else {
              // 呼叫刪除對話框，並依回傳值決定後續
              final bool didDelete = await _showDeleteDialog(uid);
              if (didDelete) {
                _audio.play(AssetSource('ding.mp3'));
                _toast('刪除完成，請確認樹結構');
                _checkChallenge();
              } else {
                _toast('已取消刪除');
              }
            }
            await Future.delayed(const Duration(seconds: 3));
            continue;

        }

        // 3d. 走訪階段
        if (_phase == Phase.traversal) {
          // 檢查是不是不在樹上或已掃描過
          if (!_inTree.contains(uid) || _visitedNodes.contains(uid)) {
            _toast('此節點已走訪過或不存在', err: true);
            _audio.play(AssetSource('buzz.mp3'));
            // 把這次錯誤或重複也算進 attempts
            _visitedAttempts.add(uid);
          } else {
            final expectedUid = _correctUids[_nextIdx];
            if (uid == expectedUid) {
              // 正確
              _visitedNodes.add(uid);
              _nextIdx++;
              _audio.play(AssetSource('ding.mp3'));
              _toast('走訪正確');
            } else {
              // 錯誤
              _toast('走訪順序錯誤', err: true);
              _audio.play(AssetSource('buzz.mp3'));
            }
            // 無論對錯都記錄一次
            _visitedAttempts.add(uid);

            setState(() {});
            // 全部走訪完畢
            if (_nextIdx >= _correctUids.length) {
              _toast('已完成所有節點走訪');
              setState(() => _scanning = false);
              break;
            }
          }
          // 等待避免連續重複掃描
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }



        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      try {
        await FlutterNfcKit.finish();
      } catch (_) {}
      _toast('NFC 掃描失敗：$e', err: true);
    } finally {
      setState(() => _scanning = false);
    }
  }


  void _updateCorrectUids() {
    if (_tree != null) {
      if (_algo == '廣度優先搜尋') {
        _correctUids = bfs(_tree!).map((e) => e.uid).toList();
      } else if (_algo == '深度優先搜尋') {
        if (_traversalType == '前序') {
          _correctUids = dfsPre(_tree!).map((e) => e.uid).toList();
        } else if (_traversalType == '中序') {
          _correctUids = dfsIn(_tree!).map((e) => e.uid).toList();
        } else if (_traversalType == '後序') {
          _correctUids = dfsPost(_tree!).map((e) => e.uid).toList();
        }
      }
      _nextIdx = 0;
    }
  }

  void _checkChallenge() {
    if (_challenge == null) return;
    final delta = _logic!.size - _startingSize;
    final needed = _challenge!.count *
        (_challenge!.kind == oc.OperationKind.insert ? 1 : -1);
    final legal = _treeType == TreeType.bst
        ? _logic!.isBST()
        : _treeType == TreeType.avl
        ? _logic!.isAVL()
        : _treeType == TreeType.redBlack
        ? _logic!.isRedBlack()
        : true;
    if (delta == needed && legal) {
      _toast('✅ 挑戰完成！');
      setState(() {
        _challenge = null;
        _phase = Phase.traversal;
      });
      // 跳到走訪階段前的提示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPhaseDialog('🔍 走訪階段', '請依正確走訪順序掃描 NFC');
      });
    }
  }


  /// 驗證結果 & AI 回饋
  Future<void> _verify() async {
    if (_algo == null || _tree == null) {
      _toast('無法驗證，請確認已生成樹並選擇演算法', err: true);
      return;
    }
    if (_visitedAttempts.isEmpty) {
      _toast('請先走訪至少一個節點以驗證結果', err: true);
      return;
    }

    // 1. 取得正確走訪節點
    final List<TreeNode> correctNodes = (_algo == '廣度優先搜尋')
        ? bfs(_tree!)
        : {
      '前序': dfsPre(_tree!),
      '中序': dfsIn(_tree!),
      '後序': dfsPost(_tree!),
    }[_traversalType]!;

    // 2. 誤差偵測（省略細節）
    detectNOM(
      userSeq: _visitedAttempts,
      correctSeq: correctNodes.map((n) => n.uid).toList(),
      stat: misStats[MisCode.NOM]!,
    );
    detectTraversalModeConfusion(
      userSeq: _visitedAttempts,
      bfsSeq: bfs(_tree!).map((e) => e.uid).toList(),
      dfsSeq: dfsPre(_tree!).map((e) => e.uid).toList(),
      stat: misStats[MisCode.TMC]!,
    );

    // 3. 計算分數（省略細節）
    final double visitScore = _calcScore(
      _visitedAttempts,
      correctNodes.map((n) => n.uid).toList(),
    );
    final double insertScore = _totalInsertions == 0
        ? 100.0
        : (_correctInsertions / _totalInsertions * 100.0);
    final double deleteScore = _totalDeletions == 0
        ? 100.0
        : (_correctDeletions / _totalDeletions * 100.0);

    // 4. 最終分數、OK 判斷（省略細節）
    double totalScore;
    bool ok;
    if (_treeType == TreeType.plain) {
      totalScore = visitScore;
      ok = totalScore == 100.0;
    } else {
      totalScore = insertScore * 0.25 +
          deleteScore * 0.25 +
          visitScore * 0.50;
      ok = totalScore == 100.0;
    }

    // 5. 更新 UI 分數顯示
    setState(() {
      _score = totalScore;
      _treeOK = ok;
    });

    // 6. 停止計時並顯示分數對話框
    _stopTimer();
    await _scoreDialog();
    if (!mounted) return;

    // 切換到結果頁面
    setState(() => _state = GameState.result);

    // 7. 準備傳給 LLM 的參數
    final uidToIndex = <String,int>{};
    for (final e in _currentRaw) {
      uidToIndex[e['uid'] as String] = e['index'] as int;
    }
    final List<int> userIndices = _visitedAttempts.map((u) => uidToIndex[u]!).toList();
    final List<int> correctIndices = correctNodes.map((n) => uidToIndex[n.uid]!).toList();

    final String levelStr = _score == 100.0
        ? '滿分'
        : progressiveLevel(score: _score, stats: misStats);

    // 8. 呼叫 AI 取得回饋
    String feedback;
    try {
      feedback = await generateAiFeedback(
        treeType:       _treeName(),
        algorithm:      '$_algo${_traversalType ?? ''}',
        stats:          misStats,
        level:          levelStr,
        misCode:        misStats[MisCode.NOM]!.hit > 0 ? 'NOM' : 'TMC',
        score:          _score,
        userIndices:    userIndices,
        correctIndices: correctIndices,
      );
      debugPrint('🧠 AI 回饋內容：\n$feedback');
    } catch (e, st) {
      debugPrint('❌ generateAiFeedback 錯誤：$e\n$st');
      feedback = '無法取得 AI 回饋：$e';
    }

    // 9. 顯示 AI 回饋對話框
    await _assistantDialog(feedback);
  }


  Future<void> _scoreDialog() async {
    if (_dialogShown) return;
    _dialogShown = true;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        title: Row(children: [
          if (_treeOK) const Icon(Icons.emoji_events, color: Colors.amber),
          const SizedBox(width: 8),
          Text(_treeOK ? '恭喜！' : '結果分析', style: _headline(14)),
        ]),
        content: Text('您的得分：${_score.toStringAsFixed(0)} / 100',
            style: _headline(18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('確認')),
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
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/assistant_robot.png'),
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
            child: const Text('了解了！', style: TextStyle(fontFamily: 'PressStart2P')),
          ),
        ],
      ),
    );
  }

  void _showMapping() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(.95),
        title: Row(children: [
          const Icon(Icons.list_alt, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text('節點對照表', style: _headline(14)),
        ]),
        content: SizedBox(
          width: 300,
          child: _currentRaw.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            itemCount: _currentRaw.length,
            itemBuilder: (_, i) {
              final e = _currentRaw[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '節點 ${e['index']} → UID: ${e['uid']}',
                  style: _headline(12, color: Colors.grey.shade800),
                ),
              );
            },
          )
              : Text(
            '目前樹上沒有任何節點。',
            style: _headline(12, color: Colors.grey.shade600),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉')),
        ],
      ),
    );
  }

  /// 計算最長共同子序列長度 (yes)
  int _lcsLength(List<String> a, List<String> b) {
    final m = a.length, n = b.length;
    if (m == 0 || n == 0) return 0;
    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (var i = 1; i <= m; ++i) {
      for (var j = 1; j <= n; ++j) {
        dp[i][j] = (a[i - 1] == b[j - 1])
            ? dp[i - 1][j - 1] + 1
            : math.max(dp[i - 1][j], dp[i][j - 1]);
      }
    }
    return dp[m][n];
  }

  /// 計算分數，對應公式：
  ///   yes   = 最長共同子序列長度（真正走對的節點數）
  ///   no    = 0（不另懲罰漏掃）
  ///   count = user 裡「不在 correct」的次數 + 「重複掃描」的次數
  ///   Score = yes / (yes + no + count) * 100
  /// 計算分數：yes / (yes + no + count) * 100
  double _calcScore(List<String> user, List<String> correct) {
    // 1. yes：最長共同子序列長度
    final yes = _lcsLength(user, correct);

    // 2. no：正確序列中漏掃的節點數
    final no = correct.where((uid) => !user.contains(uid)).length;

    // 3. count：所有嘗試總次數 - 正確走訪次數
    //    （這裡包含順序錯、掃到不在 correct 裡，或重複掃描等各種錯誤）
    final int count = user.length - yes;

    // 4. 帶回公式
    final denom = yes + no + count;
    return denom == 0 ? 0.0 : (yes / denom * 100);
  }



  void _startTimer() {
    _elapsed = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
  }

  void _stopTimer() => _timer?.cancel();

  String _treeName() => {
    TreeType.plain: '二元樹',
    TreeType.bst: '二元搜尋樹',
    TreeType.avl: 'AVL 樹',
    TreeType.redBlack: '紅黑樹',
  }[_treeType]!;

  void _onAlgo(String a) {
    setState(() {
      _algo = a;
      _traversalType = null;
      _resetVars();
      _nfcForTree.clear();
      _scanCount = 0;
      _nextIndex = 1;
      _state = a == '深度優先搜尋'
          ? GameState.chooseTraversal
          : GameState.scanningForTree;
      if (a == '廣度優先搜尋' && _tree != null) {
        _correctUids = bfs(_tree!).map((e) => e.uid).toList();
        _nextIdx = 0;
      }
    });
    if (a == '廣度優先搜尋') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDefault());
    }
  }

  void _onTraversalType(String t) {
    setState(() {
      _traversalType = t;
      _state = GameState.scanningForTree;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDefault());
  }

  /// 用來存放「預設」從 Firestore 載入的 NFC
  List<Map<String, dynamic>> _defaultNfc = [];

  Future<void> _loadDefault() async {
    try {
      final snap = await _colDefault
          .orderBy('order', descending: false)
          .get();

      _defaultNfc.clear();
      _nfcForTree.clear();
      int idx = 0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final entry = {
          'uid': data['uid'] as String,
          'index': ++idx,
        };
        _defaultNfc.add(entry);
        _nfcForTree.add(entry);
      }
      setState(() {
        _scanCount = _nfcForTree.length;
        _nextIndex = _nfcForTree.length + 1;
      });


      _toast('已載入 ${_nfcForTree.length} 筆預設 NFC');
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
      _logic = null;
      _phase = null;
      _resetVars();
      _scanInDB.clear();
      _inTree.clear();
      _visitedNodes.clear();
      _nfcForTree.clear();
      _currentRaw.clear();
      _correctUids.clear();
      _nextIdx = 0;
    });
  }

  void _resetVars() {
    _elapsed = 0;
    _treeOK = false;
    _scanCount = 0;
    _scanning = false;
    _score = 0;
    _dialogShown = false;
    _errBuf.clear();
    _visitedAttempts.clear();
  }

  Future<void> _deleteAllDocs(CollectionReference col) async {
    final snap = await col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  Widget _card(Widget child, {required Key key}) => Card(
    key: key,
    color: Colors.white.withAlpha(230),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 8,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );


  Widget _buildDBView() => Card(
    color: Colors.white.withOpacity(.85),
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
                  style: _headline(12, color: Colors.grey.shade800)),
            ),
          )
              : Text(
            '目前沒有掃描資料。',
            style: _headline(12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Align(
           alignment: Alignment.center,
           child: ElevatedButton(
           onPressed: () async {
              // 1. 刪除 Firestore 裡的使用者掃描記錄
              await _deleteAllDocs(_colScanned);
              // 2. 把 _nfcForTree 恢復成只有預設那一批
              _nfcForTree
                ..clear()
                ..addAll(_defaultNfc);
              // 3. 同步 _inTree、_currentRaw、_nextIndex
              _inTree
                ..clear()
                ..addAll(_defaultNfc.map((e) => e['uid'] as String));
              _currentRaw = List.from(_defaultNfc);
              _nextIndex = _nfcForTree.length + 1;
              // 4. 重建樹
              _detachListener();
              _logic!.buildTreeFromNfc(_currentRaw);
              _tree = _logic!.toTreeNode();
              _attachListener();
              // 5. 更新 UI
              setState(() {
                _scanInDB.clear();
                _scanCount = _nfcForTree.length;
              });
              _toast('使用者掃描資料已清除');
            },
            style: _primaryButton(),
            child: const Text('清除掃描資料'),
            ),
          ),
        ],
      ),
    ),
  );

  void _toast(String msg, {bool err = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              color: Colors.white,
            ),
          ),
          backgroundColor: err ? Colors.redAccent : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
}
