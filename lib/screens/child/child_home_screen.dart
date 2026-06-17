import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/firestore_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

enum _ReqState { waiting, pending, accepted }

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  _ReqState _state = _ReqState.waiting;
  Map<String, dynamic>? _req;
  String? _address;
  bool _loadingAddr = false;
  String? _parentUid;
  DateTime? _acceptedTime;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('linkedWithUid') ?? '';
    if (uid.isEmpty) return;
    setState(() => _parentUid = uid);

    final myUid = prefs.getString('uid') ?? '';
    await NotificationService.saveToken(myUid);

    _sub = FirestoreService().listenToRequest(uid).listen((snap) async {
      if (!snap.exists || !mounted) return;
      final data = snap.data();
      if (data == null) return;
      final status = data['status'] as String? ?? '';

      if (status == 'pending') {
        setState(() {
          _req = data;
          _state = _ReqState.pending;
        });
        final lat = (data['latitude'] as num).toDouble();
        final lng = (data['longitude'] as num).toDouble();
        await _loadAddress(lat, lng);
      } else if (status == 'accepted') {
        setState(() {
          _req = data;
          _state = _ReqState.accepted;
        });
      }
    });
  }

  Future<void> _loadAddress(double lat, double lng) async {
    setState(() {
      _loadingAddr = true;
      _address = null;
    });
    final result = await GeocodingService.reverseGeocode(lat, lng);
    if (mounted) {
      setState(() {
        _address = result;
        _loadingAddr = false;
      });
    }
  }

  Future<void> _openKakaoMap() async {
    if (_req == null) return;
    final lat = (_req!['latitude'] as num).toDouble();
    final lng = (_req!['longitude'] as num).toDouble();
    final appUri = Uri.parse('kakaomap://look?p=$lat,$lng');
    final webUri = Uri.parse('https://map.kakao.com/link/map/부모님위치,$lat,$lng');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyAddress() async {
    if (_req == null) return;
    final lat = (_req!['latitude'] as num).toDouble();
    final lng = (_req!['longitude'] as num).toDouble();
    final text = _address ?? '위도: ${lat.toStringAsFixed(5)}, 경도: ${lng.toStringAsFixed(5)}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('주소가 복사되었습니다!', style: TextStyle(fontSize: 18)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _markAccepted() async {
    if (_parentUid == null) return;
    await FirestoreService().updateRequestStatus(_parentUid!, 'accepted');
    if (!mounted) return;
    setState(() {
      _state = _ReqState.accepted;
      _acceptedTime = DateTime.now();
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h시 $m분';
  }

  String get _reqTimeText {
    final ts = _req?['timestamp'];
    if (ts == null) return '';
    try {
      return _formatTime((ts as Timestamp).toDate().toLocal());
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.childColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.directions_car_rounded, size: 28),
            SizedBox(width: 10),
            Text('안심 귀가',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SafeArea(
        child: switch (_state) {
          _ReqState.waiting  => _buildWaiting(),
          _ReqState.pending  => _buildPending(),
          _ReqState.accepted => _buildAccepted(),
        },
      ),
    );
  }

  // ─── 대기 화면 ──────────────────────────────────────────────────
  Widget _buildWaiting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 28),
            Text(
              '부모님을 기다리는 중',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '부모님이 버튼을 누르시면\n바로 알려드립니다.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 새 요청 화면 ───────────────────────────────────────────────
  Widget _buildPending() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 새 요청 배너
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B), width: 2),
            ),
            child: const Row(
              children: [
                Text('🔔', style: TextStyle(fontSize: 40)),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '새 요청이\n도착했습니다!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 위치 정보 카드
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 12,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppTheme.childColor, size: 28),
                    const SizedBox(width: 8),
                    Text('부모님 현재 위치',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const Divider(height: 24),
                if (_loadingAddr)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Text(
                    _address ?? '주소를 불러오는 중...',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.6,
                    ),
                  ),
                if (_reqTimeText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 18, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text('요청 시각: $_reqTimeText',
                          style: const TextStyle(
                              fontSize: 18, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 카카오맵 버튼
          _ActionBtn(
            label: '카카오맵으로 보기',
            icon: Icons.map_rounded,
            bg: const Color(0xFFFFE812),
            fg: const Color(0xFF3C1E1E),
            onTap: _openKakaoMap,
          ),
          const SizedBox(height: 10),

          // 주소 복사 버튼
          _ActionBtn(
            label: '주소 복사하기',
            icon: Icons.copy_rounded,
            bg: const Color(0xFFF1F5F9),
            fg: const Color(0xFF334155),
            onTap: _copyAddress,
          ),
          const SizedBox(height: 24),

          // 처리 완료 버튼
          SizedBox(
            height: 76,
            child: ElevatedButton.icon(
              onPressed: _markAccepted,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 4,
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 32),
              label: const Text('처리 완료',
                  style:
                      TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 처리 완료 화면 ─────────────────────────────────────────────
  Widget _buildAccepted() {
    final time =
        _acceptedTime != null ? _formatTime(_acceptedTime!) : '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 100, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              '처리 완료!',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: Colors.green.shade700),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '오늘 $time에 확인했습니다',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: const Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _state = _ReqState.waiting;
                  _req = null;
                  _address = null;
                  _acceptedTime = null;
                }),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.childColor, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('대기 화면으로',
                    style:
                        TextStyle(fontSize: 22, color: AppTheme.childColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 액션 버튼 공용 위젯 ────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 68,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade200)),
        ),
        icon: Icon(icon, size: 28),
        label: Text(label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
