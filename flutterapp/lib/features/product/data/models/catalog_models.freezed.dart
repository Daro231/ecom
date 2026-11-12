// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Category _$CategoryFromJson(Map<String, dynamic> json) {
  return _Category.fromJson(json);
}

/// @nodoc
mixin _$Category {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this Category to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryCopyWith<Category> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryCopyWith<$Res> {
  factory $CategoryCopyWith(Category value, $Res Function(Category) then) =
      _$CategoryCopyWithImpl<$Res, Category>;
  @useResult
  $Res call({int id, String name, String? slug, String? description});
}

/// @nodoc
class _$CategoryCopyWithImpl<$Res, $Val extends Category>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = freezed,
    Object? description = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: freezed == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CategoryImplCopyWith<$Res>
    implements $CategoryCopyWith<$Res> {
  factory _$$CategoryImplCopyWith(
    _$CategoryImpl value,
    $Res Function(_$CategoryImpl) then,
  ) = __$$CategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, String? slug, String? description});
}

/// @nodoc
class __$$CategoryImplCopyWithImpl<$Res>
    extends _$CategoryCopyWithImpl<$Res, _$CategoryImpl>
    implements _$$CategoryImplCopyWith<$Res> {
  __$$CategoryImplCopyWithImpl(
    _$CategoryImpl _value,
    $Res Function(_$CategoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = freezed,
    Object? description = freezed,
  }) {
    return _then(
      _$CategoryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: freezed == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryImpl implements _Category {
  const _$CategoryImpl({
    required this.id,
    required this.name,
    this.slug,
    this.description,
  });

  factory _$CategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String? slug;
  @override
  final String? description;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, slug: $slug, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, slug, description);

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      __$$CategoryImplCopyWithImpl<_$CategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryImplToJson(this);
  }
}

abstract class _Category implements Category {
  const factory _Category({
    required final int id,
    required final String name,
    final String? slug,
    final String? description,
  }) = _$CategoryImpl;

  factory _Category.fromJson(Map<String, dynamic> json) =
      _$CategoryImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String? get slug;
  @override
  String? get description;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Brand _$BrandFromJson(Map<String, dynamic> json) {
  return _Brand.fromJson(json);
}

/// @nodoc
mixin _$Brand {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get slug => throw _privateConstructorUsedError;

  /// Serializes this Brand to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Brand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BrandCopyWith<Brand> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BrandCopyWith<$Res> {
  factory $BrandCopyWith(Brand value, $Res Function(Brand) then) =
      _$BrandCopyWithImpl<$Res, Brand>;
  @useResult
  $Res call({int id, String name, String? slug});
}

/// @nodoc
class _$BrandCopyWithImpl<$Res, $Val extends Brand>
    implements $BrandCopyWith<$Res> {
  _$BrandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Brand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? slug = freezed}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: freezed == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BrandImplCopyWith<$Res> implements $BrandCopyWith<$Res> {
  factory _$$BrandImplCopyWith(
    _$BrandImpl value,
    $Res Function(_$BrandImpl) then,
  ) = __$$BrandImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name, String? slug});
}

