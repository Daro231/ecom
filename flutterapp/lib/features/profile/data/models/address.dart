// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/json_helpers.dart';

part 'address.freezed.dart';
part 'address.g.dart';

@freezed
class Address with _$Address {
  const Address._();

  const factory Address({
    required int id,
    required String receiverName,
    required String phone,
    required String line1,
    required String city,
    @Default(false) bool isDefault,
    @JsonKey(fromJson: toDoubleOrNull) double? latitude,
    @JsonKey(fromJson: toDoubleOrNull) double? longitude,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  String get fullLine => '$line1, $city';

  bool get hasLocation => latitude != null && longitude != null;
}
