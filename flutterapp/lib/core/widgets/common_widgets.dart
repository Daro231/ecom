import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/env.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Centers [child] and limits its width so pages do not stretch across a wide
/// browser window (no effect on phones).
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 900});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Icon for a category name (Laptop, Desktop, Monitor, Component, Accessory).
IconData categoryIcon(String? category) {
  switch ((category ?? '').toLowerCase()) {
    case 'laptop':
      return Icons.laptop_mac_rounded;
    case 'desktop':
      return Icons.desktop_windows_rounded;
    case 'monitor':
      return Icons.monitor_rounded;
    case 'component':
      return Icons.memory_rounded;
    case 'accessory':
      return Icons.mouse_rounded;
    default:
      return Icons.computer_rounded;
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.radius = 12,
    this.width,
    this.height,
    this.category,
    this.brand,
  });

  final String? url;
  final BoxFit fit;
  final double radius;
  final double? width;
  final double? height;

  /// Used by the fallback shown when there is no image or it fails to load.
  final String? category;
  final String? brand;

  Widget _fallback(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.14),
            cs.surfaceContainerHighest,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final small = box.maxHeight < 90 || box.maxWidth < 90;
          final label = (brand ?? '').trim();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                categoryIcon(category),
                size: small ? 28 : 48,
                color: AppColors.accent,
              ),
              if (label.isNotEmpty && !small) ...[
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (u == null || u.isEmpty)
          ? _fallback(context)
          : CachedNetworkImage(
              imageUrl: Env.resolveImage(u),
              fit: fit,
              width: width,
              height: height,
              placeholder: (_, _) => Container(
                width: width,
                height: height,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              errorWidget: (ctx, _, _) => _fallback(ctx),
            ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final v = rating - i;
        return Icon(
          v >= 0.75
              ? Icons.star_rounded
              : v >= 0.25
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          size: size,
          color: const Color(0xFFF5A623),
        );
      }),
    );
  }
}

class PriceText extends StatelessWidget {
  const PriceText(this.value, {super.key, this.style});
  final num value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
    formatUsd(value),
    style:
        style ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.accent
              : AppColors.navy,
        ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  static Color colorFor(String s) {
    switch (s) {
      case 'DELIVERED':
      case 'PAID':
      case 'CONFIRMED':
        return AppColors.success;
      case 'CANCELLED':
      case 'FAILED':
        return AppColors.danger;
      case 'SHIPPED':
      case 'PROCESSING':
        return const Color(0xFF1570EF);
      case 'PAID_AFTER_CANCEL':
        return AppColors.warning;
      default:
        return const Color(0xFF667085);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        humanizeEnum(status),
        style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    ),
  );
}

/// Label / value row used in totals and detail cards.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(
    this.label,
    this.value, {
    super.key,
    this.bold = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: style)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: style?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
