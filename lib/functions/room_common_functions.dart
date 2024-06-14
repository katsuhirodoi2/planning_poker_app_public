import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 部屋番号の開始値、終了値、総数
const ROOM_START_NUM = 100;
const ROOM_END_NUM = 999;

// 開放予定時間が最小の部屋の開放予定時間
const INACTIVITY_RELEASE_MINUTES = 60;

Future<bool> checkRoomExists(String roomID) async {
  final firestore = FirebaseFirestore.instance;
  DateTime inactivityReleaseTime =
      DateTime.now().subtract(Duration(minutes: INACTIVITY_RELEASE_MINUTES));

  DocumentSnapshot roomSnapshot =
      await firestore.collection('rooms').doc(roomID).get();

  if (!roomSnapshot.exists) {
    // 部屋が存在しない場合
    return false;
  } else {
    // 部屋が存在するが、最後の活動からinactivityReleaseMinutes以上経過している場合
    if (roomSnapshot['lastActivityDateTime'] != null) {
      DateTime lastActivityDateTime =
          roomSnapshot['lastActivityDateTime'].toDate();
      if (lastActivityDateTime.isBefore(inactivityReleaseTime)) {
        return false;
      }
    } else {
      // lastActivityDateTimeがnullの場合、部屋は存在しないとみなす
      return false;
    }
  }

  // 部屋が存在し、最後の活動からinactivityReleaseMinutes未満の場合
  return true;
}

Future<bool> checkBlockUser(String roomID) async {
  final firestore = FirebaseFirestore.instance;
  var roomSnapshot = await firestore.collection('rooms').doc(roomID).get();

  String forUserBlockString = roomSnapshot.data()?['forUserBlockString'] ?? '';

  final prefs = await SharedPreferences.getInstance();
  String prefsForUserBlockString = prefs.getString('forUserBlockString') ?? '';

  if (prefsForUserBlockString.isNotEmpty &&
      prefsForUserBlockString == forUserBlockString) {
    return true;
  } else {
    return false;
  }
}
