import 'dart:collection';
import 'dart:math';
import 'tree_logic_interface.dart';

/// =============================================================
/// AVLTreeLogic：自平衡二元搜尋樹（AVL）
///  - 支援：
///      • insert(index, uid) / delete(uid)
///      • insertAtParent(...)（教材手動插入）
///      • insertUnbalanced(...)（主動造成失衡，給出題用）
///      • balanceAt(pivot)（自動做 LL/LR/RR/RL 旋轉）
///  - 提供四種走訪序列 & isAVL 檢測
/// =============================================================
class _AVLNode {
  _AVLNode(this.uid, this.index);
  String uid;
  int index;
  _AVLNode? left, right;
  int height = 1;
}

class AVLTreeLogic with ActionNotifiable implements TreeLogic {
  _AVLNode? _root;
  int _size = 0;

  /* ────── ① 旗標：是否在插入時自動保持平衡 ────── */
  bool _autoBalance = true;

  /// 插入但**暫時不旋轉**，用於出題前先製造失衡
  void insertUnbalanced(int index, String uid) {
    final prev = _autoBalance;
    _autoBalance = false;           // 關掉自動平衡
    insert(index, uid);             // 呼叫原 insert
    _autoBalance = prev;            // 恢復設定
  }

  // ────────────────── 平衡輔助 ──────────────────
  int _height(_AVLNode? n) => n?.height ?? 0;

  void _updateHeight(_AVLNode n) =>
      n.height = 1 + max(_height(n.left), _height(n.right));

  int _balanceFactor(_AVLNode? n) =>
      n == null ? 0 : _height(n.left) - _height(n.right);

  _AVLNode _rotateRight(_AVLNode y) {
    final _AVLNode x = y.left!;
    final _AVLNode? t2 = x.right;

    x.right = y;
    y.left = t2;

    _updateHeight(y);
    _updateHeight(x);
    return x;
  }

  _AVLNode _rotateLeft(_AVLNode x) {
    final _AVLNode y = x.right!;
    final _AVLNode? t2 = y.left;

    y.left = x;
    x.right = t2;

    _updateHeight(x);
    _updateHeight(y);
    return y;
  }

  bool _isBalanced(_AVLNode? n) {
    if (n == null) return true;
    final bf = _balanceFactor(n).abs();
    return bf <= 1 && _isBalanced(n.left) && _isBalanced(n.right);
  }

  // ────────────────── TreeLogic：重建 ──────────────────
  @override
  void buildTreeFromNfc(List<Map<String, dynamic>> raw) {
    _root = null;
    _size = 0;
    for (final e in raw) {
      insert(e['index'] as int, e['uid'] as String);
    }
    if (!_isBalanced(_root)) {
      throw Exception('AVL 樹建立後不平衡');
    }
  }

  // ────────────────── TreeLogic：插入 ──────────────────
  @override
  void insert(int index, String uid) {
    _root = _insertNode(_root, uid, index);
    _size++;
    notifyAction(TreeActionEvent.inserted(uid: uid, index: index));
  }

  _AVLNode _insertNode(_AVLNode? node, String uid, int index) {
    if (node == null) return _AVLNode(uid, index);

    if (index < node.index) {
      node.left = _insertNode(node.left, uid, index);
    } else if (index > node.index) {
      node.right = _insertNode(node.right, uid, index);
    } else {
      // 重複 index 不插入
      return node;
    }

    _updateHeight(node);
    if (!_autoBalance) return node;           // ← 插入但不做旋轉

    final bf = _balanceFactor(node);

    // LL
    if (bf > 1 && index < node.left!.index) {
      return _rotateRight(node);
    }
    // LR
    if (bf > 1 && index > node.left!.index) {
      node.left = _rotateLeft(node.left!);
      return _rotateRight(node);
    }
    // RR
    if (bf < -1 && index > node.right!.index) {
      return _rotateLeft(node);
    }
    // RL
    if (bf < -1 && index < node.right!.index) {
      node.right = _rotateRight(node.right!);
      return _rotateLeft(node);
    }
    return node;
  }

  // ────────────────── TreeLogic：刪除（重建法） ──────────────────
  @override
  void delete(String uid) {
    if (_root == null) return;

    final nodes = <Map<String, dynamic>>[];
    final q = Queue<_AVLNode>()..add(_root!);
    while (q.isNotEmpty) {
      final n = q.removeFirst();
      if (n.uid != uid) nodes.add({'uid': n.uid, 'index': n.index});
      if (n.left != null) q.add(n.left!);
      if (n.right != null) q.add(n.right!);
    }
    buildTreeFromNfc(nodes);
    notifyAction(TreeActionEvent.deleted(uid: uid));
  }

  // ────────────────── 手動父節點插入（教材用） ──────────────────
  @override
  void insertAtParent(
      String parentUid, int ignoredIndex, String newUid,
      {required bool isLeft}) {
    final p = _findByUid(_root, parentUid);
    if (p == null) throw Exception('找不到父節點 $parentUid');
    final newIndex = isLeft ? p.index * 2 : p.index * 2 + 1;
    insert(newIndex, newUid);
  }

