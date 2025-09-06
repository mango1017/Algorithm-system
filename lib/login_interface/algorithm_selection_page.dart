import 'package:flutter/material.dart';
import 'learn_algorithm_page.dart';

const _mainColor = Colors.indigo;
ButtonStyle _mainButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: _mainColor.shade400,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  textStyle: const TextStyle(
      fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'PressStart2P'),
);

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

class AlgorithmSelectionPage extends StatelessWidget {
  const AlgorithmSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
            icon: Icon(Icons.arrow_back, color: _mainColor.shade700),
            onPressed: () => Navigator.pop(context),
          )
              : null,
          title: Text('DyAlgo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _mainColor.shade900,
                fontFamily: 'PressStart2P',
              )),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: '系統簡介'),
              Tab(icon: Icon(Icons.play_circle_outline), text: '開始學習'),
            ],
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_mainColor.shade50, _mainColor.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: TabBarView(
              children: [
                _SystemIntroductionTab(),
                _StartLearningTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartLearningTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _AnimatedRotatingIcon(),
            const SizedBox(height: 20),
            Text('挑戰你的思維極限！',
                style: TextStyle(
                  fontSize: 18,
                  color: _mainColor.shade600,
                  fontFamily: 'PressStart2P',
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Text(
              '在這裡，你可以透過體現式學習方式學習圖論與演算法。\n系統將提供動態評量與 AI 輔助，讓你在操作中即時修正錯誤，並深度理解演算法的運作機制！',
              style: TextStyle(
                  fontSize: 14, height: 1.5, color: Colors.grey.shade800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LearnAlgorithmPage()),
                );
              },
              style: _mainButtonStyle(),
              child: const Text('開始學習'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemIntroductionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _SystemIntroductionCard(),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('assets/smile_face.gif',
                  height: 120, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text('系統簡介',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _mainColor.shade800,
                  fontFamily: 'PressStart2P',
                )),
            const SizedBox(height: 12),
            Text(
              '本系統結合「體現式學習」、「動態評量』及「AI 輔助」：\n\n'
                  '• 體現式學習：通過實際操作與互動體驗促進深度理解。\n'
                  '• 動態評量：在操作中即時修正錯誤，縮短學習迴路。\n'
                  '• AI 輔助：根據你的答題情況與路徑，自動給予提示，帶來個人化學習體驗！\n\n'
                  '最終目標：使抽象的圖論與演算法變得具象易懂，並在輕鬆互動中累積深度思維。',
              style: TextStyle(
                  fontSize: 14, height: 1.5, color: Colors.grey.shade700),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _IconLabel(icon: Icons.self_improvement, label: '體現式學習'),
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
    Icon(icon, color: _mainColor, size: 28),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(fontSize: 12, color: _mainColor.shade700)),
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
  AnimationController(vsync: this, duration: const Duration(seconds: 10))
    ..repeat();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _controller,
    child: Icon(Icons.auto_graph, size: 120, color: _mainColor.shade300),
  );
}
