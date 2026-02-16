import 'package:chatting_app/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? Colors.green.shade600
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: isCurrentUser
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