  _AVLNode? _findByUid(_AVLNode? node, String uid) {
    if (node == null) return null;
    if (node.uid == uid) return node;
    return _findByUid(node.left, uid) ?? _findByUid(node.right, uid);
  }

  // ────────────────── 公開旋轉 API（教材顯示用） ──────────────────
  void rotateLeft(int pivotIndex) {
    _root = _rotateAt(_root, pivotIndex, rotateLeft: true);
    notifyAction(TreeActionEvent.inserted(uid: '', index: pivotIndex));
  }

  void rotateRight(int pivotIndex) {
    _root = _rotateAt(_root, pivotIndex, rotateLeft: false);
    notifyAction(TreeActionEvent.inserted(uid: '', index: pivotIndex));
  }

  _AVLNode? _rotateAt(_AVLNode? node, int target,
      {required bool rotateLeft}) {
    if (node == null) return null;
    if (node.index == target) {
      return rotateLeft ? _rotateLeft(node) : _rotateRight(node);
    }
    node.left = _rotateAt(node.left, target, rotateLeft: rotateLeft);
    node.right = _rotateAt(node.right, target, rotateLeft: rotateLeft);
    _updateHeight(node);
    return node;
  }

  // ──────────────── 旋轉出題用 API ────────────────
  /// 回傳第一個不平衡節點 index；若已平衡則回 null
  int? findFirstUnbalancedNode() {
    final q = Queue<_AVLNode?>();
    q.add(_root);
    while (q.isNotEmpty) {
      final n = q.removeFirst();
      if (n == null) continue;
      if (_balanceFactor(n).abs() > 1) return n.index;
      q.add(n.left);
      q.add(n.right);
    }
    return null;
  }

  /// 判斷 pivot 需做哪一型旋轉：LL / LR / RR / RL
  String determineRotationCase(int pivotIndex) {
    final pivot = _findByIndex(_root, pivotIndex);
    if (pivot == null) throw Exception('找不到 pivot 節點 $pivotIndex');

    final bf = _balanceFactor(pivot);
    if (bf > 1) {
      return _balanceFactor(pivot.left!) >= 0 ? 'LL' : 'LR';
    } else if (bf < -1) {
      return _balanceFactor(pivot.right!) <= 0 ? 'RR' : 'RL';
    } else {
      throw Exception('節點 $pivotIndex 並未失衡');
    }
  }

  /// 依 `determineRotationCase` 結果自動執行單 / 雙旋轉
  void balanceAt(int pivotIndex) {
    final pivot = _findByIndex(_root, pivotIndex);
    if (pivot == null) return;

    final caseStr = determineRotationCase(pivotIndex);
    switch (caseStr) {
      case 'LL':
        rotateRight(pivotIndex);
        break;
      case 'RR':
        rotateLeft(pivotIndex);
        break;
      case 'LR':
        rotateLeft(pivot.left!.index);
        rotateRight(pivotIndex);
        break;
      case 'RL':
        rotateRight(pivot.right!.index);
        rotateLeft(pivotIndex);
        break;
      default:
        throw StateError('未知旋轉型別 $caseStr');
    }
  }

  _AVLNode? _findByIndex(_AVLNode? node, int idx) {
    if (node == null) return null;
    if (node.index == idx) return node;
    return _findByIndex(node.left, idx) ?? _findByIndex(node.right, idx);
  }

  // ────────────────── 四種走訪 ──────────────────
  void _pre(_AVLNode? n, List<String> out) {
    if (n == null) return;
    out.add(n.uid);
    _pre(n.left, out);
    _pre(n.right, out);
  }

  void _in(_AVLNode? n, List<String> out) {
    if (n == null) return;
    _in(n.left, out);
    out.add(n.uid);
    _in(n.right, out);
  }

  void _post(_AVLNode? n, List<String> out) {
    if (n == null) return;
    _post(n.left, out);
    _post(n.right, out);
    out.add(n.uid);
  }

  @override
  List<String> traversePre() {
    final out = <String>[];
    _pre(_root, out);
    return out;
  }

  @override
  List<String> traverseIn() {
    final out = <String>[];
    _in(_root, out);
    return out;
  }

  @override
  List<String> traversePost() {
    final out = <String>[];
    _post(_root, out);
    return out;
  }

  @override
  List<String> traverseLevel() {
    final out = <String>[];
    final q = Queue<_AVLNode?>();
    q.add(_root);
    while (q.isNotEmpty) {
      final n = q.removeFirst();
      if (n == null) continue;
      out.add(n.uid);
      q.add(n.left);
      q.add(n.right);
    }
    return out;
  }

  // ────────────────── TreeNode 轉換（給 UI） ──────────────────
  @override
  TreeNode? toTreeNode() {
    TreeNode? conv(_AVLNode? n) {
      if (n == null) return null;
      final t = TreeNode(uid: n.uid, index: n.index);
      t.left = conv(n.left);
      t.right = conv(n.right);
      return t;
    }
    return conv(_root);
  }

  @override
  int get size => _size;

  @override
  bool isBST() => true;

  @override
  bool isAVL() => _isBalanced(_root);

  @override
  bool isRedBlack() => false;
}
