// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/json_helpers.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required int id,
    required String fullName,
    required String email,
    String? phone,
    @Default('CUSTOMER') String role,
    @Default(true) bool enabled,
    @JsonKey(fromJson: toDateTimeOrNull) DateTime? createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}

@freezed
class AuthResult with _$AuthResult {
  const factory AuthResult({
    required String accessToken,
    @Default('Bearer') String tokenType,
    @Default(86400) int expiresInSeconds,
    required AppUser user,
  }) = _AuthResult;

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
}
