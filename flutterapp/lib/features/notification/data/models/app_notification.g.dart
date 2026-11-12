// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppNotificationImpl _$$AppNotificationImplFromJson(
  Map<String, dynamic> json,
) => _$AppNotificationImpl(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String? ?? 'PUSH',
  title: json['title'] as String,
  message: json['message'] as String,
  read: json['read'] as bool? ?? false,
  createdAt: toDateTimeOrNull(json['createdAt']),
  priority: json['priority'] as String? ?? 'NORMAL',
);

Map<String, dynamic> _$$AppNotificationImplToJson(
  _$AppNotificationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'title': instance.title,
  'message': instance.message,
  'read': instance.read,
  'createdAt': instance.createdAt?.toIso8601String(),
  'priority': instance.priority,
};
