import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class RichTransitionAnimation extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  const RichTransitionAnimation({Key? key, required this.onAnimationComplete})
      : super(key: key);

  @override
  _RichTransitionAnimationState createState() => _RichTransitionAnimationState();
}

class _RichTransitionAnimationState extends State<RichTransitionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _playTransitionSound();
    _controller.forward().whenComplete(() {
      widget.onAnimationComplete();
    });
  }

  Future<void> _playTransitionSound() async {
    try {
      // 請確保在 pubspec.yaml 中宣告了 assets/audio/unlock.mp3
      await _audioPlayer.play(AssetSource('assets/audio/unlock.mp3'));
    } catch (e) {
      debugPrint("播放音效錯誤: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          color: Colors.black.withOpacity(0.8),
          child: Center(
            child: Text(
              "任務完成！",
              style: TextStyle(fontSize: 28, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
