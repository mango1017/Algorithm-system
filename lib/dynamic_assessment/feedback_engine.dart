import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:okk/Tree logic/tree_logic_interface.dart';

/*─────────────────────────────────────────────
  ASCII‑TREE 輔助函式（全部保留）
─────────────────────────────────────────────*/
String generateAsciiTree(
    TreeNode? node, [
      String indent = '',
      bool isLeft = true,
    ]) {
  if (node == null) return '';
  var res = '';
  if (node.right != null) {
    res += generateAsciiTree(
      node.right,
      indent + (isLeft ? '│   ' : '    '),
      false,
    );
  }
  res += indent;
  res += isLeft ? '└── ' : '┌── ';
  res += '${node.index}\n';
  if (node.left != null) {
    res += generateAsciiTree(
      node.left,
      indent + (isLeft ? '    ' : '│   '),
      true,
    );
  }
  return res;
}

String prettyPrintTree(TreeNode? root) {
  if (root == null) return '';
  final levels = <List<String>>[];
  var queue = <TreeNode?>[root];
  while (queue.any((n) => n != null)) {
    final level = <String>[];
    final next = <TreeNode?>[];
    for (final n in queue) {
      if (n == null) {
        level.add(' ');
        next.addAll([null, null]);
      } else {
        level.add('${n.index}');
        next.addAll([n.left, n.right]);
      }
    }
    levels.add(level);
    queue = next;
  }
  return levels.map((l) => l.join('   ')).join('\n');
}

String computeErrorLevel({
  required double scoreChange,
  required double scoreSpan,
}) {
  if (scoreChange >= 90 && scoreSpan >= 90) return '完全掌握';
  if (scoreChange >= 75 && scoreSpan >= 75) return '接近掌握';
  if (scoreChange >= 50 && scoreSpan >= 50) return '有進步空間';
  return '需要加強理解';
}

/*─────────────────────────────────────────────
  動態評量回饋函式
─────────────────────────────────────────────*/
Future<String> generateAiFeedback({
  required String mode,
  required List<String> userUids,
  required List<String> correctUids,
  required String algorithm,
  String? treeVisualization,
  String? errorInfo,
  String? learningHistory,
  double? score,
}) async {
  if (mode != 'dynamic') {
    return '目前僅支援 dynamic 模式，請將 mode 設為 "dynamic"。';
  }

  /*------------ OpenAI 設定 ------------*/
  const apiUrl = 'https://api.openai.com/v1/chat/completions';
  const apiKey = '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';
  if (apiKey.isEmpty) return '無法取得 OpenAI API Key';

  /*------------ 可選區塊 ------------*/
  final treeSection = (treeVisualization?.isNotEmpty ?? false)
      ? '[二元樹視覺化]:\n$treeVisualization\n'
      : '';

  final errorSection =
  (errorInfo?.isNotEmpty ?? false) ? '[錯誤資訊]:\n$errorInfo\n' : '';

  final historySection = (learningHistory?.isNotEmpty ?? false)
      ? '[學習歷程資訊]:\n$learningHistory\n'
      : '';

  /*------------ 格式模板（*唯一改動*） ------------*/
  const formatTemplate = '''
【提示格式】
【學習進展】：
<請依下列分級規則輸出：完全掌握 / 接近掌握 / 有進步空間 / 需要加強理解（擇一），回答請控制在 100 tokens 內>

[分級規則]：
1) Score_change ≥ 90 且 Score_span ≥ 90  → 完全掌握
2) Score_change ≥ 75 且 Score_span ≥ 75  → 接近掌握
3) Score_change ≥ 50 且 Score_span ≥ 50  → 有進步空間
4) 其他                                      → 需要加強理解

【改進建議】：
<分別針對 Score_change 與 Score_span 提出 1–2 句最關鍵建議，總長度 ≤ 150 tokens>

【二元樹視覺化及走訪描述】：
<引用系統提供之視覺化並描述走訪結果中的關鍵差異，總長度 ≤ 150 tokens>

請嚴格依此格式輸出，且完整回答不要超過 400 tokens。
''';

  /*------------ 動態 prompt ------------*/
  final dynamicPrompt = '''
【漸進式動態評量指引】：
請根據下列資料直接比較「使用者走訪順序」與「正確走訪順序」，並套用上方格式模板輸出：

[使用者走訪順序]: ${userUids.join(' -> ')}
[正確走訪順序]: ${correctUids.join(' -> ')}

$treeSection$errorSection$historySection
''';

  final combinedPrompt = '''
$formatTemplate
$dynamicPrompt
''';

  /*------------ 呼叫 OpenAI ------------*/
  final requestBody = jsonEncode({
    'model': 'o3-mini-2025-01-31',
    'messages': [
      {
        'role': 'system',
        'content':
        '你是一位演算法教學助理，請依格式模板返回結構化回饋，並遵守 tokens 限制。'
      },
      {'role': 'user', 'content': combinedPrompt}
    ],
    'max_completion_tokens': 1500,
    'stop': ['【提示格式】']
  });

  try {
    final res = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: requestBody,
    );

    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      final txt = data['choices'][0]['message']['content'] ?? '';
      return txt.trim().isEmpty ? 'AI 回傳為空，請檢查 prompt。' : txt.trim();
    }
    return 'OpenAI 回應錯誤 (${res.statusCode})\\n${res.body}';
  } catch (e) {
    return '請求失敗：$e';
  }
}
