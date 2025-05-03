import 'dart:convert';
import 'package:okk/login/learn_algorithm_page.dart';
import 'package:http/http.dart' as http;


String generateAsciiTree(TreeNode? node, [String indent = "", bool isLeft = true]) {
  if (node == null) return "";
  String result = "";
  if (node.right != null) {
    result += generateAsciiTree(node.right, indent + (isLeft ? "│   " : "    "), false);
  }
  result += indent;
  result += isLeft ? "└── " : "┌── ";
  result += "${node.index}\n";
  if (node.left != null) {
    result += generateAsciiTree(node.left, indent + (isLeft ? "    " : "│   "), true);
  }
  return result;
}

String prettyPrintTree(TreeNode? root) {
  if (root == null) return "";
  List<List<String>> levels = [];
  List<TreeNode?> queue = [root];
  while (queue.any((node) => node != null)) {
    List<String> level = [];
    List<TreeNode?> nextQueue = [];
    for (TreeNode? node in queue) {
      if (node == null) {
        level.add(" ");
        nextQueue.add(null);
        nextQueue.add(null);
      } else {
        level.add("${node.index}");
        nextQueue.add(node.left);
        nextQueue.add(node.right);
      }
    }
    levels.add(level);
    queue = nextQueue;
  }
  return levels.map((l) => l.join("   ")).join("\n");
}

String computeErrorLevel(double score, List<Map<String, dynamic>> errorBuffer) {
  if (score == 0) return "需要更加努力";
  int count = errorBuffer.length;
  if (count == 0) return "完全掌握";
  if (count == 1) return "接近掌握";
  if (count <= 3) return "有進步空間";
  return "需要加強理解";
}

// =====================================================
//                 動    態    評    量
// =====================================================
/// 動態生成 AI 回饋函式
///
/// [mode] 一律以 'dynamic' 為支援模式；若傳入其他值將回傳錯誤字串。
Future<String> generateAiFeedback({
  required String mode,          // 仍保留，但僅接受 'dynamic'
  double? score,                 // 不再使用（為了相容性保留）
  required List<String> userUids,
  required List<String> correctUids,
  required String algorithm,     // 不再使用（為了相容性保留）
  String? treeVisualization,
  String? errorInfo,
  String? learningHistory,
}) async {
  if (mode != 'dynamic') {
    return "目前僅支援 dynamic 模式，請將 mode 設為 'dynamic'。";
  }

  const String apiUrl = 'https://api.openai.com/v1/chat/completions';
  const String apiKey = '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';
  if (apiKey.isEmpty) {
    return '無法取得 OpenAI API Key';
  }

  final String treeSection = (treeVisualization?.isNotEmpty ?? false)
      ? '[二元樹視覺化]:\n$treeVisualization\n'
      : '[二元樹視覺化]:\n(未提供樹資料，請傳入實際視覺化內容，例如使用 prettyPrintTree() 生成)\n';

  final String errorSection = (errorInfo?.isNotEmpty ?? false)
      ? '[錯誤資訊]:\n$errorInfo\n'
      : '';

  final String historySection = (learningHistory?.isNotEmpty ?? false)
      ? '[學習歷程資訊]:\n$learningHistory\n'
      : '[學習歷程資訊]:\n(未提供學習歷程資訊，請傳入歷程數據以利更精準回饋)\n';
  
  const String formatTemplate = '''
【提示格式】
【學習進展】：<請根據下列錯誤等級規則和學習歷程資訊返回學習進展評級（完全掌握/接近掌握/有進步空間/需要加強理解），回答請不超過100 tokens>
[錯誤等級規則]:
1. 當使用者得分為 0，則返回「需要更加努力」；
2. 當錯誤統計資訊為空，且學習歷程顯示連續正確，則返回「完全掌握」；
3. 當錯誤統計資訊僅有 1 筆，且學習歷程顯示已有改善跡象，則返回「接近掌握」；
4. 當錯誤統計資訊介於 2 至 3 筆之間，且學習歷程顯示仍有部分重複錯誤，但進步明顯，則返回「有進步空間」；
5. 當錯誤統計資訊超過 3 筆，且學習歷程顯示長期不穩定，則返回「需要加強理解」；
【改進建議】：<請提供最關鍵且精煉的改進建議，不超過150 tokens>
【二元樹視覺化及走訪描述】：<請返回系統中的視覺化表示以及文字描述走訪結果中發現的關鍵差異，不超過150 tokens>
請嚴格按照此格式返回答案，且總回答不超過400 tokens。
''';


  final String dynamicPrompt = '''
【漸進式動態評量指引】：
請根據下列資料直接比較使用者走訪順序與正確走訪順序，並根據格式模板返回結構化結果：
$formatTemplate
[使用者走訪順序]: ${userUids.join(' -> ')}
[正確走訪順序]: ${correctUids.join(' -> ')}
[原始二元樹視覺化]:
<請替換為實際的樹視覺化表示>
$errorSection
$historySection
''';

  final String combinedPrompt = '''
你是一個專業的演算法教學輔助 AI，專注於幫助學生理解與應用各種演算法。
請根據下列資料直接給出結構化回饋，並在最後以【走訪描述】文字描述走訪結果的關鍵差異。
請嚴格遵守以下格式模板，且確保總回答不超過600 tokens：
$formatTemplate
$dynamicPrompt
''';

  final requestBody = jsonEncode({
    'model': 'o3-mini-2025-01-31',
    'messages': [
      {
        'role': 'system',
        'content': '你是一個專業的演算法教學輔助 AI，專注於幫助學生深入理解與應用各種演算法的原理與實踐。'
      },
      {
        'role': 'user',
        'content': combinedPrompt
      }
    ],
    'max_completion_tokens': 1200,
    'stop': ['【提示格式】']
  });

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = json.decode(decodedBody);
      final String aiMessage = data['choices'][0]['message']['content'] ?? '';
      return aiMessage
          .trim()
          .isEmpty
          ? '回傳結果為空，請檢查提示語或確認樹資料是否正確傳入。'
          : aiMessage.trim();
    } else {
      return '很抱歉，無法取得回饋，請稍後再試。(${response
          .statusCode})\n${response.body}';
    }
  } catch (e) {
    return '很抱歉，請求失敗，請稍後再試。\n$e';
  }
}