/// @nodoc
class __$$BrandImplCopyWithImpl<$Res>
    extends _$BrandCopyWithImpl<$Res, _$BrandImpl>
    implements _$$BrandImplCopyWith<$Res> {
  __$$BrandImplCopyWithImpl(
    _$BrandImpl _value,
    $Res Function(_$BrandImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Brand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? slug = freezed}) {
    return _then(
      _$BrandImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: freezed == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BrandImpl implements _Brand {
  const _$BrandImpl({required this.id, required this.name, this.slug});

  factory _$BrandImpl.fromJson(Map<String, dynamic> json) =>
      _$$BrandImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String? slug;

  @override
  String toString() {
    return 'Brand(id: $id, name: $name, slug: $slug)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BrandImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, slug);

  /// Create a copy of Brand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BrandImplCopyWith<_$BrandImpl> get copyWith =>
      __$$BrandImplCopyWithImpl<_$BrandImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BrandImplToJson(this);
  }
}

abstract class _Brand implements Brand {
  const factory _Brand({
    required final int id,
    required final String name,
    final String? slug,
  }) = _$BrandImpl;

  factory _Brand.fromJson(Map<String, dynamic> json) = _$BrandImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String? get slug;

  /// Create a copy of Brand
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BrandImplCopyWith<_$BrandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Product _$ProductFromJson(Map<String, dynamic> json) {
  return _Product.fromJson(json);
}

/// @nodoc
mixin _$Product {
  int get id => throw _privateConstructorUsedError;
  String? get sku => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get price => throw _privateConstructorUsedError;
  Category? get category => throw _privateConstructorUsedError;
  Brand? get brand => throw _privateConstructorUsedError;
  String? get cpu => throw _privateConstructorUsedError;
  int? get ram => throw _privateConstructorUsedError;
  String? get storage => throw _privateConstructorUsedError;
  String? get gpu => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDoubleOrNull)
  double? get screenSize => throw _privateConstructorUsedError;
  String? get os => throw _privateConstructorUsedError;
  int? get warrantyMonths => throw _privateConstructorUsedError;
  int get stockQuantity => throw _privateConstructorUsedError;
  int get lowStockThreshold => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get averageRating => throw _privateConstructorUsedError;
  int get reviewCount => throw _privateConstructorUsedError;
  int get soldCount => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call({
    int id,
    String? sku,
    String name,
    String? slug,
    String? description,
    @JsonKey(fromJson: toDouble) double price,
    Category? category,
    Brand? brand,
    String? cpu,
    int? ram,
    String? storage,
    String? gpu,
    @JsonKey(fromJson: toDoubleOrNull) double? screenSize,
    String? os,
    int? warrantyMonths,
    int stockQuantity,
    int lowStockThreshold,
    bool active,
    @JsonKey(fromJson: toDouble) double averageRating,
    int reviewCount,
    int soldCount,
    List<String> images,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
  });

  $CategoryCopyWith<$Res>? get category;
  $BrandCopyWith<$Res>? get brand;
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sku = freezed,
    Object? name = null,
    Object? slug = freezed,
    Object? description = freezed,
    Object? price = null,
    Object? category = freezed,
    Object? brand = freezed,
    Object? cpu = freezed,
    Object? ram = freezed,
    Object? storage = freezed,
    Object? gpu = freezed,
    Object? screenSize = freezed,
    Object? os = freezed,
    Object? warrantyMonths = freezed,
    Object? stockQuantity = null,
    Object? lowStockThreshold = null,
    Object? active = null,
    Object? averageRating = null,
    Object? reviewCount = null,
    Object? soldCount = null,
    Object? images = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            sku: freezed == sku
                ? _value.sku
                : sku // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: freezed == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as Category?,
            brand: freezed == brand
                ? _value.brand
                : brand // ignore: cast_nullable_to_non_nullable
                      as Brand?,
            cpu: freezed == cpu
                ? _value.cpu
                : cpu // ignore: cast_nullable_to_non_nullable
                      as String?,
            ram: freezed == ram
                ? _value.ram
                : ram // ignore: cast_nullable_to_non_nullable
                      as int?,
            storage: freezed == storage
                ? _value.storage
                : storage // ignore: cast_nullable_to_non_nullable
                      as String?,
            gpu: freezed == gpu
                ? _value.gpu
                : gpu // ignore: cast_nullable_to_non_nullable
                      as String?,
            screenSize: freezed == screenSize
                ? _value.screenSize
                : screenSize // ignore: cast_nullable_to_non_nullable
                      as double?,
            os: freezed == os
                ? _value.os
                : os // ignore: cast_nullable_to_non_nullable
                      as String?,
            warrantyMonths: freezed == warrantyMonths
                ? _value.warrantyMonths
                : warrantyMonths // ignore: cast_nullable_to_non_nullable
                      as int?,
            stockQuantity: null == stockQuantity
                ? _value.stockQuantity
                : stockQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
            lowStockThreshold: null == lowStockThreshold
                ? _value.lowStockThreshold
                : lowStockThreshold // ignore: cast_nullable_to_non_nullable
                      as int,
            active: null == active
                ? _value.active
                : active // ignore: cast_nullable_to_non_nullable
                      as bool,
            averageRating: null == averageRating
                ? _value.averageRating
                : averageRating // ignore: cast_nullable_to_non_nullable
                      as double,
            reviewCount: null == reviewCount
                ? _value.reviewCount
                : reviewCount // ignore: cast_nullable_to_non_nullable
                      as int,
            soldCount: null == soldCount
                ? _value.soldCount
                : soldCount // ignore: cast_nullable_to_non_nullable
                      as int,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryCopyWith<$Res>? get category {
    if (_value.category == null) {
      return null;
    }

    return $CategoryCopyWith<$Res>(_value.category!, (value) {
      return _then(_value.copyWith(category: value) as $Val);
    });
  }

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BrandCopyWith<$Res>? get brand {
    if (_value.brand == null) {
      return null;
    }

    return $BrandCopyWith<$Res>(_value.brand!, (value) {
      return _then(_value.copyWith(brand: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
    _$ProductImpl value,
    $Res Function(_$ProductImpl) then,
  ) = __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String? sku,
    String name,
    String? slug,
    String? description,
    @JsonKey(fromJson: toDouble) double price,
    Category? category,
    Brand? brand,
    String? cpu,
    int? ram,
    String? storage,
    String? gpu,
    @JsonKey(fromJson: toDoubleOrNull) double? screenSize,
    String? os,
    int? warrantyMonths,
    int stockQuantity,
    int lowStockThreshold,
    bool active,
    @JsonKey(fromJson: toDouble) double averageRating,
    int reviewCount,
    int soldCount,
    List<String> images,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
  });

  @override
  $CategoryCopyWith<$Res>? get category;
  @override
  $BrandCopyWith<$Res>? get brand;
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
    _$ProductImpl _value,
    $Res Function(_$ProductImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sku = freezed,
    Object? name = null,
    Object? slug = freezed,
    Object? description = freezed,
    Object? price = null,
    Object? category = freezed,
    Object? brand = freezed,
    Object? cpu = freezed,
    Object? ram = freezed,
    Object? storage = freezed,
    Object? gpu = freezed,
    Object? screenSize = freezed,
    Object? os = freezed,
    Object? warrantyMonths = freezed,
    Object? stockQuantity = null,
    Object? lowStockThreshold = null,
    Object? active = null,
    Object? averageRating = null,
    Object? reviewCount = null,
    Object? soldCount = null,
    Object? images = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$ProductImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        sku: freezed == sku
            ? _value.sku
            : sku // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: freezed == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as Category?,
        brand: freezed == brand
            ? _value.brand
            : brand // ignore: cast_nullable_to_non_nullable
                  as Brand?,
        cpu: freezed == cpu
            ? _value.cpu
            : cpu // ignore: cast_nullable_to_non_nullable
                  as String?,
        ram: freezed == ram
            ? _value.ram
            : ram // ignore: cast_nullable_to_non_nullable
                  as int?,
        storage: freezed == storage
            ? _value.storage
            : storage // ignore: cast_nullable_to_non_nullable
                  as String?,
        gpu: freezed == gpu
            ? _value.gpu
            : gpu // ignore: cast_nullable_to_non_nullable
                  as String?,
        screenSize: freezed == screenSize
            ? _value.screenSize
            : screenSize // ignore: cast_nullable_to_non_nullable
                  as double?,
        os: freezed == os
            ? _value.os
            : os // ignore: cast_nullable_to_non_nullable
                  as String?,
        warrantyMonths: freezed == warrantyMonths
            ? _value.warrantyMonths
            : warrantyMonths // ignore: cast_nullable_to_non_nullable
                  as int?,
        stockQuantity: null == stockQuantity
            ? _value.stockQuantity
            : stockQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
        lowStockThreshold: null == lowStockThreshold
            ? _value.lowStockThreshold
            : lowStockThreshold // ignore: cast_nullable_to_non_nullable
                  as int,
        active: null == active
            ? _value.active
            : active // ignore: cast_nullable_to_non_nullable
                  as bool,
        averageRating: null == averageRating
            ? _value.averageRating
            : averageRating // ignore: cast_nullable_to_non_nullable
                  as double,
        reviewCount: null == reviewCount
            ? _value.reviewCount
            : reviewCount // ignore: cast_nullable_to_non_nullable
                  as int,
        soldCount: null == soldCount
            ? _value.soldCount
            : soldCount // ignore: cast_nullable_to_non_nullable
                  as int,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductImpl extends _Product {
  const _$ProductImpl({
    required this.id,
    this.sku,
    required this.name,
    this.slug,
    this.description,
    @JsonKey(fromJson: toDouble) required this.price,
    this.category,
    this.brand,
    this.cpu,
    this.ram,
    this.storage,
    this.gpu,
    @JsonKey(fromJson: toDoubleOrNull) this.screenSize,
    this.os,
    this.warrantyMonths,
    this.stockQuantity = 0,
    this.lowStockThreshold = 0,
    this.active = true,
    @JsonKey(fromJson: toDouble) this.averageRating = 0,
    this.reviewCount = 0,
    this.soldCount = 0,
    final List<String> images = const <String>[],
    @JsonKey(fromJson: toDateTimeOrNull) this.createdAt,
  }) : _images = images,
       super._();

  factory _$ProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductImplFromJson(json);

  @override
  final int id;
  @override
  final String? sku;
  @override
  final String name;
  @override
  final String? slug;
  @override
  final String? description;
  @override
  @JsonKey(fromJson: toDouble)
  final double price;
  @override
  final Category? category;
  @override
  final Brand? brand;
  @override
  final String? cpu;
  @override
  final int? ram;
  @override
  final String? storage;
  @override
  final String? gpu;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  final double? screenSize;
  @override
  final String? os;
  @override
  final int? warrantyMonths;
  @override
  @JsonKey()
  final int stockQuantity;
  @override
  @JsonKey()
  final int lowStockThreshold;
  @override
  @JsonKey()
  final bool active;
  @override
  @JsonKey(fromJson: toDouble)
  final double averageRating;
  @override
  @JsonKey()
  final int reviewCount;
  @override
  @JsonKey()
  final int soldCount;
  final List<String> _images;
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Product(id: $id, sku: $sku, name: $name, slug: $slug, description: $description, price: $price, category: $category, brand: $brand, cpu: $cpu, ram: $ram, storage: $storage, gpu: $gpu, screenSize: $screenSize, os: $os, warrantyMonths: $warrantyMonths, stockQuantity: $stockQuantity, lowStockThreshold: $lowStockThreshold, active: $active, averageRating: $averageRating, reviewCount: $reviewCount, soldCount: $soldCount, images: $images, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sku, sku) || other.sku == sku) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.cpu, cpu) || other.cpu == cpu) &&
            (identical(other.ram, ram) || other.ram == ram) &&
            (identical(other.storage, storage) || other.storage == storage) &&
            (identical(other.gpu, gpu) || other.gpu == gpu) &&
            (identical(other.screenSize, screenSize) ||
                other.screenSize == screenSize) &&
            (identical(other.os, os) || other.os == os) &&
            (identical(other.warrantyMonths, warrantyMonths) ||
                other.warrantyMonths == warrantyMonths) &&
            (identical(other.stockQuantity, stockQuantity) ||
                other.stockQuantity == stockQuantity) &&
            (identical(other.lowStockThreshold, lowStockThreshold) ||
                other.lowStockThreshold == lowStockThreshold) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.averageRating, averageRating) ||
                other.averageRating == averageRating) &&
            (identical(other.reviewCount, reviewCount) ||
                other.reviewCount == reviewCount) &&
            (identical(other.soldCount, soldCount) ||
                other.soldCount == soldCount) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    sku,
    name,
    slug,
    description,
    price,
    category,
    brand,
    cpu,
    ram,
    storage,
    gpu,
    screenSize,
    os,
    warrantyMonths,
    stockQuantity,
    lowStockThreshold,
    active,
    averageRating,
    reviewCount,
    soldCount,
    const DeepCollectionEquality().hash(_images),
    createdAt,
  ]);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductImplToJson(this);
  }
}

