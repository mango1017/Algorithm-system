import 'package:flutter/material.dart';

class UserManualPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.indigo.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  '操作手冊 / 使用者指南',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                    fontFamily: 'PressStart2P',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  '歡迎使用「演算法學習系統」！本操作手冊將協助您快速了解操作流程與注意事項，'
                      '讓您能順利體驗體現式學習、動態評量與 AI 輔助之魅力。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                // 指引卡片 (1)
                _buildManualCard(
                  iconData: Icons.auto_graph,
                  title: '1. 選擇樹型與演算法',
                  content:
                  '在主頁面中，您可以選擇想要體現的樹型（如普通二元樹、二元搜尋樹、AVL 樹、紅黑樹）'
                      '，並決定使用廣度優先搜尋 (BFS) 或深度優先搜尋 (DFS)。',
                ),
                SizedBox(height: 20),
                // 指引卡片 (2)
                _buildManualCard(
                  iconData: Icons.nfc,
                  title: '2. 掃描 NFC 標籤',
                  content:
                  '系統將提示您使用手機感應器掃描 NFC 標籤，'
                      '以決定樹的節點，或在學習階段模擬算法走訪。請確保手機已開啟 NFC 功能並正確感應。',
                ),
                SizedBox(height: 20),
                // 指引卡片 (3)
                _buildManualCard(
                  iconData: Icons.play_circle_outline,
                  title: '3. 生成樹結構／開始學習',
                  content:
                  '完成節點掃描後，點擊「生成樹結構」檢視系統為所選樹型與節點自動建構的演算法邏輯，'
                      '然後點選「開始學習」進入實作操作階段。'
                      '在此階段中，您將透過體現式方式進行插入、刪除或走訪操作，系統會即時回饋。',
                ),
                SizedBox(height: 20),
                // 指引卡片 (4)
                _buildManualCard(
                  iconData: Icons.insights,
                  title: '4. 動態評量 & AI 輔助',
                  content:
                  '在漸進式動態評量模式下，系統會依操作即時評估並修正錯誤；'
                      '在總結性評量模式下，則於操作結束後提供完整結果與分析。'
                      'AI 助理將根據您的操作序列給予個人化建議。',
                ),
                SizedBox(height: 20),
                // 指引卡片 (5)
                _buildManualCard(
                  iconData: Icons.analytics,
                  title: '5. 查看結果與重學',
                  content:
                  '完成所有操作或時間結束後，系統會顯示最終得分、耗時與錯誤分析。'
                      '您可選擇「再試一次」清除先前紀錄並重新開始學習。',
                ),
                SizedBox(height: 30),
                Text(
                  '希望您能在此系統中透過體現式學習深入理解各種樹型演算法，'
                      '並享受 AI 輔助帶來的個人化學習體驗！',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualCard({
    required IconData iconData,
    required String title,
    required String content,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: Colors.indigo, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                      fontFamily: 'PressStart2P',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
