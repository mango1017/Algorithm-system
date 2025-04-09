import 'dart:async';
import 'package:flutter/material.dart';

class RichDialogueBox extends StatefulWidget {
  final String characterName;
  final String characterImage;
  final List<String> dialogues;
  final VoidCallback onDialogueComplete;

  const RichDialogueBox({
    Key? key,
    required this.characterName,
    required this.characterImage,
    required this.dialogues,
    required this.onDialogueComplete,
  }) : super(key: key);

  @override
  _RichDialogueBoxState createState() => _RichDialogueBoxState();
}

class _RichDialogueBoxState extends State<RichDialogueBox> {
  int _dialogueIndex = 0;
  String _displayedText = "";
  Timer? _timer;
  int _charIndex = 0;
  final Duration _charDelay = const Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer?.cancel();
    _displayedText = "";
    _charIndex = 0;
    String fullText = widget.dialogues[_dialogueIndex];

    _timer = Timer.periodic(_charDelay, (timer) {
      if (_charIndex < fullText.length) {
        setState(() {
          _displayedText += fullText[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _nextDialogue() {
    // 如果對話尚未完全顯示，先直接顯示完整文字
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
      setState(() {
        _displayedText = widget.dialogues[_dialogueIndex];
      });
      return;
    }
    if (_dialogueIndex < widget.dialogues.length - 1) {
      setState(() {
        _dialogueIndex++;
      });
      _startTyping();
    } else {
      widget.onDialogueComplete();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(widget.characterImage),
              radius: 30,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.characterName,
                    style: TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _displayedText,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            IconButton(
              icon: Icon(Icons.arrow_forward, color: Colors.white),
              onPressed: _nextDialogue,
            ),
          ],
        ),
      ),
    );
  }
}
