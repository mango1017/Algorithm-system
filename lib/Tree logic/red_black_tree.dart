import 'dart:collection';
import 'tree_logic_interface.dart';

/// =============================================================
/// RedBlackTreeLogic：實作紅黑樹，並支援「手動指定父節點左右子樹插入」
/// =============================================================
class _RBNode {
  _RBNode(this.uid, this.index, {this.isRed = true});
  String uid;
  int index;
  bool isRed;
  _RBNode? left, right, parent;
}

class RedBlackTreeLogic with ActionNotifiable implements TreeLogic {
  _RBNode? _root;
  int _size = 0; // 追蹤節點數

  // ------------------------------------------------------------
  //  建樹（NFC 依 index 依序插入並自動修正）
  // ------------------------------------------------------------
  @override
  void buildTreeFromNfc(List<Map<String, dynamic>> raw) {
    _root = null;
    _size = 0;

    // index 必須連續 1..N
    raw.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
    for (int i = 0; i < raw.length; i++) {
      if ((raw[i]['index'] as int) != i + 1) {
        throw Exception('紅黑樹的 index 必須從 1 開始、連續');
      }
    }

    // 逐筆插入
    for (final node in raw) {
      insert(node['index'] as int, node['uid'] as String);
    }

    if (!isValidRBTree()) {
      throw Exception('生成的紅黑樹不符合性質');
    }
  }

  // ------------------------------------------------------------
  //  插入（自動修正）
  // ------------------------------------------------------------
  @override
  void insert(int index, String uid) {
    final newNode = _RBNode(uid, index, isRed: true);
    _RBNode? parent;
    var x = _root;

    while (x != null) {
      parent = x;
      if (uid.compareTo(x.uid) < 0) {
        x = x.left;
      } else if (uid.compareTo(x.uid) > 0) {
        x = x.right;
      } else {
        return; // duplicate uid 不插入
      }
    }

    newNode.parent = parent;
    if (parent == null) {
      _root = newNode;
    } else if (uid.compareTo(parent.uid) < 0) {
      parent.left = newNode;
    } else {
      parent.right = newNode;
    }

    _size++; // ★ 節點數統計
    _fixAfterInsertion(newNode);
    notifyAction(TreeActionEvent.inserted(uid: uid, index: index)); // ★ 事件
  }

  // ------------------------------------------------------------
  //  刪除（重建法，保留原有實作）
  // ------------------------------------------------------------
  @override
  void delete(String uid) {
    if (_root == null) return;

    final nodes = <Map<String, dynamic>>[];
    final q = Queue<_RBNode>()..add(_root!);
    bool found = false;

    while (q.isNotEmpty) {
      final n = q.removeFirst();
      if (n.uid == uid) {
        found = true;
      } else {
        nodes.add({'uid': n.uid, 'index': n.index});
      }
      if (n.left != null)  q.add(n.left!);
      if (n.right != null) q.add(n.right!);
    }

    if (!found) return; // uid 不存在

    buildTreeFromNfc(nodes); // 重新建樹
    notifyAction(TreeActionEvent.deleted(uid: uid)); // ★ 事件
  }

  // ------------------------------------------------------------
  //  【新增】TreeLogic：手動指定在 parentUid 的左右子樹插入
  // ------------------------------------------------------------
  @override
  void insertAtParent(String parentUid, int index, String newUid, {required bool isLeft}) {
    // 1. 找到 parent 節點
    final parentNode = _findNodeByUid(_root, parentUid);
    if (parentNode == null) {
      throw Exception('找不到父節點 $parentUid');
    }

    // 2. 確認那一側子樹為空
    if (isLeft) {
      if (parentNode.left != null) {
        throw Exception('父節點 $parentUid 的左子樹已有節點');
      }
      parentNode.left = _RBNode(newUid, index, isRed: true);
      parentNode.left!.parent = parentNode;
      _fixAfterInsertion(parentNode.left!);
    } else {
      if (parentNode.right != null) {
        throw Exception('父節點 $parentUid 的右子樹已有節點');
      }
      parentNode.right = _RBNode(newUid, index, isRed: true);
      parentNode.right!.parent = parentNode;
      _fixAfterInsertion(parentNode.right!);
    }

    // 3. 更新節點數
    _size++;
    notifyAction(TreeActionEvent.inserted(uid: newUid, index: index));
  }

  // 輔助：遞迴尋找 _RBNode by uid
  _RBNode? _findNodeByUid(_RBNode? node, String uid) {
    if (node == null) return null;
    if (node.uid == uid) return node;
    final leftRes = _findNodeByUid(node.left, uid);
    if (leftRes != null) return leftRes;
    return _findNodeByUid(node.right, uid);
  }

