import 'package:chatting_app/pages/users_page.dart';
import 'package:flutter/material.dart';

class ExistingChatsPage extends StatelessWidget {
  const ExistingChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UsersPage(
      showOnlyExistingChats: true,
      sectionTitle: "Existing Chats",
    );
  }
}
