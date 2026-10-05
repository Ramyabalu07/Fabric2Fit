import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../fabric/domain/fabric_attributes.dart';
import '../../fabric/presentation/fabric_providers.dart';
import '../data/firestore_design_repository.dart';
import '../data/local_design_repository.dart';
import '../domain/garment_design.dart';
import '../domain/recommendation_engine.dart';

final designRepositoryProvider = Provider<DesignRepository>((ref) {
  if (AppConfig.useFirebase) return FirestoreDesignRepository(FirebaseFirestore.instance);
  return LocalDesignRepository();
});

final designsProvider = FutureProvider<List<GarmentDesign>>(
  (ref) => ref.watch(designRepositoryProvider).fetchAll(),
);

final designByIdProvider = FutureProvider.family<GarmentDesign?, String>(
  (ref, id) => ref.watch(designRepositoryProvider).byId(id),
);

final recommendationEngineProvider = Provider((ref) => const RecommendationEngine());

class RecommendationFilter {
  const RecommendationFilter({this.occasion, this.category});
  final Occasion? occasion;
  final GarmentCategory? category;
}

class RecommendationFilterNotifier extends Notifier<RecommendationFilter> {
  @override
  RecommendationFilter build() => const RecommendationFilter();

  void setOccasion(Occasion? o) => state = RecommendationFilter(occasion: o, category: state.category);
  void setCategory(GarmentCategory? c) => state = RecommendationFilter(occasion: state.occasion, category: c);
}

final recommendationFilterProvider =
    NotifierProvider<RecommendationFilterNotifier, RecommendationFilter>(RecommendationFilterNotifier.new);

final recommendationsProvider = FutureProvider<List<DesignMatch>>((ref) async {
  final analysis = ref.watch(fabricSessionProvider.select((s) => s?.analysis));
  if (analysis == null) return const [];
  final designs = await ref.watch(designsProvider.future);
  final filter = ref.watch(recommendationFilterProvider);
  return ref.watch(recommendationEngineProvider).recommend(
        analysis,
        designs,
        occasion: filter.occasion,
        category: filter.category,
      );
});

/// Match details for one design against the current fabric (null if no fabric).
final matchForDesignProvider = FutureProvider.family<DesignMatch?, String>((ref, id) async {
  final analysis = ref.watch(fabricSessionProvider.select((s) => s?.analysis));
  if (analysis == null) return null;
  final design = await ref.watch(designByIdProvider(id).future);
  if (design == null) return null;
  return ref.watch(recommendationEngineProvider).score(analysis, design);
});
