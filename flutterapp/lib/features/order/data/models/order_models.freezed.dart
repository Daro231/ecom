// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) {
  return _OrderItem.fromJson(json);
}

/// @nodoc
mixin _$OrderItem {
  int get id => throw _privateConstructorUsedError;
  int get productId => throw _privateConstructorUsedError;
  String get productName => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get unitPrice => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get lineTotal => throw _privateConstructorUsedError;

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderItemCopyWith<OrderItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemCopyWith<$Res> {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) then) =
      _$OrderItemCopyWithImpl<$Res, OrderItem>;
  @useResult
  $Res call({
    int id,
    int productId,
    String productName,
    @JsonKey(fromJson: toDouble) double unitPrice,
    int quantity,
    @JsonKey(fromJson: toDouble) double lineTotal,
  });
}

/// @nodoc
class _$OrderItemCopyWithImpl<$Res, $Val extends OrderItem>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? productName = null,
    Object? unitPrice = null,
    Object? quantity = null,
    Object? lineTotal = null,
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrderItemImplCopyWith<$Res>
    implements $OrderItemCopyWith<$Res> {
  factory _$$OrderItemImplCopyWith(
    _$OrderItemImpl value,
    $Res Function(_$OrderItemImpl) then,
  ) = __$$OrderItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int productId,
    String productName,
    @JsonKey(fromJson: toDouble) double unitPrice,
    int quantity,
    @JsonKey(fromJson: toDouble) double lineTotal,
  });
}

/// @nodoc
class __$$OrderItemImplCopyWithImpl<$Res>
    extends _$OrderItemCopyWithImpl<$Res, _$OrderItemImpl>
    implements _$$OrderItemImplCopyWith<$Res> {
  __$$OrderItemImplCopyWithImpl(
    _$OrderItemImpl _value,
    $Res Function(_$OrderItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? productId = null,
    Object? productName = null,
    Object? unitPrice = null,
    Object? quantity = null,
    Object? lineTotal = null,
  }) {
    return _then(
      _$OrderItemImpl(
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderItemImpl implements _OrderItem {
  const _$OrderItemImpl({
    required this.id,
    required this.productId,
    required this.productName,
    @JsonKey(fromJson: toDouble) required this.unitPrice,
    required this.quantity,
    @JsonKey(fromJson: toDouble) required this.lineTotal,
  });

  factory _$OrderItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemImplFromJson(json);

  @override
  final int id;
  @override
  final int productId;
  @override
  final String productName;
  @override
  @JsonKey(fromJson: toDouble)
  final double unitPrice;
  @override
  final int quantity;
  @override
  @JsonKey(fromJson: toDouble)
  final double lineTotal;

  @override
  String toString() {
    return 'OrderItem(id: $id, productId: $productId, productName: $productName, unitPrice: $unitPrice, quantity: $quantity, lineTotal: $lineTotal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.lineTotal, lineTotal) ||
                other.lineTotal == lineTotal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    productId,
    productName,
    unitPrice,
    quantity,
    lineTotal,
  );

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      __$$OrderItemImplCopyWithImpl<_$OrderItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemImplToJson(this);
  }
}

abstract class _OrderItem implements OrderItem {
  const factory _OrderItem({
    required final int id,
    required final int productId,
    required final String productName,
    @JsonKey(fromJson: toDouble) required final double unitPrice,
    required final int quantity,
    @JsonKey(fromJson: toDouble) required final double lineTotal,
  }) = _$OrderItemImpl;

  factory _OrderItem.fromJson(Map<String, dynamic> json) =
      _$OrderItemImpl.fromJson;

  @override
  int get id;
  @override
  int get productId;
  @override
  String get productName;
  @override
  @JsonKey(fromJson: toDouble)
  double get unitPrice;
  @override
  int get quantity;
  @override
  @JsonKey(fromJson: toDouble)
  double get lineTotal;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Payment _$PaymentFromJson(Map<String, dynamic> json) {
  return _Payment.fromJson(json);
}

/// @nodoc
mixin _$Payment {
  int get id => throw _privateConstructorUsedError;
  String get orderNumber => throw _privateConstructorUsedError;
  String get method => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get amount => throw _privateConstructorUsedError;
  String? get transactionRef => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get paidAt => throw _privateConstructorUsedError;
  String? get failureReason => throw _privateConstructorUsedError;

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentCopyWith<Payment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) then) =
      _$PaymentCopyWithImpl<$Res, Payment>;
  @useResult
  $Res call({
    int id,
    String orderNumber,
    String method,
    String status,
    @JsonKey(fromJson: toDouble) double amount,
    String? transactionRef,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? paidAt,
    String? failureReason,
  });
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res, $Val extends Payment>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = null,
    Object? method = null,
    Object? status = null,
    Object? amount = null,
    Object? transactionRef = freezed,
    Object? paidAt = freezed,
    Object? failureReason = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            orderNumber: null == orderNumber
                ? _value.orderNumber
                : orderNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            transactionRef: freezed == transactionRef
                ? _value.transactionRef
                : transactionRef // ignore: cast_nullable_to_non_nullable
                      as String?,
            paidAt: freezed == paidAt
                ? _value.paidAt
                : paidAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            failureReason: freezed == failureReason
                ? _value.failureReason
                : failureReason // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaymentImplCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$$PaymentImplCopyWith(
    _$PaymentImpl value,
    $Res Function(_$PaymentImpl) then,
  ) = __$$PaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String orderNumber,
    String method,
    String status,
    @JsonKey(fromJson: toDouble) double amount,
    String? transactionRef,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? paidAt,
    String? failureReason,
  });
}

