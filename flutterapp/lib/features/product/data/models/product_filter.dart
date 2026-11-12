// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_filter.freezed.dart';

/// Search / filter state for `GET /products`.
@freezed
class ProductFilter with _$ProductFilter {
  const ProductFilter._();

  const factory ProductFilter({
    String? keyword,
    int? categoryId,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    int? ram,
    double? minRating,
    @Default(false) bool inStockOnly,
    @Default('newest') String sort,
  }) = _ProductFilter;

  Map<String, dynamic> toQuery({required int page, required int size}) => {
    if (keyword != null && keyword!.trim().isNotEmpty)
      'keyword': keyword!.trim(),
    if (categoryId != null) 'categoryId': categoryId,
    if (brandId != null) 'brandId': brandId,
    if (minPrice != null) 'minPrice': minPrice,
    if (maxPrice != null) 'maxPrice': maxPrice,
    if (ram != null) 'ram': ram,
    if (minRating != null) 'minRating': minRating,
    if (inStockOnly) 'inStock': true,
    'sort': sort,
    'page': page,
    'size': size,
  };

  /// Number of active filters (excluding keyword and sort) for the badge.
  int get activeCount =>
      (categoryId != null ? 1 : 0) +
      (brandId != null ? 1 : 0) +
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (ram != null ? 1 : 0) +
      (minRating != null ? 1 : 0) +
      (inStockOnly ? 1 : 0);
}
