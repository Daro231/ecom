import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/page_response.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/paged.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/order_models.dart';

class OrdersController extends PagedNotifier<Order> {
  @override
  PagedState<Order> build() {
    ref.watch(currentUserIdProvider);
    return beginLoad();
  }

  @override
  Future<PageResponse<Order>> fetchPage(int page) =>
      ref.read(orderRepositoryProvider).list(page: page, size: 20);

  /// Replace one order after it changed (cancel, payment...).
  void replace(Order order) {
    state = state.copyWith(
      items: [
        for (final o in state.items)
          o.orderNumber == order.orderNumber ? order : o,
      ],
    );
  }
}

final ordersProvider = NotifierProvider<OrdersController, PagedState<Order>>(
  OrdersController.new,
);

final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((
  ref,
  orderNumber,
) {
  ref.watch(currentUserIdProvider);
  return ref.watch(orderRepositoryProvider).get(orderNumber);
});

final invoiceProvider = FutureProvider.autoDispose.family<Invoice, String>(
  (ref, orderNumber) => ref.watch(orderRepositoryProvider).invoice(orderNumber),
);

final trackingProvider = FutureProvider.autoDispose.family<Shipment, String>(
  (ref, orderNumber) =>
      ref.watch(orderRepositoryProvider).tracking(orderNumber),
);

/// Order-list tabs. PROCESSING is grouped under "Confirmed".
const orderTabs = <(String label, Set<String>? statuses)>[
  ('All', null),
  ('Pending', {'PENDING'}),
  ('Confirmed', {'CONFIRMED', 'PROCESSING'}),
  ('Shipped', {'SHIPPED'}),
  ('Delivered', {'DELIVERED'}),
  ('Cancelled', {'CANCELLED'}),
];
