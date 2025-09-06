import 'dart:math';
import 'operation_challenge.dart';

class ChallengeGenerator {
  final _rng = Random();

  /// 依選擇的樹種產生下一題
  OperationChallenge nextChallenge(TreeCategory cat) {
    // ——— 普通二元樹：不要求任何操作 ———
    if (cat == TreeCategory.binary) {
      return OperationChallenge(
        category: TreeCategory.binary,
        kind: OperationKind.insert, // 其實無意義
        count: 0,                   // ==> 不需動樹
      );
    }

    // ——— 其餘三棵樹：隨機 insert / delete 1~3 個節點 ———
    final kind  = OperationKind.values[_rng.nextInt(2)];
    final count = _rng.nextInt(3) + 1;     // 1..3
    return OperationChallenge(category: cat, kind: kind, count: count);
  }
}
