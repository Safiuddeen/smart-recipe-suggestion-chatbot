import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/save_chat_service.dart';
import '../services/session_service.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController searchController = TextEditingController();
  final ChatSessionService _chatSessionService = ChatSessionService();

  List<dynamic> _allChats = [];
  List<dynamic> _filteredChats = [];
  bool _isLoading = true;
  String _email = "";

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterChats);
    _loadChats();
  }

  Future<String?> _getCurrentEmail() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.email != null) {
      await SessionService.saveEmail(currentUser.email!);
      return currentUser.email!;
    }

    return await SessionService.getEmail();
  }

  Future<void> _loadChats() async {
    try {
      final email = await _getCurrentEmail();
      if (email == null || email.isEmpty) {
        throw Exception("No logged-in user found");
      }

      final chats = await _chatSessionService.getChatSessions(email);

      setState(() {
        _email = email;
        _allChats = chats;
        _filteredChats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load history: $e")));
    }
  }

  void _filterChats() {
    final q = searchController.text.trim().toLowerCase();

    setState(() {
      _filteredChats = _allChats.where((item) {
        final title = (item["title"] ?? "").toString().toLowerCase();
        return title.contains(q);
      }).toList();
    });
  }

  Future<void> _openChat(dynamic item) async {
    try {
      final result = await _chatSessionService.getOneChatSession(
        _email,
        item["id"],
      );

      if (!mounted) return;

      final messages = List<Map<String, dynamic>>.from(
        (result["messages"] as List).map((e) => Map<String, dynamic>.from(e)),
      );

      context.push(
        '/chatpage',
        extra: {
          "initialMessage": "",
          "sessionId": item["id"],
          "messages": messages,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to open chat: $e")));
    }
  }

  Future<void> _deleteChat(int sessionId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Chat"),
          content: const Text("Are you sure you want to delete this chat?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    try {
      await _chatSessionService.deleteChatSession(_email, sessionId);
      await _loadChats();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat deleted successfully")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  Widget _chatCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openChat(item),
              child: Text(
                (item["title"] ?? "New Chat").toString(),
                style: const TextStyle(
                  color: Color(0xFF7A2D00),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _deleteChat(item["id"]),
            icon: const Icon(Icons.delete_outline, color: Color(0xFF7A2D00)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            context.go('/home');
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFBCEAA9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFBCEAA9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.go('/home'),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screen.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pick or Search chat an existing one",
                    style: TextStyle(
                      fontSize: screen.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  SizedBox(height: screen.height * 0.025),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screen.width * 0.04,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: "Search chat history",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => searchController.clear(),
                          child: const Icon(Icons.close, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredChats.isEmpty
                        ? const Center(
                            child: Text(
                              "No chat history found",
                              style: TextStyle(color: Color(0xFF7A2D00)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredChats.length,
                            itemBuilder: (context, index) {
                              return _chatCard(_filteredChats[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            height: 40,
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.only(right: 16),
            alignment: Alignment.centerRight,
            child: Image.asset(
              'assets/appIcon/footerlogo2.jpg',
              height: 30,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
