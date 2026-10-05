import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../domain/fabric_analysis.dart';
import '../domain/fabric_attributes.dart';
import 'fabric_providers.dart';

class FabricAnalysisScreen extends ConsumerWidget {
  const FabricAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(fabricSessionProvider);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.texture_rounded,
          title: 'No fabric yet',
          message: 'Upload a fabric photo to start.',
          actionLabel: 'Upload fabric',
          onAction: () => context.pushReplacement(AppRoutes.upload),
        ),
      );
    }
    final analysis = session.analysis;
    final notifier = ref.read(fabricSessionProvider.notifier);
    void update(FabricAnalysis a) => notifier.updateAnalysis(a);

    return Scaffold(
      appBar: AppBar(title: const Text('Fabric analysis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(session.photo.bytes, fit: BoxFit.cover, gaplessPlayback: true),
                  if (session.isAnalyzing)
                    Container(
                      color: AppColors.charcoal.withValues(alpha: 0.35),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.white),
                            SizedBox(height: 12),
                            Text('Reading colours, pattern & texture…', style: TextStyle(color: AppColors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (session.error != null)
            Text('Analysis failed: ${session.error}', style: const TextStyle(color: Colors.red)),
          if (analysis != null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.rose, size: 20),
                      const SizedBox(width: 8),
                      Text('We detected', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PaletteRow(analysis.palette, size: 30),
                  const SizedBox(height: 12),
                  Text(
                    '${analysis.colorFamily.label} · ${analysis.pattern.label} · ${analysis.texture.label} '
                    '· likely ${analysis.fabricType.label}',
                    style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  const Text('Not quite right? Adjust anything below — matches update instantly.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _Section(
              'Fabric type',
              EnumChoiceChips<FabricType>(
                values: FabricType.values,
                selected: {analysis.fabricType},
                labelOf: (v) => v.label,
                onChanged: (s) => update(analysis.copyWith(fabricType: s.first)),
              ),
            ),
            _Section(
              'Pattern',
              EnumChoiceChips<FabricPattern>(
                values: FabricPattern.values,
                selected: {analysis.pattern},
                labelOf: (v) => v.label,
                onChanged: (s) => update(analysis.copyWith(pattern: s.first)),
              ),
            ),
            _Section(
              'Texture',
              EnumChoiceChips<FabricTexture>(
                values: FabricTexture.values,
                selected: {analysis.texture},
                labelOf: (v) => v.label,
                onChanged: (s) => update(analysis.copyWith(texture: s.first)),
              ),
            ),
            _Section(
              'Main colour',
              EnumChoiceChips<ColorFamily>(
                values: ColorFamily.values,
                selected: {analysis.colorFamily},
                labelOf: (v) => v.label,
                onChanged: (s) => update(analysis.copyWith(colorFamily: s.first)),
              ),
            ),
            _Section(
              'Occasion',
              EnumChoiceChips<Occasion>(
                values: Occasion.values,
                selected: analysis.occasions,
                multi: true,
                labelOf: (v) => v.label,
                onChanged: (s) => update(analysis.copyWith(occasions: s)),
              ),
            ),
            _Section(
              'Style',
              EnumChoiceChips<StyleTag>(
                values: StyleTag.values,
                selected: analysis.styles,
                multi: true,
                labelOf: (v) => v.label,
                onChanged: (s) => update(analysis.copyWith(styles: s)),
              ),
            ),
            _Section(
              'Garment category',
              EnumChoiceChips<GarmentCategory>(
                values: GarmentCategory.values,
                selected: {?analysis.category},
                allowEmpty: true,
                labelOf: (v) => v.label,
                onChanged: (s) => update(
                  s.isEmpty ? analysis.copyWith(clearCategory: true) : analysis.copyWith(category: s.first),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomSheet: analysis == null
          ? null
          : Container(
              color: AppColors.cream,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.recommendations),
                icon: const Icon(Icons.style_rounded),
                label: const Text('Find matching designs'),
              ),
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.child);
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}
