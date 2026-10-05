import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final seen = ref.read(sharedPreferencesProvider).getBool(onboardingSeenKey) ?? false;
      context.go(seen ? AppRoutes.home : AppRoutes.onboarding);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: Center(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandMark(size: 40, light: true),
                    const SizedBox(height: 16),
                    Text(
                      AppConfig.tagline,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.cream,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
