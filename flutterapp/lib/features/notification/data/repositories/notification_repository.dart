import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._api);
  final ApiClient _api;

  Future<PageResponse<AppNotification>> list({
    int page = 0,
    int size = 20,
  }) async {
    final r = await _api.get(
      '/notifications',
      query: {'page': page, 'size': size},
    );
    return PageResponse.fromJson(r.data, AppNotification.fromJson);
  }

  Future<int> unreadCount() async {
    final r = await _api.get('/notifications/unread-count');
    return (r.data as num?)?.toInt() ?? 0;
  }

  Future<AppNotification> markRead(int id) async {
    final r = await _api.patch('/notifications/$id/read');
    return AppNotification.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<void> markAllRead() async {
    await _api.patch('/notifications/read-all');
  }
}
