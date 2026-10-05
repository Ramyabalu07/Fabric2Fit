import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../fabric/presentation/fabric_providers.dart';
import '../../visualization/presentation/garment_painter.dart';
import 'design_providers.dart';

class DesignDetailsScreen extends ConsumerStatefulWidget {
  const DesignDetailsScreen({super.key, required this.designId});
  final String designId;

  @override
  ConsumerState<DesignDetailsScreen> createState() => _DesignDetailsScreenState();
}

class _DesignDetailsScreenState extends ConsumerState<DesignDetailsScreen> {
  bool _withFabric = true;

  @override
  Widget build(BuildContext context) {
    final designAsync = ref.watch(designByIdProvider(widget.designId));
    final session = ref.watch(fabricSessionProvider);
    final match = ref.watch(matchForDesignProvider(widget.designId)).value;
    final hasFabric = session?.analysis != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Design details')),
      body: designAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (design) {
          if (design == null) {
            return const EmptyState(
                icon: Icons.help_outline, title: 'Design not found', message: 'It may have been removed.');
          }
          final t = Theme.of(context).textTheme;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            children: [
              Container(
                height: 380,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: AppColors.softShadow,
                ),
                padding: const EdgeInsets.all(24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GarmentView(
                        design: design,
                        fabricBytes: hasFabric && _withFabric ? session!.photo.bytes : null,
                      ),
                    ),
                    if (match != null) Positioned(top: 0, right: 0, child: MatchBadge(match.score)),
                  ],
                ),
              ),
              if (hasFabric) ...[
                const SizedBox(height: 12),
                Center(
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('Original'), icon: Icon(Icons.checkroom_outlined)),
                      ButtonSegment(value: true, label: Text('My fabric'), icon: Icon(Icons.texture_rounded)),
                    ],
                    selected: {_withFabric},
                    onSelectionChanged: (s) => setState(() => _withFabric = s.first),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text(design.name, style: t.headlineSmall),
              const SizedBox(height: 6),
              Text(design.description, style: const TextStyle(color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 18),
              Row(
                children: [
                  _Stat(Icons.category_outlined, 'Category', design.category.label),
                  _Stat(Icons.straighten_rounded, 'Fabric', '${design.fabricMeters.toStringAsFixed(1)} m'),
                  _Stat(Icons.content_cut_rounded, 'Stitching', design.difficulty.label),
                ],
              ),
              if (match != null && match.reasons.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader('Why it suits your fabric'),
                for (final r in match.reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.rose, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(r)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              const SectionHeader('Design features'),
              _ChipWrap(design.features),
              const SizedBox(height: 20),
              const SectionHeader('Best fabrics'),
              _ChipWrap(design.fabricTypes.map((e) => e.label).toList()),
              const SizedBox(height: 20),
              const SectionHeader('Occasions'),
              _ChipWrap(design.occasions.map((e) => e.label).toList()),
            ],
          );
        },
      ),
      bottomSheet: Container(
        color: AppColors.cream,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: FilledButton.icon(
          onPressed: () =>
              hasFabric ? context.push(AppRoutes.visualize(widget.designId)) : context.push(AppRoutes.upload),
          icon: Icon(hasFabric ? Icons.auto_fix_high_rounded : Icons.add_a_photo_rounded),
          label: Text(hasFabric ? 'Visualise with my fabric' : 'Add fabric to visualise'),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: AppColors.lavenderSoft, borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              Icon(icon, color: AppColors.deepPurple, size: 22),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
            ],
          ),
        ),
      );
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final i in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(i, style: const TextStyle(fontSize: 13)),
            ),
        ],
      );
}