/// @nodoc
class __$$PaymentImplCopyWithImpl<$Res>
    extends _$PaymentCopyWithImpl<$Res, _$PaymentImpl>
    implements _$$PaymentImplCopyWith<$Res> {
  __$$PaymentImplCopyWithImpl(
    _$PaymentImpl _value,
    $Res Function(_$PaymentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = null,
    Object? method = null,
    Object? status = null,
    Object? amount = null,
    Object? transactionRef = freezed,
    Object? paidAt = freezed,
    Object? failureReason = freezed,
  }) {
    return _then(
      _$PaymentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        orderNumber: null == orderNumber
            ? _value.orderNumber
            : orderNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        transactionRef: freezed == transactionRef
            ? _value.transactionRef
            : transactionRef // ignore: cast_nullable_to_non_nullable
                  as String?,
        paidAt: freezed == paidAt
            ? _value.paidAt
            : paidAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        failureReason: freezed == failureReason
            ? _value.failureReason
            : failureReason // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentImpl extends _Payment {
  const _$PaymentImpl({
    required this.id,
    required this.orderNumber,
    required this.method,
    required this.status,
    @JsonKey(fromJson: toDouble) required this.amount,
    this.transactionRef,
    @JsonKey(fromJson: toDateTimeOrNull) this.paidAt,
    this.failureReason,
  }) : super._();

  factory _$PaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentImplFromJson(json);

  @override
  final int id;
  @override
  final String orderNumber;
  @override
  final String method;
  @override
  final String status;
  @override
  @JsonKey(fromJson: toDouble)
  final double amount;
  @override
  final String? transactionRef;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  final DateTime? paidAt;
  @override
  final String? failureReason;

  @override
  String toString() {
    return 'Payment(id: $id, orderNumber: $orderNumber, method: $method, status: $status, amount: $amount, transactionRef: $transactionRef, paidAt: $paidAt, failureReason: $failureReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.transactionRef, transactionRef) ||
                other.transactionRef == transactionRef) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    orderNumber,
    method,
    status,
    amount,
    transactionRef,
    paidAt,
    failureReason,
  );

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      __$$PaymentImplCopyWithImpl<_$PaymentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentImplToJson(this);
  }
}

abstract class _Payment extends Payment {
  const factory _Payment({
    required final int id,
    required final String orderNumber,
    required final String method,
    required final String status,
    @JsonKey(fromJson: toDouble) required final double amount,
    final String? transactionRef,
    @JsonKey(fromJson: toDateTimeOrNull) final DateTime? paidAt,
    final String? failureReason,
  }) = _$PaymentImpl;
  const _Payment._() : super._();

  factory _Payment.fromJson(Map<String, dynamic> json) = _$PaymentImpl.fromJson;

  @override
  int get id;
  @override
  String get orderNumber;
  @override
  String get method;
  @override
  String get status;
  @override
  @JsonKey(fromJson: toDouble)
  double get amount;
  @override
  String? get transactionRef;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get paidAt;
  @override
  String? get failureReason;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Shipment _$ShipmentFromJson(Map<String, dynamic> json) {
  return _Shipment.fromJson(json);
}

/// @nodoc
mixin _$Shipment {
  int get id => throw _privateConstructorUsedError;
  String? get orderNumber => throw _privateConstructorUsedError;
  String? get method => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get fee => throw _privateConstructorUsedError;
  String? get trackingNumber => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get shippedAt => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get deliveredAt => throw _privateConstructorUsedError;

  /// Serializes this Shipment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Shipment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShipmentCopyWith<Shipment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShipmentCopyWith<$Res> {
  factory $ShipmentCopyWith(Shipment value, $Res Function(Shipment) then) =
      _$ShipmentCopyWithImpl<$Res, Shipment>;
  @useResult
  $Res call({
    int id,
    String? orderNumber,
    String? method,
    @JsonKey(fromJson: toDouble) double fee,
    String? trackingNumber,
    String status,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? shippedAt,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? deliveredAt,
  });
}

/// @nodoc
class _$ShipmentCopyWithImpl<$Res, $Val extends Shipment>
    implements $ShipmentCopyWith<$Res> {
  _$ShipmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Shipment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = freezed,
    Object? method = freezed,
    Object? fee = null,
    Object? trackingNumber = freezed,
    Object? status = null,
    Object? shippedAt = freezed,
    Object? deliveredAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            orderNumber: freezed == orderNumber
                ? _value.orderNumber
                : orderNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            method: freezed == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String?,
            fee: null == fee
                ? _value.fee
                : fee // ignore: cast_nullable_to_non_nullable
                      as double,
            trackingNumber: freezed == trackingNumber
                ? _value.trackingNumber
                : trackingNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            shippedAt: freezed == shippedAt
                ? _value.shippedAt
                : shippedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            deliveredAt: freezed == deliveredAt
                ? _value.deliveredAt
                : deliveredAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShipmentImplCopyWith<$Res>
    implements $ShipmentCopyWith<$Res> {
  factory _$$ShipmentImplCopyWith(
    _$ShipmentImpl value,
    $Res Function(_$ShipmentImpl) then,
  ) = __$$ShipmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String? orderNumber,
    String? method,
    @JsonKey(fromJson: toDouble) double fee,
    String? trackingNumber,
    String status,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? shippedAt,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? deliveredAt,
  });
}

