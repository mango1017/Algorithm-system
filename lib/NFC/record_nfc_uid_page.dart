import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nfc_scanner.dart';

class RecordNFCUIDPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('記錄 NFC UID'),
      ),
      body: RecordNFCUIDBody(),
    );
  }
}

class RecordNFCUIDBody extends StatefulWidget {
  @override
  _RecordNFCUIDBodyState createState() => _RecordNFCUIDBodyState();
}

class _RecordNFCUIDBodyState extends State<RecordNFCUIDBody> {
  final NFCScanner _nfcScanner = NFCScanner();
  String _statusMessage = 'NFC UID 會顯示在這裡';
  bool _scanning = false;
  List<String> _nfcUids = [];

  @override
  void initState() {
    super.initState();
    _loadNfcUids();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNFCAvailability();
    });
  }

  Future<void> _loadNfcUids() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nfcUids = prefs.getStringList('nfcUids') ?? [];
    });
  }

  Future<void> _saveNfcUids() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nfcUids', _nfcUids);
  }

  Future<void> _checkNFCAvailability() async {
    try {
      bool isAvailable = await _nfcScanner.isNfcAvailable();
      setState(() {
        _statusMessage = isAvailable ? 'NFC 可用' : 'NFC 不可用';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '檢查 NFC 可用性時出錯: $e';
      });
    }
  }

  void _startNFC() async {
    setState(() {
      _scanning = true;
      _statusMessage = '正在掃描 NFC...';
    });

    try {
      String? nfcUid = await _nfcScanner.scanNfc();
      if (nfcUid != null) {
        setState(() {
          _nfcUids.add(nfcUid);
          _statusMessage = 'NFC 掃描成功: $nfcUid';
        });
        await _sendUidToFirebase(nfcUid);
        await _saveNfcUids();  // 保存 UID 到 SharedPreferences
      } else {
        setState(() {
          _statusMessage = 'NFC 掃描失敗';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'NFC 掃描出錯: $e';
      });
    } finally {
      setState(() {
        _scanning = false;
      });
    }
  }

  Future<void> _sendUidToFirebase(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('nfc_uids').add({
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('傳送 UID 至 Firestore 時出錯: $e');
    }
  }

  void _clearNfcUids() async {
    setState(() {
      _nfcUids.clear();
    });
    await _saveNfcUids();  // 清除後保存
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _statusMessage,
            style: TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          _scanning
              ? Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('掃描中...'),
            ],
          )
              : ElevatedButton(
            onPressed: _startNFC,
            child: Text('開始掃描 NFC'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _clearNfcUids,
            child: Text('清除 UID 列表'),
          ),
          SizedBox(height: 20),
          Text(
            '掃描記錄',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _nfcUids.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(_nfcUids[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
