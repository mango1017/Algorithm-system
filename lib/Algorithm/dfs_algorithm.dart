import 'package:DyAlgo/Tree logic/tree_logic_interface.dart';

/// 深度優先搜尋：前序、中序、後序
List<TreeNode> dfsPre(TreeNode? n) {
  if (n == null) return [];
  return [n, ...dfsPre(n.left), ...dfsPre(n.right)];
}

List<TreeNode> dfsIn(TreeNode? n) {
  if (n == null) return [];
  return [...dfsIn(n.left), n, ...dfsIn(n.right)];
}

List<TreeNode> dfsPost(TreeNode? n) {
  if (n == null) return [];
  return [...dfsPost(n.left), ...dfsPost(n.right), n];
}
