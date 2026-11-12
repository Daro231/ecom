import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/order_models.dart';
import '../providers/order_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: orderTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My orders'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [for (final t in orderTabs) Tab(text: t.$1)],
          ),
        ),
        body: TabBarView(
          children: [for (final t in orderTabs) _OrdersTab(statuses: t.$2)],
        ),
      ),
    );
  }
}

class _OrdersTab extends ConsumerStatefulWidget {
  const _OrdersTab({required this.statuses});
  final Set<String>? statuses;

  @override
  ConsumerState<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<_OrdersTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        ref.read(ordersProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(ordersProvider);
    if (state.loading) return const ShimmerList(itemHeight: 110);
    if (state.error != null) {
      return ErrorState(
        error: state.error!,
        onRetry: () =>
            ref.read(ordersProvider.notifier).refresh().catchError((_) {}),
      );
    }
    final items = widget.statuses == null
        ? state.items
        : state.items
              .where((o) => widget.statuses!.contains(o.status))
              .toList();

    // The API has no status filter: keep fetching pages until this tab has content.
    if (items.length < 5 &&
        !state.last &&
        !state.loadingMore &&
        state.loadMoreError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(ordersProvider.notifier).loadMore();
      });
    }

    if (items.isEmpty && !state.loadingMore && state.last) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(ordersProvider.notifier).refresh().catchError((_) {}),
        child: LayoutBuilder(
          builder: (_, c) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: c.maxHeight,
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders here',
                message: 'Orders you place will show up in this list.',
                actionLabel: widget.statuses == null ? 'Start shopping' : null,
                onAction: () => context.go('/home'),
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(ordersProvider.notifier).refresh().catchError((_) {}),
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == items.length) {
            return state.loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : state.loadMoreError != null
                ? TextButton(
                    onPressed: ref.read(ordersProvider.notifier).loadMore,
                    child: const Text('Could not load more. Tap to retry'),
                  )
                : const SizedBox.shrink();
          }
          return OrderCard(order: items[i]);
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final first = order.items.isEmpty ? null : order.items.first;
    final more = order.items.length - 1;
    return Card(
      child: InkWell(
        key: Key('order_${order.orderNumber}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/order/${order.orderNumber}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip(
                    order.paidAfterCancel ? 'PAID_AFTER_CANCEL' : order.status,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                formatDateTime(order.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              if (first != null)
                Text(
                  '${first.quantity} × ${first.productName}${more > 0 ? '  +$more more' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    enumLabel(order.paymentMethod ?? ''),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  PriceText(order.total),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