abstract class _Product extends Product {
  const factory _Product({
    required final int id,
    final String? sku,
    required final String name,
    final String? slug,
    final String? description,
    @JsonKey(fromJson: toDouble) required final double price,
    final Category? category,
    final Brand? brand,
    final String? cpu,
    final int? ram,
    final String? storage,
    final String? gpu,
    @JsonKey(fromJson: toDoubleOrNull) final double? screenSize,
    final String? os,
    final int? warrantyMonths,
    final int stockQuantity,
    final int lowStockThreshold,
    final bool active,
    @JsonKey(fromJson: toDouble) final double averageRating,
    final int reviewCount,
    final int soldCount,
    final List<String> images,
    @JsonKey(fromJson: toDateTimeOrNull) final DateTime? createdAt,
  }) = _$ProductImpl;
  const _Product._() : super._();

  factory _Product.fromJson(Map<String, dynamic> json) = _$ProductImpl.fromJson;

  @override
  int get id;
  @override
  String? get sku;
  @override
  String get name;
  @override
  String? get slug;
  @override
  String? get description;
  @override
  @JsonKey(fromJson: toDouble)
  double get price;
  @override
  Category? get category;
  @override
  Brand? get brand;
  @override
  String? get cpu;
  @override
  int? get ram;
  @override
  String? get storage;
  @override
  String? get gpu;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  double? get screenSize;
  @override
  String? get os;
  @override
  int? get warrantyMonths;
  @override
  int get stockQuantity;
  @override
  int get lowStockThreshold;
  @override
  bool get active;
  @override
  @JsonKey(fromJson: toDouble)
  double get averageRating;
  @override
  int get reviewCount;
  @override
  int get soldCount;
  @override
  List<String> get images;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get createdAt;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ShippingMethodInfo _$ShippingMethodInfoFromJson(Map<String, dynamic> json) {
  return _ShippingMethodInfo.fromJson(json);
}

/// @nodoc
mixin _$ShippingMethodInfo {
  String get code => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get fee => throw _privateConstructorUsedError;
  String? get estimatedDelivery => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDoubleOrNull)
  double? get freeShippingThreshold => throw _privateConstructorUsedError;

