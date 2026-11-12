import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/location_map.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../product/presentation/widgets/review_dialog.dart';
import '../../data/models/order_models.dart';
import '../providers/order_providers.dart';

const lateNoticeText =
    'We received your payment after the order was cancelled. Our team will restore your order or refund you.';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderNumber});
  final String orderNumber;

  Future<void> _cancel(BuildContext context, WidgetRef ref, Order o) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _CancelDialog(),
    );
    if (reason == null) return;
    try {
      final updated = await ref
          .read(orderRepositoryProvider)
          .cancel(o.orderNumber, reason);
      ref.invalidate(orderDetailProvider(o.orderNumber));
      ref.read(ordersProvider.notifier).replace(updated);
      if (context.mounted) showSnack(context, 'Order cancelled');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(orderDetailProvider(orderNumber));
    return Scaffold(
      appBar: AppBar(
        title: Text(orderNumber, style: const TextStyle(fontSize: 16)),
      ),
      body: AsyncView<Order>(
        value: value,
        onRetry: () => ref.invalidate(orderDetailProvider(orderNumber)),
        data: (o) => ContentWidth(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(orderDetailProvider(orderNumber));
              ref.invalidate(trackingProvider(orderNumber));
              await ref
                  .read(orderDetailProvider(orderNumber).future)
                  .catchError((_) => o);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    StatusChip(o.status),
                    const SizedBox(width: 8),
                    if (o.payment != null) ...[
                      const Text('Payment:'),
                      const SizedBox(width: 6),
                      StatusChip(o.payment!.status),
                    ],
                  ],
                ),
                if (o.paidAfterCancel) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('late_payment_notice'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppColors.warning),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lateNoticeText,
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (o.isCancelled &&
                    (o.cancelledReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Cancelled: ${o.cancelledReason}',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 16),
                _section(context, 'Order status', _Timeline(order: o)),
                if (o.status == 'SHIPPED' || o.status == 'DELIVERED')
                  _TrackingCard(
                    orderNumber: o.orderNumber,
                    fallback: o.shipment,
                  ),
                _section(
                  context,
                  'Items',
                  Column(
                    children: [
                      for (final i in o.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () => context.push(
                                        '/product/${i.productId}',
                                      ),
                                      child: Text(
                                        i.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${i.quantity} × ${formatUsd(i.unitPrice)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    if (o.isDelivered)
                                      TextButton.icon(
                                        key: Key('review_${i.productId}'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 32),
                                        ),
                                        onPressed: () => showReviewDialog(
                                          context,
                                          ref,
                                          productId: i.productId,
                                          productName: i.productName,
                                        ),
                                        icon: const Icon(
                                          Icons.rate_review_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('Review'),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                formatUsd(i.lineTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Summary',
                  Column(
                    children: [
                      KeyValueRow('Subtotal', formatUsd(o.subtotal)),
                      if (o.discountAmount > 0)
                        KeyValueRow(
                          'Discount${o.couponCode == null ? '' : ' (${o.couponCode})'}',
                          '-${formatUsd(o.discountAmount)}',
                          valueColor: AppColors.success,
                        ),
                      KeyValueRow('Shipping', formatUsd(o.shippingFee)),
                      const Divider(),
                      KeyValueRow('Total', formatUsd(o.total), bold: true),
                    ],
                  ),
                ),
                _section(
                  context,
                  'Delivery & payment',
                  Column(
                    children: [
                      KeyValueRow(
                        'Receiver',
                        '${o.receiverName ?? '-'}\n${o.receiverPhone ?? ''}',
                      ),
                      KeyValueRow('Address', o.shippingAddress ?? '-'),
                      if (o.hasDeliveryLocation)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: MapPreview(
                            key: const Key('order_map'),
                            latitude: o.deliveryLatitude!,
                            longitude: o.deliveryLongitude!,
                          ),
                        ),
                      KeyValueRow(
                        'Shipping',
                        enumLabel(o.shippingMethod ?? '-'),
                      ),
                      KeyValueRow('Payment', enumLabel(o.paymentMethod ?? '-')),
                      if ((o.note ?? '').isNotEmpty)
                        KeyValueRow('Note', o.note!),
                      KeyValueRow('Placed', formatDateTime(o.createdAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (o.canPayNow)
                  FilledButton.icon(
                    key: const Key('pay_now'),
                    onPressed: () => context.push('/pay/${o.orderNumber}'),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Pay now with KHQR'),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('view_invoice'),
                  onPressed: () =>
                      context.push('/order/${o.orderNumber}/invoice'),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('View invoice'),
                ),
                if (o.canCancel) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('cancel_order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    onPressed: () => _cancel(context, ref, o),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel order'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ],
    ),
  );
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog();

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cancel this order?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Tell us why you are cancelling.'),
        const SizedBox(height: 12),
        TextField(
          key: const Key('cancel_reason'),
          controller: _reason,
          maxLines: 3,
          decoration: InputDecoration(labelText: 'Reason', errorText: _error),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Keep order'),
      ),
      FilledButton(
        key: const Key('confirm_cancel'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 44),
          backgroundColor: AppColors.danger,
        ),
        onPressed: () {
          if (_reason.text.trim().isEmpty) {
            setState(() => _error = 'Please enter a reason');
            return;
          }
          Navigator.pop(context, _reason.text.trim());
        },
        child: const Text('Cancel order'),
      ),
    ],
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});
  final Order order;

  static const _steps = [
    ('PENDING', 'Order placed'),
    ('CONFIRMED', 'Confirmed'),
    ('PROCESSING', 'Processing'),
    ('SHIPPED', 'Shipped'),
    ('DELIVERED', 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final cancelled = order.isCancelled;
    final idx = _steps.indexWhere((s) => s.$1 == order.status);
    final entries =
        <(String label, bool done, bool current, bool bad, String? when)>[];
    if (cancelled) {
      entries.add((
        'Order placed',
        true,
        false,
        false,
        formatDateTime(order.createdAt),
      ));
      entries.add(('Cancelled', true, true, true, null));
    } else {
      for (var i = 0; i < _steps.length; i++) {
        String? when;
        if (i == 0) when = formatDateTime(order.createdAt);
        if (_steps[i].$1 == 'SHIPPED' && order.shipment?.shippedAt != null)
          when = formatDateTime(order.shipment!.shippedAt);
        if (_steps[i].$1 == 'DELIVERED' && order.shipment?.deliveredAt != null)
          when = formatDateTime(order.shipment!.deliveredAt);
        entries.add((_steps[i].$2, i <= idx, i == idx, false, when));
      }
    }
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Icon(
                        entries[i].$4
                            ? Icons.cancel
                            : entries[i].$2
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 22,
                        color: entries[i].$4
                            ? AppColors.danger
                            : entries[i].$2
                            ? AppColors.success
                            : Colors.grey,
                      ),
                      if (i != entries.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: entries[i + 1].$2
                                ? AppColors.success
                                : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].$1,
                          style: TextStyle(
                            fontWeight: entries[i].$3
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: entries[i].$2 ? null : Colors.grey,
                          ),
                        ),
                        if (entries[i].$5 != null)
                          Text(
                            entries[i].$5!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TrackingCard extends ConsumerWidget {
  const _TrackingCard({required this.orderNumber, this.fallback});
  final String orderNumber;
  final Shipment? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(trackingProvider(orderNumber)).value ?? fallback;
    if (s == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Tracking',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  KeyValueRow('Shipment', humanizeEnum(s.status)),
                  if ((s.trackingNumber ?? '').isNotEmpty)
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('Tracking no.')),
                        Expanded(
                          flex: 3,
                          child: SelectableText(
                            s.trackingNumber!,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          key: const Key('copy_tracking'),
                          tooltip: 'Copy tracking number',
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: s.trackingNumber!),
                            );
                            showSnack(context, 'Tracking number copied');
                          },
                        ),
                      ],
                    )
                  else
                    const KeyValueRow('Tracking no.', 'Not assigned yet'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