/// @nodoc
class __$$ShipmentImplCopyWithImpl<$Res>
    extends _$ShipmentCopyWithImpl<$Res, _$ShipmentImpl>
    implements _$$ShipmentImplCopyWith<$Res> {
  __$$ShipmentImplCopyWithImpl(
    _$ShipmentImpl _value,
    $Res Function(_$ShipmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Shipment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = freezed,
    Object? method = freezed,
    Object? fee = null,
    Object? trackingNumber = freezed,
    Object? status = null,
    Object? shippedAt = freezed,
    Object? deliveredAt = freezed,
  }) {
    return _then(
      _$ShipmentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        orderNumber: freezed == orderNumber
            ? _value.orderNumber
            : orderNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        method: freezed == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String?,
        fee: null == fee
            ? _value.fee
            : fee // ignore: cast_nullable_to_non_nullable
                  as double,
        trackingNumber: freezed == trackingNumber
            ? _value.trackingNumber
            : trackingNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        shippedAt: freezed == shippedAt
            ? _value.shippedAt
            : shippedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        deliveredAt: freezed == deliveredAt
            ? _value.deliveredAt
            : deliveredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShipmentImpl implements _Shipment {
  const _$ShipmentImpl({
    required this.id,
    this.orderNumber,
    this.method,
    @JsonKey(fromJson: toDouble) this.fee = 0,
    this.trackingNumber,
    required this.status,
    @JsonKey(fromJson: toDateTimeOrNull) this.shippedAt,
    @JsonKey(fromJson: toDateTimeOrNull) this.deliveredAt,
  });

  factory _$ShipmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShipmentImplFromJson(json);

  @override
  final int id;
  @override
  final String? orderNumber;
  @override
  final String? method;
  @override
  @JsonKey(fromJson: toDouble)
  final double fee;
  @override
  final String? trackingNumber;
  @override
  final String status;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  final DateTime? shippedAt;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  final DateTime? deliveredAt;

  @override
  String toString() {
    return 'Shipment(id: $id, orderNumber: $orderNumber, method: $method, fee: $fee, trackingNumber: $trackingNumber, status: $status, shippedAt: $shippedAt, deliveredAt: $deliveredAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShipmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.fee, fee) || other.fee == fee) &&
            (identical(other.trackingNumber, trackingNumber) ||
                other.trackingNumber == trackingNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.shippedAt, shippedAt) ||
                other.shippedAt == shippedAt) &&
            (identical(other.deliveredAt, deliveredAt) ||
                other.deliveredAt == deliveredAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    orderNumber,
    method,
    fee,
    trackingNumber,
    status,
    shippedAt,
    deliveredAt,
  );

  /// Create a copy of Shipment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShipmentImplCopyWith<_$ShipmentImpl> get copyWith =>
      __$$ShipmentImplCopyWithImpl<_$ShipmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShipmentImplToJson(this);
  }
}

abstract class _Shipment implements Shipment {
  const factory _Shipment({
    required final int id,
    final String? orderNumber,
    final String? method,
    @JsonKey(fromJson: toDouble) final double fee,
    final String? trackingNumber,
    required final String status,
    @JsonKey(fromJson: toDateTimeOrNull) final DateTime? shippedAt,
    @JsonKey(fromJson: toDateTimeOrNull) final DateTime? deliveredAt,
  }) = _$ShipmentImpl;

  factory _Shipment.fromJson(Map<String, dynamic> json) =
      _$ShipmentImpl.fromJson;

  @override
  int get id;
  @override
  String? get orderNumber;
  @override
  String? get method;
  @override
  @JsonKey(fromJson: toDouble)
  double get fee;
  @override
  String? get trackingNumber;
  @override
  String get status;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get shippedAt;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get deliveredAt;

  /// Create a copy of Shipment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShipmentImplCopyWith<_$ShipmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Order _$OrderFromJson(Map<String, dynamic> json) {
  return _Order.fromJson(json);
}

/// @nodoc
mixin _$Order {
  int get id => throw _privateConstructorUsedError;
  String get orderNumber => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get subtotal => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get discountAmount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get shippingFee => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get total => throw _privateConstructorUsedError;
  String? get couponCode => throw _privateConstructorUsedError;
  String? get receiverName => throw _privateConstructorUsedError;
  String? get receiverPhone => throw _privateConstructorUsedError;
  String? get shippingAddress => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDoubleOrNull)
  double? get deliveryLatitude => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDoubleOrNull)
  double? get deliveryLongitude => throw _privateConstructorUsedError;
  String? get shippingMethod => throw _privateConstructorUsedError;
  String? get paymentMethod => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  String? get cancelledReason => throw _privateConstructorUsedError;
  String? get customerEmail => throw _privateConstructorUsedError;
  List<OrderItem> get items => throw _privateConstructorUsedError;
  Payment? get payment => throw _privateConstructorUsedError;
  Shipment? get shipment => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderCopyWith<Order> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderCopyWith<$Res> {
  factory $OrderCopyWith(Order value, $Res Function(Order) then) =
      _$OrderCopyWithImpl<$Res, Order>;
  @useResult
  $Res call({
    int id,
    String orderNumber,
    String status,
    @JsonKey(fromJson: toDouble) double subtotal,
    @JsonKey(fromJson: toDouble) double discountAmount,
    @JsonKey(fromJson: toDouble) double shippingFee,
    @JsonKey(fromJson: toDouble) double total,
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
    List<OrderItem> items,
    Payment? payment,
    Shipment? shipment,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
  });

  $PaymentCopyWith<$Res>? get payment;
  $ShipmentCopyWith<$Res>? get shipment;
}

/// @nodoc
class _$OrderCopyWithImpl<$Res, $Val extends Order>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = null,
    Object? status = null,
    Object? subtotal = null,
    Object? discountAmount = null,
    Object? shippingFee = null,
    Object? total = null,
    Object? couponCode = freezed,
    Object? receiverName = freezed,
    Object? receiverPhone = freezed,
    Object? shippingAddress = freezed,
    Object? deliveryLatitude = freezed,
    Object? deliveryLongitude = freezed,
    Object? shippingMethod = freezed,
    Object? paymentMethod = freezed,
    Object? note = freezed,
    Object? cancelledReason = freezed,
    Object? customerEmail = freezed,
    Object? items = null,
    Object? payment = freezed,
    Object? shipment = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            orderNumber: null == orderNumber
                ? _value.orderNumber
                : orderNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as double,
            discountAmount: null == discountAmount
                ? _value.discountAmount
                : discountAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            shippingFee: null == shippingFee
                ? _value.shippingFee
                : shippingFee // ignore: cast_nullable_to_non_nullable
                      as double,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as double,
            couponCode: freezed == couponCode
                ? _value.couponCode
                : couponCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            receiverName: freezed == receiverName
                ? _value.receiverName
                : receiverName // ignore: cast_nullable_to_non_nullable
                      as String?,
            receiverPhone: freezed == receiverPhone
                ? _value.receiverPhone
                : receiverPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingAddress: freezed == shippingAddress
                ? _value.shippingAddress
                : shippingAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            deliveryLatitude: freezed == deliveryLatitude
                ? _value.deliveryLatitude
                : deliveryLatitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            deliveryLongitude: freezed == deliveryLongitude
                ? _value.deliveryLongitude
                : deliveryLongitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            shippingMethod: freezed == shippingMethod
                ? _value.shippingMethod
                : shippingMethod // ignore: cast_nullable_to_non_nullable
                      as String?,
            paymentMethod: freezed == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                      as String?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            cancelledReason: freezed == cancelledReason
                ? _value.cancelledReason
                : cancelledReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            customerEmail: freezed == customerEmail
                ? _value.customerEmail
                : customerEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<OrderItem>,
            payment: freezed == payment
                ? _value.payment
                : payment // ignore: cast_nullable_to_non_nullable
                      as Payment?,
            shipment: freezed == shipment
                ? _value.shipment
                : shipment // ignore: cast_nullable_to_non_nullable
                      as Shipment?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaymentCopyWith<$Res>? get payment {
    if (_value.payment == null) {
      return null;
    }

    return $PaymentCopyWith<$Res>(_value.payment!, (value) {
      return _then(_value.copyWith(payment: value) as $Val);
    });
  }

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ShipmentCopyWith<$Res>? get shipment {
    if (_value.shipment == null) {
      return null;
    }

    return $ShipmentCopyWith<$Res>(_value.shipment!, (value) {
      return _then(_value.copyWith(shipment: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OrderImplCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$$OrderImplCopyWith(
    _$OrderImpl value,
    $Res Function(_$OrderImpl) then,
  ) = __$$OrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String orderNumber,
    String status,
    @JsonKey(fromJson: toDouble) double subtotal,
    @JsonKey(fromJson: toDouble) double discountAmount,
    @JsonKey(fromJson: toDouble) double shippingFee,
    @JsonKey(fromJson: toDouble) double total,
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
    List<OrderItem> items,
    Payment? payment,
    Shipment? shipment,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
  });

  @override
  $PaymentCopyWith<$Res>? get payment;
  @override
  $ShipmentCopyWith<$Res>? get shipment;
}

/// @nodoc
class __$$OrderImplCopyWithImpl<$Res>
    extends _$OrderCopyWithImpl<$Res, _$OrderImpl>
    implements _$$OrderImplCopyWith<$Res> {
  __$$OrderImplCopyWithImpl(
    _$OrderImpl _value,
    $Res Function(_$OrderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderNumber = null,
    Object? status = null,
    Object? subtotal = null,
    Object? discountAmount = null,
    Object? shippingFee = null,
    Object? total = null,
    Object? couponCode = freezed,
    Object? receiverName = freezed,
    Object? receiverPhone = freezed,
    Object? shippingAddress = freezed,
    Object? deliveryLatitude = freezed,
    Object? deliveryLongitude = freezed,
    Object? shippingMethod = freezed,
    Object? paymentMethod = freezed,
    Object? note = freezed,
    Object? cancelledReason = freezed,
    Object? customerEmail = freezed,
    Object? items = null,
    Object? payment = freezed,
    Object? shipment = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$OrderImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        orderNumber: null == orderNumber
            ? _value.orderNumber
            : orderNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as double,
        discountAmount: null == discountAmount
            ? _value.discountAmount
            : discountAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        shippingFee: null == shippingFee
            ? _value.shippingFee
            : shippingFee // ignore: cast_nullable_to_non_nullable
                  as double,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as double,
        couponCode: freezed == couponCode
            ? _value.couponCode
            : couponCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        receiverName: freezed == receiverName
            ? _value.receiverName
            : receiverName // ignore: cast_nullable_to_non_nullable
                  as String?,
        receiverPhone: freezed == receiverPhone
            ? _value.receiverPhone
            : receiverPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingAddress: freezed == shippingAddress
            ? _value.shippingAddress
            : shippingAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        deliveryLatitude: freezed == deliveryLatitude
            ? _value.deliveryLatitude
            : deliveryLatitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        deliveryLongitude: freezed == deliveryLongitude
            ? _value.deliveryLongitude
            : deliveryLongitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        shippingMethod: freezed == shippingMethod
            ? _value.shippingMethod
            : shippingMethod // ignore: cast_nullable_to_non_nullable
                  as String?,
        paymentMethod: freezed == paymentMethod
            ? _value.paymentMethod
            : paymentMethod // ignore: cast_nullable_to_non_nullable
                  as String?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        cancelledReason: freezed == cancelledReason
            ? _value.cancelledReason
            : cancelledReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        customerEmail: freezed == customerEmail
            ? _value.customerEmail
            : customerEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<OrderItem>,
        payment: freezed == payment
            ? _value.payment
            : payment // ignore: cast_nullable_to_non_nullable
                  as Payment?,
        shipment: freezed == shipment
            ? _value.shipment
            : shipment // ignore: cast_nullable_to_non_nullable
                  as Shipment?,
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
class _$OrderImpl extends _Order {
  const _$OrderImpl({
    required this.id,
    required this.orderNumber,
    required this.status,
    @JsonKey(fromJson: toDouble) required this.subtotal,
    @JsonKey(fromJson: toDouble) this.discountAmount = 0,
    @JsonKey(fromJson: toDouble) this.shippingFee = 0,
    @JsonKey(fromJson: toDouble) required this.total,
    this.couponCode,
    this.receiverName,
    this.receiverPhone,
    this.shippingAddress,
    @JsonKey(fromJson: toDoubleOrNull) this.deliveryLatitude,
    @JsonKey(fromJson: toDoubleOrNull) this.deliveryLongitude,
    this.shippingMethod,
    this.paymentMethod,
    this.note,
    this.cancelledReason,
    this.customerEmail,
    final List<OrderItem> items = const <OrderItem>[],
    this.payment,
    this.shipment,
    @JsonKey(fromJson: toDateTimeOrNull) this.createdAt,
  }) : _items = items,
       super._();

  factory _$OrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderImplFromJson(json);

  @override
  final int id;
  @override
  final String orderNumber;
  @override
  final String status;
  @override
  @JsonKey(fromJson: toDouble)
  final double subtotal;
  @override
  @JsonKey(fromJson: toDouble)
  final double discountAmount;
  @override
  @JsonKey(fromJson: toDouble)
  final double shippingFee;
  @override
  @JsonKey(fromJson: toDouble)
  final double total;
  @override
  final String? couponCode;
  @override
  final String? receiverName;
  @override
  final String? receiverPhone;
  @override
  final String? shippingAddress;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  final double? deliveryLatitude;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  final double? deliveryLongitude;
  @override
  final String? shippingMethod;
  @override
  final String? paymentMethod;
  @override
  final String? note;
  @override
  final String? cancelledReason;
  @override
  final String? customerEmail;
  final List<OrderItem> _items;
  @override
  @JsonKey()
  List<OrderItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final Payment? payment;
  @override
  final Shipment? shipment;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, status: $status, subtotal: $subtotal, discountAmount: $discountAmount, shippingFee: $shippingFee, total: $total, couponCode: $couponCode, receiverName: $receiverName, receiverPhone: $receiverPhone, shippingAddress: $shippingAddress, deliveryLatitude: $deliveryLatitude, deliveryLongitude: $deliveryLongitude, shippingMethod: $shippingMethod, paymentMethod: $paymentMethod, note: $note, cancelledReason: $cancelledReason, customerEmail: $customerEmail, items: $items, payment: $payment, shipment: $shipment, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.shippingFee, shippingFee) ||
                other.shippingFee == shippingFee) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.couponCode, couponCode) ||
                other.couponCode == couponCode) &&
            (identical(other.receiverName, receiverName) ||
                other.receiverName == receiverName) &&
            (identical(other.receiverPhone, receiverPhone) ||
                other.receiverPhone == receiverPhone) &&
            (identical(other.shippingAddress, shippingAddress) ||
                other.shippingAddress == shippingAddress) &&
            (identical(other.deliveryLatitude, deliveryLatitude) ||
                other.deliveryLatitude == deliveryLatitude) &&
            (identical(other.deliveryLongitude, deliveryLongitude) ||
                other.deliveryLongitude == deliveryLongitude) &&
            (identical(other.shippingMethod, shippingMethod) ||
                other.shippingMethod == shippingMethod) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.cancelledReason, cancelledReason) ||
                other.cancelledReason == cancelledReason) &&
            (identical(other.customerEmail, customerEmail) ||
                other.customerEmail == customerEmail) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.payment, payment) || other.payment == payment) &&
            (identical(other.shipment, shipment) ||
                other.shipment == shipment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    orderNumber,
    status,
    subtotal,
    discountAmount,
    shippingFee,
    total,
    couponCode,
    receiverName,
    receiverPhone,
    shippingAddress,
    deliveryLatitude,
    deliveryLongitude,
    shippingMethod,
    paymentMethod,
    note,
    cancelledReason,
    customerEmail,
    const DeepCollectionEquality().hash(_items),
    payment,
    shipment,
    createdAt,
  ]);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      __$$OrderImplCopyWithImpl<_$OrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderImplToJson(this);
  }
}

