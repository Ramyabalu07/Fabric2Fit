import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../data/fabric_image_prep.dart';
import '../data/sample_fabrics.dart';
import '../domain/fabric_analysis.dart';
import 'fabric_providers.dart';

class UploadFabricScreen extends ConsumerStatefulWidget {
  const UploadFabricScreen({super.key});

  @override
  ConsumerState<UploadFabricScreen> createState() => _UploadFabricScreenState();
}

class _UploadFabricScreenState extends ConsumerState<UploadFabricScreen> {
  bool _busy = false;
  late final List<(String, Uint8List)> _samples = [for (final s in sampleFabrics) (s.name, s.encode())];

  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 92);
      if (file == null) return;
      final bytes = await prepareFabricImage(await file.readAsBytes());
      await _useFabric(FabricPhoto(bytes: bytes, label: file.name));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open the photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _useFabric(FabricPhoto photo) async {
    ref.read(fabricSessionProvider.notifier).setPhoto(photo);
    if (mounted) context.push(AppRoutes.analysis);
  }

  @override
  Widget build(BuildContext context) {
    final cameraAvailable = !kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    return Scaffold(
      appBar: AppBar(title: const Text('Add your fabric')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            onTap: _busy ? null : () => _pick(ImageSource.gallery),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(color: AppColors.lavenderSoft, shape: BoxShape.circle),
                  child: _busy
                      ? const SizedBox(width: 44, height: 44, child: CircularProgressIndicator(strokeWidth: 3))
                      : const Icon(Icons.cloud_upload_outlined, size: 44, color: AppColors.deepPurple),
                ),
                const SizedBox(height: 18),
                Text('Upload a fabric photo', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('JPG or PNG · we\'ll analyse it on your device',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (cameraAvailable) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Take photo'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionHeader('Or try a sample fabric'),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _samples.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final (name, bytes) = _samples[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _useFabric(FabricPhoto(bytes: bytes, label: name)),
                  child: SizedBox(
                    width: 92,
                    child: Column(
                      children: [
                        FabricThumb(bytes, size: 92, radius: 18),
                        const SizedBox(height: 6),
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Tips for the best results'),
          for (final (icon, tip) in const [
            (Icons.wb_sunny_outlined, 'Use natural daylight, avoid harsh shadows'),
            (Icons.crop_free_rounded, 'Lay the fabric flat and fill the frame'),
            (Icons.pattern_rounded, 'Include at least one full repeat of the print'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.rose, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
