// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppUserImpl _$$AppUserImplFromJson(Map<String, dynamic> json) =>
    _$AppUserImpl(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'CUSTOMER',
      enabled: json['enabled'] as bool? ?? true,
      createdAt: toDateTimeOrNull(json['createdAt']),
    );

Map<String, dynamic> _$$AppUserImplToJson(_$AppUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'phone': instance.phone,
      'role': instance.role,
      'enabled': instance.enabled,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$AuthResultImpl _$$AuthResultImplFromJson(Map<String, dynamic> json) =>
    _$AuthResultImpl(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 86400,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AuthResultImplToJson(_$AuthResultImpl instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'tokenType': instance.tokenType,
      'expiresInSeconds': instance.expiresInSeconds,
      'user': instance.user.toJson(),
    };
