import 'dart:math';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'tree_logic_interface.dart';


// =============================================================
//  PlainTreeLogic & TreeVisualization
// =============================================================


class PlainTreeLogic implements TreeLogic {
  TreeNode? _root;

  /// 根據 NFC 掃描資料生成樹
  @override
  void buildTreeFromNfc(List<Map<String, dynamic>> raw) {
    _root = TreeGenerator.generate(raw);
  }


  @override
  void insert(int index, String uid) {
    // PlainTreeLogic 不支援 insert；直接留空，保留原本功能
  }

  /// 刪除指定節點（PlainTreeLogic 不支援 delete，留空）
  @override
  void delete(String uid) {
    // PlainTreeLogic 不支援 delete；直接留空
  }

  /// 【介面要求】手動指定在 parentUid 的左右子樹插入
  /// PlainTreeLogic 不支援此功能，留空即可
  @override
  void insertAtParent(String parentUid, int index, String newUid,
      {required bool isLeft}) {
    // PlainTreeLogic 無手動插入；這裡留空，不做任何事
  }

  /// 走訪（前序）
  @override
  List<String> traversePre() => _pre(_root, []);

  /// 走訪（中序）
  @override
  List<String> traverseIn() => _in(_root, []);

  /// 走訪（後序）
  @override
  List<String> traversePost() => _post(_root, []);

  /// 走訪（層序）
  @override
  List<String> traverseLevel() {
    final out = <String>[];
    if (_root == null) return out;
    final q = Queue<TreeNode>()..add(_root!);
    while (q.isNotEmpty) {
      final n = q.removeFirst();
      out.add(n.uid);
      if (n.left != null) q.add(n.left!);
      if (n.right != null) q.add(n.right!);
    }
    return out;
  }

  /// 轉成 TreeNode 給視覺化使用
  @override
  TreeNode? toTreeNode() => _root;

  /// 節點數量
  @override
  int get size => _count(_root);

  /// 普通二元樹不驗證 BST
  @override
  bool isBST() => false;

  /// 普通二元樹不驗證 AVL
  @override
  bool isAVL() => false;

  /// 普通二元樹不驗證紅黑樹
  @override
  bool isRedBlack() => false;

  // ─────────────────────────────────────────────────────
  // 私有遞迴走訪與計數實作
  // ─────────────────────────────────────────────────────
  List<String> _pre(TreeNode? n, List<String> o) {
    if (n == null) return o;
    o.add(n.uid);
    _pre(n.left, o);
    _pre(n.right, o);
    return o;
  }

  List<String> _in(TreeNode? n, List<String> o) {
    if (n == null) return o;
    _in(n.left, o);
    o.add(n.uid);
    _in(n.right, o);
    return o;
  }

  List<String> _post(TreeNode? n, List<String> o) {
    if (n == null) return o;
    _post(n.left, o);
    _post(n.right, o);
    o.add(n.uid);
    return o;
  }

  int _count(TreeNode? n) => n == null ? 0 : 1 + _count(n.left) + _count(n.right);
}

