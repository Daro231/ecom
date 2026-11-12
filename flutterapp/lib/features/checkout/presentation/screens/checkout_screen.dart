import '../../../../core/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/totals.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/data/models/cart_models.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../order/data/repositories/order_repository.dart';
import '../../../product/data/models/catalog_models.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../profile/data/models/address.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/address_form_sheet.dart';

const paymentOptions =
    <(String code, String label, String hint, IconData icon)>[
      (
        'KHQR',
        'KHQR (Bakong)',
        'Scan or save the QR and pay with any banking app',
        Icons.qr_code_2_rounded,
      ),
      (
        'CASH_ON_DELIVERY',
        'Cash on delivery',
        'Pay the courier when your order arrives',
        Icons.payments_outlined,
      ),
      ('CARD', 'Credit / debit card', 'Pay by card', Icons.credit_card),
      (
        'BANK_TRANSFER',
        'Bank transfer',
        'Transfer to our bank account',
        Icons.account_balance_outlined,
      ),
    ];

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _step = 0;
  int? _addressId;
  String? _shipping;
  String _payment = 'KHQR';
  final _note = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool _canContinue() {
    switch (_step) {
      case 0:
        return _addressId != null;
      case 1:
        return _shipping != null;
      default:
        return true;
    }
  }

  Future<void> _place(Cart cart) async {
    setState(() => _placing = true);
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .checkout(
            CheckoutRequest(
              addressId: _addressId!,
              shippingMethod: _shipping!,
              paymentMethod: _payment,
              couponCode: ref.read(appliedCouponProvider),
              note: _note.text,
            ),
          );
      await ref.read(cartProvider.notifier).afterCheckout();
      if (!mounted) return;
      if (_payment == 'KHQR') {
        context.pushReplacement('/pay/${order.orderNumber}');
      } else {
        context.pushReplacement('/success/${order.orderNumber}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        showError(context, e);
        ref.read(cartProvider.notifier).refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addresses = ref.watch(addressesProvider);
    final methods = ref.watch(shippingMethodsProvider);

    // Preselect the default address / first shipping method once loaded.
    addresses.whenData((list) {
      if (_addressId == null && list.isNotEmpty) {
        _addressId =
            (list.where((a) => a.isDefault).firstOrNull ?? list.first).id;
      }
    });
    methods.whenData((list) {
      if (_shipping == null && list.isNotEmpty) _shipping = list.first.code;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: AsyncView<Cart>(
        value: cartAsync,
        onRetry: () => ref.read(cartProvider.notifier).refresh(),
        data: (cart) {
          if (cart.items.isEmpty && !_placing) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              actionLabel: 'Back to shop',
              onAction: () => context.go('/home'),
            );
          }
          return ContentWidth(
            child: Stepper(
              currentStep: _step,
              type: StepperType.vertical,
              physics: const ClampingScrollPhysics(),
              onStepTapped: (i) {
                if (i < _step) setState(() => _step = i);
              },
              controlsBuilder: (context, details) {
                if (details.stepIndex != _step) return const SizedBox.shrink();
                final last = _step == 3;
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          key: Key(last ? 'place_order' : 'step_next'),
                          onPressed: !_canContinue() || _placing
                              ? null
                              : (last
                                    ? () => _place(cart)
                                    : () => setState(() => _step++)),
                          child: _placing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(last ? 'Place order' : 'Continue'),
                        ),
                      ),
                      if (_step > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _placing
                                ? null
                                : () => setState(() => _step--),
                            child: const Text('Back'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Address'),
                  isActive: _step >= 0,
                  state: _step > 0 ? StepState.complete : StepState.indexed,
                  content: _addressStep(addresses),
                ),
                Step(
                  title: const Text('Shipping'),
                  isActive: _step >= 1,
                  state: _step > 1 ? StepState.complete : StepState.indexed,
                  content: _shippingStep(methods, cart),
                ),
                Step(
                  title: const Text('Payment'),
                  isActive: _step >= 2,
                  state: _step > 2 ? StepState.complete : StepState.indexed,
                  content: _paymentStep(),
                ),
                Step(
                  title: const Text('Review'),
                  isActive: _step >= 3,
                  content: _reviewStep(
                    cart,
                    addresses.value ?? const [],
                    methods.value ?? const [],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _addressStep(AsyncValue<List<Address>> addresses) {
    return addresses.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.read(addressesProvider.notifier).reload(),
      ),
      data: (list) => RadioGroup<int>(
        groupValue: _addressId,
        onChanged: (v) => setState(() => _addressId = v),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('You have no saved address yet.'),
              ),
            for (final a in list)
              Card(
                child: RadioListTile<int>(
                  key: Key('address_${a.id}'),
                  value: a.id,
                  title: Text(
                    '${a.receiverName}${a.isDefault ? '  (default)' : ''}',
                  ),
                  subtitle: Text('${a.phone}\n${a.fullLine}'),
                  isThreeLine: true,
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('add_address'),
              onPressed: () async {
                final before =
                    ref
                        .read(addressesProvider)
                        .value
                        ?.map((e) => e.id)
                        .toSet() ??
                    {};
                final ok = await showAddressForm(
                  context,
                  forceDefault: list.isEmpty,
                );
                if (ok) {
                  final after = ref.read(addressesProvider).value ?? const [];
                  final added = after
                      .where((a) => !before.contains(a.id))
                      .firstOrNull;
                  if (added != null) setState(() => _addressId = added.id);
                }
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add new address'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shippingStep(
    AsyncValue<List<ShippingMethodInfo>> methods,
    Cart cart,
  ) {
    return methods.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(shippingMethodsProvider),
      ),
      data: (list) => RadioGroup<String>(
        groupValue: _shipping,
        onChanged: (v) => setState(() => _shipping = v),
        child: Column(
          children: [
            for (final m in list)
              Card(
                child: RadioListTile<String>(
                  key: Key('ship_${m.code}'),
                  value: m.code,
                  title: Text(m.label),
                  subtitle: Text(m.estimatedDelivery ?? ''),
                  secondary: Text(() {
                    final fee = shippingFeeFor(
                      subtotal: cart.subtotal,
                      fee: m.fee,
                      freeShippingThreshold: m.freeShippingThreshold,
                    );
                    return fee == 0 ? 'FREE' : formatUsd(fee);
                  }(), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _paymentStep() {
    return RadioGroup<String>(
      groupValue: _payment,
      onChanged: (v) => setState(() => _payment = v!),
      child: Column(
        children: [
          for (final p in paymentOptions)
            Card(
              child: RadioListTile<String>(
                key: Key('pay_${p.$1}'),
                value: p.$1,
                title: Text(p.$2),
                subtitle: Text(p.$3),
                secondary: Icon(p.$4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reviewStep(
    Cart cart,
    List<Address> addresses,
    List<ShippingMethodInfo> methods,
  ) {
    final address = addresses.where((a) => a.id == _addressId).firstOrNull;
    final method = methods.where((m) => m.code == _shipping).firstOrNull;
    final coupon = ref.watch(appliedCouponProvider);
    final payLabel = paymentOptions.firstWhere((p) => p.$1 == _payment).$2;

    Widget totals;
    if (coupon != null && _shipping != null) {
      final prev = ref.watch(
        couponPreviewProvider((code: coupon, shipping: _shipping!)),
      );
      totals = prev.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text(
          errorMessage(e),
          style: const TextStyle(color: AppColors.danger),
        ),
        data: (p) => Column(
          children: [
            KeyValueRow('Subtotal', formatUsd(p.subtotal)),
            KeyValueRow(
              'Discount (${p.couponCode})',
              '-${formatUsd(p.discount)}',
              valueColor: AppColors.success,
            ),
            KeyValueRow('Shipping', formatUsd(p.shippingFee)),
            KeyValueRow('Total', formatUsd(p.total), bold: true),
          ],
        ),
      );
    } else {
      final t = OrderTotals(
        subtotal: cart.subtotal,
        discount: 0,
        shippingFee: method == null
            ? 0
            : shippingFeeFor(
                subtotal: cart.subtotal,
                fee: method.fee,
                freeShippingThreshold: method.freeShippingThreshold,
              ),
      );
      totals = Column(
        children: [
          KeyValueRow('Subtotal', formatUsd(t.subtotal)),
          KeyValueRow(
            'Shipping',
            t.shippingFee == 0 ? 'FREE' : formatUsd(t.shippingFee),
          ),
          KeyValueRow('Total', formatUsd(t.total), bold: true),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final i in cart.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${i.quantity} × ${i.productName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(formatUsd(i.lineTotal)),
                      ],
                    ),
                  ),
                const Divider(),
                if (address != null)
                  KeyValueRow(
                    'Deliver to',
                    '${address.receiverName}\n${address.fullLine}',
                  ),
                KeyValueRow('Shipping', method?.label ?? '-'),
                KeyValueRow('Payment', payLabel),
                const Divider(),
                totals,
                const SizedBox(height: 4),
                const Text(
                  'Final amounts are confirmed by the store when the order is placed.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Note for the courier (optional)',
          ),
        ),
      ],
    );
  }
}
