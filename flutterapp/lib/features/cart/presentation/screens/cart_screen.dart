import '../../../../core/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/cart_models.dart';
import '../providers/cart_providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _coupon = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _applyCoupon() async {
    final code = _coupon.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _applying = true);
    try {
      await ref.read(cartRepositoryProvider).applyCoupon(code, 'STANDARD');
      ref.read(appliedCouponProvider.notifier).set(code);
      _coupon.clear();
      if (mounted) showSnack(context, 'Coupon $code applied');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My cart')),
      body: AsyncView<Cart>(
        value: cart,
        onRetry: () => ref.read(cartProvider.notifier).refresh(),
        data: (c) {
          if (c.items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Browse our computers and add something you like.',
              actionLabel: 'Start shopping',
              onAction: () => context.go('/home'),
            );
          }
          return ContentWidth(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.read(cartProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final item in c.items) ...[
                          _CartRow(
                            item: item,
                            onQty: (q) => _guard(
                              () => ref
                                  .read(cartProvider.notifier)
                                  .setQuantity(item.id, q),
                            ),
                            onRemove: () => _guard(
                              () => ref
                                  .read(cartProvider.notifier)
                                  .remove(item.id),
                            ),
                            onTap: () =>
                                context.push('/product/${item.productId}'),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 6),
                        _couponCard(context),
                      ],
                    ),
                  ),
                ),
                _summary(context, c),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _couponCard(BuildContext context) {
    final applied = ref.watch(appliedCouponProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: applied != null
            ? Row(
                children: [
                  const Icon(
                    Icons.local_offer_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coupon $applied applied',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: ref.read(appliedCouponProvider.notifier).clear,
                    child: const Text('Remove'),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('coupon_field'),
                      controller: _coupon,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Coupon code',
                        prefixIcon: Icon(Icons.local_offer_outlined),
                      ),
                      onSubmitted: (_) => _applyCoupon(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('apply_coupon'),
                    onPressed: _applying ? null : _applyCoupon,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(90, 50),
                    ),
                    child: _applying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Apply'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _summary(BuildContext context, Cart c) {
    final code = ref.watch(appliedCouponProvider);
    final preview = code == null
        ? null
        : ref.watch(couponPreviewProvider((code: code, shipping: 'STANDARD')));
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyValueRow(
                'Subtotal (${c.totalItems} item${c.totalItems == 1 ? '' : 's'})',
                formatUsd(c.subtotal),
              ),
              if (preview != null)
                preview.when(
                  data: (p) => Column(
                    children: [
                      KeyValueRow(
                        'Discount (${p.couponCode})',
                        '-${formatUsd(p.discount)}',
                        valueColor: AppColors.success,
                      ),
                      KeyValueRow(
                        'Shipping (Standard)',
                        formatUsd(p.shippingFee),
                      ),
                      KeyValueRow(
                        'Estimated total',
                        formatUsd(p.total),
                        bold: true,
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          errorMessage(e),
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      TextButton(
                        onPressed: ref
                            .read(appliedCouponProvider.notifier)
                            .clear,
                        child: const Text('Remove coupon'),
                      ),
                    ],
                  ),
                )
              else
                const KeyValueRow('Shipping', 'Calculated at checkout'),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('go_checkout'),
                onPressed: () => context.push('/checkout'),
                child: const Text('Proceed to checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onQty,
    required this.onRemove,
    required this.onTap,
  });
  final CartItem item;
  final ValueChanged<int> onQty;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('cart_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: ProductImage(url: item.imageUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatUsd(item.unitPrice),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Row(
                        children: [
                          IconButton(
                            key: Key('dec_${item.id}'),
                            visualDensity: VisualDensity.compact,
                            onPressed: item.quantity > 1
                                ? () => onQty(item.quantity - 1)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            key: Key('inc_${item.id}'),
                            visualDensity: VisualDensity.compact,
                            onPressed: item.quantity < item.stockQuantity
                                ? () => onQty(item.quantity + 1)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                          const Spacer(),
                          PriceText(item.lineTotal),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