/// 隨機生成一棵普通二元樹，依照 NFC 掃描順序排列
class TreeGenerator {
  static TreeNode? generate(List<Map<String, dynamic>> src) {
    if (src.isEmpty) return null;
    src.shuffle();
    final nodes = src
        .map((e) => TreeNode(uid: e['uid'] as String, index: e['index'] as int))
        .toList();
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

/// 樹的視覺化元件
/// － onNodeTap 改為可選參數（nullable），預設為 null
class TreeVisualization extends StatelessWidget {
  const TreeVisualization({
    super.key,
    required this.tree,
    required this.visitedUids,
    this.onNodeTap, // 可選參數，如果不傳就是 null
  });

  final TreeNode tree;
  final Set<String> visitedUids;

  /// 當使用者點擊節點時會被呼叫，如果不想要點擊功能，可不傳此參數
  final void Function(String uid)? onNodeTap;

  // ---------------- 排版演算法 ----------------
  void _layout(TreeNode? n, double x, double y, double offset) {
    if (n == null) return;
    n.x = x;
    n.y = y;
    _layout(n.left, x - offset / 2, y + 1, offset / 2);
    _layout(n.right, x + offset / 2, y + 1, offset / 2);
  }

  void _center(TreeNode root) {
    final minX = _minX(root), maxX = _maxX(root);
    _shift(root, -(minX + (maxX - minX) / 2));
  }

  void _shift(TreeNode? n, double dx) {
    if (n == null) return;
    n.x = (n.x ?? 0) + dx;
    _shift(n.left, dx);
    _shift(n.right, dx);
  }

  double _minX(TreeNode n) =>
      [n.x ?? 0, if (n.left != null) _minX(n.left!), if (n.right != null) _minX(n.right!)]
          .reduce(min);
  double _maxX(TreeNode n) =>
      [n.x ?? 0, if (n.left != null) _maxX(n.left!), if (n.right != null) _maxX(n.right!)]
          .reduce(max);

  @override
  Widget build(BuildContext context) {
    _layout(tree, 0, 0, 4);
    _center(tree);

    return LayoutBuilder(
      builder: (_, c) {
        final width = c.maxWidth;
        final height = c.maxHeight;

        return Stack(
          children: [
            // 底層：畫線與節點
            Positioned.fill(
              child: CustomPaint(
                painter: _TreePainter(tree, visitedUids),
                size: Size(width, height),
              ),
            ),

            // 只有當 onNodeTap != null 時，才顯示「透明按鈕」來攔截點擊
            if (onNodeTap != null)
              ..._buildNodeButtons(width, height),
          ],
        );
      },
    );
  }

  /// 只有在 onNodeTap 不為 null 時，才會將每個節點上方放一個透明 GestureDetector
  List<Widget> _buildNodeButtons(double fullW, double fullH) {
    final List<Widget> list = [];
    final nodes = <TreeNode>[];

    void collect(TreeNode? n) {
      if (n == null) return;
      nodes.add(n);
      collect(n.left);
      collect(n.right);
    }

    collect(tree);

    const double grid = 40;
    final double nodeR = grid * 0.35;

    for (final n in nodes) {
      final x = (n.x ?? 0) * grid;
      final y = (n.y ?? 0) * grid;
      final left = x - nodeR;
      final top = y - nodeR;
      final size = nodeR * 2;

      list.add(Positioned(
        left: left,
        top: top,
        width: size,
        height: size,
        child: GestureDetector(
          onTap: () {
            // 由於已檢查 onNodeTap != null，這裡安全地使用 !
            onNodeTap!(n.uid);
          },
          behavior: HitTestBehavior.translucent,
          child: Container(color: Colors.transparent),
        ),
      ));
    }

    return list;
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter(this.tree, this.visited);
  final TreeNode tree;
  final Set<String> visited;

  static const double _grid = 40;
  double get _nodeR => _grid * 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    final minX = _min(tree), maxX = _max(tree);
    final depth = _depth(tree);
    final treeW = (maxX - minX) * _grid;
    final treeH = (depth - 1) * _grid;

    final scale = min((size.width - 40) / treeW, (size.height - 40) / treeH);
    final dx = (size.width - treeW * scale) / 2 - minX * _grid * scale;
    final dy = (size.height - treeH * scale) / 2;

    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);
    _draw(canvas, tree);
    canvas.restore();
  }

  void _draw(Canvas c, TreeNode n) {
    final linePaint = Paint()
      ..color = const Color(0xFF69BDFD)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final child in [n.left, n.right]) {
      if (child == null) continue;
      c.drawLine(_p(n), _p(child), linePaint);
      _draw(c, child);
    }

    final center = _p(n);
    final nodePaint = Paint()
      ..shader = const RadialGradient(colors: [
        Color(0xFFC8F2FF), Color(0xFFA3E4FF), Color(0xFFE6C7FF)
      ]).createShader(Rect.fromCircle(center: center, radius: _nodeR));
    c.drawCircle(center, _nodeR, nodePaint);

    if (visited.contains(n.uid)) {
      c.drawCircle(
        center,
        _nodeR + 2,
        Paint()
          ..color = Colors.yellowAccent.withAlpha((0.6 * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
    }

    c.drawCircle(
      center,
      _nodeR,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: n.index.toString(),
        style: const TextStyle(fontFamily: 'PressStart2P', fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  Offset _p(TreeNode n) => Offset((n.x ?? 0) * _grid, (n.y ?? 0) * _grid);

  double _min(TreeNode n) =>
      [n.x ?? 0, if (n.left != null) _min(n.left!), if (n.right != null) _min(n.right!)]
          .reduce(min);
  double _max(TreeNode n) =>
      [n.x ?? 0, if (n.left != null) _max(n.left!), if (n.right != null) _max(n.right!)]
          .reduce(max);
  int _depth(TreeNode? n) => n == null ? 0 : 1 + max(_depth(n.left), _depth(n.right));

  @override
  bool shouldRepaint(covariant _TreePainter old) =>
      visited.length != old.visited.length || tree != old.tree;
}
