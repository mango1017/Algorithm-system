import 'package:flutter/material.dart';

class ExploreAlgorithmsPage extends StatelessWidget {
  final List<AlgorithmInfo> algorithms = [
    AlgorithmInfo('深度優先搜尋演算法 (DFS)', '深度優先搜尋演算法是一種遍歷或搜尋樹或圖資料結構的演算法。從根節點開始，沿著每個分支盡可能深入探索，然後回溯。', 'assets/dfs_full_binary_tree.gif'),
    AlgorithmInfo('廣度優先搜尋演算法 (BFS)', '廣度優先搜尋演算法是一種遍歷或搜尋樹或圖資料結構的演算法。它從根節點開始，探索當前深度的所有鄰居節點，然後再移到下一個深度層次的節點。', 'assets/bfs_full_binary_tree.gif'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('探索演算法'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: algorithms.length,
        itemBuilder: (context, index) {
          return buildAlgorithmCard(algorithms[index]);
        },
      ),
    );
  }

  Widget buildAlgorithmCard(AlgorithmInfo algorithm) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              algorithm.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              style: TextStyle(fontSize: 16),
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