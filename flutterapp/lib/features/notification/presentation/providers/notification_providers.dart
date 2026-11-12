import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show SnackBar, Text;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/page_response.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/messenger.dart';
import '../../../../core/utils/paged.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/app_notification.dart';

/// HIGH priority first (red marker), then newest first.
List<AppNotification> sortNotifications(List<AppNotification> list) {
  final copy = [...list];
  copy.sort((a, b) {
    if (a.isHigh != b.isHigh) return a.isHigh ? -1 : 1;
    final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  });
  return copy;
}

class NotificationsController extends PagedNotifier<AppNotification> {
  @override
  PagedState<AppNotification> build() {
    ref.watch(currentUserIdProvider);
    return beginLoad();
  }

  @override
  Future<PageResponse<AppNotification>> fetchPage(int page) =>
      ref.read(notificationRepositoryProvider).list(page: page, size: 20);

  Future<void> markRead(AppNotification n) async {
    if (n.read) return;
    final updated = await ref
        .read(notificationRepositoryProvider)
        .markRead(n.id);
    state = state.copyWith(
      items: [for (final x in state.items) x.id == n.id ? updated : x],
    );
    ref.read(unreadCountProvider.notifier).decrement();
  }

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    state = state.copyWith(
      items: [for (final x in state.items) x.copyWith(read: true)],
    );
    ref.read(unreadCountProvider.notifier).set(0);
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsController, PagedState<AppNotification>>(
      NotificationsController.new,
    );

class UnreadCountController extends Notifier<int> {
  @override
  int build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId != null) Future.microtask(refresh);
    return 0;
  }

  void set(int v) => state = v < 0 ? 0 : v;
  void decrement() => set(state - 1);

  Future<int> refresh() async {
    try {
      final n = await ref.read(notificationRepositoryProvider).unreadCount();
      if (ref.mounted) state = n;
    } catch (_) {
      // Badge is best-effort; keep the previous value.
    }
    return state;
  }
}

final unreadCountProvider = NotifierProvider<UnreadCountController, int>(
  UnreadCountController.new,
);

/// Shows OS-level notifications; replaceable in tests.
abstract class LocalNotifier {
  Future<void> init();
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

class PluginLocalNotifier implements LocalNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  @override
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings: settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      // Browsers: no OS notification plugin - show an in-app SnackBar instead.
      final m = rootMessengerKey.currentState;
      m?.hideCurrentSnackBar();
      m?.showSnackBar(
        SnackBar(
          content: Text('$title\n$body'),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    if (!_ready) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ecom_updates',
        'Order updates',
        channelDescription: 'Order, payment and delivery updates',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}

final localNotifierProvider = Provider<LocalNotifier>(
  (ref) => PluginLocalNotifier(),
);

/// Polls the unread count (on app resume / every minute in the foreground)
/// and raises a local notification when something new arrived.
class NotificationWatcher {
  NotificationWatcher(this._ref);
  final Ref _ref;

  String _key(int userId) => 'last_notified_id_$userId';

  Future<void> check() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    final repo = _ref.read(notificationRepositoryProvider);
    final prefs = _ref.read(sharedPrefsProvider);
    try {
      final before = _ref.read(unreadCountProvider);
      final count = await repo.unreadCount();
      _ref.read(unreadCountProvider.notifier).set(count);

      final lastId = prefs.getInt(_key(userId));
      if (lastId != null && count <= before) return;

      final page = await repo.list(page: 0, size: 10);
      if (page.content.isEmpty) return;
      final maxId = page.content
          .map((n) => n.id)
          .reduce((a, b) => a > b ? a : b);
      if (lastId == null) {
        // First run for this account: remember the baseline, stay silent.
        await prefs.setInt(_key(userId), maxId);
        return;
      }
      final fresh = sortNotifications(
        page.content.where((n) => !n.read && n.id > lastId).toList(),
      );
      if (fresh.isEmpty) return;
      await prefs.setInt(_key(userId), maxId);
      final top = fresh.first;
      await _ref
          .read(localNotifierProvider)
          .show(
            id: top.id,
            title: top.title,
            body: fresh.length > 1
                ? '${top.message}\n+${fresh.length - 1} more'
                : top.message,
          );
      _ref.invalidate(notificationsProvider);
    } catch (_) {
      // Best-effort background check; never surface errors to the user.
    }
  }
}

final notificationWatcherProvider = Provider<NotificationWatcher>(
  (ref) => NotificationWatcher(ref),
);
