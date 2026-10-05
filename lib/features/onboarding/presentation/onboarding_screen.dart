import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../profile/presentation/auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      Icons.photo_camera_rounded,
      'Capture your fabric',
      'Snap or upload a photo of your unstitched fabric. We read its colours, pattern and texture.',
      AppColors.lavenderSoft,
    ),
    (
      Icons.auto_awesome_rounded,
      'Discover perfect designs',
      'Get garment designs matched to your fabric, occasion and style — from kurtis to gowns.',
      AppColors.roseSoft,
    ),
    (
      Icons.checkroom_rounded,
      'See it before you stitch',
      'Preview your actual fabric on the design you love, then save the look for your tailor.',
      Color(0xFFF3EEE8),
    ),
  ];

  Future<void> _finish() async {
    await ref.read(sharedPreferencesProvider).setBool(onboardingSeenKey, true);
    final auth = ref.read(authRepositoryProvider);
    if (auth.currentUser == null) {
      try {
        await auth.continueAsGuest();
      } catch (_) {
        // Guest sign-in can be retried from Profile.
      }
    }
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  const BrandMark(size: 20),
                  const Spacer(),
                  if (!last) TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final (icon, title, body, bg) = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(120)),
                          child: Icon(icon, size: 96, color: AppColors.deepPurple),
                        ),
                        const SizedBox(height: 40),
                        Text(title,
                            style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        Text(body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.muted, height: 1.6, fontSize: 15)),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.deepPurple : AppColors.lavender,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: last
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
                child: Text(last ? 'Get started' : 'Next'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
