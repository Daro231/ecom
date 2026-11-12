// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CartItemImpl _$$CartItemImplFromJson(Map<String, dynamic> json) =>
    _$CartItemImpl(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      productName: json['productName'] as String,
      imageUrl: json['imageUrl'] as String?,
      unitPrice: toDouble(json['unitPrice']),
      quantity: (json['quantity'] as num).toInt(),
      lineTotal: toDouble(json['lineTotal']),
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$CartItemImplToJson(_$CartItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'productName': instance.productName,
      'imageUrl': instance.imageUrl,
      'unitPrice': instance.unitPrice,
      'quantity': instance.quantity,
      'lineTotal': instance.lineTotal,
      'stockQuantity': instance.stockQuantity,
    };

_$CartImpl _$$CartImplFromJson(Map<String, dynamic> json) => _$CartImpl(
  id: (json['id'] as num?)?.toInt(),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CartItem>[],
  totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
  subtotal: json['subtotal'] == null ? 0 : toDouble(json['subtotal']),
);

Map<String, dynamic> _$$CartImplToJson(_$CartImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'totalItems': instance.totalItems,
      'subtotal': instance.subtotal,
    };

_$CouponPreviewImpl _$$CouponPreviewImplFromJson(Map<String, dynamic> json) =>
    _$CouponPreviewImpl(
      couponCode: json['couponCode'] as String,
      subtotal: toDouble(json['subtotal']),
      discount: toDouble(json['discount']),
      shippingFee: toDouble(json['shippingFee']),
      total: toDouble(json['total']),
    );

Map<String, dynamic> _$$CouponPreviewImplToJson(_$CouponPreviewImpl instance) =>
    <String, dynamic>{
      'couponCode': instance.couponCode,
      'subtotal': instance.subtotal,
      'discount': instance.discount,
      'shippingFee': instance.shippingFee,
      'total': instance.total,
    };
