// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CartItem _$CartItemFromJson(Map<String, dynamic> json) {
  return _CartItem.fromJson(json);
}

/// @nodoc
mixin _$CartItem {
  int get id => throw _privateConstructorUsedError;
  int get productId => throw _privateConstructorUsedError;
  String get productName => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get unitPrice => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get lineTotal => throw _privateConstructorUsedError;
  int get stockQuantity => throw _privateConstructorUsedError;

  /// Serializes this CartItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CartItemCopyWith<CartItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartItemCopyWith<$Res> {
  factory $CartItemCopyWith(CartItem value, $Res Function(CartItem) then) =
      _$CartItemCopyWithImpl<$Res, CartItem>;
  @useResult
  $Res call({
    int id,
    int productId,
    String productName,
    String? imageUrl,
    @JsonKey(fromJson: toDouble) double unitPrice,
    int quantity,
    @JsonKey(fromJson: toDouble) double lineTotal,
    int stockQuantity,
  });
}

/// @nodoc
class _$CartItemCopyWithImpl<$Res, $Val extends CartItem>
    implements $CartItemCopyWith<$Res> {
  _$CartItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? productName = null,
    Object? imageUrl = freezed,
    Object? unitPrice = null,
    Object? quantity = null,
    Object? lineTotal = null,
    Object? stockQuantity = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as int,
            productName: null == productName
                ? _value.productName
                : productName // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            unitPrice: null == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            lineTotal: null == lineTotal
                ? _value.lineTotal
                : lineTotal // ignore: cast_nullable_to_non_nullable
                      as double,
            stockQuantity: null == stockQuantity
                ? _value.stockQuantity
                : stockQuantity // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CartItemImplCopyWith<$Res>
    implements $CartItemCopyWith<$Res> {
  factory _$$CartItemImplCopyWith(
    _$CartItemImpl value,
    $Res Function(_$CartItemImpl) then,
  ) = __$$CartItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int productId,
    String productName,
    String? imageUrl,
    @JsonKey(fromJson: toDouble) double unitPrice,
    int quantity,
    @JsonKey(fromJson: toDouble) double lineTotal,
    int stockQuantity,
  });
}

