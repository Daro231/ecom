import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/order_models.dart';
import '../providers/order_providers.dart';

class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key, required this.orderNumber});
  final String orderNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(invoiceProvider(orderNumber));
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: AsyncView<Invoice>(
        value: value,
        onRetry: () => ref.invalidate(invoiceProvider(orderNumber)),
        data: (inv) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.invoiceNumber,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Issued ${formatDateTime(inv.issuedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 28),
                    KeyValueRow('Order', inv.orderNumber),
                    if (inv.orderStatus != null)
                      KeyValueRow(
                        'Order status',
                        humanizeEnum(inv.orderStatus!),
                      ),
                    KeyValueRow(
                      'Billed to',
                      '${inv.customerName ?? '-'}\n${inv.customerEmail ?? ''}',
                    ),
                    KeyValueRow(
                      'Ship to',
                      '${inv.receiverName ?? '-'}\n${inv.receiverPhone ?? ''}\n${inv.shippingAddress ?? ''}',
                    ),
                    const Divider(height: 28),
                    for (final i in inv.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${i.productName}\n${i.quantity} × ${formatUsd(i.unitPrice)}',
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
                    const Divider(height: 28),
                    KeyValueRow('Subtotal', formatUsd(inv.subtotal)),
                    if (inv.discountAmount > 0)
                      KeyValueRow(
                        'Discount${inv.couponCode == null ? '' : ' (${inv.couponCode})'}',
                        '-${formatUsd(inv.discountAmount)}',
                      ),
                    KeyValueRow('Shipping', formatUsd(inv.shippingFee)),
                    KeyValueRow('Total', formatUsd(inv.total), bold: true),
                    if (inv.payment != null) ...[
                      const Divider(height: 28),
                      KeyValueRow(
                        'Payment method',
                        humanizeEnum(inv.payment!.method),
                      ),
                      KeyValueRow(
                        'Payment status',
                        humanizeEnum(inv.payment!.status),
                      ),
                      if (inv.payment!.paidAt != null)
                        KeyValueRow(
                          'Paid at',
                          formatDateTime(inv.payment!.paidAt),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
