// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderItemImpl _$$OrderItemImplFromJson(Map<String, dynamic> json) =>
    _$OrderItemImpl(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      productName: json['productName'] as String,
      unitPrice: toDouble(json['unitPrice']),
      quantity: (json['quantity'] as num).toInt(),
      lineTotal: toDouble(json['lineTotal']),
    );

Map<String, dynamic> _$$OrderItemImplToJson(_$OrderItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'productName': instance.productName,
      'unitPrice': instance.unitPrice,
      'quantity': instance.quantity,
      'lineTotal': instance.lineTotal,
    };

_$PaymentImpl _$$PaymentImplFromJson(Map<String, dynamic> json) =>
    _$PaymentImpl(
      id: (json['id'] as num).toInt(),
      orderNumber: json['orderNumber'] as String,
      method: json['method'] as String,
      status: json['status'] as String,
      amount: toDouble(json['amount']),
      transactionRef: json['transactionRef'] as String?,
      paidAt: toDateTimeOrNull(json['paidAt']),
      failureReason: json['failureReason'] as String?,
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderNumber': instance.orderNumber,
      'method': instance.method,
      'status': instance.status,
      'amount': instance.amount,
      'transactionRef': instance.transactionRef,
      'paidAt': instance.paidAt?.toIso8601String(),
      'failureReason': instance.failureReason,
    };

_$ShipmentImpl _$$ShipmentImplFromJson(Map<String, dynamic> json) =>
    _$ShipmentImpl(
      id: (json['id'] as num).toInt(),
      orderNumber: json['orderNumber'] as String?,
      method: json['method'] as String?,
      fee: json['fee'] == null ? 0 : toDouble(json['fee']),
      trackingNumber: json['trackingNumber'] as String?,
      status: json['status'] as String,
      shippedAt: toDateTimeOrNull(json['shippedAt']),
      deliveredAt: toDateTimeOrNull(json['deliveredAt']),
    );

Map<String, dynamic> _$$ShipmentImplToJson(_$ShipmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderNumber': instance.orderNumber,
      'method': instance.method,
      'fee': instance.fee,
      'trackingNumber': instance.trackingNumber,
      'status': instance.status,
      'shippedAt': instance.shippedAt?.toIso8601String(),
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
    };

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
  id: (json['id'] as num).toInt(),
  orderNumber: json['orderNumber'] as String,
  status: json['status'] as String,
  subtotal: toDouble(json['subtotal']),
  discountAmount: json['discountAmount'] == null
      ? 0
      : toDouble(json['discountAmount']),
  shippingFee: json['shippingFee'] == null ? 0 : toDouble(json['shippingFee']),
  total: toDouble(json['total']),
  couponCode: json['couponCode'] as String?,
  receiverName: json['receiverName'] as String?,
  receiverPhone: json['receiverPhone'] as String?,
  shippingAddress: json['shippingAddress'] as String?,
  deliveryLatitude: toDoubleOrNull(json['deliveryLatitude']),
  deliveryLongitude: toDoubleOrNull(json['deliveryLongitude']),
  shippingMethod: json['shippingMethod'] as String?,
  paymentMethod: json['paymentMethod'] as String?,
  note: json['note'] as String?,
  cancelledReason: json['cancelledReason'] as String?,
  customerEmail: json['customerEmail'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OrderItem>[],
  payment: json['payment'] == null
      ? null
      : Payment.fromJson(json['payment'] as Map<String, dynamic>),
  shipment: json['shipment'] == null
      ? null
      : Shipment.fromJson(json['shipment'] as Map<String, dynamic>),
  createdAt: toDateTimeOrNull(json['createdAt']),
);

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderNumber': instance.orderNumber,
      'status': instance.status,
      'subtotal': instance.subtotal,
      'discountAmount': instance.discountAmount,
      'shippingFee': instance.shippingFee,
      'total': instance.total,
      'couponCode': instance.couponCode,
      'receiverName': instance.receiverName,
      'receiverPhone': instance.receiverPhone,
      'shippingAddress': instance.shippingAddress,
      'deliveryLatitude': instance.deliveryLatitude,
      'deliveryLongitude': instance.deliveryLongitude,
      'shippingMethod': instance.shippingMethod,
      'paymentMethod': instance.paymentMethod,
      'note': instance.note,
      'cancelledReason': instance.cancelledReason,
      'customerEmail': instance.customerEmail,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'payment': instance.payment?.toJson(),
      'shipment': instance.shipment?.toJson(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$InvoiceImpl _$$InvoiceImplFromJson(Map<String, dynamic> json) =>
    _$InvoiceImpl(
      invoiceNumber: json['invoiceNumber'] as String,
      issuedAt: toDateTimeOrNull(json['issuedAt']),
      orderNumber: json['orderNumber'] as String,
      orderStatus: json['orderStatus'] as String?,
      customerName: json['customerName'] as String?,
      customerEmail: json['customerEmail'] as String?,
      receiverName: json['receiverName'] as String?,
      receiverPhone: json['receiverPhone'] as String?,
      shippingAddress: json['shippingAddress'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OrderItem>[],
      subtotal: toDouble(json['subtotal']),
      discountAmount: json['discountAmount'] == null
          ? 0
          : toDouble(json['discountAmount']),
      couponCode: json['couponCode'] as String?,
      shippingFee: json['shippingFee'] == null
          ? 0
          : toDouble(json['shippingFee']),
      total: toDouble(json['total']),
      payment: json['payment'] == null
          ? null
          : Payment.fromJson(json['payment'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$InvoiceImplToJson(_$InvoiceImpl instance) =>
    <String, dynamic>{
      'invoiceNumber': instance.invoiceNumber,
      'issuedAt': instance.issuedAt?.toIso8601String(),
      'orderNumber': instance.orderNumber,
      'orderStatus': instance.orderStatus,
      'customerName': instance.customerName,
      'customerEmail': instance.customerEmail,
      'receiverName': instance.receiverName,
      'receiverPhone': instance.receiverPhone,
      'shippingAddress': instance.shippingAddress,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'subtotal': instance.subtotal,
      'discountAmount': instance.discountAmount,
      'couponCode': instance.couponCode,
      'shippingFee': instance.shippingFee,
      'total': instance.total,
      'payment': instance.payment?.toJson(),
    };