/// @nodoc
class __$$CartItemImplCopyWithImpl<$Res>
    extends _$CartItemCopyWithImpl<$Res, _$CartItemImpl>
    implements _$$CartItemImplCopyWith<$Res> {
  __$$CartItemImplCopyWithImpl(
    _$CartItemImpl _value,
    $Res Function(_$CartItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? productName = null,
    Object? imageUrl = freezed,
    Object? unitPrice = null,
    Object? quantity = null,
    Object? lineTotal = null,
    Object? stockQuantity = null,
  }) {
    return _then(
      _$CartItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as int,
        productName: null == productName
            ? _value.productName
            : productName // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        unitPrice: null == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        lineTotal: null == lineTotal
            ? _value.lineTotal
            : lineTotal // ignore: cast_nullable_to_non_nullable
                  as double,
        stockQuantity: null == stockQuantity
            ? _value.stockQuantity
            : stockQuantity // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CartItemImpl implements _CartItem {
  const _$CartItemImpl({
    required this.id,
    required this.productId,
    required this.productName,
    this.imageUrl,
    @JsonKey(fromJson: toDouble) required this.unitPrice,
    required this.quantity,
    @JsonKey(fromJson: toDouble) required this.lineTotal,
    this.stockQuantity = 0,
  });

  factory _$CartItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$CartItemImplFromJson(json);

  @override
  final int id;
  @override
  final int productId;
  @override
  final String productName;
  @override
  final String? imageUrl;
  @override
  @JsonKey(fromJson: toDouble)
  final double unitPrice;
  @override
  final int quantity;
  @override
  @JsonKey(fromJson: toDouble)
  final double lineTotal;
  @override
  @JsonKey()
  final int stockQuantity;

  @override
  String toString() {
    return 'CartItem(id: $id, productId: $productId, productName: $productName, imageUrl: $imageUrl, unitPrice: $unitPrice, quantity: $quantity, lineTotal: $lineTotal, stockQuantity: $stockQuantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CartItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.lineTotal, lineTotal) ||
                other.lineTotal == lineTotal) &&
            (identical(other.stockQuantity, stockQuantity) ||
                other.stockQuantity == stockQuantity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    productId,
    productName,
    imageUrl,
    unitPrice,
    quantity,
    lineTotal,
    stockQuantity,
  );

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CartItemImplCopyWith<_$CartItemImpl> get copyWith =>
      __$$CartItemImplCopyWithImpl<_$CartItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CartItemImplToJson(this);
  }
}

abstract class _CartItem implements CartItem {
  const factory _CartItem({
    required final int id,
    required final int productId,
    required final String productName,
    final String? imageUrl,
    @JsonKey(fromJson: toDouble) required final double unitPrice,
    required final int quantity,
    @JsonKey(fromJson: toDouble) required final double lineTotal,
    final int stockQuantity,
  }) = _$CartItemImpl;

  factory _CartItem.fromJson(Map<String, dynamic> json) =
      _$CartItemImpl.fromJson;

  @override
  int get id;
  @override
  int get productId;
  @override
  String get productName;
  @override
  String? get imageUrl;
  @override
  @JsonKey(fromJson: toDouble)
  double get unitPrice;
  @override
  int get quantity;
  @override
  @JsonKey(fromJson: toDouble)
  double get lineTotal;
  @override
  int get stockQuantity;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CartItemImplCopyWith<_$CartItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Cart _$CartFromJson(Map<String, dynamic> json) {
  return _Cart.fromJson(json);
}

/// @nodoc
mixin _$Cart {
  int? get id => throw _privateConstructorUsedError;
  List<CartItem> get items => throw _privateConstructorUsedError;
  int get totalItems => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get subtotal => throw _privateConstructorUsedError;

  /// Serializes this Cart to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CartCopyWith<Cart> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartCopyWith<$Res> {
  factory $CartCopyWith(Cart value, $Res Function(Cart) then) =
      _$CartCopyWithImpl<$Res, Cart>;
  @useResult
  $Res call({
    int? id,
    List<CartItem> items,
    int totalItems,
    @JsonKey(fromJson: toDouble) double subtotal,
  });
}

/// @nodoc
class _$CartCopyWithImpl<$Res, $Val extends Cart>
    implements $CartCopyWith<$Res> {
  _$CartCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? items = null,
    Object? totalItems = null,
    Object? subtotal = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<CartItem>,
            totalItems: null == totalItems
                ? _value.totalItems
                : totalItems // ignore: cast_nullable_to_non_nullable
                      as int,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CartImplCopyWith<$Res> implements $CartCopyWith<$Res> {
  factory _$$CartImplCopyWith(
    _$CartImpl value,
    $Res Function(_$CartImpl) then,
  ) = __$$CartImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    List<CartItem> items,
    int totalItems,
    @JsonKey(fromJson: toDouble) double subtotal,
  });
}

/// @nodoc
class __$$CartImplCopyWithImpl<$Res>
    extends _$CartCopyWithImpl<$Res, _$CartImpl>
    implements _$$CartImplCopyWith<$Res> {
  __$$CartImplCopyWithImpl(_$CartImpl _value, $Res Function(_$CartImpl) _then)
    : super(_value, _then);

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? items = null,
    Object? totalItems = null,
    Object? subtotal = null,
  }) {
    return _then(
      _$CartImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<CartItem>,
        totalItems: null == totalItems
            ? _value.totalItems
            : totalItems // ignore: cast_nullable_to_non_nullable
                  as int,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CartImpl implements _Cart {
  const _$CartImpl({
    this.id,
    final List<CartItem> items = const <CartItem>[],
    this.totalItems = 0,
    @JsonKey(fromJson: toDouble) this.subtotal = 0,
  }) : _items = items;

  factory _$CartImpl.fromJson(Map<String, dynamic> json) =>
      _$$CartImplFromJson(json);

  @override
  final int? id;
  final List<CartItem> _items;
  @override
  @JsonKey()
  List<CartItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final int totalItems;
  @override
  @JsonKey(fromJson: toDouble)
  final double subtotal;

  @override
  String toString() {
    return 'Cart(id: $id, items: $items, totalItems: $totalItems, subtotal: $subtotal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CartImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.totalItems, totalItems) ||
                other.totalItems == totalItems) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    const DeepCollectionEquality().hash(_items),
    totalItems,
    subtotal,
  );

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CartImplCopyWith<_$CartImpl> get copyWith =>
      __$$CartImplCopyWithImpl<_$CartImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CartImplToJson(this);
  }
}

abstract class _Cart implements Cart {
  const factory _Cart({
    final int? id,
    final List<CartItem> items,
    final int totalItems,
    @JsonKey(fromJson: toDouble) final double subtotal,
  }) = _$CartImpl;

  factory _Cart.fromJson(Map<String, dynamic> json) = _$CartImpl.fromJson;

  @override
  int? get id;
  @override
  List<CartItem> get items;
  @override
  int get totalItems;
  @override
  @JsonKey(fromJson: toDouble)
  double get subtotal;

