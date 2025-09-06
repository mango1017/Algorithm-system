enum TreeCategory { binary, bst, avl, redBlack }
enum OperationKind { insert, delete }

/// 系統出給使用者的一題（只告訴「操作幾個」節點）
class OperationChallenge {
  OperationChallenge({
    required this.category,
    required this.kind,
    required this.count,
  });

  final TreeCategory category;   // 哪種樹
  final OperationKind kind;      // insert / delete
  final int count;               // 要操作「幾個」節點
}
