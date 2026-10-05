import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../designs/presentation/design_providers.dart';
import '../../visualization/presentation/garment_painter.dart';
import '../domain/saved_look.dart';
import 'favorites_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final looks = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'), automaticallyImplyLeading: false),
      body: looks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load favorites: $e')),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'No saved looks yet',
                message: 'Visualise your fabric on a design and tap “Save look” to keep it here.',
                actionLabel: 'Upload fabric',
                onAction: () => context.push(AppRoutes.upload),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: list.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.66,
                ),
                itemBuilder: (context, i) => _LookCard(look: list[i]),
              ),
      ),
    );
  }
}

class _LookCard extends ConsumerWidget {
  const _LookCard({required this.look});
  final SavedLook look;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designByIdProvider(look.designId)).value;
    final d = look.createdAt;
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push(AppRoutes.visualize(look.designId, lookId: look.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  if (design != null)
                    Positioned.fill(
                      child: GarmentView(
                        design: design,
                        fabricBytes: look.fabricBytes,
                        patternScale: look.patternScale,
                        patternRotation: look.patternRotation,
                      ),
                    ),
                  Positioned(left: 0, bottom: 0, child: FabricThumb(look.fabricBytes, size: 34, radius: 10)),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted, size: 20),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Remove this look?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              FilledButton(
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (ok ?? false) await ref.read(favoritesProvider.notifier).remove(look.id);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(look.designName,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('${look.analysis.fabricType.label} · ${d.day}/${d.month}/${d.year}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
