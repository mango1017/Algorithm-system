import 'package:flutter/material.dart';
import 'algorithm_selection_page.dart';
import 'explore_algorithms_page.dart';
import 'learn_algorithm_page.dart';
import '../NFC/record_nfc_uid_page.dart';

class AlgorithmLearningPage extends StatefulWidget {
  @override
  _AlgorithmLearningPageState createState() => _AlgorithmLearningPageState();
}

class _AlgorithmLearningPageState extends State<AlgorithmLearningPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AlgorithmSelectionPage(),
    ExploreAlgorithmsPage(),
    LearnAlgorithmPage(),
    RecordNFCUIDPage(),
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: '選擇學習',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: '學習演算法',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nfc),
            label: '記錄 NFC',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
