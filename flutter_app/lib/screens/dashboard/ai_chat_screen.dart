import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/services/auth_manager.dart';

class AIChatScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? latestHealthRecord;
  final String? initialPrompt;

  const AIChatScreen({
    super.key,
    required this.token,
    this.latestHealthRecord,
    this.initialPrompt,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _ChatMessage {
  final String id;
  final String text;
  final bool fromUser;
  final DateTime createdAt;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.fromUser,
    required this.createdAt,
  });
}

class _ConversationPreview {
  final String id;
  final String title;
  final String preview;
  final DateTime? lastMessageAt;
  final int messageCount;

  const _ConversationPreview({
    required this.id,
    required this.title,
    required this.preview,
    required this.lastMessageAt,
    required this.messageCount,
  });
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final List<_ChatMessage> _messages = [];

  final List<_ConversationPreview> _conversations = [];

  String? _conversationId;

  bool _sending = false;
  bool _loadingHistory = true;
  bool _loadingConversations = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _startNewChatWithPrompt(widget.initialPrompt!);
    } else {
      _loadConversations();
    }
  }

  void _startNewChatWithPrompt(String prompt) {
    setState(() {
      _loadingConversations = false;
      _loadingHistory = false;
      _conversationId = null;
      _messages.clear();
    });
    
    // Defer the message sending to ensure the build completes first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.text = prompt;
      _sendMessage();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // AUTH
  // ---------------------------------------------------------------------------

  Future<String?> _getToken() async {
    return await AuthManager().getToken() ?? widget.token;
  }

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ---------------------------------------------------------------------------
  // LOAD CONVERSATIONS
  // ---------------------------------------------------------------------------

  Future<void> _loadConversations() async {
    if (!mounted) return;

    setState(() {
      _loadingConversations = true;
      _loadingHistory = true;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing');
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/ai/conversations',
        ),
        headers: _headers(token),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> data =
            decoded['conversations'] ?? [];

        _conversations.clear();

        for (final item in data) {
          _conversations.add(
            _ConversationPreview(
              id: item['id']?.toString() ??
                  item['_id']?.toString() ??
                  '',
              title:
                  item['title']?.toString() ??
                      'Health Chat',
              preview:
                  item['preview']?.toString() ?? '',
              lastMessageAt:
                  item['lastMessageAt'] != null
                      ? DateTime.tryParse(
                          item['lastMessageAt']
                              .toString(),
                        )
                      : null,
              messageCount:
                  int.tryParse(
                        item['messageCount']
                                ?.toString() ??
                            '0',
                      ) ??
                      0,
            ),
          );
        }

        if (_conversations.isNotEmpty) {
          await _loadConversation(
            _conversations.first.id,
          );
        } else {
          _startNewChatInternal();
        }
      } else if (response.statusCode == 401) {
        _showError(
          'Your session has expired. Please sign in again.',
        );
      } else {
        _showError(
          'Could not load previous chats.',
        );

        _startNewChatInternal();
      }
    } catch (e) {
      debugPrint(
        '[AIChat] Load conversations error: $e',
      );

      if (mounted) {
        _startNewChatInternal();

        _showError(
          'Could not load previous chats.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingConversations = false;
          _loadingHistory = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD ONE CONVERSATION
  // ---------------------------------------------------------------------------

  Future<void> _loadConversation(
    String conversationId,
  ) async {
    if (conversationId.isEmpty) return;

    setState(() {
      _loadingHistory = true;
      _messages.clear();
      _conversationId = conversationId;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing');
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/ai/conversations/$conversationId',
        ),
        headers: _headers(token),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final conversation =
            decoded['conversation'];

        final List<dynamic> messages =
            conversation?['messages'] ?? [];

        for (final item in messages) {
          final role =
              item['role']?.toString() ?? '';

          final content =
              item['content']?.toString() ?? '';

          if (content.trim().isEmpty) {
            continue;
          }

          _messages.add(
            _ChatMessage(
              id: item['_id']?.toString() ??
                  DateTime.now()
                      .microsecondsSinceEpoch
                      .toString(),
              text: content,
              fromUser: role == 'user',
              createdAt:
                  item['createdAt'] != null
                      ? DateTime.tryParse(
                            item['createdAt']
                                .toString(),
                          ) ??
                          DateTime.now()
                      : DateTime.now(),
            ),
          );
        }

        _scrollToBottom();
      } else {
        _showError(
          'Could not open this conversation.',
        );
      }
    } catch (e) {
      debugPrint(
        '[AIChat] Load conversation error: $e',
      );

      if (mounted) {
        _showError(
          'Could not load this conversation.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingHistory = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // NEW CHAT
  // ---------------------------------------------------------------------------

  void _startNewChatInternal() {
    setState(() {
      _conversationId = null;
      _messages.clear();
    });

    _scrollToBottom();
  }

  Future<void> _newChat() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _conversationId = null;
      _messages.clear();
      _loadingHistory = false;
    });

    _scrollToBottom();
  }

  // ---------------------------------------------------------------------------
  // SEND MESSAGE
  // ---------------------------------------------------------------------------

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _sending) {
      return;
    }

    FocusScope.of(context).unfocus();

    _controller.clear();

    final now = DateTime.now();

    setState(() {
      _messages.add(
        _ChatMessage(
          id: now.microsecondsSinceEpoch.toString(),
          text: text,
          fromUser: true,
          createdAt: now,
        ),
      );

      _sending = true;
    });

    _scrollToBottom();

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token missing',
        );
      }

      final body = {
        'message': text,
        if (_conversationId != null)
          'conversationId': _conversationId,
      };

      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.baseUrl}/ai/chat',
            ),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 180),
          );

      if (!mounted) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final decoded =
            jsonDecode(response.body);

        final returnedConversationId =
            decoded['conversationId']
                ?.toString();

        if (returnedConversationId != null &&
            returnedConversationId.isNotEmpty) {
          _conversationId =
              returnedConversationId;
        }

        final message =
            decoded['message'];

        final reply =
            message is Map
                ? message['content']
                    ?.toString()
                : null;

        if (reply != null &&
            reply.trim().isNotEmpty) {
          setState(() {
            _messages.add(
              _ChatMessage(
                id: DateTime.now()
                    .microsecondsSinceEpoch
                    .toString(),
                text: reply,
                fromUser: false,
                createdAt: DateTime.now(),
              ),
            );
          });
        } else {
          _showError(
            'The AI returned an empty response.',
          );
        }

        await _refreshConversationList();
      } else if (response.statusCode == 401) {
        _showError(
          'Your session has expired. Please sign in again.',
        );
      } else if (response.statusCode == 503) {
        _showError(
          'Pulse AI is temporarily unavailable.',
        );
      } else {
        String errorMessage =
            'AI request failed.';

        try {
          final decoded =
              jsonDecode(response.body);

          errorMessage =
              decoded['message']
                      ?.toString() ??
                  errorMessage;
        } catch (_) {}

        _showError(errorMessage);
      }
    } catch (e) {
      debugPrint(
        '[AIChat] Send error: $e',
      );

      if (mounted) {
        _showError(
          'Could not connect to Pulse AI.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });

        _scrollToBottom();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // REFRESH CONVERSATIONS
  // ---------------------------------------------------------------------------

  Future<void> _refreshConversationList() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/ai/conversations',
        ),
        headers: _headers(token),
      );

      if (response.statusCode != 200) {
        return;
      }

      final decoded = jsonDecode(response.body);

      final List<dynamic> data =
          decoded['conversations'] ?? [];

      if (!mounted) return;

      setState(() {
        _conversations.clear();

        for (final item in data) {
          _conversations.add(
            _ConversationPreview(
              id: item['id']?.toString() ??
                  item['_id']?.toString() ??
                  '',
              title:
                  item['title']?.toString() ??
                      'Health Chat',
              preview:
                  item['preview']?.toString() ??
                      '',
              lastMessageAt:
                  item['lastMessageAt'] != null
                      ? DateTime.tryParse(
                          item['lastMessageAt']
                              .toString(),
                        )
                      : null,
              messageCount:
                  int.tryParse(
                        item['messageCount']
                                ?.toString() ??
                            '0',
                      ) ??
                      0,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint(
        '[AIChat] Refresh list error: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE CHAT
  // ---------------------------------------------------------------------------

  Future<void> _deleteConversation(
    String id,
  ) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      final response = await http.delete(
        Uri.parse(
          '${ApiConstants.baseUrl}/ai/conversations/$id',
        ),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        if (_conversationId == id) {
          _startNewChatInternal();
        }

        await _refreshConversationList();
      }
    } catch (e) {
      debugPrint(
        '[AIChat] Delete error: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UI HELPERS
  // ---------------------------------------------------------------------------

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController
            .position
            .maxScrollExtent,
        duration:
            const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour % 12 == 0
            ? 12
            : time.hour % 12;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xfff5f7fb),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.black87,
              ),
              onPressed: () {
                Scaffold.of(context)
                    .openDrawer();
              },
            );
          },
        ),

        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    const Color(0xff9f6eff)
                        .withOpacity(0.12),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xff9f6eff),
              ),
            ),

            const SizedBox(width: 10),

            const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Pulse AI',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'Powered by Qwen3',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(
              Icons.add_comment_outlined,
              color: Colors.black87,
            ),
            onPressed: _newChat,
          ),
        ],
      ),

      drawer: _buildDrawer(),

      body: Column(
        children: [
          _buildHealthContext(),

          Expanded(
            child: _loadingHistory
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller:
                            _scrollController,
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          18,
                          16,
                          18,
                        ),
                        itemCount:
                            _messages.length +
                                (_sending ? 1 : 0),
                        itemBuilder:
                            (_, index) {
                          if (_sending &&
                              index ==
                                  _messages.length) {
                            return _buildTyping();
                          }

                          return _buildMessage(
                            _messages[index],
                          );
                        },
                      ),
          ),

          _buildComposer(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DRAWER
  // ---------------------------------------------------------------------------

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,

      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                18,
                12,
                12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration:
                        BoxDecoration(
                      color: const Color(
                        0xff9f6eff,
                      ).withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color:
                          Color(0xff9f6eff),
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Text(
                      'Your conversations',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.close,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Padding(
              padding:
                  const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _newChat();
                  },
                  icon: const Icon(
                    Icons.add_rounded,
                  ),
                  label: const Text(
                    'New chat',
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xff9f6eff,
                    ),
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child:
                  _loadingConversations
                      ? const Center(
                          child:
                              CircularProgressIndicator(),
                        )
                      : _conversations.isEmpty
                          ? const Center(
                              child: Padding(
                                padding:
                                    EdgeInsets.all(
                                  24,
                                ),
                                child: Text(
                                  'No previous chats yet.',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        Colors.black45,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount:
                                  _conversations
                                      .length,
                              itemBuilder:
                                  (_, index) {
                                final chat =
                                    _conversations[
                                        index];

                                final selected =
                                    chat.id ==
                                        _conversationId;

                                return ListTile(
                                  selected:
                                      selected,
                                  selectedTileColor:
                                      const Color(
                                    0xff9f6eff,
                                  ).withOpacity(
                                    0.08,
                                  ),

                                  leading:
                                      const Icon(
                                    Icons
                                        .chat_bubble_outline_rounded,
                                  ),

                                  title: Text(
                                    chat.title,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),

                                  subtitle:
                                      chat.preview
                                              .isEmpty
                                          ? null
                                          : Text(
                                              chat.preview,
                                              maxLines:
                                                  1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                            ),

                                  trailing:
                                      PopupMenuButton<
                                          String>(
                                    onSelected:
                                        (value) {
                                      if (value ==
                                          'delete') {
                                        _deleteConversation(
                                          chat.id,
                                        );
                                      }
                                    },
                                    itemBuilder:
                                        (_) => const [
                                      PopupMenuItem(
                                        value:
                                            'delete',
                                        child:
                                            Text(
                                          'Delete',
                                        ),
                                      ),
                                    ],
                                  ),

                                  onTap: () {
                                    Navigator.pop(
                                      context,
                                    );

                                    _loadConversation(
                                      chat.id,
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEALTH CONTEXT
  // ---------------------------------------------------------------------------

  Widget _buildHealthContext() {
    final record =
        widget.latestHealthRecord;

    if (record == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      padding:
          const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.black.withOpacity(0.05),
        ),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.favorite_rounded,
            color: Colors.redAccent,
            size: 20,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              'Latest health data • '
              '${record['steps'] ?? 0} steps • '
              '${record['heartRate'] ?? 0} BPM',

              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 74,
              height: 74,
              decoration:
                  BoxDecoration(
                color: const Color(
                  0xff9f6eff,
                ).withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 36,
                color:
                    Color(0xff9f6eff),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'How can I help?',
              style: TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Ask me about your activity, sleep, '
              'heart rate or other health metrics.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 24),

            _suggestion(
              'How was my sleep?',
            ),

            _suggestion(
              'How active was I today?',
            ),

            _suggestion(
              'Explain my heart rate',
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestion(String text) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () {
          _controller.text = text;
          _sendMessage();
        },
        style:
            OutlinedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
        child: Align(
          alignment:
              Alignment.centerLeft,
          child: Text(text),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MESSAGE
  // ---------------------------------------------------------------------------

  Widget _buildMessage(
    _ChatMessage message,
  ) {
    return Align(
      alignment: message.fromUser
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  0.84,
        ),

        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),

        decoration:
            BoxDecoration(
          color: message.fromUser
              ? const Color(
                  0xff9f6eff,
                )
              : Colors.white,

          borderRadius:
              BorderRadius.circular(
            18,
          ).copyWith(
            bottomRight:
                message.fromUser
                    ? const Radius.circular(
                        4,
                      )
                    : null,
            bottomLeft:
                message.fromUser
                    ? null
                    : const Radius.circular(
                        4,
                      ),
          ),

          boxShadow:
              message.fromUser
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(
                          0.035,
                        ),
                        blurRadius: 8,
                        offset:
                            const Offset(
                          0,
                          3,
                        ),
                      ),
                    ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              message.text,
              style: TextStyle(
                color:
                    message.fromUser
                        ? Colors.white
                        : const Color(
                            0xff2d3748,
                          ),
                fontSize: 14,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              _formatTime(
                message.createdAt,
              ),
              style: TextStyle(
                color:
                    message.fromUser
                        ? Colors.white
                            .withOpacity(
                            0.65,
                          )
                        : Colors.black38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TYPING
  // ---------------------------------------------------------------------------

  Widget _buildTyping() {
    return Align(
      alignment:
          Alignment.centerLeft,

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),

        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),

        child: const SizedBox(
          width: 28,
          height: 20,
          child: Center(
            child:
                SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPOSER
  // ---------------------------------------------------------------------------

  Widget _buildComposer() {
    return SafeArea(
      top: false,

      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          10,
        ),

        color: Colors.white,

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,

          children: [
            Expanded(
              child: TextField(
                controller:
                    _controller,

                minLines: 1,
                maxLines: 5,

                textInputAction:
                    TextInputAction.newline,

                decoration:
                    InputDecoration(
                  hintText:
                      'Ask Pulse AI...',
                  filled: true,
                  fillColor:
                      const Color(
                    0xfff4f7f6,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),

                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                ),

                onSubmitted:
                    (_) =>
                        _sendMessage(),
              ),
            ),

            const SizedBox(width: 8),

            SizedBox(
              width: 48,
              height: 48,

              child:
                  ElevatedButton(
                onPressed:
                    _sending
                        ? null
                        : _sendMessage,

                style:
                    ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.zero,

                  backgroundColor:
                      const Color(
                    0xff9f6eff,
                  ),

                  foregroundColor:
                      Colors.white,

                  shape:
                      const CircleBorder(),

                  elevation: 0,
                ),

                child: _sending
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons
                            .arrow_upward_rounded,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}