// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'khqr_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

KhqrData _$KhqrDataFromJson(Map<String, dynamic> json) {
  return _KhqrData.fromJson(json);
}

/// @nodoc
mixin _$KhqrData {
  String get orderNumber => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDouble)
  double get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get qrString => throw _privateConstructorUsedError;
  String? get md5 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDateTime)
  DateTime get expiresAt => throw _privateConstructorUsedError;
  String get mode => throw _privateConstructorUsedError;

  /// Serializes this KhqrData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KhqrData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KhqrDataCopyWith<KhqrData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KhqrDataCopyWith<$Res> {
  factory $KhqrDataCopyWith(KhqrData value, $Res Function(KhqrData) then) =
      _$KhqrDataCopyWithImpl<$Res, KhqrData>;
  @useResult
  $Res call({
    String orderNumber,
    @JsonKey(fromJson: toDouble) double amount,
    String currency,
    String qrString,
    String? md5,
    @JsonKey(fromJson: toDateTime) DateTime expiresAt,
    String mode,
  });
}

/// @nodoc
class _$KhqrDataCopyWithImpl<$Res, $Val extends KhqrData>
    implements $KhqrDataCopyWith<$Res> {
  _$KhqrDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KhqrData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderNumber = null,
    Object? amount = null,
    Object? currency = null,
    Object? qrString = null,
    Object? md5 = freezed,
    Object? expiresAt = null,
    Object? mode = null,
  }) {
    return _then(
      _value.copyWith(
            orderNumber: null == orderNumber
                ? _value.orderNumber
                : orderNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            qrString: null == qrString
                ? _value.qrString
                : qrString // ignore: cast_nullable_to_non_nullable
                      as String,
            md5: freezed == md5
                ? _value.md5
                : md5 // ignore: cast_nullable_to_non_nullable
                      as String?,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KhqrDataImplCopyWith<$Res>
    implements $KhqrDataCopyWith<$Res> {
  factory _$$KhqrDataImplCopyWith(
    _$KhqrDataImpl value,
    $Res Function(_$KhqrDataImpl) then,
  ) = __$$KhqrDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String orderNumber,
    @JsonKey(fromJson: toDouble) double amount,
    String currency,
    String qrString,
    String? md5,
    @JsonKey(fromJson: toDateTime) DateTime expiresAt,
    String mode,
  });
}

/// @nodoc
class __$$KhqrDataImplCopyWithImpl<$Res>
    extends _$KhqrDataCopyWithImpl<$Res, _$KhqrDataImpl>
    implements _$$KhqrDataImplCopyWith<$Res> {
  __$$KhqrDataImplCopyWithImpl(
    _$KhqrDataImpl _value,
    $Res Function(_$KhqrDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of KhqrData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderNumber = null,
    Object? amount = null,
    Object? currency = null,
    Object? qrString = null,
    Object? md5 = freezed,
    Object? expiresAt = null,
    Object? mode = null,
  }) {
    return _then(
      _$KhqrDataImpl(
        orderNumber: null == orderNumber
            ? _value.orderNumber
            : orderNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        qrString: null == qrString
            ? _value.qrString
            : qrString // ignore: cast_nullable_to_non_nullable
                  as String,
        md5: freezed == md5
            ? _value.md5
            : md5 // ignore: cast_nullable_to_non_nullable
                  as String?,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$KhqrDataImpl extends _KhqrData {
  const _$KhqrDataImpl({
    required this.orderNumber,
    @JsonKey(fromJson: toDouble) required this.amount,
    this.currency = 'USD',
    required this.qrString,
    this.md5,
    @JsonKey(fromJson: toDateTime) required this.expiresAt,
    this.mode = 'MOCK',
  }) : super._();

  factory _$KhqrDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$KhqrDataImplFromJson(json);

  @override
  final String orderNumber;
  @override
  @JsonKey(fromJson: toDouble)
  final double amount;
  @override
  @JsonKey()
  final String currency;
  @override
  final String qrString;
  @override
  final String? md5;
  @override
  @JsonKey(fromJson: toDateTime)
  final DateTime expiresAt;
  @override
  @JsonKey()
  final String mode;

  @override
  String toString() {
    return 'KhqrData(orderNumber: $orderNumber, amount: $amount, currency: $currency, qrString: $qrString, md5: $md5, expiresAt: $expiresAt, mode: $mode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KhqrDataImpl &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.qrString, qrString) ||
                other.qrString == qrString) &&
            (identical(other.md5, md5) || other.md5 == md5) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.mode, mode) || other.mode == mode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    orderNumber,
    amount,
    currency,
    qrString,
    md5,
    expiresAt,
    mode,
  );

  /// Create a copy of KhqrData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KhqrDataImplCopyWith<_$KhqrDataImpl> get copyWith =>
      __$$KhqrDataImplCopyWithImpl<_$KhqrDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KhqrDataImplToJson(this);
  }
}

abstract class _KhqrData extends KhqrData {
  const factory _KhqrData({
    required final String orderNumber,
    @JsonKey(fromJson: toDouble) required final double amount,
    final String currency,
    required final String qrString,
    final String? md5,
    @JsonKey(fromJson: toDateTime) required final DateTime expiresAt,
    final String mode,
  }) = _$KhqrDataImpl;
  const _KhqrData._() : super._();

  factory _KhqrData.fromJson(Map<String, dynamic> json) =
      _$KhqrDataImpl.fromJson;

  @override
  String get orderNumber;
  @override
  @JsonKey(fromJson: toDouble)
  double get amount;
  @override
  String get currency;
  @override
  String get qrString;
  @override
  String? get md5;
  @override
  @JsonKey(fromJson: toDateTime)
  DateTime get expiresAt;
  @override
  String get mode;

  /// Create a copy of KhqrData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KhqrDataImplCopyWith<_$KhqrDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
