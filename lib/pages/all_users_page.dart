import 'package:chatting_app/pages/users_page.dart';
import 'package:flutter/material.dart';

class AllUsersPage extends StatelessWidget {
  const AllUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UsersPage(
      showOnlyExistingChats: false,
      sectionTitle: "All People",
    );
  }
}
