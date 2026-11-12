import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/address.dart';

class AddressesController extends AsyncNotifier<List<Address>> {
  @override
  Future<List<Address>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    return ref.watch(profileRepositoryProvider).addresses();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).addresses(),
    );
  }

  Future<Address> add({
    required String receiverName,
    required String phone,
    required String line1,
    required String city,
    required bool isDefault,
    double? latitude,
    double? longitude,
  }) async {
    final a = await ref
        .read(profileRepositoryProvider)
        .addAddress(
          receiverName: receiverName,
          phone: phone,
          line1: line1,
          city: city,
          isDefault: isDefault,
          latitude: latitude,
          longitude: longitude,
        );
    await reload();
    return a;
  }

  Future<void> edit(
    int id, {
    required String receiverName,
    required String phone,
    required String line1,
    required String city,
    required bool isDefault,
    double? latitude,
    double? longitude,
  }) async {
    await ref
        .read(profileRepositoryProvider)
        .updateAddress(
          id,
          receiverName: receiverName,
          phone: phone,
          line1: line1,
          city: city,
          isDefault: isDefault,
          latitude: latitude,
          longitude: longitude,
        );
    await reload();
  }

  Future<void> setDefault(int id) async {
    await ref.read(profileRepositoryProvider).setDefaultAddress(id);
    await reload();
  }

  Future<void> remove(int id) async {
    await ref.read(profileRepositoryProvider).deleteAddress(id);
    await reload();
  }
}

final addressesProvider =
    AsyncNotifierProvider<AddressesController, List<Address>>(
      AddressesController.new,
    );

/// Light / dark / system, persisted in SharedPreferences.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final v = ref.read(sharedPrefsProvider).getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == v,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
