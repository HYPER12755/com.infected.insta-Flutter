import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () {
              // Create new message
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return _ChatListItem(
            avatar: 'https://picsum.photos/seed/user$index/100/100',
            name: _getName(index),
            message: _getLastMessage(index),
            time: _getTime(index),
            isRead: index > 2,
            isOnline: index < 5,
          );
        },
      ),
    );
  }

  String _getName(int index) {
    final names = [
      'Sarah Johnson',
      'Mike Chen',
      'Emma Wilson',
      'David Brown',
      'Lisa Martinez',
      'James Taylor',
      'Amy Davis',
      'Robert Garcia',
      'Jennifer Lee',
      'Chris Anderson',
    ];
    return names[index % names.length];
  }

  String _getLastMessage(int index) {
    final messages = [
      'Hey, how are you doing?',
      'Did you see the new video?',
      'Let\'s meet up tomorrow!',
      'Thanks for the help 🙏',
      'Can\'t wait for the party!',
      'Check out this link',
      'Lol that\'s hilarious 😂',
      'On my way!',
      'Good morning! 🌞',
      'See you later!',
    ];
    return messages[index % messages.length];
  }

  String _getTime(int index) {
    final times = ['2m', '15m', '1h', '2h', '5h', '1d', '2d', '3d', '1w', '2w'];
    return times[index % times.length];
  }
}

class _ChatListItem extends StatelessWidget {
  final String avatar;
  final String name;
  final String message;
  final String time;
  final bool isRead;
  final bool isOnline;

  const _ChatListItem({
    required this.avatar,
    required this.name,
    required this.message,
    required this.time,
    this.isRead = true,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(radius: 28, backgroundImage: NetworkImage(avatar)),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        message,
        style: TextStyle(
          color: isRead ? Colors.grey : Colors.white,
          fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          if (!isRead)
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFC039FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // Open chat conversation
      },
    );
  }
}
