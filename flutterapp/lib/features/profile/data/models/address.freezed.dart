// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Address _$AddressFromJson(Map<String, dynamic> json) {
  return _Address.fromJson(json);
}

/// @nodoc
mixin _$Address {
  int get id => throw _privateConstructorUsedError;
  String get receiverName => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get line1 => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDoubleOrNull)
  double? get latitude => throw _privateConstructorUsedError;
  @JsonKey(fromJson: toDoubleOrNull)
  double? get longitude => throw _privateConstructorUsedError;

  /// Serializes this Address to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddressCopyWith<Address> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddressCopyWith<$Res> {
  factory $AddressCopyWith(Address value, $Res Function(Address) then) =
      _$AddressCopyWithImpl<$Res, Address>;
  @useResult
  $Res call({
    int id,
    String receiverName,
    String phone,
    String line1,
    String city,
    bool isDefault,
    @JsonKey(fromJson: toDoubleOrNull) double? latitude,
    @JsonKey(fromJson: toDoubleOrNull) double? longitude,
  });
}

/// @nodoc
class _$AddressCopyWithImpl<$Res, $Val extends Address>
    implements $AddressCopyWith<$Res> {
  _$AddressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? receiverName = null,
    Object? phone = null,
    Object? line1 = null,
    Object? city = null,
    Object? isDefault = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            receiverName: null == receiverName
                ? _value.receiverName
                : receiverName // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            line1: null == line1
                ? _value.line1
                : line1 // ignore: cast_nullable_to_non_nullable
                      as String,
            city: null == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String,
            isDefault: null == isDefault
                ? _value.isDefault
                : isDefault // ignore: cast_nullable_to_non_nullable
                      as bool,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AddressImplCopyWith<$Res> implements $AddressCopyWith<$Res> {
  factory _$$AddressImplCopyWith(
    _$AddressImpl value,
    $Res Function(_$AddressImpl) then,
  ) = __$$AddressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String receiverName,
    String phone,
    String line1,
    String city,
    bool isDefault,
    @JsonKey(fromJson: toDoubleOrNull) double? latitude,
    @JsonKey(fromJson: toDoubleOrNull) double? longitude,
  });
}

/// @nodoc
class __$$AddressImplCopyWithImpl<$Res>
    extends _$AddressCopyWithImpl<$Res, _$AddressImpl>
    implements _$$AddressImplCopyWith<$Res> {
  __$$AddressImplCopyWithImpl(
    _$AddressImpl _value,
    $Res Function(_$AddressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? receiverName = null,
    Object? phone = null,
    Object? line1 = null,
    Object? city = null,
    Object? isDefault = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
  }) {
    return _then(
      _$AddressImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        receiverName: null == receiverName
            ? _value.receiverName
            : receiverName // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        line1: null == line1
            ? _value.line1
            : line1 // ignore: cast_nullable_to_non_nullable
                  as String,
        city: null == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String,
        isDefault: null == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AddressImpl extends _Address {
  const _$AddressImpl({
    required this.id,
    required this.receiverName,
    required this.phone,
    required this.line1,
    required this.city,
    this.isDefault = false,
    @JsonKey(fromJson: toDoubleOrNull) this.latitude,
    @JsonKey(fromJson: toDoubleOrNull) this.longitude,
  }) : super._();

  factory _$AddressImpl.fromJson(Map<String, dynamic> json) =>
      _$$AddressImplFromJson(json);

  @override
  final int id;
  @override
  final String receiverName;
  @override
  final String phone;
  @override
  final String line1;
  @override
  final String city;
  @override
  @JsonKey()
  final bool isDefault;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  final double? latitude;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  final double? longitude;

  @override
  String toString() {
    return 'Address(id: $id, receiverName: $receiverName, phone: $phone, line1: $line1, city: $city, isDefault: $isDefault, latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddressImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.receiverName, receiverName) ||
                other.receiverName == receiverName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.line1, line1) || other.line1 == line1) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    receiverName,
    phone,
    line1,
    city,
    isDefault,
    latitude,
    longitude,
  );

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddressImplCopyWith<_$AddressImpl> get copyWith =>
      __$$AddressImplCopyWithImpl<_$AddressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AddressImplToJson(this);
  }
}

abstract class _Address extends Address {
  const factory _Address({
    required final int id,
    required final String receiverName,
    required final String phone,
    required final String line1,
    required final String city,
    final bool isDefault,
    @JsonKey(fromJson: toDoubleOrNull) final double? latitude,
    @JsonKey(fromJson: toDoubleOrNull) final double? longitude,
  }) = _$AddressImpl;
  const _Address._() : super._();

  factory _Address.fromJson(Map<String, dynamic> json) = _$AddressImpl.fromJson;

  @override
  int get id;
  @override
  String get receiverName;
  @override
  String get phone;
  @override
  String get line1;
  @override
  String get city;
  @override
  bool get isDefault;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  double? get latitude;
  @override
  @JsonKey(fromJson: toDoubleOrNull)
  double? get longitude;

  /// Create a copy of Address
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddressImplCopyWith<_$AddressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
