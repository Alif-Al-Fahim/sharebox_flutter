import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_indicator.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final rooms = chatProvider.chatRooms;

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
          child: const Text(
            'Messages',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: rooms.isEmpty
          ? const EmptyState(
              title: 'No Conversations Yet',
              subtitle:
                  'When you contact a tool owner or someone contacts you, your chats will appear here.',
              icon: Icons.chat_bubble_outline_rounded,
            )
          : ListView.separated(
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 80,
              ),
              itemBuilder: (ctx, i) {
                final room = rooms[i];
                final otherName = room.getOtherParticipantName(auth.userId);
                final otherImage = room.getOtherParticipantImage(auth.userId);
                final otherId = room.getOtherParticipantId(auth.userId);
                final timeStr = _formatTime(room.lastMessageTime);

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: otherImage != null
                            ? CachedNetworkImageProvider(otherImage)
                            : null,
                        child: otherImage == null
                            ? Text(
                                otherName.isNotEmpty
                                    ? otherName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      // Online dot placeholder
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (room.toolName != null)
                        Text(
                          '🔧 ${room.toolName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor.withOpacity(0.7),
                          ),
                        ),
                      Text(
                        room.lastMessage.isEmpty
                            ? 'No messages yet'
                            : room.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatRoomId: room.id,
                          otherUserId: otherId,
                          otherUserName: otherName,
                          otherUserImage: otherImage,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return DateFormat('h:mm a').format(dt);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(dt);
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }
}