abstract class _Order extends Order {
  const factory _Order({
    required final int id,
    required final String orderNumber,
    required final String status,
    @JsonKey(fromJson: toDouble) required final double subtotal,
    @JsonKey(fromJson: toDouble) final double discountAmount,
    @JsonKey(fromJson: toDouble) final double shippingFee,
    @JsonKey(fromJson: toDouble) required final double total,
    final String? couponCode,
    final String? receiverName,
    final String? receiverPhone,
    final String? shippingAddress,
    @JsonKey(fromJson: toDoubleOrNull) final double? deliveryLatitude,
    @JsonKey(fromJson: toDoubleOrNull) final double? deliveryLongitude,
    final String? shippingMethod,
    final String? paymentMethod,
    final String? note,
    final String? cancelledReason,
    final String? customerEmail,
    final List<OrderItem> items,
    final Payment? payment,
    final Shipment? shipment,
    @JsonKey(fromJson: toDateTimeOrNull) final DateTime? createdAt,
  }) = _$OrderImpl;
  const _Order._() : super._();

  factory _Order.fromJson(Map<String, dynamic> json) = _$OrderImpl.fromJson;

  @override
  int get id;
  @override
  String get orderNumber;
  @override
  String get status;
  @override
  @JsonKey(fromJson: toDouble)
  double get subtotal;
  @override
  @JsonKey(fromJson: toDouble)
  double get discountAmount;
  @override
  @JsonKey(fromJson: toDouble)
  double get shippingFee;
  @override
  @JsonKey(fromJson: toDouble)
  double get total;
  @override
  String? get couponCode;
  @override
  String? get receiverName;
  @override
  String? get receiverPhone;
  @override
  String? get shippingAddress;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  double? get deliveryLatitude;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  double? get deliveryLongitude;
  @override
  String? get shippingMethod;
  @override
  String? get paymentMethod;
  @override
  String? get note;
  @override
  String? get cancelledReason;
  @override
  String? get customerEmail;
  @override
  List<OrderItem> get items;
  @override
  Payment? get payment;
  @override
  Shipment? get shipment;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get createdAt;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Invoice _$InvoiceFromJson(Map<String, dynamic> json) {
  return _Invoice.fromJson(json);
}

/// @nodoc
mixin _$Invoice {
  String get invoiceNumber => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get issuedAt => throw _privateConstructorUsedError;
  String get orderNumber => throw _privateConstructorUsedError;
  String? get orderStatus => throw _privateConstructorUsedError;
  String? get customerName => throw _privateConstructorUsedError;
  String? get customerEmail => throw _privateConstructorUsedError;
  String? get receiverName => throw _privateConstructorUsedError;
  String? get receiverPhone => throw _privateConstructorUsedError;
  String? get shippingAddress => throw _privateConstructorUsedError;
  List<OrderItem> get items => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get subtotal => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get discountAmount => throw _privateConstructorUsedError;
  String? get couponCode => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get shippingFee => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get total => throw _privateConstructorUsedError;
  Payment? get payment => throw _privateConstructorUsedError;

  /// Serializes this Invoice to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvoiceCopyWith<Invoice> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceCopyWith<$Res> {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) then) =
      _$InvoiceCopyWithImpl<$Res, Invoice>;
  @useResult
  $Res call({
    String invoiceNumber,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? issuedAt,
    String orderNumber,
    String? orderStatus,
    String? customerName,
    String? customerEmail,
    String? receiverName,
    String? receiverPhone,
    String? shippingAddress,
    List<OrderItem> items,
    @JsonKey(fromJson: toDouble) double subtotal,
    @JsonKey(fromJson: toDouble) double discountAmount,
    String? couponCode,
    @JsonKey(fromJson: toDouble) double shippingFee,
    @JsonKey(fromJson: toDouble) double total,
    Payment? payment,
  });

  $PaymentCopyWith<$Res>? get payment;
}

/// @nodoc
class _$InvoiceCopyWithImpl<$Res, $Val extends Invoice>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? invoiceNumber = null,
    Object? issuedAt = freezed,
    Object? orderNumber = null,
    Object? orderStatus = freezed,
    Object? customerName = freezed,
    Object? customerEmail = freezed,
    Object? receiverName = freezed,
    Object? receiverPhone = freezed,
    Object? shippingAddress = freezed,
    Object? items = null,
    Object? subtotal = null,
    Object? discountAmount = null,
    Object? couponCode = freezed,
    Object? shippingFee = null,
    Object? total = null,
    Object? payment = freezed,
  }) {
    return _then(
      _value.copyWith(
            invoiceNumber: null == invoiceNumber
                ? _value.invoiceNumber
                : invoiceNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            issuedAt: freezed == issuedAt
                ? _value.issuedAt
                : issuedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            orderNumber: null == orderNumber
                ? _value.orderNumber
                : orderNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            orderStatus: freezed == orderStatus
                ? _value.orderStatus
                : orderStatus // ignore: cast_nullable_to_non_nullable
                      as String?,
            customerName: freezed == customerName
                ? _value.customerName
                : customerName // ignore: cast_nullable_to_non_nullable
                      as String?,
            customerEmail: freezed == customerEmail
                ? _value.customerEmail
                : customerEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            receiverName: freezed == receiverName
                ? _value.receiverName
                : receiverName // ignore: cast_nullable_to_non_nullable
                      as String?,
            receiverPhone: freezed == receiverPhone
                ? _value.receiverPhone
                : receiverPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingAddress: freezed == shippingAddress
                ? _value.shippingAddress
                : shippingAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<OrderItem>,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as double,
            discountAmount: null == discountAmount
                ? _value.discountAmount
                : discountAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            couponCode: freezed == couponCode
                ? _value.couponCode
                : couponCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            shippingFee: null == shippingFee
                ? _value.shippingFee
                : shippingFee // ignore: cast_nullable_to_non_nullable
                      as double,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as double,
            payment: freezed == payment
                ? _value.payment
                : payment // ignore: cast_nullable_to_non_nullable
                      as Payment?,
          )
          as $Val,
    );
  }

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PaymentCopyWith<$Res>? get payment {
    if (_value.payment == null) {
      return null;
    }

    return $PaymentCopyWith<$Res>(_value.payment!, (value) {
      return _then(_value.copyWith(payment: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InvoiceImplCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$$InvoiceImplCopyWith(
    _$InvoiceImpl value,
    $Res Function(_$InvoiceImpl) then,
  ) = __$$InvoiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String invoiceNumber,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? issuedAt,
    String orderNumber,
    String? orderStatus,
    String? customerName,
    String? customerEmail,
    String? receiverName,
    String? receiverPhone,
    String? shippingAddress,
    List<OrderItem> items,
    @JsonKey(fromJson: toDouble) double subtotal,
    @JsonKey(fromJson: toDouble) double discountAmount,
    String? couponCode,
    @JsonKey(fromJson: toDouble) double shippingFee,
    @JsonKey(fromJson: toDouble) double total,
    Payment? payment,
  });

  @override
  $PaymentCopyWith<$Res>? get payment;
}

/// @nodoc
class __$$InvoiceImplCopyWithImpl<$Res>
    extends _$InvoiceCopyWithImpl<$Res, _$InvoiceImpl>
    implements _$$InvoiceImplCopyWith<$Res> {
  __$$InvoiceImplCopyWithImpl(
    _$InvoiceImpl _value,
    $Res Function(_$InvoiceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? invoiceNumber = null,
    Object? issuedAt = freezed,
    Object? orderNumber = null,
    Object? orderStatus = freezed,
    Object? customerName = freezed,
    Object? customerEmail = freezed,
    Object? receiverName = freezed,
    Object? receiverPhone = freezed,
    Object? shippingAddress = freezed,
    Object? items = null,
    Object? subtotal = null,
    Object? discountAmount = null,
    Object? couponCode = freezed,
    Object? shippingFee = null,
    Object? total = null,
    Object? payment = freezed,
  }) {
    return _then(
      _$InvoiceImpl(
        invoiceNumber: null == invoiceNumber
            ? _value.invoiceNumber
            : invoiceNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        issuedAt: freezed == issuedAt
            ? _value.issuedAt
            : issuedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        orderNumber: null == orderNumber
            ? _value.orderNumber
            : orderNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        orderStatus: freezed == orderStatus
            ? _value.orderStatus
            : orderStatus // ignore: cast_nullable_to_non_nullable
                  as String?,
        customerName: freezed == customerName
            ? _value.customerName
            : customerName // ignore: cast_nullable_to_non_nullable
                  as String?,
        customerEmail: freezed == customerEmail
            ? _value.customerEmail
            : customerEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        receiverName: freezed == receiverName
            ? _value.receiverName
            : receiverName // ignore: cast_nullable_to_non_nullable
                  as String?,
        receiverPhone: freezed == receiverPhone
            ? _value.receiverPhone
            : receiverPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingAddress: freezed == shippingAddress
            ? _value.shippingAddress
            : shippingAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<OrderItem>,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as double,
        discountAmount: null == discountAmount
            ? _value.discountAmount
            : discountAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        couponCode: freezed == couponCode
            ? _value.couponCode
            : couponCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        shippingFee: null == shippingFee
            ? _value.shippingFee
            : shippingFee // ignore: cast_nullable_to_non_nullable
                  as double,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as double,
        payment: freezed == payment
            ? _value.payment
            : payment // ignore: cast_nullable_to_non_nullable
                  as Payment?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InvoiceImpl implements _Invoice {
  const _$InvoiceImpl({
    required this.invoiceNumber,
    @JsonKey(fromJson: toDateTimeOrNull) this.issuedAt,
    required this.orderNumber,
    this.orderStatus,
    this.customerName,
    this.customerEmail,
    this.receiverName,
    this.receiverPhone,
    this.shippingAddress,
    final List<OrderItem> items = const <OrderItem>[],
    @JsonKey(fromJson: toDouble) required this.subtotal,
    @JsonKey(fromJson: toDouble) this.discountAmount = 0,
    this.couponCode,
    @JsonKey(fromJson: toDouble) this.shippingFee = 0,
    @JsonKey(fromJson: toDouble) required this.total,
    this.payment,
  }) : _items = items;

  factory _$InvoiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceImplFromJson(json);

  @override
  final String invoiceNumber;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  final DateTime? issuedAt;
  @override
  final String orderNumber;
  @override
  final String? orderStatus;
  @override
  final String? customerName;
  @override
  final String? customerEmail;
  @override
  final String? receiverName;
  @override
  final String? receiverPhone;
  @override
  final String? shippingAddress;
  final List<OrderItem> _items;
  @override
  @JsonKey()
  List<OrderItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey(fromJson: toDouble)
  final double subtotal;
  @override
  @JsonKey(fromJson: toDouble)
  final double discountAmount;
  @override
  final String? couponCode;
  @override
  @JsonKey(fromJson: toDouble)
  final double shippingFee;
  @override
  @JsonKey(fromJson: toDouble)
  final double total;
  @override
  final Payment? payment;

  @override
  String toString() {
    return 'Invoice(invoiceNumber: $invoiceNumber, issuedAt: $issuedAt, orderNumber: $orderNumber, orderStatus: $orderStatus, customerName: $customerName, customerEmail: $customerEmail, receiverName: $receiverName, receiverPhone: $receiverPhone, shippingAddress: $shippingAddress, items: $items, subtotal: $subtotal, discountAmount: $discountAmount, couponCode: $couponCode, shippingFee: $shippingFee, total: $total, payment: $payment)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceImpl &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.issuedAt, issuedAt) ||
                other.issuedAt == issuedAt) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.orderStatus, orderStatus) ||
                other.orderStatus == orderStatus) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.customerEmail, customerEmail) ||
                other.customerEmail == customerEmail) &&
            (identical(other.receiverName, receiverName) ||
                other.receiverName == receiverName) &&
            (identical(other.receiverPhone, receiverPhone) ||
                other.receiverPhone == receiverPhone) &&
            (identical(other.shippingAddress, shippingAddress) ||
                other.shippingAddress == shippingAddress) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.couponCode, couponCode) ||
                other.couponCode == couponCode) &&
            (identical(other.shippingFee, shippingFee) ||
                other.shippingFee == shippingFee) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.payment, payment) || other.payment == payment));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    invoiceNumber,
    issuedAt,
    orderNumber,
    orderStatus,
    customerName,
    customerEmail,
    receiverName,
    receiverPhone,
    shippingAddress,
    const DeepCollectionEquality().hash(_items),
    subtotal,
    discountAmount,
    couponCode,
    shippingFee,
    total,
    payment,
  );

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      __$$InvoiceImplCopyWithImpl<_$InvoiceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceImplToJson(this);
  }
}

