import 'package:flutter/material.dart';
import 'algorithm_selection_page.dart';
import 'explore_algorithms_page.dart';
import 'learn_algorithm_page.dart';
import '../NFC/User_Manual_Page.dart';

class AlgorithmLearningPage extends StatefulWidget {
  @override
  _AlgorithmLearningPageState createState() => _AlgorithmLearningPageState();
}

class _AlgorithmLearningPageState extends State<AlgorithmLearningPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AlgorithmSelectionPage(), // 演算法選擇（首頁）
    ExploreAlgorithmsPage(),  // 探索演算法
    LearnAlgorithmPage(),     // 學習演算法
    UserManualPage(),         // 使用者指南
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('演算法學習'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: '探索學習'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: '學習演算法'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '使用者指南'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