  /// Serializes this ShippingMethodInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShippingMethodInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShippingMethodInfoCopyWith<ShippingMethodInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShippingMethodInfoCopyWith<$Res> {
  factory $ShippingMethodInfoCopyWith(
    ShippingMethodInfo value,
    $Res Function(ShippingMethodInfo) then,
  ) = _$ShippingMethodInfoCopyWithImpl<$Res, ShippingMethodInfo>;
  @useResult
  $Res call({
    String code,
    String label,
    @JsonKey(fromJson: toDouble) double fee,
    String? estimatedDelivery,
    @JsonKey(fromJson: toDoubleOrNull) double? freeShippingThreshold,
  });
}

/// @nodoc
class _$ShippingMethodInfoCopyWithImpl<$Res, $Val extends ShippingMethodInfo>
    implements $ShippingMethodInfoCopyWith<$Res> {
  _$ShippingMethodInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShippingMethodInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? label = null,
    Object? fee = null,
    Object? estimatedDelivery = freezed,
    Object? freeShippingThreshold = freezed,
  }) {
    return _then(
      _value.copyWith(
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            fee: null == fee
                ? _value.fee
                : fee // ignore: cast_nullable_to_non_nullable
                      as double,
            estimatedDelivery: freezed == estimatedDelivery
                ? _value.estimatedDelivery
                : estimatedDelivery // ignore: cast_nullable_to_non_nullable
                      as String?,
            freeShippingThreshold: freezed == freeShippingThreshold
                ? _value.freeShippingThreshold
                : freeShippingThreshold // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShippingMethodInfoImplCopyWith<$Res>
    implements $ShippingMethodInfoCopyWith<$Res> {
  factory _$$ShippingMethodInfoImplCopyWith(
    _$ShippingMethodInfoImpl value,
    $Res Function(_$ShippingMethodInfoImpl) then,
  ) = __$$ShippingMethodInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String code,
    String label,
    @JsonKey(fromJson: toDouble) double fee,
    String? estimatedDelivery,
    @JsonKey(fromJson: toDoubleOrNull) double? freeShippingThreshold,
  });
}

/// @nodoc
class __$$ShippingMethodInfoImplCopyWithImpl<$Res>
    extends _$ShippingMethodInfoCopyWithImpl<$Res, _$ShippingMethodInfoImpl>
    implements _$$ShippingMethodInfoImplCopyWith<$Res> {
  __$$ShippingMethodInfoImplCopyWithImpl(
    _$ShippingMethodInfoImpl _value,
    $Res Function(_$ShippingMethodInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShippingMethodInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? label = null,
    Object? fee = null,
    Object? estimatedDelivery = freezed,
    Object? freeShippingThreshold = freezed,
  }) {
    return _then(
      _$ShippingMethodInfoImpl(
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        fee: null == fee
            ? _value.fee
            : fee // ignore: cast_nullable_to_non_nullable
                  as double,
        estimatedDelivery: freezed == estimatedDelivery
            ? _value.estimatedDelivery
            : estimatedDelivery // ignore: cast_nullable_to_non_nullable
                  as String?,
        freeShippingThreshold: freezed == freeShippingThreshold
            ? _value.freeShippingThreshold
            : freeShippingThreshold // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShippingMethodInfoImpl implements _ShippingMethodInfo {
  const _$ShippingMethodInfoImpl({
    required this.code,
    required this.label,
    @JsonKey(fromJson: toDouble) required this.fee,
    this.estimatedDelivery,
    @JsonKey(fromJson: toDoubleOrNull) this.freeShippingThreshold,
  });

  factory _$ShippingMethodInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShippingMethodInfoImplFromJson(json);

  @override
  final String code;
  @override
  final String label;
  @override
  @JsonKey(fromJson: toDouble)
  final double fee;
  @override
  final String? estimatedDelivery;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  final double? freeShippingThreshold;

  @override
  String toString() {
    return 'ShippingMethodInfo(code: $code, label: $label, fee: $fee, estimatedDelivery: $estimatedDelivery, freeShippingThreshold: $freeShippingThreshold)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShippingMethodInfoImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.fee, fee) || other.fee == fee) &&
            (identical(other.estimatedDelivery, estimatedDelivery) ||
                other.estimatedDelivery == estimatedDelivery) &&
            (identical(other.freeShippingThreshold, freeShippingThreshold) ||
                other.freeShippingThreshold == freeShippingThreshold));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    code,
    label,
    fee,
    estimatedDelivery,
    freeShippingThreshold,
  );

  /// Create a copy of ShippingMethodInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShippingMethodInfoImplCopyWith<_$ShippingMethodInfoImpl> get copyWith =>
      __$$ShippingMethodInfoImplCopyWithImpl<_$ShippingMethodInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ShippingMethodInfoImplToJson(this);
  }
}

abstract class _ShippingMethodInfo implements ShippingMethodInfo {
  const factory _ShippingMethodInfo({
    required final String code,
    required final String label,
    @JsonKey(fromJson: toDouble) required final double fee,
    final String? estimatedDelivery,
    @JsonKey(fromJson: toDoubleOrNull) final double? freeShippingThreshold,
  }) = _$ShippingMethodInfoImpl;

  factory _ShippingMethodInfo.fromJson(Map<String, dynamic> json) =
      _$ShippingMethodInfoImpl.fromJson;

  @override
  String get code;
  @override
  String get label;
  @override
  @JsonKey(fromJson: toDouble)
  double get fee;
  @override
  String? get estimatedDelivery;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  double? get freeShippingThreshold;

  /// Create a copy of ShippingMethodInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShippingMethodInfoImplCopyWith<_$ShippingMethodInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Review _$ReviewFromJson(Map<String, dynamic> json) {
  return _Review.fromJson(json);
}

/// @nodoc
mixin _$Review {
  int get id => throw _privateConstructorUsedError;
  int? get productId => throw _privateConstructorUsedError;
  String? get productName => throw _privateConstructorUsedError;
  int? get userId => throw _privateConstructorUsedError;
  String? get userName => throw _privateConstructorUsedError;
  int get rating => throw _privateConstructorUsedError;
  String? get comment => throw _privateConstructorUsedError;
  bool get verifiedPurchase => throw _privateConstructorUsedError;
  bool get visible => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Review to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Review
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReviewCopyWith<Review> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReviewCopyWith<$Res> {
  factory $ReviewCopyWith(Review value, $Res Function(Review) then) =
      _$ReviewCopyWithImpl<$Res, Review>;
  @useResult
  $Res call({
    int id,
    int? productId,
    String? productName,
    int? userId,
    String? userName,
    int rating,
    String? comment,
    bool verifiedPurchase,
    bool visible,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
  });
}

/// @nodoc
class _$ReviewCopyWithImpl<$Res, $Val extends Review>
    implements $ReviewCopyWith<$Res> {
  _$ReviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Review
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = freezed,
    Object? productName = freezed,
    Object? userId = freezed,
    Object? userName = freezed,
    Object? rating = null,
    Object? comment = freezed,
    Object? verifiedPurchase = null,
    Object? visible = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            productId: freezed == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as int?,
            productName: freezed == productName
                ? _value.productName
                : productName // ignore: cast_nullable_to_non_nullable
                      as String?,
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int?,
            userName: freezed == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String?,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as int,
            comment: freezed == comment
                ? _value.comment
                : comment // ignore: cast_nullable_to_non_nullable
                      as String?,
            verifiedPurchase: null == verifiedPurchase
                ? _value.verifiedPurchase
                : verifiedPurchase // ignore: cast_nullable_to_non_nullable
                      as bool,
            visible: null == visible
                ? _value.visible
                : visible // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReviewImplCopyWith<$Res> implements $ReviewCopyWith<$Res> {
  factory _$$ReviewImplCopyWith(
    _$ReviewImpl value,
    $Res Function(_$ReviewImpl) then,
  ) = __$$ReviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int? productId,
    String? productName,
    int? userId,
    String? userName,
    int rating,
    String? comment,
    bool verifiedPurchase,
    bool visible,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
  });
}

/// @nodoc
class __$$ReviewImplCopyWithImpl<$Res>
    extends _$ReviewCopyWithImpl<$Res, _$ReviewImpl>
    implements _$$ReviewImplCopyWith<$Res> {
  __$$ReviewImplCopyWithImpl(
    _$ReviewImpl _value,
    $Res Function(_$ReviewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Review
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = freezed,
    Object? productName = freezed,
    Object? userId = freezed,
    Object? userName = freezed,
    Object? rating = null,
    Object? comment = freezed,
    Object? verifiedPurchase = null,
    Object? visible = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$ReviewImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        productId: freezed == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as int?,
        productName: freezed == productName
            ? _value.productName
            : productName // ignore: cast_nullable_to_non_nullable
                  as String?,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int?,
        userName: freezed == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String?,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as int,
        comment: freezed == comment
            ? _value.comment
            : comment // ignore: cast_nullable_to_non_nullable
                  as String?,
        verifiedPurchase: null == verifiedPurchase
            ? _value.verifiedPurchase
            : verifiedPurchase // ignore: cast_nullable_to_non_nullable
                  as bool,
        visible: null == visible
            ? _value.visible
            : visible // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReviewImpl implements _Review {
  const _$ReviewImpl({
    required this.id,
    this.productId,
    this.productName,
    this.userId,
    this.userName,
    required this.rating,
    this.comment,
    this.verifiedPurchase = false,
    this.visible = true,
    @JsonKey(fromJson: toDateTimeOrNull) this.createdAt,
  });

  factory _$ReviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReviewImplFromJson(json);

  @override
  final int id;
  @override
  final int? productId;
  @override
  final String? productName;
  @override
  final int? userId;
  @override
  final String? userName;
  @override
  final int rating;
  @override
  final String? comment;
  @override
  @JsonKey()
  final bool verifiedPurchase;
  @override
  @JsonKey()
  final bool visible;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Review(id: $id, productId: $productId, productName: $productName, userId: $userId, userName: $userName, rating: $rating, comment: $comment, verifiedPurchase: $verifiedPurchase, visible: $visible, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReviewImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.verifiedPurchase, verifiedPurchase) ||
                other.verifiedPurchase == verifiedPurchase) &&
            (identical(other.visible, visible) || other.visible == visible) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    productId,
    productName,
    userId,
    userName,
    rating,
    comment,
    verifiedPurchase,
    visible,
    createdAt,
  );

  /// Create a copy of Review
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReviewImplCopyWith<_$ReviewImpl> get copyWith =>
      __$$ReviewImplCopyWithImpl<_$ReviewImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReviewImplToJson(this);
  }
}

abstract class _Review implements Review {
  const factory _Review({
    required final int id,
    final int? productId,
    final String? productName,
    final int? userId,
    final String? userName,
    required final int rating,
    final String? comment,
    final bool verifiedPurchase,
    final bool visible,
    @JsonKey(fromJson: toDateTimeOrNull) final DateTime? createdAt,
  }) = _$ReviewImpl;

  factory _Review.fromJson(Map<String, dynamic> json) = _$ReviewImpl.fromJson;

  @override
  int get id;
  @override
  int? get productId;
  @override
  String? get productName;
  @override
  int? get userId;
  @override
  String? get userName;
  @override
  int get rating;
  @override
  String? get comment;
  @override
  bool get verifiedPurchase;
  @override
  bool get visible;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get createdAt;

  /// Create a copy of Review
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReviewImplCopyWith<_$ReviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
