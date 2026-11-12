// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AddressImpl _$$AddressImplFromJson(Map<String, dynamic> json) =>
    _$AddressImpl(
      id: (json['id'] as num).toInt(),
      receiverName: json['receiverName'] as String,
      phone: json['phone'] as String,
      line1: json['line1'] as String,
      city: json['city'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      latitude: toDoubleOrNull(json['latitude']),
      longitude: toDoubleOrNull(json['longitude']),
    );

Map<String, dynamic> _$$AddressImplToJson(_$AddressImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'receiverName': instance.receiverName,
      'phone': instance.phone,
      'line1': instance.line1,
      'city': instance.city,
      'isDefault': instance.isDefault,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
