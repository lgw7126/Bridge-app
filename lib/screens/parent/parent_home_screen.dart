import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

enum _Status { idle, loading, success, error }

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  _Status _status = _Status.idle;
  DateTime? _lastSentTime;
  String? _errorMessage;
  StreamSubscription? _requestSub;
  String? _childStatus; // 'accepted'

  @override
  void initState() {
    super.initState();
    _listenToChildStatus();
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    super.dispose();
  }

  Future<void> _listenToChildStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final parentUid = prefs.getString('uid') ?? '';
    if (parentUid.isEmpty) return;
    _requestSub =
        FirestoreService().listenToRequest(parentUid).listen((snap) {
      if (!snap.exists || !mounted) return;
      final data = snap.data();
      if (data == null) return;
      final s = data['status'] as String?;
      if ((s == 'accepted' || s == 'completed') && _childStatus != s) {
        setState(() => _childStatus = s);
      }
    });
  }

  // ─── 메인 버튼 탭 ───────────────────────────────────────────────
  Future<void> _onRequestTaxi() async {
    final permitted = await _ensureLocationPermission();
    if (!permitted || !mounted) return;

    setState(() {
      _status = _Status.loading;
      _errorMessage = null;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));

      final prefs = await SharedPreferences.getInstance();
      final parentUid = prefs.getString('uid') ?? '';
      final linkedChildUid = prefs.getString('linkedWithUid') ?? '';

      await FirebaseFirestore.instance
          .collection('requests')
          .doc(parentUid)
          .set({
        'parentUid': parentUid,
        'linkedChildUid': linkedChildUid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (!mounted) return;
      setState(() {
        _status = _Status.success;
        _lastSentTime = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _errorMessage = '위치를 가져오는 데\n실패했습니다.\n다시 눌러 주세요.';
      });
    }
  }

  // ─── 권한 확인 ───────────────────────────────────────────────────
  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      await _showKoreanDialog(
        icon: Icons.location_off_rounded,
        iconColor: Colors.orange,
        title: 'GPS가 꺼져 있어요',
        body: '위치 서비스를 켜 주셔야\n택시를 부를 수 있어요.\n\n설정 → 위치 → 켜기',
        confirmLabel: '확인',
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      if (!mounted) return false;
      final proceed = await _showKoreanDialog(
        icon: Icons.location_on_rounded,
        iconColor: AppTheme.parentColor,
        title: '위치 권한이 필요해요',
        body: '자녀가 택시를 불러드리려면\n부모님의 현재 위치가 필요해요.\n\n"허용"을 눌러 주세요.',
        confirmLabel: '허용하기',
        cancelLabel: '취소',
      );
      if (!proceed || !mounted) return false;
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      await _showKoreanDialog(
        icon: Icons.location_disabled_rounded,
        iconColor: Colors.red,
        title: '위치 권한이 막혀있어요',
        body: '설정에서 직접 허용해 주세요.\n\n설정 → 앱 → 안심귀가\n→ 권한 → 위치',
        confirmLabel: '설정 열기',
        onConfirm: Geolocator.openAppSettings,
      );
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ─── 커스텀 다이얼로그 (시니어 친화) ────────────────────────────
  Future<bool> _showKoreanDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String confirmLabel,
    String? cancelLabel,
    Future<void> Function()? onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SeniorDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
    final confirmed = result ?? false;
    if (confirmed && onConfirm != null) await onConfirm();
    return confirmed;
  }

  // ─── 시간 포맷 ───────────────────────────────────────────────────
  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h시 $m분';
  }

  // ─── UI ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.parentColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.directions_car_rounded, size: 28),
            SizedBox(width: 10),
            Text(
              '안심 귀가',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 안내 / 오류 메시지
              _buildStatusBanner(),
              const SizedBox(height: 20),

              // ★ 핵심 버튼 — 화면 세로 50%
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.50,
                child: _buildMainButton(),
              ),

              const SizedBox(height: 20),

              // 마지막 전송 시각
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_status == _Status.error && _errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200, width: 1.5),
        ),
        child: Text(
          _errorMessage!,
          style: TextStyle(fontSize: 20, color: Colors.red.shade700),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Text(
      '버튼을 누르면\n자녀에게 위치가 전달됩니다.',
      style: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(color: const Color(0xFF64748B)),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMainButton() {
    // 로딩 상태: 비활성화 + 스피너
    if (_status == _Status.loading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(36),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 28),
              Text(
                '위치 확인 중...',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 성공 상태: 초록 버튼 (재전송 가능)
    if (_status == _Status.success) {
      return _BigButton(
        onPressed: _onRequestTaxi,
        backgroundColor: const Color(0xFF16A34A),
        shadowColor: const Color(0xFF16A34A),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 100, color: Colors.white),
            SizedBox(height: 24),
            Text(
              '요청 전송 완료!',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '다시 누르면 재전송합니다',
              style: TextStyle(fontSize: 20, color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // idle / error 상태: 주황 버튼
    return _BigButton(
      onPressed: _onRequestTaxi,
      backgroundColor: AppTheme.parentColor,
      shadowColor: AppTheme.parentColor,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_taxi_rounded, size: 100, color: Colors.white),
          SizedBox(height: 24),
          Text(
            '자녀에게',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          Text(
            '택시 호출',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          Text(
            '요청하기',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    // 자녀가 확인한 경우 — 최우선 표시
    if (_childStatus == 'accepted' || _childStatus == 'completed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade300, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: Colors.green.shade600, size: 28),
            const SizedBox(width: 10),
            Text(
              '자녀가 확인했어요! 🚕',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }

    // 요청 전송 후 대기 중
    if (_status == _Status.success && _lastSentTime != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time_rounded,
                    color: Colors.green.shade600, size: 24),
                const SizedBox(width: 10),
                Text(
                  '${_formatTime(_lastSentTime!)}에 전송됨',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 10),
              Text(
                '자녀 확인을 기다리는 중...',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── 재사용 가능한 대형 버튼 위젯 ─────────────────────────────────
class _BigButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color shadowColor;
  final Widget child;

  const _BigButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.shadowColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(36),
      elevation: 10,
      shadowColor: shadowColor.withAlpha(120),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(36),
        splashColor: Colors.white24,
        child: SizedBox.expand(child: Center(child: child)),
      ),
    );
  }
}

// ─── 시니어 친화 권한 다이얼로그 ──────────────────────────────────
class _SeniorDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String confirmLabel;
  final String? cancelLabel;

  const _SeniorDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 76, color: iconColor),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF475569),
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 66,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (cancelLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    cancelLabel!,
                    style: const TextStyle(
                        fontSize: 20, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
