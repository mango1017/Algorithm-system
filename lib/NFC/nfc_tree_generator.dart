import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

// 定義樹節點
class TreeNode {
  String uid;
  int value;
  TreeNode? left;
  TreeNode? right;
  bool isSelected = false; // 添加 isSelected 屬性，用於標記節點是否被選中

  TreeNode({required this.uid, required this.value, this.left, this.right});
}

// 二元樹生成邏輯
class BinaryTreeGenerator {
  static final Random _random = Random();

  // 生成符合圖論的二元樹，每個節點帶有唯一的 UID
  static TreeNode generateBinaryTree(List<String> uids) {
    if (uids.isEmpty) return TreeNode(uid: 'Unknown', value: 0);

    List<TreeNode> nodes = List.generate(
      uids.length,
          (index) => TreeNode(uid: uids[index], value: _random.nextInt(100)),
    );

    for (int i = 0; i < uids.length; i++) {
      if (2 * i + 1 < uids.length) nodes[i].left = nodes[2 * i + 1];
      if (2 * i + 2 < uids.length) nodes[i].right = nodes[2 * i + 2];
    }

    return nodes[0];
  }

  // 基於 NFC 掃描生成二元樹
  static Future<TreeNode> generateBinaryTreeFromNFC() async {
    List<String> uids = [];

    try {
      var availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        throw Exception('NFC 無法使用');
      }

      print('NFC 可用，請掃描 NFC 標籤...');
      for (int i = 0; i < 30; i++) {
        var tag = await FlutterNfcKit.poll();
        if (tag != null) {
          uids.add(tag.id);
          print('已掃描 NFC 標籤: ${tag.id}');
        } else {
          print('未發現 NFC 標籤，停止掃描...');
          break;
        }
      }
    } catch (e) {
      print('NFC 掃描失敗: $e');
    }

    if (uids.isEmpty) {
      return TreeNode(uid: 'Unknown', value: 0);
    }

    return generateBinaryTree(uids);
  }

  // 從 JSON 或類似資料結構創建二元樹
  static TreeNode createTreeFromData(Map<String, dynamic> data) {
    if (data == null || data.isEmpty) {
      throw ArgumentError('無效的樹資料');
    }

    return TreeNode(
      uid: data['uid'],
      value: data['value'],
      left: data['left'] != null ? createTreeFromData(data['left']) : null,
      right: data['right'] != null ? createTreeFromData(data['right']) : null,
    );
  }
}

// 樹的可視化類別
class TreeVisualization extends StatefulWidget {
  final TreeNode tree;

  TreeVisualization({required this.tree});

  @override
  _TreeVisualizationState createState() => _TreeVisualizationState();
}

class _TreeVisualizationState extends State<TreeVisualization> {
  TreeNode? _selectedNode;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: TreePainter(
        tree: widget.tree,
        onNodeTap: (node) {
          setState(() {
            if (_selectedNode == node) {
              _selectedNode = null; // 取消選中
            } else {
              _selectedNode = node; // 選中節點
            }
          });
        },
      ),
    );
  }
}

// 樹的繪畫邏輯
class TreePainter extends CustomPainter {
  final TreeNode tree;
  final double nodeRadius = 20.0;
  final double verticalSpacing = 70.0;
  final Function(TreeNode) onNodeTap; // 添加 onNodeTap 回調函式

  TreePainter({required this.tree, required this.onNodeTap});

  @override
  void paint(Canvas canvas, Size size) {
    _drawTree(canvas, tree, size.width / 2, nodeRadius + 10, size.width / 4);
  }

  void _drawTree(Canvas canvas, TreeNode node, double x, double y, double xOffset) {
    final Paint nodePaint = Paint()..color = Colors.blue;
    final Paint linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    // 使用 Stack 和 Positioned 疊加節點和 GestureDetector
    GestureDetector(
      onTap: () {
        onNodeTap(node);
      },
      child: Stack(
        children: [
          Positioned(
            left: x - nodeRadius,
            top: y - nodeRadius,
            child: Container(
              width: nodeRadius * 2,
              height: nodeRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );

    _drawNodeValue(canvas, node, x, y);

    if (node.left != null) {
      canvas.drawLine(Offset(x, y + nodeRadius), Offset(x - xOffset, y + verticalSpacing), linePaint);
      _drawTree(canvas, node.left!, x - xOffset, y + verticalSpacing, xOffset / 2);
    }
    if (node.right != null) {
      canvas.drawLine(Offset(x, y + nodeRadius), Offset(x + xOffset, y + verticalSpacing), linePaint);
      _drawTree(canvas, node.right!, x + xOffset, y + verticalSpacing, xOffset / 2);
    }
  }

  // 只顯示節點的值
  void _drawNodeValue(Canvas canvas, TreeNode node, double x, double y) {
    final TextSpan span = TextSpan(
      style: TextStyle(color: Colors.white, fontSize: 12.0),
      text: '${node.value}',
    );
    final TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(x - nodeRadius, y - nodeRadius / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 主畫面
class LearnAlgorithmPage extends StatefulWidget {
  @override
  _LearnAlgorithmPageState createState() => _LearnAlgorithmPageState();
}

class _LearnAlgorithmPageState extends State<LearnAlgorithmPage> {
  TreeNode? _randomTree;
  int _scannedNfcCount = 0;
  bool _isScanning = false;
  TreeNode? _selectedNode;

  Future<void> _scanNfc() async {
    setState(() {
      _isScanning = true;
    });

    TreeNode scannedTree = await BinaryTreeGenerator.generateBinaryTreeFromNFC();

    setState(() {
      _randomTree = scannedTree;
      _scannedNfcCount = _countNodes(scannedTree);
      _isScanning = false;
    });
  }

  int _countNodes(TreeNode? node) {
    if (node == null) return 0;
    return 1 + _countNodes(node.left) + _countNodes(node.right);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('學習演算法'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanning)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _scanNfc,
                child: Text('掃描 NFC'),
              ),
            SizedBox(height: 20),
            Text('掃描到的節點數量：$_scannedNfcCount'),
            SizedBox(height: 20),
            if (_randomTree != null) ...[
              Expanded(
                child: TreeVisualization(tree: _randomTree!),
              ),
              if (_selectedNode != null)
                Text('選中節點的 NFC ID: ${_selectedNode!.uid}'),
            ] else ...[
              Text('未生成樹'),
            ],
          ],
        ),
      ),
    );
  }
}