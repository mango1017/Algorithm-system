import 'package:flutter/material.dart';
import 'algorithm_selection_page.dart';

class ExploreAlgorithmsPage extends StatelessWidget {
  final List<AlgorithmInfo> algorithms = [
    AlgorithmInfo(
      '深度優先搜尋演算法 (DFS)',
      '深度優先搜尋演算法是一種遍歷或搜尋樹或圖資料結構的演算法。從根節點開始，沿著每個分支盡可能深入探索，然後回溯。',
      'assets/dfs_full_binary_tree.gif',
    ),
    AlgorithmInfo(
      '廣度優先搜尋演算法 (BFS)',
      '廣度優先搜尋演算法是一種遍歷或搜尋樹或圖資料結構的演算法。它從根節點開始，探索當前深度的所有鄰居節點，然後再移到下一個深度層次的節點。',
      'assets/bfs_full_binary_tree.gif',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          '探索演算法',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.indigo.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: algorithms.length,
            itemBuilder: (context, index) {
              return _buildAlgorithmCard(algorithms[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAlgorithmCard(AlgorithmInfo algorithm) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              algorithm.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12.0),
            Image.asset(
              algorithm.gifPath,
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 12.0),
            Text(
              algorithm.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlgorithmInfo {
  final String name;
  final String description;
  final String gifPath;

  AlgorithmInfo(this.name, this.description, this.gifPath);
}
