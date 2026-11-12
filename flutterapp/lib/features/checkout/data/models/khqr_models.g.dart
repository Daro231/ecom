// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'khqr_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KhqrDataImpl _$$KhqrDataImplFromJson(Map<String, dynamic> json) =>
    _$KhqrDataImpl(
      orderNumber: json['orderNumber'] as String,
      amount: toDouble(json['amount']),
      currency: json['currency'] as String? ?? 'USD',
      qrString: json['qrString'] as String,
      md5: json['md5'] as String?,
      expiresAt: toDateTime(json['expiresAt']),
      mode: json['mode'] as String? ?? 'MOCK',
    );

Map<String, dynamic> _$$KhqrDataImplToJson(_$KhqrDataImpl instance) =>
    <String, dynamic>{
      'orderNumber': instance.orderNumber,
      'amount': instance.amount,
      'currency': instance.currency,
      'qrString': instance.qrString,
      'md5': instance.md5,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'mode': instance.mode,
    };