  // ------------------------------------------------------------
  //  紅黑樹修正 & 工具（保持原有程式碼不變）
  // ------------------------------------------------------------
  void _fixAfterInsertion(_RBNode node) {
    var x = node;
    while (x != _root && x.parent!.isRed) {
      if (x.parent == x.parent!.parent!.left) {
        final y = x.parent!.parent!.right;
        if (y?.isRed ?? false) {
          x.parent!.isRed = false;
          y!.isRed = false;
          x.parent!.parent!.isRed = true;
          x = x.parent!.parent!;
        } else {
          if (x == x.parent!.right) {
            x = x.parent!;
            _rotateLeft(x);
          }
          x.parent!.isRed = false;
          x.parent!.parent!.isRed = true;
          _rotateRight(x.parent!.parent!);
        }
      } else {
        final y = x.parent!.parent!.left;
        if (y?.isRed ?? false) {
          x.parent!.isRed = false;
          y!.isRed = false;
          x.parent!.parent!.isRed = true;
          x = x.parent!.parent!;
        } else {
          if (x == x.parent!.left) {
            x = x.parent!;
            _rotateRight(x);
          }
          x.parent!.isRed = false;
          x.parent!.parent!.isRed = true;
          _rotateLeft(x.parent!.parent!);
        }
      }
    }
    _root!.isRed = false;
  }

  void _rotateLeft(_RBNode node) {
    final right = node.right!;
    node.right = right.left;
    if (right.left != null) right.left!.parent = node;
    right.parent = node.parent;
    if (node.parent == null) {
      _root = right;
    } else if (node == node.parent!.left) {
      node.parent!.left = right;
    } else {
      node.parent!.right = right;
    }
    right.left = node;
    node.parent = right;
  }

  void _rotateRight(_RBNode node) {
    final left = node.left!;
    node.left = left.right;
    if (left.right != null) left.right!.parent = node;
    left.parent = node.parent;
    if (node.parent == null) {
      _root = left;
    } else if (node == node.parent!.right) {
      node.parent!.right = left;
    } else {
      node.parent!.left = left;
    }
    left.right = node;
    node.parent = left;
  }

  bool isValidRBTree() {
    if (_root?.isRed ?? false) return false;
    int blackHeight(_RBNode? node) {
      if (node == null) return 0;
      int leftH = blackHeight(node.left);
      int rightH = blackHeight(node.right);
      if (leftH == -1 || rightH == -1 || leftH != rightH) return -1;
      if (node.isRed) {
        if ((node.left?.isRed ?? false) || (node.right?.isRed ?? false)) return -1;
        return leftH;
      } else {
        return leftH + 1;
      }
    }
    return blackHeight(_root) != -1;
  }

  // ------------------------------------------------------------
  //  走訪（保持原有邏輯）
  // ------------------------------------------------------------
  @override
  List<String> traversePre() {
    final res = <String>[];
    void dfs(_RBNode? n) {
      if (n == null) return;
      res.add(n.uid);
      dfs(n.left);
      dfs(n.right);
    }
    dfs(_root);
    return res;
  }

  @override
  List<String> traverseIn() {
    final res = <String>[];
    void dfs(_RBNode? n) {
      if (n == null) return;
      dfs(n.left);
      res.add(n.uid);
      dfs(n.right);
    }
    dfs(_root);
    return res;
  }

  @override
  List<String> traversePost() {
    final res = <String>[];
    void dfs(_RBNode? n) {
      if (n == null) return;
      dfs(n.left);
      dfs(n.right);
      res.add(n.uid);
    }
    dfs(_root);
    return res;
  }

  @override
  List<String> traverseLevel() {
    final res = <String>[];
    if (_root == null) return res;
    final q = Queue<_RBNode>()..add(_root!);
    while (q.isNotEmpty) {
      final n = q.removeFirst();
      res.add(n.uid);
      if (n.left != null)  q.add(n.left!);
      if (n.right != null) q.add(n.right!);
    }
    return res;
  }

  // ------------------------------------------------------------
  //  TreeLogic 其餘
  // ------------------------------------------------------------
  @override
  TreeNode? toTreeNode() {
    TreeNode? copy(_RBNode? n) {
      if (n == null) return null;
      final t = TreeNode(uid: n.uid, index: n.index)..isRed = n.isRed;
      t.left = copy(n.left);
      t.right = copy(n.right);
      return t;
    }
    return copy(_root);
  }

  @override
  int get size => _size;
  @override
  bool isBST() => true;
  @override
  bool isAVL() => false;
  @override
  bool isRedBlack() => isValidRBTree();
}
