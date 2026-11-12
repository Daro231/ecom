// ignore_for_file: invalid_annotation_target
import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/json_helpers.dart';

part 'khqr_models.freezed.dart';
part 'khqr_models.g.dart';

/// Response of `POST /payments/{orderNumber}/khqr`. `qrPayload` is a
/// deprecated alias of `qrString` and is intentionally not modelled.
@freezed
class KhqrData with _$KhqrData {
  const KhqrData._();

  const factory KhqrData({
    required String orderNumber,
    @JsonKey(fromJson: toDouble) required double amount,
    @Default('USD') String currency,
    required String qrString,
    String? md5,
    @JsonKey(fromJson: toDateTime) required DateTime expiresAt,
    @Default('MOCK') String mode,
  }) = _KhqrData;

  factory KhqrData.fromJson(Map<String, dynamic> json) =>
      _$KhqrDataFromJson(json);

  bool get isMock => mode == 'MOCK';
}

/// A KHQR plus the moment it expires on *this* device's clock.
class KhqrSession {
  const KhqrSession({required this.data, required this.expiresAtLocal});

  final KhqrData data;
  final DateTime expiresAtLocal;

  Duration remaining([DateTime? now]) =>
      expiresAtLocal.difference(now ?? clock.now());

  bool isExpired([DateTime? now]) => remaining(now) <= Duration.zero;
}
