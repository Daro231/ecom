// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/json_helpers.dart';

part 'order_models.freezed.dart';
part 'order_models.g.dart';

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required int id,
    required int productId,
    required String productName,
    @JsonKey(fromJson: toDouble) required double unitPrice,
    required int quantity,
    @JsonKey(fromJson: toDouble) required double lineTotal,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}

@freezed
class Payment with _$Payment {
  const Payment._();

  const factory Payment({
    required int id,
    required String orderNumber,
    required String method,
    required String status,
    @JsonKey(fromJson: toDouble) required double amount,
    String? transactionRef,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? paidAt,
    String? failureReason,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  bool get isPaid => status == 'PAID';
  bool get isPaidAfterCancel => status == 'PAID_AFTER_CANCEL';
}

@freezed
class Shipment with _$Shipment {
  const factory Shipment({
    required int id,
    String? orderNumber,
    String? method,
    @JsonKey(fromJson: toDouble) @Default(0) double fee,
    String? trackingNumber,
    required String status,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? shippedAt,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? deliveredAt,
  }) = _Shipment;

  factory Shipment.fromJson(Map<String, dynamic> json) =>
      _$ShipmentFromJson(json);
}

@freezed
class Order with _$Order {
  const Order._();

  const factory Order({
    required int id,
    required String orderNumber,
    required String status,
    @JsonKey(fromJson: toDouble) required double subtotal,
    @JsonKey(fromJson: toDouble) @Default(0) double discountAmount,
    @JsonKey(fromJson: toDouble) @Default(0) double shippingFee,
    @JsonKey(fromJson: toDouble) required double total,
    String? couponCode,
    String? receiverName,
    String? receiverPhone,
    String? shippingAddress,
    @JsonKey(fromJson: toDoubleOrNull) double? deliveryLatitude,
    @JsonKey(fromJson: toDoubleOrNull) double? deliveryLongitude,
    String? shippingMethod,
    String? paymentMethod,
    String? note,
    String? cancelledReason,
    String? customerEmail,
    @Default(<OrderItem>[]) List<OrderItem> items,
    Payment? payment,
    Shipment? shipment,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  bool get hasDeliveryLocation =>
      deliveryLatitude != null && deliveryLongitude != null;

  bool get canCancel =>
      status == 'PENDING' || status == 'CONFIRMED' || status == 'PROCESSING';

  bool get isCancelled => status == 'CANCELLED';
  bool get isDelivered => status == 'DELIVERED';

  /// Paid by KHQR after the order was auto-cancelled (order stays CANCELLED).
  bool get paidAfterCancel => payment?.isPaidAfterCancel ?? false;

  /// Unpaid KHQR order that can still be paid ("Pay now").
  bool get canPayNow =>
      paymentMethod == 'KHQR' &&
      status == 'PENDING' &&
      (payment?.status ?? 'PENDING') == 'PENDING';
}

@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    required String invoiceNumber,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? issuedAt,
    required String orderNumber,
    String? orderStatus,
    String? customerName,
    String? customerEmail,
    String? receiverName,
    String? receiverPhone,
    String? shippingAddress,
    @Default(<OrderItem>[]) List<OrderItem> items,
    @JsonKey(fromJson: toDouble) required double subtotal,
    @JsonKey(fromJson: toDouble) @Default(0) double discountAmount,
    String? couponCode,
    @JsonKey(fromJson: toDouble) @Default(0) double shippingFee,
    @JsonKey(fromJson: toDouble) required double total,
    Payment? payment,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}
