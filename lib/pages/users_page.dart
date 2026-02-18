import 'package:chatting_app/pages/chat_page.dart';
import 'package:chatting_app/services/auth/auth_service.dart';
import 'package:chatting_app/services/chats/chat_service.dart';
import 'package:flutter/material.dart';

class UsersPage extends StatefulWidget {
  final bool showOnlyExistingChats;
  final String sectionTitle;

  const UsersPage({
    super.key,
    required this.showOnlyExistingChats,
    required this.sectionTitle,
  });

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search by email or username...",
              prefixIcon: const Icon(Icons.search),
              border: InputBorder.none,
              filled: true,
              // ignore: deprecated_member_use
              fillColor: cs.secondaryContainer.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        Expanded(child: _buildUserList()),
      ],
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading users"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allUsers = snapshot.data ?? [];
        final currentUserId = _authService.getCurrentUser()?.uid;

        if (currentUserId == null) {
          return const Center(child: Text("No signed-in user"));
        }

        final usersExceptMe = allUsers.where((userData) {
          return userData["uid"] != currentUserId;
        }).toList();

        if (!widget.showOnlyExistingChats) {
          final allPeopleUsers = usersExceptMe.where(_matchesSearch).toList();
          return _buildUsersResult(users: allPeopleUsers);
        }

        return StreamBuilder<Set<String>>(
          stream: _chatService.getChattedUserIdsStream(),
          builder: (context, chattedSnapshot) {
            if (chattedSnapshot.hasError) {
              return const Center(child: Text("Error loading chats"));
            }

            if (chattedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final chattedIds = chattedSnapshot.data ?? <String>{};

            final existingChatUsers = usersExceptMe.where((userData) {
              final uid = userData["uid"];
              return uid is String &&
                  chattedIds.contains(uid) &&
                  _matchesSearch(userData);
            }).toList();

            return StreamBuilder<Map<String, int>>(
              stream: _chatService.getUnreadCountsByUserIdStream(),
              builder: (context, unreadSnapshot) {
                final unreadByUserId = unreadSnapshot.data ?? <String, int>{};
                return _buildUsersResult(
                  users: existingChatUsers,
                  unreadByUserId: unreadByUserId,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUsersResult({
    required List<Map<String, dynamic>> users,
    Map<String, int> unreadByUserId = const {},
  }) {
    if (users.isEmpty) {
      return const Center(child: Text("No users found"));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildSectionTitle(widget.sectionTitle),
        ...users.map((userData) {
          final uid = (userData["uid"] ?? '').toString();
          final unread = unreadByUserId[uid] ?? 0;
          return _buildUserListItem(userData, context, unreadCount: unread);
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  bool _matchesSearch(Map<String, dynamic> userData) {
    final email = (userData["email"] ?? '').toString().toLowerCase();
    final username = (userData["username"] ?? '').toString().toLowerCase();

    return email.contains(_searchQuery) || username.contains(_searchQuery);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
    );
  }

  Widget _buildUserListItem(
    Map<String, dynamic> userData,
    BuildContext context, {
    int unreadCount = 0,
  }) {
    final receiverId = (userData["uid"] ?? '').toString();
    final receiverEmail = (userData["email"] ?? '').toString();
    final username = (userData["username"] ?? '').toString();
    final avatarLabel = username.isNotEmpty
        ? username.substring(0, 1).toUpperCase()
        : '?';

    return InkWell(
      onTap: () {
        if (receiverId.isEmpty || receiverEmail.isEmpty) return;
        _chatService.markChatAsRead(receiverId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              receiverEmail: receiverEmail,
              receiverID: receiverId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                avatarLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username.isNotEmpty ? username : 'Unknown user',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    receiverEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (unreadCount > 0) const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
