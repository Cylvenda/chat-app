import 'package:chatting_app/components/chat_bubble.dart';
import 'package:chatting_app/components/my_textfield.dart';
import 'package:chatting_app/services/auth/auth_service.dart';
import 'package:chatting_app/services/chats/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // text controller
  final TextEditingController _messageController = TextEditingController();

  // chat & auth services
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  // for text field focus
  final FocusNode myFocusNode = FocusNode();

  // scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _chatService.markChatAsRead(widget.receiverID);

    // listen on focus node (when keyboard opens)
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        // small delay so keyboard can open then scroll
        Future.delayed(const Duration(milliseconds: 250), scrollDown);
      }
    });

    // wait a bit for listview to be built, then scroll down
    Future.delayed(const Duration(milliseconds: 300), scrollDown);
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // safe scroll to bottom
  void scrollDown() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      maxScroll,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // send message
  Future<void> sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    await _chatService.sendMessage(widget.receiverID, text);

    // clear message controller
    _messageController.clear();

    // after sending, scroll to bottom
    Future.delayed(const Duration(milliseconds: 150), scrollDown);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.receiverEmail,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // all message displayed
            Expanded(child: _buildMessageList()),

            // user input
            _buildUserInput(),
          ],
        ),
      ),
    );
  }

  // build message list
  Widget _buildMessageList() {
    final String senderID = _authService.getCurrentUser()!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.receiverID, senderID),
      builder: (context, snapshot) {
        // errors
        if (snapshot.hasError) {
          return const Center(child: Text("Error"));
        }

        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text("Loading..."));
        }

        final docs = snapshot.data?.docs ?? [];

        _chatService.markChatAsRead(widget.receiverID);

        // auto-scroll when new messages come in
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollDown());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final previousDoc = index > 0 ? docs[index - 1] : null;
            return _buildMessageItem(docs[index], previousDoc: previousDoc);
          },
        );
      },
    );
  }

  // build message items
  Widget _buildMessageItem(
    DocumentSnapshot doc, {
    DocumentSnapshot? previousDoc,
  }) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final bool isCurrentUser =
        data['senderID'] == _authService.getCurrentUser()!.uid;

    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
    final DateTime? messageDate = timestamp?.toDate();
    final DateTime? previousDate = _getDocDate(previousDoc);

    final bool showDayHeader =
        messageDate != null &&
        (previousDate == null ||
            messageDate.year != previousDate.year ||
            messageDate.month != previousDate.month ||
            messageDate.day != previousDate.day);

    final String timeText = messageDate != null ? _formatTime(messageDate) : '';

    // align message to the right if current user, otherwise left
    final Alignment alignment = isCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Column(
      children: [
        if (showDayHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _formatDay(messageDate),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        Container(
          alignment: alignment,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ChatBubble(
            message: data['message'] ?? '',
            isCurrentUser: isCurrentUser,
          ),
        ),
        if (timeText.isNotEmpty)
          Container(
            alignment: alignment,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              timeText,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  DateTime? _getDocDate(DocumentSnapshot? doc) {
    if (doc == null) return null;
    final data = doc.data();
    if (data is! Map<String, dynamic>) return null;
    final ts = data['timestamp'];
    return ts is Timestamp ? ts.toDate() : null;
  }

  String _formatDay(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // build message input (keyboard-safe)
  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer
                    .withOpacity(0.4), // softer background
                borderRadius: BorderRadius.circular(30), // pill shape
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
              ), // internal spacing
              child: MyTextField(
                hintText: "Type a message",
                obscureText: false,
                controller: _messageController,
                focusNode: myFocusNode,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // send icon
          Container(
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
