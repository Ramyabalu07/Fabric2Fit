import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_fabric_analyzer.dart';
import '../domain/fabric_analysis.dart';

final fabricAnalyzerProvider = Provider<FabricAnalyzer>((ref) => const LocalFabricAnalyzer());

class FabricSession {
  const FabricSession({required this.photo, this.analysis, this.error});
  final FabricPhoto photo;
  final FabricAnalysis? analysis;
  final Object? error;

  bool get isAnalyzing => analysis == null && error == null;
}

/// The fabric the user is currently working with.
class FabricSessionNotifier extends Notifier<FabricSession?> {
  @override
  FabricSession? build() => null;

  Future<void> setPhoto(FabricPhoto photo) async {
    state = FabricSession(photo: photo);
    try {
      final analysis = await ref.read(fabricAnalyzerProvider).analyze(photo.bytes);
      if (state?.photo == photo) state = FabricSession(photo: photo, analysis: analysis);
    } catch (e) {
      if (state?.photo == photo) state = FabricSession(photo: photo, error: e);
    }
  }

  void restore(FabricPhoto photo, FabricAnalysis analysis) =>
      state = FabricSession(photo: photo, analysis: analysis);

  void updateAnalysis(FabricAnalysis analysis) {
    final s = state;
    if (s != null) state = FabricSession(photo: s.photo, analysis: analysis);
  }

  void clear() => state = null;
}

final fabricSessionProvider = NotifierProvider<FabricSessionNotifier, FabricSession?>(FabricSessionNotifier.new);
