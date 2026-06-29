import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/api_client_provider.dart';

final _notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(apiClientProvider).getNotifications();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(_notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notifAsync.whenOrNull(
            data: (items) => items.isNotEmpty
                ? TextButton(
                    onPressed: () async {
                      await ref
                          .read(apiClientProvider)
                          .markNotificationsRead();
                      ref.invalidate(_notificationsProvider);
                    },
                    child: const Text('Mark all read'),
                  )
                : null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: notifAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Color(0xFF689F38))),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  Text('No notifications',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0, indent: 16),
            itemBuilder: (context, i) => _NotifTile(notification: items[i]),
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  const _NotifTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final type = notification['type'] as String? ?? '';
    final readAt = notification['read_at'];
    final isUnread = readAt == null;

    final message = data['message'] as String? ??
        data['body'] as String? ??
        _labelFromType(type);

    final createdAt = notification['created_at'] as String?;
    final timeLabel = _formatTime(createdAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isUnread
            ? const Color(0xFF689F38).withOpacity(0.2)
            : Colors.grey.shade800,
        child: Icon(
          _iconFromType(type),
          color: isUnread ? const Color(0xFF689F38) : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      subtitle: timeLabel.isNotEmpty
          ? Text(timeLabel,
              style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF689F38),
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  IconData _iconFromType(String type) {
    if (type.contains('Comment')) return Icons.comment_outlined;
    if (type.contains('Follow')) return Icons.person_add_outlined;
    if (type.contains('Like')) return Icons.favorite_border;
    if (type.contains('Play')) return Icons.play_circle_outline;
    return Icons.notifications_outlined;
  }

  String _labelFromType(String type) {
    if (type.contains('Comment')) return 'Someone commented on your content';
    if (type.contains('Follow')) return 'Someone followed you';
    if (type.contains('Like')) return 'Someone liked your content';
    return 'New notification';
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
