import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28, this.light = false});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? AppColors.white : AppColors.deepPurple;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 1.3,
          height: size * 1.3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: light ? AppColors.white.withValues(alpha: 0.18) : AppColors.lavenderSoft,
          ),
          child: Icon(Icons.checkroom_rounded, color: light ? AppColors.white : AppColors.deepPurple, size: size * 0.8),
        ),
        SizedBox(width: size * 0.35),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Fabric', style: TextStyle(color: color)),
            TextSpan(text: '2', style: TextStyle(color: light ? AppColors.cream : AppColors.rose)),
            TextSpan(text: 'Fit', style: TextStyle(color: color)),
          ]),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: size, height: 1),
        ),
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19))),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: AppColors.deepPurple),
                child: Text(actionLabel!),
              ),
          ],
        ),
      );
}

class PaletteRow extends StatelessWidget {
  const PaletteRow(this.colors, {super.key, this.size = 22});
  final List<int> colors;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in colors.take(5))
            Container(
              width: size,
              height: size,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
              ),
            ),
        ],
      );
}

/// Wrap of selectable chips backed by an enum.
class EnumChoiceChips<T extends Enum> extends StatelessWidget {
  const EnumChoiceChips({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.multi = false,
    this.allowEmpty = false,
  });

  final List<T> values;
  final Set<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<Set<T>> onChanged;
  final bool multi;
  final bool allowEmpty;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values)
            FilterChip(
              label: Text(labelOf(v)),
              selected: selected.contains(v),
              showCheckmark: multi,
              onSelected: (on) {
                if (multi) {
                  onChanged(on ? {...selected, v} : ({...selected}..remove(v)));
                } else if (on) {
                  onChanged({v});
                } else if (allowEmpty) {
                  onChanged({});
                }
              },
            ),
        ],
      );
}

class MatchBadge extends StatelessWidget {
  const MatchBadge(this.score, {super.key});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 75 ? AppColors.deepPurple : (score >= 55 ? const Color(0xFF8B74B8) : AppColors.rose);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text('$score% match',
          style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: AppColors.lavenderSoft, shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: AppColors.deepPurple),
              ),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.5)),
              if (actionLabel != null) ...[
                const SizedBox(height: 24),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}

class FabricThumb extends StatelessWidget {
  const FabricThumb(this.bytes, {super.key, this.size = 56, this.radius = 16});
  final List<int> bytes;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          bytes is Uint8List ? bytes as Uint8List : Uint8List.fromList(bytes),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
}
