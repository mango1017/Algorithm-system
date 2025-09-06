import 'dart:collection';
import 'tree_logic_interface.dart';

class _BSTNode extends TreeNode {
  _BSTNode({required super.uid, required super.index});

  /// 建立一個攜帶原左右子樹的新節點（copy-replace 用）
  _BSTNode copyWith({TreeNode? left, TreeNode? right}) =>
      _BSTNode(uid: uid, index: index)
        ..left = left
        ..right = right;
}

class BinarySearchTreeLogic with ActionNotifiable implements TreeLogic {
  _BSTNode? _root;
  int _size = 0;
  final Map<String, int> _uidToIndex = {}; // uid → index，供 delete 使用

  // ------------------------------------------------------------
  //  建樹（保留原有不改）
  // ------------------------------------------------------------
  @override
  void buildTreeFromNfc(List<Map<String, dynamic>> raw) {
    final sortedRaw = [...raw]..sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
    _root = null;
    _size = 0;
    _uidToIndex.clear();
    _root = _buildBalanced(sortedRaw, 0, sortedRaw.length - 1);
  }

  _BSTNode? _buildBalanced(List<Map<String, dynamic>> sortedRaw, int lo, int hi) {
    if (lo > hi) return null;
    final mid = (lo + hi) ~/ 2;
    final entry = sortedRaw[mid];
    final index = entry['index'] as int;
    final uid = entry['uid'] as String;

    final node = _BSTNode(uid: uid, index: index);
    _uidToIndex[uid] = index;
    _size++;
    notifyAction(TreeActionEvent.inserted(uid: uid, index: index));

    node.left  = _buildBalanced(sortedRaw, lo, mid - 1);
    node.right = _buildBalanced(sortedRaw, mid + 1, hi);
    return node;
  }

  // ------------------------------------------------------------
  //  插入 (保留原有不改)
  // ------------------------------------------------------------
  @override
  void insert(int index, String uid) {
    if (_uidToIndex.containsKey(uid)) return;
    _root = _insertRec(_root, index, uid);
    _uidToIndex[uid] = index;
    _size++;
    notifyAction(TreeActionEvent.inserted(uid: uid, index: index));
  }

  _BSTNode _insertRec(_BSTNode? node, int index, String uid) {
    if (node == null) return _BSTNode(uid: uid, index: index);
    if (index < node.index) {
      node.left  = _insertRec(node.left  as _BSTNode?, index, uid);
    } else if (index > node.index) {
      node.right = _insertRec(node.right as _BSTNode?, index, uid);
    }
    return node;
  }

  // ------------------------------------------------------------
  //  刪除 (保留原有不改)
  // ------------------------------------------------------------
  @override
  void delete(String uid) {
    final key = _uidToIndex[uid];
    if (key == null) return;
    _root = _deleteRec(_root, key);
    _uidToIndex.remove(uid);
    _size--;
    notifyAction(TreeActionEvent.deleted(uid: uid));
  }

  _BSTNode? _deleteRec(_BSTNode? node, int key) {
    if (node == null) return null;
    if (key < node.index) {
      node.left = _deleteRec(node.left as _BSTNode?, key);
      return node;
    }
    if (key > node.index) {
      node.right = _deleteRec(node.right as _BSTNode?, key);
      return node;
    }
    // 兩子節點
    if (node.left != null && node.right != null) {
      final succ = _min(node.right as _BSTNode);
      return _BSTNode(uid: succ.uid, index: succ.index)
        ..left  = node.left
        ..right = _deleteMin(node.right as _BSTNode?);
    }
    // 0 或 1 子節點
    return (node.left as _BSTNode?) ?? (node.right as _BSTNode?);
  }

  _BSTNode _min(_BSTNode n) => n.left == null ? n : _min(n.left as _BSTNode);
  _BSTNode? _deleteMin(_BSTNode? n) {
    if (n == null) return null;
    if (n.left == null) return n.right as _BSTNode?;
    n.left = _deleteMin(n.left as _BSTNode?);
    return n;
  }

  // ------------------------------------------------------------
  //  新增：手動指定父節點左右子樹插入
  // ------------------------------------------------------------
  @override
  void insertAtParent(String parentUid, int index, String newUid, {required bool isLeft}) {
    if (_uidToIndex.containsKey(newUid)) {
      throw Exception('節點 $newUid 已存在');
    }
    final parentNode = _findNodeByUid(_root, parentUid);
    if (parentNode == null) throw Exception('找不到父節點 $parentUid');
    if (_uidToIndex.containsValue(index)) throw Exception('Index $index 已被使用');

    if (isLeft) {
      if (parentNode.left != null) throw Exception('父節點 $parentUid 的左子樹已有節點');
      parentNode.left = _BSTNode(uid: newUid, index: index);
    } else {
      if (parentNode.right != null) throw Exception('父節點 $parentUid 的右子樹已有節點');
      parentNode.right = _BSTNode(uid: newUid, index: index);
    }
    _uidToIndex[newUid] = index;
    _size++;
    notifyAction(TreeActionEvent.inserted(uid: newUid, index: index));
  }

  _BSTNode? _findNodeByUid(_BSTNode? node, String uid) {
    if (node == null) return null;
    if (node.uid == uid) return node;
    final leftRes = _findNodeByUid(node.left as _BSTNode?, uid);
    return leftRes ?? _findNodeByUid(node.right as _BSTNode?, uid);
  }

  // ------------------------------------------------------------
  //  新增：取得插入時正確的父節點 index
  // ------------------------------------------------------------
  int findParentForInsertion(int index) {
    if (_root == null) {
      throw Exception('BST 目前為空，無父節點');
    }
    _BSTNode? node = _root;
    _BSTNode? parent;
    while (node != null) {
      parent = node;
      if (index < node.index) {
        node = node.left as _BSTNode?;
      } else {
        node = node.right as _BSTNode?;
      }
    }
    return parent!.index;
  }

  // ------------------------------------------------------------
  //  走訪 (保留原有不改)
  // ------------------------------------------------------------
  @override
  List<String> traversePre() { /* ... */ return []; }

  @override
  List<String> traverseIn() { /* ... */ return []; }

  @override
  List<String> traversePost() { /* ... */ return []; }

  @override
  List<String> traverseLevel() { /* ... */ return []; }

  // ------------------------------------------------------------
  //  介面其餘要求 (保留原有不改)
  // ------------------------------------------------------------
  @override int get size => _size;
  @override bool isBST() { /* ... */ return true; }
  @override bool isAVL() => false;
  @override bool isRedBlack() => false;
  @override TreeNode? toTreeNode() => _root;
}
