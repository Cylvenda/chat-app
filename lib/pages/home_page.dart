import 'package:chatting_app/components/my_bottom_navigation_bar.dart';
import 'package:chatting_app/pages/all_users_page.dart';
import 'package:chatting_app/pages/existing_chats_page.dart';
import 'package:chatting_app/pages/settings_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tabTitles = ["Home", "People", "Settings"];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          tabTitles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: _buildCurrentTabBody(),
      bottomNavigationBar: MyBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          FocusScope.of(context).unfocus();
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildCurrentTabBody() {
    if (_selectedIndex == 0) {
      return const ExistingChatsPage();
    }

    if (_selectedIndex == 1) {
      return const AllUsersPage();
    }

    return const SettingsContent();
  }
}
