import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/app_shell.dart';

class SarprasGoApp extends StatefulWidget {
  const SarprasGoApp({super.key});

  @override
  State<SarprasGoApp> createState() => _SarprasGoAppState();
}

class _SarprasGoAppState extends State<SarprasGoApp> {
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthController(AuthRepository());
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SarprasGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: AnimatedBuilder(
          animation: _auth,
          builder: (context, _) => _auth.user == null
              ? LoginPage(controller: _auth)
              : AppShell(controller: _auth),
        ),
      );
}
