import 'package:flutter/material.dart';

class UserManualPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 如果需要 AppBar，可以打開使用
      // appBar: AppBar(
      //   title: Text('使用者指南'),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      // ),
      body: Container(
        // 與主系統相同的漸層背景
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
                // 主標題
                Text(
                  '操作手冊 / 使用者指南',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                    fontFamily: 'PressStart2P', // 若無此字型可移除
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                // 簡要引言
                Text(
                  '歡迎使用「演算法學習系統」！本操作手冊將協助您快速了解操作流程與注意事項，'
                      '讓您能順利體驗遊戲化學習、動態評量與 AI 輔助之魅力。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                // 操作指引卡片 (1)
                _buildManualCard(
                  iconData: Icons.auto_graph,
                  title: '1. 選擇演算法',
                  content:
                  '在主頁面中，您可以選擇想要體驗或驗證的圖論演算法，例如 DFS 或 BFS。'
                      '並且可指定評量方式（總結性 / 動態評量）。選擇後會進入 NFC 掃描頁面。',
                ),
                SizedBox(height: 20),
                // 操作指引卡片 (2)
                _buildManualCard(
                  iconData: Icons.nfc,
                  title: '2. 掃描 NFC',
                  content:
                  '系統將指示您使用手機感應器掃描 NFC 標籤，以決定樹的節點或驗證演算法走訪順序。'
                      '確保手機已開啟 NFC 功能並正確感應標籤位置。',
                ),
                SizedBox(height: 20),
                // 操作指引卡片 (3)
                _buildManualCard(
                  iconData: Icons.catching_pokemon,
                  title: '3. 生成二元樹 / 開始遊戲',
                  content:
                  '掃描完成後，可按下「生成二元樹」按鈕查看系統自動建構的樹形結構，並點選「開始遊戲」進入計時掃描階段。'
                      '系統會偵測您掃描的順序並與理想走訪順序對比，給予即時回饋或最後分數。',
                ),
                SizedBox(height: 20),
                // 操作指引卡片 (4)
                _buildManualCard(
                  iconData: Icons.lightbulb,
                  title: '4. AI 助理 / 動態評量',
                  content:
                  '若選擇「漸進式動態評量」，系統會根據您掃描的先後順序，'
                      '即時偵測錯誤並透過 AI 助理給予提示，協助您修正路徑。'
                      '若選擇「總結性評量」，則在遊戲結束時一次提供結果與分析。',
                ),
                SizedBox(height: 20),
                // 操作指引卡片 (5)
                _buildManualCard(
                  iconData: Icons.insights,
                  title: '5. 查看結果與分析',
                  content:
                  '完成整個走訪或時間到後，系統會顯示最終得分與耗時，並可透過 AI 回饋了解錯誤之處。'
                      '若想重新開始，可點擊「重新開始遊戲」並清除先前的掃描紀錄。',
                ),
                SizedBox(height: 30),
                // 結尾或備註
                Text(
                  '希望您能在此系統中享受學習與遊戲結合的樂趣，\n'
                      '並藉由動態評量與 AI 輔助快速提升對圖論演算法的理解與應用能力！',
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

  /// 生成操作指引卡片
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
                      fontFamily: 'PressStart2P', // 若無此字型可刪除
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
