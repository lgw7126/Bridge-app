import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum LinkResult { success, codeNotFound, alreadyLinked, error }

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  Future<String> signInAnonymously() async {
    if (_auth.currentUser != null) return _auth.currentUser!.uid;
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  /// 중복되지 않는 6자리 코드를 생성합니다.
  Future<String> generateUniqueCode() async {
    final random = Random();
    String code;
    bool exists;
    do {
      code = (100000 + random.nextInt(900000)).toString();
      final doc = await _db.collection('linking_codes').doc(code).get();
      exists = doc.exists;
    } while (exists);
    return code;
  }

  /// 부모님 코드를 Firestore에 생성합니다.
  Future<void> createParentCode(String uid, String code) async {
    final batch = _db.batch();
    batch.set(_db.collection('linking_codes').doc(code), {
      'parentUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isLinked': false,
      'childUid': null,
    });
    batch.set(_db.collection('users').doc(uid), {
      'role': 'parent',
      'linkCode': code,
      'linkedWithUid': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// 코드 문서의 변경 사항을 실시간으로 수신합니다.
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToLinkingCode(
      String code) {
    return _db.collection('linking_codes').doc(code).snapshots();
  }

  /// 자녀가 코드를 입력하여 부모님 계정과 연결합니다.
  Future<LinkResult> linkChildToParent(String code, String childUid) async {
    try {
      final codeDoc = await _db.collection('linking_codes').doc(code).get();
      if (!codeDoc.exists) return LinkResult.codeNotFound;

      final data = codeDoc.data()!;
      if (data['isLinked'] == true) return LinkResult.alreadyLinked;

      final String parentUid = data['parentUid'] as String;

      await _db.runTransaction((txn) async {
        final codeRef = _db.collection('linking_codes').doc(code);
        final childRef = _db.collection('users').doc(childUid);
        final parentRef = _db.collection('users').doc(parentUid);

        txn.update(codeRef, {
          'isLinked': true,
          'childUid': childUid,
          'linkedAt': FieldValue.serverTimestamp(),
        });
        txn.set(childRef, {
          'role': 'child',
          'linkCode': code,
          'linkedWithUid': parentUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        txn.update(parentRef, {'linkedWithUid': childUid});
      });

      return LinkResult.success;
    } catch (_) {
      return LinkResult.error;
    }
  }

  /// 자녀가 requests 문서를 실시간 구독합니다.
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToRequest(
      String parentUid) {
    return _db.collection('requests').doc(parentUid).snapshots();
  }

  /// 요청 상태를 업데이트합니다 (accepted / completed).
  Future<void> updateRequestStatus(String parentUid, String status) async {
    final data = <String, dynamic>{'status': status};
    if (status == 'accepted') {
      data['acceptedAt'] = FieldValue.serverTimestamp();
    } else if (status == 'completed') {
      data['completedAt'] = FieldValue.serverTimestamp();
    }
    await _db.collection('requests').doc(parentUid).update(data);
  }
}
