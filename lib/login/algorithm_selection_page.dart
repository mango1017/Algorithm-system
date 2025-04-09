import 'package:flutter/material.dart';
import 'package:okk/widgets/DialogueBox.dart';
import 'package:okk/widgets/TransitionAnimation.dart';

void main() {
  runApp(MyGameApp());
}

class MyGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '演算法學習系統',
      home: AlgorithmSelectionPage(),
    );
  }
}

class AlgorithmSelectionPage extends StatefulWidget {
  @override
  _AlgorithmSelectionPageState createState() => _AlgorithmSelectionPageState();
}

class _AlgorithmSelectionPageState extends State<AlgorithmSelectionPage> {
  bool _showDialogue = false;
  bool _showTransition = false;

  void _startDialogue() {
    setState(() {
      _showDialogue = true;
    });
  }

  void _onDialogueComplete() {
    setState(() {
      _showDialogue = false;
      _showTransition = true;
    });
  }

  void _onTransitionComplete() {
    setState(() {
      _showTransition = false;
      // 例如，進入下一個頁面或關卡
    });
  }

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
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AnimatedRotatingIcon(),
                      SizedBox(height: 20),
                      Text(
                        '演算法學習系統',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                          fontFamily: 'PressStart2P',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '挑戰你的思維極限！',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.indigo.shade600,
                          fontFamily: 'PressStart2P',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      Text(
                        '在這裡，你可以透過遊戲化方式學習圖論與演算法。'
                            '系統將提供動態評量與 AI 輔助，讓你在任務中即時修正錯誤，'
                            '並深度理解演算法的運作機制！',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      _buildSystemIntroductionCard(),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _startDialogue,
                        child: Text("開始劇情"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade200,
                          padding: EdgeInsets.symmetric(
                              vertical: 20.0, horizontal: 30.0),
                          textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PressStart2P'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showDialogue)
                RichDialogueBox(
                  characterName: "小幫手",
                  characterImage: "assets/assistant_robot.png",
                  dialogues: [
                    "歡迎來到演算法的世界！",
                    "請仔細觀察系統簡介，準備進入學習模式。",
                    "按下下一步，我們馬上開始！"
                  ],
                  onDialogueComplete: _onDialogueComplete,
                ),
              if (_showTransition)
                RichTransitionAnimation(
                  onAnimationComplete: _onTransitionComplete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemIntroductionCard() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/smile_face.gif',
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '系統簡介',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
                fontFamily: 'PressStart2P',
              ),
            ),
            SizedBox(height: 12),
            Text(
              '本系統結合「遊戲化學習」、「動態評量」及「AI 輔助」：\n\n'
                  '• 遊戲化：以關卡制、成就系統激發挑戰動力。\n'
                  '• 動態評量：在操作中即時修正錯誤，縮短學習迴路。\n'
                  '• AI 輔助：根據你的答題情況與路徑，自動給予提示，帶來個人化學習體驗！\n\n'
                  '最終目標：使抽象的圖論與演算法變得具象易懂，並在輕鬆互動中累積深度思維。',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconLabel(Icons.videogame_asset, '遊戲化'),
                _buildIconLabel(Icons.insights, '動態評量'),
                _buildIconLabel(Icons.psychology, 'AI 輔助'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo, size: 28),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.indigo.shade700),
        ),
      ],
    );
  }
}

class _AnimatedRotatingIcon extends StatefulWidget {
  @override
  __AnimatedRotatingIconState createState() => __AnimatedRotatingIconState();
}

class __AnimatedRotatingIconState extends State<_AnimatedRotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.auto_graph,
        size: 120,
        color: Colors.indigo.shade300,
      ),
    );
  }
}
