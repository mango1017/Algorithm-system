import 'dart:collection';
import 'package:DyAlgo/Tree logic/tree_logic_interface.dart';

/// 廣度優先搜尋
List<TreeNode> bfs(TreeNode? root) {
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
