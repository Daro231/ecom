// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/json_helpers.dart';

part 'cart_models.freezed.dart';
part 'cart_models.g.dart';

@freezed
class CartItem with _$CartItem {
  const factory CartItem({
    required int id,
    required int productId,
    required String productName,
    String? imageUrl,
    @JsonKey(fromJson: toDouble) required double unitPrice,
    required int quantity,
    @JsonKey(fromJson: toDouble) required double lineTotal,
    @Default(0) int stockQuantity,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}

@freezed
class Cart with _$Cart {
  const factory Cart({
    int? id,
    @Default(<CartItem>[]) List<CartItem> items,
    @Default(0) int totalItems,
    @JsonKey(fromJson: toDouble) @Default(0) double subtotal,
  }) = _Cart;

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
}

@freezed
class CouponPreview with _$CouponPreview {
  const factory CouponPreview({
    required String couponCode,
    @JsonKey(fromJson: toDouble) required double subtotal,
    @JsonKey(fromJson: toDouble) required double discount,
    @JsonKey(fromJson: toDouble) required double shippingFee,
    @JsonKey(fromJson: toDouble) required double total,
  }) = _CouponPreview;

  factory CouponPreview.fromJson(Map<String, dynamic> json) =>
      _$CouponPreviewFromJson(json);
}
