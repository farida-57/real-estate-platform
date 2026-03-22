import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import 'property_provider.dart';

class MessageState {
  final AsyncValue<List<MessageModel>> messages;
  final int unreadCount;

  MessageState({
    this.messages = const AsyncValue.loading(),
    this.unreadCount = 0,
  });

  MessageState copyWith({
    AsyncValue<List<MessageModel>>? messages,
    int? unreadCount,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

final messagesProvider = StateNotifierProvider<MessageNotifier, MessageState>((
  ref,
) {
  return MessageNotifier(ref);
});

class MessageNotifier extends StateNotifier<MessageState> {
  final Ref _ref;

  MessageNotifier(this._ref) : super(MessageState()) {
    fetchMessages();
    fetchUnreadCount();
  }

  /// Fetches the conversation list (last message per partner).
  /// Backend GET /messages returns: List<{ partner, lastMessage, unreadCount }>
  Future<void> fetchMessages() async {
    if (state.messages is! AsyncData) {
      state = state.copyWith(messages: const AsyncValue.loading());
    }

    try {
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.get('/messages');
      final dynamic raw = response.data;
      if (raw == null || raw is! List) {
        state = state.copyWith(messages: const AsyncValue.data([]));
        return;
      }

      // Backend returns conversation summaries: { partner, lastMessage, unreadCount }
      // Extract the lastMessage from each summary to build the flat list used by MessageListScreen
      final messagesList = <MessageModel>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          final lastMsg = item['lastMessage'];
          if (lastMsg != null && lastMsg is Map<String, dynamic>) {
            try {
              messagesList.add(MessageModel.fromJson(lastMsg));
            } catch (_) {}
          }
        }
      }

      state = state.copyWith(messages: AsyncValue.data(messagesList));
      await fetchUnreadCount();
    } catch (e, st) {
      state = state.copyWith(messages: AsyncValue.error(e, st));
    }
  }

  /// Fetches the full conversation thread with a specific user.
  /// Calls GET /messages/:userId on the backend.
  Future<List<MessageModel>> fetchConversation(String otherUserId) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.get('/messages/$otherUserId');
      final dynamic raw = response.data;
      if (raw == null || raw is! List) return [];
      return (raw as List<dynamic>)
          .map((item) => MessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.get('/messages/unread-count');
      final count = response.data['unreadCount'] ?? 0;
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> markConversationAsRead(String otherUserId) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.post(
        '/messages/mark-read',
        data: {'otherUserId': otherUserId},
      );
      await fetchMessages();
    } catch (e) {
      // Silently fail
    }
  }

  Future<bool> sendMessage(
    String receiverId,
    String content, {
    String? propertyId,
  }) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.post(
        '/messages',
        data: {
          'receiverId': receiverId,
          'content': content,
          if (propertyId != null) 'propertyId': propertyId,
        },
      );
      if (response.statusCode == 201) {
        await fetchMessages();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

/// Fetches the full conversation thread with [otherUserId] directly from the API.
final chatProvider = FutureProvider.family<List<MessageModel>, String>((
  ref,
  otherUserId,
) async {
  final notifier = ref.read(messagesProvider.notifier);
  final messages = await notifier.fetchConversation(otherUserId);
  return messages;
});
