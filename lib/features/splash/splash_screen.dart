import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../shell/main_shell.dart';

/// Écran de démarrage : portrait en fond, monogramme BF, slogan, sports couverts.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _night = Color(0xFF050A1A);

  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2600), _goHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goHome() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondary) => const MainShell(),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _night,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goHome,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/splash/portrait.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.4),
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: _night),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 0.78, 1.0],
                  colors: [
                    Color(0x66050A1A),
                    Color(0x00050A1A),
                    Color(0xD9050A1A),
                    Color(0xF2050A1A),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image.asset(
                      'assets/splash/logo_bf.png',
                      width: 170,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(height: 170),
                    ),
                    const Text(
                      'BET-FOLDER',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Analyse · Probabilités · Discipline',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SportIcon(Icons.sports_soccer),
                        _SportIcon(Icons.sports_basketball),
                        _SportIcon(Icons.sports_tennis),
                        _SportIcon(Icons.sports_hockey),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppColors.accent,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppTexts.disclaimer,
                      textAlign: TextAlign.center,
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportIcon extends StatelessWidget {
  const _SportIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Icon(icon, size: 24, color: AppColors.textMuted),
    );
  }
}