abstract class _Invoice implements Invoice {
  const factory _Invoice({
    required final String invoiceNumber,
    @JsonKey(fromJson: toDateTimeOrNull) final DateTime? issuedAt,
    required final String orderNumber,
    final String? orderStatus,
    final String? customerName,
    final String? customerEmail,
    final String? receiverName,
    final String? receiverPhone,
    final String? shippingAddress,
    final List<OrderItem> items,
    @JsonKey(fromJson: toDouble) required final double subtotal,
    @JsonKey(fromJson: toDouble) final double discountAmount,
    final String? couponCode,
    @JsonKey(fromJson: toDouble) final double shippingFee,
    @JsonKey(fromJson: toDouble) required final double total,
    final Payment? payment,
  }) = _$InvoiceImpl;

  factory _Invoice.fromJson(Map<String, dynamic> json) = _$InvoiceImpl.fromJson;

  @override
  String get invoiceNumber;
  @override
  @JsonKey(fromJson: toDateTimeOrNull)
  DateTime? get issuedAt;
  @override
  String get orderNumber;
  @override
  String? get orderStatus;
  @override
  String? get customerName;
  @override
  String? get customerEmail;
  @override
  String? get receiverName;
  @override
  String? get receiverPhone;
  @override
  String? get shippingAddress;
  @override
  List<OrderItem> get items;
  @override
  @JsonKey(fromJson: toDouble)
  double get subtotal;
  @override
  @JsonKey(fromJson: toDouble)
  double get discountAmount;
  @override
  String? get couponCode;
  @override
  @JsonKey(fromJson: toDouble)
  double get shippingFee;
  @override
  @JsonKey(fromJson: toDouble)
  double get total;
  @override
  Payment? get payment;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
