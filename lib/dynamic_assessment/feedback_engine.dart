// feedback_engine.dart
// ─────────────────────────────────────────────────────────────
//  Flutter + OpenAI 漸進式動態評量核心模組  (NOM + TMC)
//  • 走訪順序錯誤偵測 (Node Order Misplacement, NOM)
//  • 演算法混淆偵測 (Traversal Mode Confusion, TMC)
//  • 提示層級 L1–L4 + 滿分提示
//  • 四級總評：滿分 / 完全掌握 / 接近掌握 / 有進步空間 / 需要加強理解
//  • LLM 最終一次回饋依分級與誤區自動套用模板 (L4 直接提供完整走訪)
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:DyAlgo/Tree logic/tree_logic_interface.dart';

/*────────────────────── 0.  基本型別 ──────────────────────*/
enum MisCode { NOM, TMC }
enum HintLevel { none, L1, L2, L3, L4 }

class MisStat {
  int hit = 0;
  int total = 0;
  HintLevel hint = HintLevel.none;
  double get rate => total == 0 ? 0.0 : hit / total;
}

HintLevel nextHint(HintLevel h) =>
    h.index < HintLevel.L4.index ? HintLevel.values[h.index + 1] : HintLevel.L4;

bool listsEqual<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/*────────────────────── 1.  Tree ASCII & JSON ─────────────────────*/
String generateAsciiTree(TreeNode? n, [String ind = '', bool isLeft = true]) {
  if (n == null) return '';
  final buffer = StringBuffer();
  if (n.right != null) {
    buffer.write(
      generateAsciiTree(
        n.right,
        ind + (isLeft ? '│   ' : '    '),
        false,
      ),
    );
  }
  buffer.writeln('${ind}${isLeft ? '└── ' : '┌── '}${n.index}');
  if (n.left != null) {
    buffer.write(
      generateAsciiTree(
        n.left,
        ind + (isLeft ? '    ' : '│   '),
        true,
      ),
    );
  }
  return buffer.toString();
}

Map<String, dynamic>? treeToJson(TreeNode? n) {
  if (n == null) return null;
  return {
    'value': n.index,
    'left': treeToJson(n.left),
    'right': treeToJson(n.right),
  };
}

/*────────────────────── 2.  迷思概念定義 ─────────────────────*/
// 走訪順序錯誤偵測 (Node Order Misplacement, NOM)
bool detectNOM({
  required List<String> userSeq,
  required List<String> correctSeq,
  required MisStat stat,
}) {
  stat.total++;
  for (var i = 1; i < userSeq.length; i++) {
    final prev = correctSeq.indexOf(userSeq[i - 1]);
    final cur  = correctSeq.indexOf(userSeq[i]);
    if (cur < prev) {
      stat.hit++;
      stat.hint = nextHint(stat.hint);
      return true;
    }
  }
  return false;
}

// TMC（Traversal Mode Confusion）
bool detectTraversalModeConfusion({
  required List<String> userSeq,
  required List<String> bfsSeq,
  required List<String> dfsSeq,
  required MisStat stat,
}) {
  stat.total++;
  if (listsEqual(userSeq, bfsSeq) && !listsEqual(bfsSeq, dfsSeq)) {
    stat.hit++;
    stat.hint = nextHint(stat.hint);
    return true;
  }
  if (listsEqual(userSeq, dfsSeq) && !listsEqual(bfsSeq, dfsSeq)) {
    stat.hit++;
    stat.hint = nextHint(stat.hint);
    return true;
  }
  return false;
}

/*────────────────────── 3.  四級總評 ─────────────────────*/
String progressiveLevel({
  required double score,
  required Map<MisCode, MisStat> stats,
}) {
  // 累計 NOM 與 TMC 的誤區次數
  final int errorCount = stats[MisCode.NOM]!.hit + stats[MisCode.TMC]!.hit;

  // 同時檢查分數與誤區次數
  if (score == 100.0 && errorCount == 0) {
    return '滿分';
  }
  if (score >= 90.0 && errorCount == 0) {
    return '接近完全理解';
  }
  if (score >= 75.0 && errorCount <= 1) {
    return '接近掌握';
  }
  if (score >= 50.0 && errorCount <= 2) {
    return '有進步空間';
  }
  return '需要加強理解';
}


/*────────────────────── 4.  LLM 回饋 ─────────────────────*/
Future<String> generateAiFeedback({
  required String treeType,
  required String algorithm,
  required Map<MisCode, MisStat> stats,
  required String level,      // "滿分" | "完全掌握" | "接近掌握" | "有進步空間" | "需要加強理解"
  required String misCode,    // "NOM" | "TMC"
  required double score,
  required List<int> userIndices,
  required List<int> correctIndices,
}) async {
  const apiKey = 'YOUR_OPENAI_API_KEY_H';

  // 1. 系統提示：內含格式範本，並要求嚴格遵守
  final systemPrompt = '''
你是一位演算法專家，專注於樹的走訪教學（BFS/DFS）。
請嚴格遵守下列「提示層級」定義，並且：
  • 只回應與走訪錯誤相關的回饋；
  • 不要輸出任何程式碼；
  • 使用繁體中文；

── 提示層級：$level ──

當 level == '滿分'：
  只回應「恭喜你！完全掌握了這個演算法！」

當 level == '接近完全理解'（對應 L1）：
  簡短回覆「正確」或「錯誤」，並附上一個關鍵字提示
  例如：「錯誤 —— 注意左子節點優先」

當 level == '接近掌握'（對應 L2）：
  以一句話指出錯誤關鍵，或提出一句引導式問題

當 level == '有進步空間'（對應 L3）：
  提供範例、步驟提示，促進思維重構

當 level == '需要加強理解'（對應 L4）：
  完整列出正確走訪序列，並附簡要解析關鍵邏輯

── 嚴格格式──
請**只**以以下格式回覆，**不要**額外加任何文字：

掌握層級：$level

學習建議：<請依 $level 規則，使用流暢句子提供回饋>
''';

  // 2. 用戶 Prompt：樹型、演算法、使用者＆正確走訪序列
  final userPrompt = '''
【樹型】 $treeType
【演算法】 $algorithm
【使用者走訪 (index)】 ${userIndices.join(' -> ')}
【正確走訪 (index)】 ${correctIndices.join(' -> ')}
''';

  // 3. 呼叫 OpenAI API
  final payload = {
    'model': 'o4-mini',
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user',   'content': userPrompt},
    ],
    'max_completion_tokens': 1500,
  };

  final res = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode(payload),
  );

  if (res.statusCode != 200) {
    throw Exception('OpenAI API Error ${res.statusCode}: ${res.body}');
  }

  final data = jsonDecode(res.body);
  final content = data['choices']?[0]?['message']?['content'] as String? ?? '';
  return content.trim();
}




