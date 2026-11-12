import '../../../../core/network/dio_client.dart';
import '../../../auth/data/models/app_user.dart';
import '../models/address.dart';

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<AppUser> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final r = await _api.put(
      '/users/me',
      body: {'fullName': fullName.trim(), 'phone': phone.trim()},
    );
    return AppUser.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put(
      '/users/me/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<List<Address>> addresses() async {
    final r = await _api.get('/users/me/addresses');
    return (r.data as List)
        .map((e) => Address.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Map<String, dynamic> _body({
    required String receiverName,
    required String phone,
    required String line1,
    required String city,
    required bool isDefault,
    double? latitude,
    double? longitude,
  }) => {
    'receiverName': receiverName.trim(),
    'phone': phone.trim(),
    'line1': line1.trim(),
    'city': city.trim(),
    'isDefault': isDefault,
    // The API wants both or neither (omitting both clears the location).
    if (latitude != null && longitude != null) ...{
      'latitude': _round6(latitude),
      'longitude': _round6(longitude),
    },
  };

  static double _round6(double v) => double.parse(v.toStringAsFixed(6));

  Future<Address> addAddress({
    required String receiverName,
    required String phone,
    required String line1,
    required String city,
    required bool isDefault,
    double? latitude,
    double? longitude,
  }) async {
    final r = await _api.post(
      '/users/me/addresses',
      body: _body(
        receiverName: receiverName,
        phone: phone,
        line1: line1,
        city: city,
        isDefault: isDefault,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    return Address.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<Address> updateAddress(
    int id, {
    required String receiverName,
    required String phone,
    required String line1,
    required String city,
    required bool isDefault,
    double? latitude,
    double? longitude,
  }) async {
    final r = await _api.put(
      '/users/me/addresses/$id',
      body: _body(
        receiverName: receiverName,
        phone: phone,
        line1: line1,
        city: city,
        isDefault: isDefault,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    return Address.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<Address> setDefaultAddress(int id) async {
    final r = await _api.patch('/users/me/addresses/$id/default');
    return Address.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<void> deleteAddress(int id) async {
    await _api.delete('/users/me/addresses/$id');
  }
}
