import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/role_selection_screen.dart';
import 'screens/parent/parent_code_screen.dart';
import 'screens/parent/parent_home_screen.dart';
import 'screens/child/child_link_screen.dart';
import 'screens/child/child_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final String? role = prefs.getString('role');
  final bool isLinked = prefs.getBool('isLinked') ?? false;

  Widget initialScreen;
  if (role == null) {
    initialScreen = const RoleSelectionScreen();
  } else if (role == 'parent' && isLinked) {
    initialScreen = const ParentHomeScreen();
  } else if (role == 'parent') {
    initialScreen = const ParentCodeScreen();
  } else if (role == 'child' && isLinked) {
    initialScreen = const ChildHomeScreen();
  } else {
    initialScreen = const ChildLinkScreen();
  }

  runApp(BridgeApp(initialScreen: initialScreen));
}

class BridgeApp extends StatelessWidget {
  final Widget initialScreen;

  const BridgeApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '안심 귀가',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: initialScreen,
    );
  }
}
