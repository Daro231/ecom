import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../network/api_exception.dart';

/// Skeleton block used by shimmer placeholders.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class Shimmered extends StatelessWidget {
  const Shimmered({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF1B2F4F) : const Color(0xFFE3E6EC),
      highlightColor: dark ? const Color(0xFF2A4470) : const Color(0xFFF5F6F9),
      child: child,
    );
  }
}

/// Vertical list of card-shaped skeletons.
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.count = 6, this.itemHeight = 92});
  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => Shimmered(
    child: ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => SkeletonBox(height: itemHeight, radius: 14),
    ),
  );
}

class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) => Shimmered(
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const SkeletonBox(radius: 14, height: 200),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: t.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: t.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: t.textTheme.bodyMedium?.copyWith(
                  color: t.colorScheme.outline,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Friendly error with Retry; connectivity problems get their own wording.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final conn =
        error is ApiException && (error as ApiException).isConnectivity;
    return EmptyState(
      icon: conn ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      title: conn ? 'You seem to be offline' : 'Something went wrong',
      message: errorMessage(error),
      actionLabel: onRetry == null ? null : 'Retry',
      onAction: onRetry,
    );
  }
}

/// Renders an [AsyncValue] with shimmer / error+retry / data.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: true,
      skipError: false,
      data: data,
      loading: () => loading ?? const ShimmerList(),
      error: (e, _) => ErrorState(error: e, onRetry: onRetry),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

void showError(BuildContext context, Object error) =>
    showSnack(context, errorMessage(error), error: true);
