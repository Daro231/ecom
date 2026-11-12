/// Estimated order totals for the checkout summary. The backend recomputes
/// everything on checkout, and the placed order is the source of truth.
class OrderTotals {
  const OrderTotals({
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
  });

  final double subtotal;
  final double discount;
  final double shippingFee;

  double get total {
    final t = subtotal - discount + shippingFee;
    return t < 0 ? 0 : double.parse(t.toStringAsFixed(2));
  }
}

/// Shipping fee for [subtotal]: free when the method has a free-shipping
/// threshold and the subtotal reaches it.
double shippingFeeFor({
  required double subtotal,
  required double fee,
  double? freeShippingThreshold,
}) {
  if (freeShippingThreshold != null &&
      freeShippingThreshold > 0 &&
      subtotal >= freeShippingThreshold) {
    return 0;
  }
  return fee;
}
