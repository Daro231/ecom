import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../data/models/catalog_models.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.horizontal = false,
  });

  final Product product;
  final VoidCallback onTap;

  /// List layout (image left) instead of grid layout (image on top).
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.brand != null)
          Text(
            product.brand!.name,
            style: t.textTheme.labelSmall?.copyWith(
              color: t.colorScheme.outline,
            ),
          ),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            RatingStars(rating: product.averageRating, size: 14),
            const SizedBox(width: 4),
            Text('(${product.reviewCount})', style: t.textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 4),
        PriceText(product.price),
        if (!product.inStock)
          Text(
            'Out of stock',
            style: t.textTheme.labelSmall?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          )
        else if (product.lowStock)
          Text(
            'Only ${product.stockQuantity} left',
            style: t.textTheme.labelSmall?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );

    final image = Stack(
      children: [
        Positioned.fill(
          child: ProductImage(
            url: product.firstImage,
            category: product.category?.name,
            brand: product.brand?.name,
          ),
        ),
        if (!product.inStock)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Colors.black38,
                child: Center(
                  child: Text(
                    'SOLD OUT',
                    style: t.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('product_card_${product.id}'),
        onTap: onTap,
        child: horizontal
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    SizedBox(width: 100, height: 100, child: image),
                    const SizedBox(width: 12),
                    Expanded(child: info),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(aspectRatio: 4 / 3, child: image),
                    const SizedBox(height: 8),
                    Expanded(child: info),
                  ],
                ),
              ),
      ),
    );
  }
}
