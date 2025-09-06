import 'package:meta/meta.dart';

// =======================================================
// TreeNode —— 視覺化層共用的節點資料
// =======================================================
class TreeNode {
  TreeNode({
    required this.uid,
    required this.index,
    this.isRed = false,
    this.left,
    this.right,
  });

  final String uid;
  final int index;
  bool isRed;            // AVL / BST 不用，但 RB Tree 會用來標記顏色
  TreeNode? left;
  TreeNode? right;
  double? x;             // for UI layout
  double? y;
}

// =======================================================
// TreeLogic —— 各樹種必須實作的邏輯介面
// =======================================================
abstract class TreeLogic {
  // ---------- 建樹 / 動態變動 ----------
  void buildTreeFromNfc(List<Map<String, dynamic>> raw);
  void insert(int index, String uid);
  void delete(String uid);
  void insertAtParent(String parentUid, int index, String newUid, {required bool isLeft});

  // ---------- 走訪 ----------
  List<String> traversePre();
  List<String> traverseIn();
  List<String> traversePost();
  List<String> traverseLevel();

  // ---------- 視覺化 ----------
  TreeNode? toTreeNode();

  // ---------- 其他輔助 ----------
  int get size;
  bool isBST();
  bool isAVL();
  bool isRedBlack();
}

// =======================================================
// ActionNotifiable —— 讓樹在 insert/delete 後能通知 UI
// =======================================================
mixin ActionNotifiable {
  final List<void Function(TreeActionEvent)> _listeners = [];

  void addListener(void Function(TreeActionEvent e) l) => _listeners.add(l);
  void removeListener(void Function(TreeActionEvent e) l) =>
      _listeners.remove(l);

  @protected
  void notifyAction(TreeActionEvent e) {
    for (final l in List<void Function(TreeActionEvent)>.from(_listeners)) {
      l(e);
    }
  }
}

/// 操作類型
enum OperationKind { insert, delete }

/// insert / delete 完成後給 UI 的事件
class TreeActionEvent {
  TreeActionEvent.inserted({required this.uid, required this.index})
      : kind = OperationKind.insert;
  TreeActionEvent.deleted({required this.uid})
      : index = null,
        kind = OperationKind.delete;

  final OperationKind kind;
  final String uid;
  final int? index;
}
