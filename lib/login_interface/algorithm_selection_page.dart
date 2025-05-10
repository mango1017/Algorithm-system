import 'package:flutter/material.dart';
import 'learn_algorithm_page.dart';

void main() => runApp(const MyGameApp());

class MyGameApp extends StatelessWidget {
  const MyGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '演算法學習系統',
      home: AlgorithmSelectionPage(),
    );
  }
}

/// 首頁
class AlgorithmSelectionPage extends StatelessWidget {
  const AlgorithmSelectionPage({super.key});

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _AnimatedRotatingIcon(),
                  const SizedBox(height: 20),
                  Text('演算法學習系統',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                        fontFamily: 'PressStart2P',
                      ),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('挑戰你的思維極限！',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.indigo.shade600,
                        fontFamily: 'PressStart2P',
                      ),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Text(
                    '在這裡，你可以透過遊戲化方式學習圖論與演算法。'
                        '系統將提供動態評量與 AI 輔助，讓你在任務中即時修正錯誤，'
                        '並深度理解演算法的運作機制！',
                    style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _SystemIntroductionCard(),
                  const SizedBox(height: 30),
                  // ================= 開始學習按鈕 =================
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LearnAlgorithmPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'PressStart2P'),
                    ),
                    child: const Text('開始學習'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------- 子元件 -----------------------------
class _SystemIntroductionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('assets/smile_face.gif', height: 120, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text('系統簡介',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                  fontFamily: 'PressStart2P',
                )),
            const SizedBox(height: 12),
            Text(
              '本系統結合「遊戲化學習」、「動態評量」及「AI 輔助」：\n\n'
                  '• 遊戲化：以關卡制、成就系統激發挑戰動力。\n'
                  '• 動態評量：在操作中即時修正錯誤，縮短學習迴路。\n'
                  '• AI 輔助：根據你的答題情況與路徑，自動給予提示，帶來個人化學習體驗！\n\n'
                  '最終目標：使抽象的圖論與演算法變得具象易懂，並在輕鬆互動中累積深度思維。',
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade700),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: const [
              _IconLabel(icon: Icons.videogame_asset, label: '遊戲化'),
              _IconLabel(icon: Icons.insights, label: '動態評量'),
              _IconLabel(icon: Icons.psychology, label: 'AI 輔助'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: Colors.indigo, size: 28),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(fontSize: 12, color: Colors.indigo.shade700)),
  ]);
}

class _AnimatedRotatingIcon extends StatefulWidget {
  const _AnimatedRotatingIcon();
  @override
  State<_AnimatedRotatingIcon> createState() => _AnimatedRotatingIconState();
}

class _AnimatedRotatingIconState extends State<_AnimatedRotatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _controller,
    child: Icon(Icons.auto_graph, size: 120, color: Colors.indigo.shade300),
  );
}
