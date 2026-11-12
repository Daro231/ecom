import '../../../../core/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/models/catalog_models.dart';
import '../providers/product_providers.dart';
import '../widgets/review_dialog.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  bool _adding = false;

  Future<void> _add(Product p) async {
    setState(() => _adding = true);
    try {
      await ref.read(cartProvider.notifier).add(p.id, _qty);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $_qty × ${p.name} to cart'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => context.go('/cart'),
          ),
        ),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(productDetailProvider(widget.productId));
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: AsyncView<Product>(
        value: value,
        onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        data: (p) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productDetailProvider(widget.productId));
            ref.invalidate(reviewsProvider(widget.productId));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _Gallery(
                images: p.images,
                category: p.category?.name,
                brand: p.brand?.name,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        if (p.brand != null)
                          Chip(
                            label: Text(p.brand!.name),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (p.category != null)
                          Chip(
                            label: Text(p.category!.name),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    Text(
                      p.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingStars(rating: p.averageRating),
                        const SizedBox(width: 6),
                        Text(
                          '${p.averageRating.toStringAsFixed(1)} · ${p.reviewCount} review${p.reviewCount == 1 ? '' : 's'}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        PriceText(
                          p.price,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        _StockBadge(p),
                      ],
                    ),
                    if (p.description != null && p.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(p.description!),
                    ],
                    const SizedBox(height: 20),
                    _SpecTable(p),
                    const SizedBox(height: 20),
                    if (p.inStock)
                      Row(
                        children: [
                          const Text('Quantity'),
                          const Spacer(),
                          _Stepper(
                            value: _qty,
                            max: p.stockQuantity,
                            onChanged: (v) => setState(() => _qty = v),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('add_to_cart'),
                      onPressed: (!p.inStock || _adding) ? null : () => _add(p),
                      icon: _adding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(p.inStock ? 'Add to cart' : 'Out of stock'),
                    ),
                  ],
                ),
              ),
              _ReviewsSection(product: p),
            ],
          ),
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images, this.category, this.brand});
  final List<String> images;
  final String? category;
  final String? brand;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images.isEmpty ? <String?>[null] : widget.images;
    return Column(
      children: [
        // Capped so the gallery does not fill a whole desktop browser window.
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: PageView.builder(
                itemCount: imgs.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) => ProductImage(
                  url: imgs[i],
                  radius: 0,
                  fit: BoxFit.contain,
                  category: widget.category,
                  brand: widget.brand,
                ),
              ),
            ),
          ),
        ),
        if (imgs.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < imgs.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _i ? AppColors.accent : Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge(this.p);
  final Product p;

  @override
  Widget build(BuildContext context) {
    final (label, color) = !p.inStock
        ? ('Out of stock', AppColors.danger)
        : p.lowStock
        ? ('Only ${p.stockQuantity} left', AppColors.warning)
        : ('In stock', AppColors.success);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SpecTable extends StatelessWidget {
  const _SpecTable(this.p);
  final Product p;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('CPU', p.cpu),
      ('RAM', p.ram == null ? null : '${p.ram} GB'),
      ('Storage', p.storage),
      ('GPU', p.gpu),
      ('Screen', p.screenSize == null ? null : '${p.screenSize} inch'),
      ('OS', p.os),
      (
        'Warranty',
        p.warrantyMonths == null ? null : '${p.warrantyMonths} months',
      ),
    ].where((r) => r.$2 != null && r.$2!.isNotEmpty).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specifications',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Container(
                  color: i.isEven
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          rows[i].$1,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rows[i].$2!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.outlined(
        onPressed: value > 1 ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove),
        tooltip: 'Decrease',
      ),
      SizedBox(
        width: 44,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      IconButton.outlined(
        onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add),
        tooltip: 'Increase',
      ),
    ],
  );
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(reviewsProvider(product.id));
    final canReview = ref.watch(canReviewProvider(product.id)).value ?? false;
    final myId = ref.watch(authControllerProvider).user?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reviews (${product.reviewCount})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          reviews.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorStateInline(
              error: e,
              onRetry: () => ref.invalidate(reviewsProvider(product.id)),
            ),
            data: (page) {
              final mine = page.content
                  .where((r) => r.userId == myId)
                  .firstOrNull;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canReview && mine == null)
                    OutlinedButton.icon(
                      key: const Key('write_review'),
                      onPressed: () => showReviewDialog(
                        context,
                        ref,
                        productId: product.id,
                        productName: product.name,
                      ),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Write a review'),
                    ),
                  if (page.content.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No reviews yet.'),
                    ),
                  for (final r in page.content)
                    _ReviewTile(
                      review: r,
                      onEdit: r.userId == myId
                          ? () => showReviewDialog(
                              context,
                              ref,
                              productId: product.id,
                              productName: product.name,
                              existing: r,
                            )
                          : null,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ErrorStateInline extends StatelessWidget {
  const ErrorStateInline({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(errorMessage(error))),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ],
  );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, this.onEdit});
  final Review review;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 10),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName ?? 'Customer',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (review.verifiedPurchase)
                const Tooltip(
                  message: 'Verified purchase',
                  child: Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit review',
                ),
            ],
          ),
          Row(
            children: [
              RatingStars(rating: review.rating.toDouble(), size: 15),
              const SizedBox(width: 8),
              Text(
                formatDate(review.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          if ((review.comment ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment!),
          ],
        ],
      ),
    ),
  );
}
