import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/app_notification.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        ref.read(notificationsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markAll() async {
    try {
      await ref.read(notificationsProvider.notifier).markAllRead();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _open(AppNotification n) async {
    try {
      await ref.read(notificationsProvider.notifier).markRead(n);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final hasUnread = state.items.any((n) => !n.read);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            key: const Key('mark_all_read'),
            onPressed: hasUnread ? _markAll : null,
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: hasUnread ? Colors.white : Colors.white38,
              ),
            ),
          ),
        ],
      ),
      body: () {
        if (state.loading) return const ShimmerList(itemHeight: 76);
        if (state.error != null) {
          return ErrorState(
            error: state.error!,
            onRetry: () => ref
                .read(notificationsProvider.notifier)
                .refresh()
                .catchError((_) {}),
          );
        }
        if (state.isEmpty)
          return const EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications',
            message: 'Order and payment updates will appear here.',
          );
        final items = sortNotifications(state.items);
        return RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(notificationsProvider.notifier)
                .refresh()
                .catchError((_) {});
            await ref.read(unreadCountProvider.notifier).refresh();
          },
          child: ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length + (state.loadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i >= items.length)
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                );
              final n = items[i];
              return _Tile(n: n, onTap: () => _open(n));
            },
          ),
        );
      }(),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      shape: n.isHigh
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.danger, width: 1.5),
            )
          : null,
      child: InkWell(
        key: Key('notif_${n.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 10),
                child: !n.read
                    ? Container(
                        key: Key('unread_dot_${n.id}'),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: n.isHigh ? AppColors.danger : AppColors.accent,
                        ),
                      )
                    : const SizedBox(width: 10, height: 10),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (n.isHigh)
                          Container(
                            key: Key('high_${n.id}'),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'IMPORTANT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.read
                                  ? FontWeight.w500
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.message, style: t.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      formatDateTime(n.createdAt),
                      style: t.textTheme.bodySmall?.copyWith(
                        color: t.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