  /// Create a copy of Cart
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CartImplCopyWith<_$CartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CouponPreview _$CouponPreviewFromJson(Map<String, dynamic> json) {
  return _CouponPreview.fromJson(json);
}

/// @nodoc
mixin _$CouponPreview {
  String get couponCode => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get subtotal => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get discount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get shippingFee => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get total => throw _privateConstructorUsedError;

  /// Serializes this CouponPreview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CouponPreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CouponPreviewCopyWith<CouponPreview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CouponPreviewCopyWith<$Res> {
  factory $CouponPreviewCopyWith(
    CouponPreview value,
    $Res Function(CouponPreview) then,
  ) = _$CouponPreviewCopyWithImpl<$Res, CouponPreview>;
  @useResult
  $Res call({
    String couponCode,
    @JsonKey(fromJson: toDouble) double subtotal,
    @JsonKey(fromJson: toDouble) double discount,
    @JsonKey(fromJson: toDouble) double shippingFee,
    @JsonKey(fromJson: toDouble) double total,
  });
}

/// @nodoc
class _$CouponPreviewCopyWithImpl<$Res, $Val extends CouponPreview>
    implements $CouponPreviewCopyWith<$Res> {
  _$CouponPreviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CouponPreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? couponCode = null,
    Object? subtotal = null,
    Object? discount = null,
    Object? shippingFee = null,
    Object? total = null,
  }) {
    return _then(
      _value.copyWith(
            couponCode: null == couponCode
                ? _value.couponCode
                : couponCode // ignore: cast_nullable_to_non_nullable
                      as String,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as double,
            discount: null == discount
                ? _value.discount
                : discount // ignore: cast_nullable_to_non_nullable
                      as double,
            shippingFee: null == shippingFee
                ? _value.shippingFee
                : shippingFee // ignore: cast_nullable_to_non_nullable
                      as double,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CouponPreviewImplCopyWith<$Res>
    implements $CouponPreviewCopyWith<$Res> {
  factory _$$CouponPreviewImplCopyWith(
    _$CouponPreviewImpl value,
    $Res Function(_$CouponPreviewImpl) then,
  ) = __$$CouponPreviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String couponCode,
    @JsonKey(fromJson: toDouble) double subtotal,
    @JsonKey(fromJson: toDouble) double discount,
    @JsonKey(fromJson: toDouble) double shippingFee,
    @JsonKey(fromJson: toDouble) double total,
  });
}

/// @nodoc
class __$$CouponPreviewImplCopyWithImpl<$Res>
    extends _$CouponPreviewCopyWithImpl<$Res, _$CouponPreviewImpl>
    implements _$$CouponPreviewImplCopyWith<$Res> {
  __$$CouponPreviewImplCopyWithImpl(
    _$CouponPreviewImpl _value,
    $Res Function(_$CouponPreviewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CouponPreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? couponCode = null,
    Object? subtotal = null,
    Object? discount = null,
    Object? shippingFee = null,
    Object? total = null,
  }) {
    return _then(
      _$CouponPreviewImpl(
        couponCode: null == couponCode
            ? _value.couponCode
            : couponCode // ignore: cast_nullable_to_non_nullable
                  as String,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as double,
        discount: null == discount
            ? _value.discount
            : discount // ignore: cast_nullable_to_non_nullable
                  as double,
        shippingFee: null == shippingFee
            ? _value.shippingFee
            : shippingFee // ignore: cast_nullable_to_non_nullable
                  as double,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CouponPreviewImpl implements _CouponPreview {
  const _$CouponPreviewImpl({
    required this.couponCode,
    @JsonKey(fromJson: toDouble) required this.subtotal,
    @JsonKey(fromJson: toDouble) required this.discount,
    @JsonKey(fromJson: toDouble) required this.shippingFee,
    @JsonKey(fromJson: toDouble) required this.total,
  });

  factory _$CouponPreviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$CouponPreviewImplFromJson(json);

  @override
  final String couponCode;
  @override
  @JsonKey(fromJson: toDouble)
  final double subtotal;
  @override
  @JsonKey(fromJson: toDouble)
  final double discount;
  @override
  @JsonKey(fromJson: toDouble)
  final double shippingFee;
  @override
  @JsonKey(fromJson: toDouble)
  final double total;

  @override
  String toString() {
    return 'CouponPreview(couponCode: $couponCode, subtotal: $subtotal, discount: $discount, shippingFee: $shippingFee, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CouponPreviewImpl &&
            (identical(other.couponCode, couponCode) ||
                other.couponCode == couponCode) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            (identical(other.shippingFee, shippingFee) ||
                other.shippingFee == shippingFee) &&
            (identical(other.total, total) || other.total == total));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    couponCode,
    subtotal,
    discount,
    shippingFee,
    total,
  );

  /// Create a copy of CouponPreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CouponPreviewImplCopyWith<_$CouponPreviewImpl> get copyWith =>
      __$$CouponPreviewImplCopyWithImpl<_$CouponPreviewImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CouponPreviewImplToJson(this);
  }
}

abstract class _CouponPreview implements CouponPreview {
  const factory _CouponPreview({
    required final String couponCode,
    @JsonKey(fromJson: toDouble) required final double subtotal,
    @JsonKey(fromJson: toDouble) required final double discount,
    @JsonKey(fromJson: toDouble) required final double shippingFee,
    @JsonKey(fromJson: toDouble) required final double total,
  }) = _$CouponPreviewImpl;

  factory _CouponPreview.fromJson(Map<String, dynamic> json) =
      _$CouponPreviewImpl.fromJson;

  @override
  String get couponCode;
  @override
  @JsonKey(fromJson: toDouble)
  double get subtotal;
  @override
  @JsonKey(fromJson: toDouble)
  double get discount;
  @override
  @JsonKey(fromJson: toDouble)
  double get shippingFee;
  @override
  @JsonKey(fromJson: toDouble)
  double get total;

  /// Create a copy of CouponPreview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CouponPreviewImplCopyWith<_$CouponPreviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
