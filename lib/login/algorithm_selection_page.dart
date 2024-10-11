import 'package:flutter/material.dart';
import 'explore_algorithms_page.dart';
import 'learn_algorithm_page.dart';

class AlgorithmSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '選擇一個選項',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.0),
          _buildOptionButton(
            context,
            '探索演算法',
                () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ExploreAlgorithmsPage()),
            ),
          ),
          SizedBox(height: 16.0),
          _buildOptionButton(
            context,
            '學習演算法',
                () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LearnAlgorithmPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, String title, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(title),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          textStyle: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
