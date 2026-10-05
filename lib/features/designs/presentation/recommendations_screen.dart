import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../fabric/domain/fabric_attributes.dart';
import '../../fabric/presentation/fabric_providers.dart';
import '../../home/presentation/home_screen.dart';
import 'design_providers.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(fabricSessionProvider);
    final filter = ref.watch(recommendationFilterProvider);
    final matches = ref.watch(recommendationsProvider);
    final filterNotifier = ref.read(recommendationFilterProvider.notifier);
    final analysis = session?.analysis;

    if (session == null || analysis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Designs for you')),
        body: EmptyState(
          icon: Icons.style_outlined,
          title: 'Start with your fabric',
          message: 'Upload a fabric and we\'ll recommend designs that suit it.',
          actionLabel: 'Upload fabric',
          onAction: () => context.pushReplacement(AppRoutes.upload),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Designs for you')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverToBoxAdapter(
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    FabricThumb(session.photo.bytes, size: 64),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.photo.label ?? 'Your fabric',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('${analysis.fabricType.label} · ${analysis.pattern.label} · ${analysis.colorFamily.label}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          PaletteRow(analysis.palette, size: 16),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit analysis',
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.tune_rounded, color: AppColors.deepPurple),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                children: [
                  _chip('All occasions', filter.occasion == null, () => filterNotifier.setOccasion(null)),
                  for (final o in Occasion.values)
                    _chip(o.label, filter.occasion == o, () => filterNotifier.setOccasion(filter.occasion == o ? null : o)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                children: [
                  _chip('All styles', filter.category == null, () => filterNotifier.setCategory(null)),
                  for (final c in GarmentCategory.values)
                    _chip(c.label, filter.category == c,
                        () => filterNotifier.setCategory(filter.category == c ? null : c)),
                ],
              ),
            ),
          ),
          ...matches.when(
            loading: () => [
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            ],
            error: (e, _) => [SliverToBoxAdapter(child: Text('Error: $e'))],
            data: (list) => list.isEmpty
                ? [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matches with these filters',
                        message: 'Try another occasion or category.',
                      ),
                    ),
                  ]
                : [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      sliver: SliverToBoxAdapter(
                        child: Text('${list.length} designs match your fabric',
                            style: const TextStyle(color: AppColors.muted)),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      sliver: SliverGrid.builder(
                        itemCount: list.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                        itemBuilder: (context, i) {
                          final m = list[i];
                          return DesignTile(
                            design: m.design,
                            fabricBytes: session.photo.bytes,
                            score: m.score,
                            subtitle: m.reasons.isEmpty ? null : m.reasons.first,
                          );
                        },
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: selected, showCheckmark: false, onSelected: (_) => onTap()),
      );
}
