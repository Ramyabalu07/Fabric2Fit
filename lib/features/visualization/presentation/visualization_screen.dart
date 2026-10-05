import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../designs/presentation/design_providers.dart';
import '../../fabric/domain/fabric_analysis.dart';
import '../../fabric/presentation/fabric_providers.dart';
import '../../favorites/domain/saved_look.dart';
import '../../favorites/presentation/favorites_providers.dart';
import 'garment_painter.dart';

/// Applies the user's fabric to a design. Opens either with the current
/// fabric session or with a saved look ([lookId]).
class VisualizationScreen extends ConsumerStatefulWidget {
  const VisualizationScreen({super.key, required this.designId, this.lookId});
  final String designId;
  final String? lookId;

  @override
  ConsumerState<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends ConsumerState<VisualizationScreen> {
  double _scale = 1;
  double _rotation = 0;
  bool _shading = true;
  bool _compare = false;
  bool _saving = false;
  String? _savedId;
  bool _initialisedFromLook = false;

  SavedLook? _look(List<SavedLook>? looks) =>
      widget.lookId == null ? null : looks?.where((l) => l.id == widget.lookId).firstOrNull;

  Future<void> _save(FabricPhoto photo, FabricAnalysis analysis) async {
    final design = await ref.read(designByIdProvider(widget.designId).future);
    if (design == null) return;
    setState(() => _saving = true);
    try {
      final saved = await ref.read(favoritesProvider.notifier).saveLook(
            design: design,
            fabricBytes: photo.bytes,
            analysis: analysis,
            scale: _scale,
            rotation: _rotation,
          );
      if (!mounted) return;
      setState(() => _savedId = saved.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Look saved to Favorites'),
          action: SnackBarAction(label: 'View', onPressed: () => context.go(AppRoutes.favorites)),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final designAsync = ref.watch(designByIdProvider(widget.designId));
    final looks = ref.watch(favoritesProvider).value;
    final look = _look(looks);
    final session = ref.watch(fabricSessionProvider);

    if (look != null && !_initialisedFromLook) {
      _initialisedFromLook = true;
      _scale = look.patternScale;
      _rotation = look.patternRotation;
      _savedId = look.id;
    }

    final photo = look != null ? FabricPhoto(bytes: look.fabricBytes, label: look.designName) : session?.photo;
    final analysis = look?.analysis ?? session?.analysis;

    return Scaffold(
      appBar: AppBar(title: const Text('Your fabric, visualised')),
      body: designAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (design) {
          if (design == null) {
            return const EmptyState(icon: Icons.help_outline, title: 'Design not found', message: '');
          }
          if (photo == null || analysis == null) {
            return EmptyState(
              icon: Icons.texture_rounded,
              title: 'Add a fabric first',
              message: 'Upload your fabric to see it on ${design.name}.',
              actionLabel: 'Upload fabric',
              onAction: () => context.push(AppRoutes.upload),
            );
          }
          final preview = Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: AppColors.softShadow,
            ),
            padding: const EdgeInsets.all(20),
            child: _compare
                ? Row(
                    children: [
                      Expanded(child: _labelled('Original', GarmentView(design: design))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _labelled(
                          'Your fabric',
                          GarmentView(
                            design: design,
                            fabricBytes: photo.bytes,
                            patternScale: _scale,
                            patternRotation: _rotation,
                            showShading: _shading,
                          ),
                        ),
                      ),
                    ],
                  )
                : GarmentView(
                    design: design,
                    fabricBytes: photo.bytes,
                    patternScale: _scale,
                    patternRotation: _rotation,
                    showShading: _shading,
                  ),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
            children: [
              SizedBox(height: 420, child: preview),
              const SizedBox(height: 16),
              Row(
                children: [
                  FabricThumb(photo.bytes, size: 44, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(design.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${analysis.fabricType.label} · ${analysis.pattern.label}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Compare with original',
                    isSelected: _compare,
                    onPressed: () => setState(() => _compare = !_compare),
                    icon: const Icon(Icons.compare_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Print size', style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('${(_scale * 100).round()}%', style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                    Slider(
                      value: _scale,
                      min: 0.4,
                      max: 2.5,
                      onChanged: (v) => setState(() {
                        _scale = v;
                        _savedId = null;
                      }),
                    ),
                    const Text('Print direction', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    SegmentedButton<double>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Straight')),
                        ButtonSegment(value: 45, label: Text('Bias 45°')),
                        ButtonSegment(value: 90, label: Text('Cross')),
                      ],
                      selected: {_rotation},
                      onSelectionChanged: (s) => setState(() {
                        _rotation = s.first;
                        _savedId = null;
                      }),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Drape shading', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Adds folds and depth', style: TextStyle(fontSize: 12)),
                      value: _shading,
                      onChanged: (v) => setState(() => _shading = v),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: photo == null || analysis == null
          ? null
          : Container(
              color: AppColors.cream,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
                      child: const Text('Try another'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving || _savedId != null ? null : () => _save(photo, analysis),
                      icon: _saving
                          ? const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : Icon(_savedId != null ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                      label: Text(_savedId != null ? 'Saved' : 'Save look'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _labelled(String label, Widget child) => Column(
        children: [
          Expanded(child: child),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      );
}
