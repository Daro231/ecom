// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/json_helpers.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

@freezed
class AppNotification with _$AppNotification {
  const AppNotification._();

  const factory AppNotification({
    required int id,
    @Default('PUSH') String type,
    required String title,
    required String message,
    @Default(false) bool read,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
    @Default('NORMAL') String priority,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  bool get isHigh => priority == 'HIGH';
}
