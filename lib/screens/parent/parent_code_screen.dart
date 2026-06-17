import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'parent_home_screen.dart';

class ParentCodeScreen extends StatefulWidget {
  const ParentCodeScreen({super.key});

  @override
  State<ParentCodeScreen> createState() => _ParentCodeScreenState();
}

class _ParentCodeScreenState extends State<ParentCodeScreen> {
  String? _code;
  bool _isLoading = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initCode();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initCode() async {
    final service = FirestoreService();
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('linkCode');

    if (code == null) {
      final uid = await service.signInAnonymously();
      code = await service.generateUniqueCode();
      await service.createParentCode(uid, code);
      await prefs.setString('linkCode', code);
    }

    if (!mounted) return;
    setState(() {
      _code = code;
      _isLoading = false;
    });

    _subscription = service.listenToLinkingCode(code).listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null || data['isLinked'] != true) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLinked', true);
      await prefs.setString('linkedWithUid', (data['childUid'] ?? '') as String);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ParentHomeScreen()),
        );
      }
    });
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('코드가 복사되었습니다!', style: TextStyle(fontSize: 18)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatCode(String code) =>
      '${code.substring(0, 3)} ${code.substring(3)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연결 코드',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.parentColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.link_rounded,
                        size: 72, color: AppTheme.parentColor),
                    const SizedBox(height: 20),
                    Text(
                      '자녀에게 이 코드를\n알려주세요',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppTheme.parentColor, width: 3),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatCode(_code!),
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: AppTheme.parentColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _copyCode,
                            icon: const Icon(Icons.copy_rounded, size: 26),
                            label: const Text('코드 복사',
                                style: TextStyle(fontSize: 20)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '자녀 연결을 기다리는 중...',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
