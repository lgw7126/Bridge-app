import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../config/app_globals.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드 수신 — Firebase는 이미 초기화된 상태
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n == null) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            n.body ?? n.title ?? '알림이 도착했습니다.',
            style: const TextStyle(fontSize: 18),
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF1A56DB),
        ),
      );
    });
  }

  static Future<void> saveToken(String uid) async {
    if (uid.isEmpty) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    await _db.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  static Future<void> sendTaxiRequest(String childUid) async {
    if (!AppConfig.hasFcmKey || childUid.isEmpty) return;
    final snap = await _db.collection('users').doc(childUid).get();
    final token = snap.data()?['fcmToken'] as String?;
    if (token == null) return;

    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=${AppConfig.fcmServerKey}',
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'title': '🚕 택시 호출 요청',
          'body': '부모님이 택시를 요청하셨어요. 지금 확인해 주세요!',
          'android_channel_id': 'taxi_request',
        },
        'priority': 'high',
      }),
    );
  }
}
