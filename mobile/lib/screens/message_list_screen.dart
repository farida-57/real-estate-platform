import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/message_provider.dart';
import '../providers/auth_provider.dart';
import '../models/message_model.dart';
import '../core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class MessageListScreen extends ConsumerWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: messagesAsync.messages.when(
        data: (messages) {
          final conversations = _groupMessages(messages, currentUserId);

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aucun message',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.foreground,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vos conversations apparaîtront ici',
                    style: TextStyle(fontSize: 14, color: AppColors.muted),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(messagesProvider.notifier).fetchMessages(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      conversation.participantName.isNotEmpty
                          ? conversation.participantName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    conversation.participantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      conversation.lastMessage.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat.Hm().format(
                          conversation.lastMessage.createdAt.toLocal(),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  onTap: () =>
                      context.push('/chat?id=${conversation.participantId}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Erreur de chargement',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(messagesProvider.notifier).fetchMessages(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ConversationSummary> _groupMessages(
    List<MessageModel> messages,
    String currentUserId,
  ) {
    final Map<String, MessageModel> lastMessages = {};
    final Map<String, String> participantNames = {};

    for (final m in messages) {
      final isMe = m.senderId == currentUserId;
      final otherId = isMe ? m.receiverId : m.senderId;
      final otherName = isMe
          ? (m.receiverName ?? '')
          : (m.senderName ?? '');

      if (!lastMessages.containsKey(otherId) ||
          m.createdAt.isAfter(lastMessages[otherId]!.createdAt)) {
        lastMessages[otherId] = m;
      }
      // Save name if we don't have it yet (or if the newer one has it)
      if (otherName.isNotEmpty) {
        participantNames[otherId] = otherName;
      }
    }

    return lastMessages.entries.map((e) {
      final otherId = e.key;
      String name = participantNames[otherId] ?? '';
      if (name.isEmpty) {
        name = 'Utilisateur ${otherId.length >= 6 ? otherId.substring(0, 6) : otherId}';
      }
      return ConversationSummary(
        participantId: otherId,
        participantName: name,
        lastMessage: e.value,
      );
    }).toList()
      ..sort(
        (a, b) =>
            b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt),
      );
  }
}

class ConversationSummary {
  final String participantId;
  final String participantName;
  final MessageModel lastMessage;

  ConversationSummary({
    required this.participantId,
    required this.participantName,
    required this.lastMessage,
  });
}
