// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/json_helpers.dart';

part 'catalog_models.freezed.dart';
part 'catalog_models.g.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required int id,
    required String name,
    String? slug,
    String? description,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

@freezed
class Brand with _$Brand {
  const factory Brand({required int id, required String name, String? slug}) =
      _Brand;

  factory Brand.fromJson(Map<String, dynamic> json) => _$BrandFromJson(json);
}

@freezed
class Product with _$Product {
  const Product._();

  const factory Product({
    required int id,
    String? sku,
    required String name,
    String? slug,
    String? description,
    @JsonKey(fromJson: toDouble) required double price,
    Category? category,
    Brand? brand,
    String? cpu,
    int? ram,
    String? storage,
    String? gpu,
    @JsonKey(fromJson: toDoubleOrNull) double? screenSize,
    String? os,
    int? warrantyMonths,
    @Default(0) int stockQuantity,
    @Default(0) int lowStockThreshold,
    @Default(true) bool active,
    @JsonKey(fromJson: toDouble) @Default(0) double averageRating,
    @Default(0) int reviewCount,
    @Default(0) int soldCount,
    @Default(<String>[]) List<String> images,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  bool get inStock => stockQuantity > 0;
  bool get lowStock => inStock && stockQuantity <= lowStockThreshold;
  String? get firstImage => images.isEmpty ? null : images.first;
}

@freezed
class ShippingMethodInfo with _$ShippingMethodInfo {
  const factory ShippingMethodInfo({
    required String code,
    required String label,
    @JsonKey(fromJson: toDouble) required double fee,
    String? estimatedDelivery,
    @JsonKey(fromJson: toDoubleOrNull) double? freeShippingThreshold,
  }) = _ShippingMethodInfo;

  factory ShippingMethodInfo.fromJson(Map<String, dynamic> json) =>
      _$ShippingMethodInfoFromJson(json);
}

@freezed
class Review with _$Review {
  const factory Review({
    required int id,
    int? productId,
    String? productName,
    int? userId,
    String? userName,
    required int rating,
    String? comment,
    @Default(false) bool verifiedPurchase,
    @Default(true) bool visible,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
}
