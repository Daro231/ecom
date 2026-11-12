// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoryImpl _$$CategoryImplFromJson(Map<String, dynamic> json) =>
    _$CategoryImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$CategoryImplToJson(_$CategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
    };

_$BrandImpl _$$BrandImplFromJson(Map<String, dynamic> json) => _$BrandImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  slug: json['slug'] as String?,
);

Map<String, dynamic> _$$BrandImplToJson(_$BrandImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
    };

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: (json['id'] as num).toInt(),
      sku: json['sku'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      price: toDouble(json['price']),
      category: json['category'] == null
          ? null
          : Category.fromJson(json['category'] as Map<String, dynamic>),
      brand: json['brand'] == null
          ? null
          : Brand.fromJson(json['brand'] as Map<String, dynamic>),
      cpu: json['cpu'] as String?,
      ram: (json['ram'] as num?)?.toInt(),
      storage: json['storage'] as String?,
      gpu: json['gpu'] as String?,
      screenSize: toDoubleOrNull(json['screenSize']),
      os: json['os'] as String?,
      warrantyMonths: (json['warrantyMonths'] as num?)?.toInt(),
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      averageRating: json['averageRating'] == null
          ? 0
          : toDouble(json['averageRating']),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      createdAt: toDateTimeOrNull(json['createdAt']),
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sku': instance.sku,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'price': instance.price,
      'category': instance.category?.toJson(),
      'brand': instance.brand?.toJson(),
      'cpu': instance.cpu,
      'ram': instance.ram,
      'storage': instance.storage,
      'gpu': instance.gpu,
      'screenSize': instance.screenSize,
      'os': instance.os,
      'warrantyMonths': instance.warrantyMonths,
      'stockQuantity': instance.stockQuantity,
      'lowStockThreshold': instance.lowStockThreshold,
      'active': instance.active,
      'averageRating': instance.averageRating,
      'reviewCount': instance.reviewCount,
      'soldCount': instance.soldCount,
      'images': instance.images,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$ShippingMethodInfoImpl _$$ShippingMethodInfoImplFromJson(
  Map<String, dynamic> json,
) => _$ShippingMethodInfoImpl(
  code: json['code'] as String,
  label: json['label'] as String,
  fee: toDouble(json['fee']),
  estimatedDelivery: json['estimatedDelivery'] as String?,
  freeShippingThreshold: toDoubleOrNull(json['freeShippingThreshold']),
);

Map<String, dynamic> _$$ShippingMethodInfoImplToJson(
  _$ShippingMethodInfoImpl instance,
) => <String, dynamic>{
  'code': instance.code,
  'label': instance.label,
  'fee': instance.fee,
  'estimatedDelivery': instance.estimatedDelivery,
  'freeShippingThreshold': instance.freeShippingThreshold,
};

_$ReviewImpl _$$ReviewImplFromJson(Map<String, dynamic> json) => _$ReviewImpl(
  id: (json['id'] as num).toInt(),
  productId: (json['productId'] as num?)?.toInt(),
  productName: json['productName'] as String?,
  userId: (json['userId'] as num?)?.toInt(),
  userName: json['userName'] as String?,
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
  verifiedPurchase: json['verifiedPurchase'] as bool? ?? false,
  visible: json['visible'] as bool? ?? true,
  createdAt: toDateTimeOrNull(json['createdAt']),
);

Map<String, dynamic> _$$ReviewImplToJson(_$ReviewImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'productName': instance.productName,
      'userId': instance.userId,
      'userName': instance.userName,
      'rating': instance.rating,
      'comment': instance.comment,
      'verifiedPurchase': instance.verifiedPurchase,
      'visible': instance.visible,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
