/*
import 'dart:async';
import 'dart:io' show Platform;
import 'package:nfc_manager/nfc_manager.dart';

class NFCScanner {
  Future<bool> isNfcAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      print('檢查 NFC 可用性時出錯: $e');
      return false;
    }
  }

  /// 開始掃描 NFC 標籤並返回其 UID
  Future<String?> scanNfc() async {
    final Completer<String?> completer = Completer<String?>();

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          String? nfcUid = _parseNfcTag(tag);
          await NfcManager.instance.stopSession();
          completer.complete(nfcUid);
        },
        onError: (error) async {
          print('NFC 掃描錯誤: $error');
          await NfcManager.instance.stopSession(errorMessage: error.toString());
          completer.complete(null);
        },
      );
    } catch (e) {
      print('掃描 NFC 時出錯: $e');
      completer.complete(null);
    }

    return completer.future;
  }

  /// 解析 NFC 標籤以獲取 UID
  String? _parseNfcTag(NfcTag tag) {
    try {
      String? nfcUid;
      if (Platform.isIOS) {
        if (tag.data.containsKey('mifare')) {
          nfcUid = tag.data['mifare']['identifier']
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':');
        } else if (tag.data.containsKey('iso15693')) {
          nfcUid = tag.data['iso15693']['identifier']
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':');
        }
      } else if (Platform.isAndroid) {
        if (tag.data.containsKey('nfca')) {
          nfcUid = tag.data['nfca']['identifier']
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':');
        } else if (tag.data.containsKey('nfcb')) {
          nfcUid = tag.data['nfcb']['identifier']
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':');
        } else if (tag.data.containsKey('nfcf')) {
          nfcUid = tag.data['nfcf']['identifier']
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':');
        } else if (tag.data.containsKey('nfcv')) {
          nfcUid = tag.data['nfcv']['identifier']
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':');
        }
      }
      return nfcUid;
    } catch (e) {
      print('解析 NFC 標籤時出錯: $e');
      return null;
    }
  }
}
*/