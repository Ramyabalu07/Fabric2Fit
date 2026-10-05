import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../designs/domain/garment_design.dart';
import '../../designs/presentation/design_providers.dart';
import '../../fabric/domain/fabric_attributes.dart';
import '../../favorites/presentation/favorites_providers.dart';
import '../../profile/presentation/auth_providers.dart';
import '../../visualization/presentation/garment_painter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Occasion? _occasion;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final designs = ref.watch(designsProvider);
    final looks = ref.watch(favoritesProvider).value ?? const [];
    final name = user?.displayName ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                const BrandMark(size: 22),
                const Spacer(),
                CircleAvatar(
                  backgroundColor: AppColors.lavenderSoft,
                  child: Text(name.characters.first.toUpperCase(),
                      style: const TextStyle(color: AppColors.deepPurple, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Hi, $name', style: const TextStyle(color: AppColors.muted, fontSize: 15)),
            const SizedBox(height: 4),
            Text('What will you create today?', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            _HeroCard(onTap: () => context.push(AppRoutes.upload)),
            const SizedBox(height: 28),
            const SectionHeader('How it works'),
            const _StepsRow(),
            const SizedBox(height: 28),
            if (looks.isNotEmpty) ...[
              SectionHeader('Your saved looks',
                  actionLabel: 'See all', onAction: () => context.go(AppRoutes.favorites)),
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: looks.length.clamp(0, 8),
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final look = looks[i];
                    final design = designs.value?.where((d) => d.id == look.designId).firstOrNull;
                    if (design == null) return const SizedBox.shrink();
                    return SizedBox(
                      width: 120,
                      child: AppCard(
                        padding: const EdgeInsets.all(8),
                        onTap: () => context.push(AppRoutes.visualize(design.id, lookId: look.id)),
                        child: GarmentView(
                          design: design,
                          fabricBytes: look.fabricBytes,
                          patternScale: look.patternScale,
                          patternRotation: look.patternRotation,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],
            const SectionHeader('Explore designs'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _occasionChip(null, 'All'),
                  for (final o in Occasion.values) _occasionChip(o, o.label),
                ],
              ),
            ),
            const SizedBox(height: 14),
            designs.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Could not load designs: $e'),
              data: (all) {
                final list = _curate(all);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, i) => DesignTile(design: list[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// One design per silhouette for variety, filtered by occasion.
  List<GarmentDesign> _curate(List<GarmentDesign> all) {
    final filtered = all.where((d) => _occasion == null || d.occasions.contains(_occasion)).toList();
    final seen = <GarmentSilhouette>{};
    final picks = <GarmentDesign>[];
    for (final d in filtered) {
      if (seen.add(d.silhouette)) picks.add(d);
    }
    for (final d in filtered) {
      if (picks.length >= 8) break;
      if (!picks.contains(d)) picks.add(d);
    }
    return picks.take(8).toList();
  }

  Widget _occasionChip(Occasion? o, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _occasion == o,
          showCheckmark: false,
          onSelected: (_) => setState(() => _occasion = o),
        ),
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.softShadow,
        ),
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppConfig.tagline,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.white, fontSize: 21, height: 1.3)),
                  const SizedBox(height: 10),
                  Text('Upload your unstitched fabric and discover designs made for it.',
                      style: TextStyle(color: AppColors.cream.withValues(alpha: 0.9), height: 1.4, fontSize: 13)),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.deepPurple,
                      minimumSize: const Size(0, 46),
                    ),
                    icon: const Icon(Icons.add_a_photo_rounded, size: 20),
                    label: const Text('Upload fabric'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.checkroom_rounded, size: 88, color: AppColors.white.withValues(alpha: 0.85)),
          ],
        ),
      );
}

class _StepsRow extends StatelessWidget {
  const _StepsRow();

  static const _steps = [
    (Icons.photo_camera_outlined, 'Upload'),
    (Icons.insights_rounded, 'Analyse'),
    (Icons.style_outlined, 'Match'),
    (Icons.visibility_outlined, 'Preview'),
    (Icons.favorite_border_rounded, 'Save'),
  ];

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final (icon, label) in _steps)
            Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Icon(icon, color: AppColors.deepPurple),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
        ],
      );
}

/// Design card used on Home and Recommendations.
class DesignTile extends StatelessWidget {
  const DesignTile({super.key, required this.design, this.fabricBytes, this.score, this.subtitle});
  final GarmentDesign design;
  final List<int>? fabricBytes;
  final int? score;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push(AppRoutes.design(design.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Positioned.fill(child: GarmentView(design: design, fabricBytes: fabricBytes)),
                    if (score != null) Positioned(top: 0, right: 0, child: MatchBadge(score!)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(design.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle ?? '${design.category.label} · ${design.difficulty.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      );
}
