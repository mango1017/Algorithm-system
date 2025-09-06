import 'dart:math';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'tree_logic_interface.dart';

// ───────── 粒子資料結構 ─────────
class _LeafParticle {
  _LeafParticle(this.origin)
      : angle = Random().nextDouble() * 2 * pi,
        life = 1.0,
        spin = (Random().nextDouble() - .5) * .6,
        size = 12 + Random().nextDouble() * 6,
        vy = 14 + Random().nextDouble() * 14;
  final Offset origin;
  final double angle, spin, size, vy;
  double life;
}

// ───────── 主元件 ─────────
class RedBlackTreeVisualization extends StatefulWidget {
  const RedBlackTreeVisualization({
    super.key,
    required this.root,
    this.visitedUids = const {},
    this.nodeRadius = 24,
    this.levelGap = 80,
    this.siblingGap = 32,
    this.onNodeTap,
  });

  final TreeNode root;
  final Set<String> visitedUids;
  final double nodeRadius, levelGap, siblingGap;

  /// onNodeTap 為 nullable，如果不傳就不支援點擊功能
  final void Function(String uid)? onNodeTap;

  @override
  State<RedBlackTreeVisualization> createState() =>
      _RedBlackTreeVisualizationState();
}

class _RedBlackTreeVisualizationState
    extends State<RedBlackTreeVisualization>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  final List<_LeafParticle> _particles = [];

  /// 我們要把「所有節點的實際畫面座標」存起來，供透明按鈕用
  final Map<TreeNode, Offset> _nodePositions = {};

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          // 更新粒子生命週期
          _particles.removeWhere((p) => p.life <= 0);
          for (final p in _particles) p.life -= .02;

          return LayoutBuilder(
            builder: (_, constraints) {
              // 先「佈局」一次，把每個 TreeNode 對應到一個 canvas 座標
              _computeNodePositions(constraints.biggest);

              return Stack(
                children: [
                  // 底層：原本的 CustomPaint（繪製樹和粒子）
                  Positioned.fill(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _RBPainter(
                        root: widget.root,
                        visitedUids: widget.visitedUids,
                        nodeRadius: widget.nodeRadius,
                        levelGap: widget.levelGap,
                        siblingGap: widget.siblingGap,
                        t: _ctrl.value,
                        particles: _particles,
                      ),
                    ),
                  ),

                  // 上層：如果 onNodeTap 不為 null，就在每個節點中心放一個透明的 GestureDetector
                  if (widget.onNodeTap != null) ..._buildNodeHitAreas(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 這段會跟 _RBPainter 一致的「佈局邏輯」，算出每個 TreeNode 在畫布上的實際座標
  void _computeNodePositions(Size fullSize) {
    _nodePositions.clear();

    // 跳到 painter 的私有 _layout 方法：遞迴計算出所有 n.x, n.y，
    // 然後轉成絕對 pixel 座標後存到 _nodePositions。
    // 與 _RBPainter 完全一致：
    final Map<TreeNode, Offset> tempPos = {};
    void _layout(TreeNode n, int depth, double x0) {
      final y = depth * widget.levelGap + widget.nodeRadius;
      double x = x0;
      if (n.left != null) {
        _layout(n.left!, depth + 1, x);
        x += widget.siblingGap;
      }
      final cx = x + widget.nodeRadius;
      tempPos[n] = Offset(cx, y);
      x = cx + widget.nodeRadius;
      if (n.right != null) {
        x += widget.siblingGap;
        _layout(n.right!, depth + 1, x);
      }
    }

    // 先讓每個 node 設定好 x,y（相對值）
    _layout(widget.root, 0, 0);

    // 計算整棵樹的寬高（跟 Painter 用法一樣）
    final allOffsets = tempPos.values.toList();
    final minX = allOffsets.map((o) => o.dx).reduce(min);
    final maxX = allOffsets.map((o) => o.dx).reduce(max);
    final maxY = allOffsets.map((o) => o.dy).reduce(max);

    final treeW = (maxX - minX) + widget.nodeRadius * 2;
    final treeH = maxY + widget.nodeRadius;

    // scale & translate 參考 _RBPainter
    final scale = min(1.0, min(
      (fullSize.width - 40) / treeW,
      (fullSize.height * .6) / treeH,
    ));
    final dx = (fullSize.width - treeW * scale) / 2 - minX * scale;
    final dy = (fullSize.height * .55 - treeH * scale);

    // 把 tempPos 裡的「相對座標」轉成「實際 pixel 座標」
    tempPos.forEach((node, offset) {
      final px = (offset.dx * scale) + dx;
      final py = (offset.dy * scale) + dy;
      _nodePositions[node] = Offset(px, py);
    });
  }

  /// 為每個 TreeNode 加上透明點擊區
  List<Widget> _buildNodeHitAreas() {
    const double radiusFactor = 0.35; // 與 painter 裡 nodeRadius * 0.35 對應
    final List<Widget> list = [];
    final double r = widget.nodeRadius * radiusFactor;

    _nodePositions.forEach((node, pos) {
      list.add(Positioned(
        left: pos.dx - r,
        top: pos.dy - r,
        width: r * 2,
        height: r * 2,
        child: GestureDetector(
          onTap: () {
            widget.onNodeTap!(node.uid);
          },
          behavior: HitTestBehavior.translucent,
          child: Container(color: Colors.transparent),
        ),
      ));
    });

    return list;
  }

  /// 如果想在刪除或插入時觸發粒子效果，可從呼叫端取得
  void spawnParticles(Offset worldPos) {
    setState(() {
      for (int i = 0; i < 8; ++i) {
        _particles.add(_LeafParticle(worldPos));
      }
    });
  }
}

// ─────────────────────── Painter ───────────────────────
class _RBPainter extends CustomPainter {
  _RBPainter({
    required this.root,
    required this.visitedUids,
    required this.nodeRadius,
    required this.levelGap,
    required this.siblingGap,
    required this.t,
    required this.particles,
  });
  final TreeNode root;
  final Set<String> visitedUids;
  final double nodeRadius, levelGap, siblingGap, t;
  final List<_LeafParticle> particles;

  final Map<TreeNode, Offset> _pos = {};
  final Path _leafPath = Path()
    ..moveTo(0, -1)
    ..cubicTo(.6, -1, 1, -.4, 1, .2)
    ..cubicTo(1, .9, .3, 1.2, 0, 1.6)
    ..cubicTo(-.3, 1.2, -1, .9, -1, .2)
    ..cubicTo(-1, -.4, -.6, -1, 0, -1)
    ..close();

  // 佈局
  double _layout(TreeNode n, int d, double x0) {
    final y = d * levelGap + nodeRadius;
    double x = x0;
    if (n.left != null) {
      x = _layout(n.left!, d + 1, x);
      x += siblingGap;
    }
    final cx = x + nodeRadius;
    _pos[n] = Offset(cx, y);
    x = cx + nodeRadius;
    if (n.right != null) {
      x += siblingGap;
      x = _layout(n.right!, d + 1, x);
    }
    return x;
  }

  // 背景（保持透明）
  void _background(Canvas c, Size s) {
    // 留空
  }

  // 樹幹
  void _branch(Canvas c, Offset a, Offset b) {
    c.drawLine(
      a,
      b,
      Paint()
        ..color = const Color(0xFF795548)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  // 節點
  void _node(Canvas c, Offset p, TreeNode n) {
    final r = nodeRadius * (1 + .05 * sin((t * 2 + n.index) * pi));
    final visited = visitedUids.contains(n.uid);
    c.drawCircle(p, r, Paint()..color = n.isRed ? Colors.red : Colors.black);

    final glow =
    HSVColor.fromAHSV(1, (t * 360 + n.index * 27) % 360, .8, 1).toColor();
    c.drawCircle(
      p,
      r + 5,
      Paint()
        ..color = glow.withOpacity(.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    if (visited) {
      c.drawCircle(
        p,
        r + 3,
        Paint()
          ..color = Colors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: n.index.toString(),
        style: const TextStyle(
          fontFamily: 'PressStart2P',
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, p - Offset(tp.width / 2, tp.height / 2));
  }

  // 粒子
  void _drawParticles(Canvas c) {
    for (final p in particles) {
      final prog = 1 - p.life;
      final pos = p.origin +
          Offset(
            cos(p.angle) * prog * 26,
            sin(p.angle) * prog * 26 + p.vy * prog * .6,
          );
      final m = Matrix4.identity()
        ..translate(pos.dx, pos.dy)
        ..scale(p.size * p.life)
        ..rotateZ(p.spin * prog * 2 * pi);
      c.drawPath(
        _leafPath.transform(m.storage),
        Paint()..color = const Color(0xFF81C784).withOpacity(p.life),
      );
    }
  }

  @override
  void paint(Canvas c, Size size) {
    _background(c, size);

    // 佈局
    _pos.clear();
    final w = _layout(root, 0, 0);
    final h = _pos.values.map((e) => e.dy).reduce(max) + nodeRadius;

    // 自適應置中
    final scale = min(1.0,
        min((size.width - 40) / w, (size.height * .6) / h));
    final dx = (size.width - w * scale) / 2;
    final dy = (size.height * .55 - h * scale);

    c.save();
    c.translate(dx, dy);
    c.scale(scale);

    // branches & nodes
    _pos.forEach((n, _) {
      if (n.left != null) _branch(c, _pos[n]!, _pos[n.left]!);
      if (n.right != null) _branch(c, _pos[n]!, _pos[n.right]!);
    });
    _pos.forEach((n, o) => _node(c, o, n));

    // particles
    _drawParticles(c);

    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
