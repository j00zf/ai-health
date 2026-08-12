import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/services/auth_manager.dart';

/// Health-focused AI chat screen opened from the main dashboard.
///
/// The API route used here is POST /ai/chat. Expected request:
/// {
///   "message": "...",
///   "healthData": { ... }
/// }
///
/// Expected response can contain one of: {"reply":"..."},
/// {"message":"..."}, or {"data":{"reply":"..."}}.
class AIChatScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? latestHealthRecord;

  const AIChatScreen({
    super.key,
    required this.token,
    this.latestHealthRecord,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool fromUser;

  const _ChatMessage({
    required this.text,
    required this.fromUser,
  });
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Hi! I’m Pulse AI. Ask me about your health metrics, activity, or trends. I can explain your data, but I can’t replace a doctor.',
      fromUser: false,
    ),
  ];

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _sending) return;

    FocusScope.of(context).unfocus();
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: message, fromUser: true));
      _sending = true;
    });
    _scrollToBottom();

    try {
      final token = await AuthManager().getToken() ?? widget.token;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/ai/chat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'healthData': widget.latestHealthRecord,
        }),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final reply = _extractReply(decoded);

        setState(() {
          _messages.add(
            _ChatMessage(
              text: reply ?? 'I received your request, but the AI did not return a message.',
              fromUser: false,
            ),
          );
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _messages.add(
            const _ChatMessage(
              text: 'Your app session has expired. Please sign in again.',
              fromUser: false,
            ),
          );
        });
      } else {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: 'AI request failed (${response.statusCode}). Please try again.',
              fromUser: false,
            ),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatMessage(
            text: 'Could not connect to Pulse AI. Check your internet connection and try again.',
            fromUser: false,
          ),
        );
      });
      debugPrint('[AIChat] $e');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  String? _extractReply(dynamic decoded) {
    if (decoded is String && decoded.trim().isNotEmpty) return decoded;

    if (decoded is Map) {
      final direct = decoded['reply'] ?? decoded['message'] ?? decoded['response'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString();
      }

      final data = decoded['data'];
      if (data is Map) {
        final nested = data['reply'] ?? data['message'] ?? data['response'];
        if (nested != null && nested.toString().trim().isNotEmpty) {
          return nested.toString();
        }
      }
    }

    return null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xff9f6eff).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xff9f6eff),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Health assistant',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.latestHealthRecord != null)
            _buildHealthContextCard(widget.latestHealthRecord!),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (_, index) => _buildMessage(_messages[index]),
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildHealthContextCard(Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Latest health data: ${record['date'] ?? 'today'} • ${record['steps'] ?? 0} steps • ${record['heartRate'] ?? 0} BPM',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    return Align(
      alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: message.fromUser ? const Color(0xff9f6eff) : Colors.white,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: message.fromUser ? const Radius.circular(4) : null,
            bottomLeft: message.fromUser ? null : const Radius.circular(4),
          ),
          boxShadow: message.fromUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.fromUser ? Colors.white : const Color(0xff2d3748),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask Pulse AI about your health...',
                  filled: true,
                  fillColor: const Color(0xfff4f7f6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xff9f6eff),
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
