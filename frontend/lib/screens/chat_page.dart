import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const Color _kDark   = Color(0xFF0D1B4B);
const Color _kBlue   = Color(0xFF1A3C8F);
const Color _kLight  = Color(0xFF4A72D4);
const Color _kBg     = Color(0xFFF0F4FF);
const Color _kSec    = Color(0xFF6B7A99);
const Color _kBubbleMe    = Color(0xFF1A3C8F);
const Color _kBubbleOther = Color(0xFFFFFFFF);

class ChatPage extends StatefulWidget {
  final String otherEmail;
  final String otherName;
  final String otherPhoto;

  const ChatPage({
    super.key,
    required this.otherEmail,
    required this.otherName,
    this.otherPhoto = '',
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final api        = ApiService();
  final _msgCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();

  List   _messages  = [];
  bool   _loading   = true;
  String _myEmail   = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _myEmail = await api.storage.read(key: "email") ?? '';
    await _loadMessages();
    // Polling toutes les 5 secondes
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  Future<void> _loadMessages() async {
    try {
      final data = await api.getConversation(widget.otherEmail);
      if (mounted) {
        setState(() { _messages = data; _loading = false; });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      await api.sendMessage(widget.otherEmail, text);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
    } catch (_) { return ''; }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return "Aujourd'hui";
      }
      return "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}";
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kDark, _kBlue, _kLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _kLight,
              backgroundImage: widget.otherPhoto.isNotEmpty
                  ? NetworkImage("${ApiService.baseUrl}/uploads/${widget.otherPhoto}")
                  : null,
              child: widget.otherPhoto.isEmpty
                  ? Text(_initials(widget.otherName),
                      style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherName,
                style: const TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
              Text(widget.otherEmail,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
                overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadMessages),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(children: [
        // ── Messages ──────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kBlue))
              : _messages.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _kBlue.withOpacity(0.08),
                            shape: BoxShape.circle),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 48, color: _kBlue)),
                        const SizedBox(height: 16),
                        const Text("Aucun message",
                          style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold, color: _kDark)),
                        const SizedBox(height: 8),
                        Text("Commencez la conversation avec\n${widget.otherName}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13,
                            color: _kSec, height: 1.5)),
                      ],
                    ))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final senderEmail =
                            (msg['sender']?['email'] ?? '').toString().toLowerCase();
                        final isMe = senderEmail == _myEmail.toLowerCase();
                        final content   = (msg['content'] ?? '').toString();
                        final timeStr   = _formatTime(msg['createdAt']?.toString());
                        final dateStr   = _formatDate(msg['createdAt']?.toString());

                        // Date separator
                        bool showDate = false;
                        if (i == 0) {
                          showDate = true;
                        } else {
                          final prevDate = _formatDate(
                            _messages[i-1]['createdAt']?.toString());
                          showDate = prevDate != dateStr;
                        }

                        return Column(children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20)),
                                child: Text(dateStr,
                                  style: const TextStyle(
                                    fontSize: 11, color: _kBlue,
                                    fontWeight: FontWeight.w600)),
                              ),
                            ),
                          _buildBubble(content, timeStr, isMe),
                        ]);
                      },
                    ),
        ),

        // ── Input ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(
              color: _kBlue.withOpacity(0.08),
              blurRadius: 10, offset: const Offset(0, -3))],
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _kBlue.withOpacity(0.2))),
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 14, color: _kDark),
                    decoration: InputDecoration(
                      hintText: "Écrire un message...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kDark, _kBlue]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: _kBlue.withOpacity(0.3),
                      blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildBubble(String content, String time, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: _kLight,
              backgroundImage: widget.otherPhoto.isNotEmpty
                  ? NetworkImage("${ApiService.baseUrl}/uploads/${widget.otherPhoto}")
                  : null,
              child: widget.otherPhoto.isEmpty
                  ? Text(_initials(widget.otherName),
                      style: const TextStyle(color: Colors.white,
                        fontSize: 9, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _kBubbleMe : _kBubbleOther,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [BoxShadow(
                  color: (isMe ? _kBlue : Colors.black).withOpacity(0.1),
                  blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(content,
                    style: TextStyle(
                      fontSize: 14, height: 1.4,
                      color: isMe ? Colors.white : _kDark)),
                  const SizedBox(height: 4),
                  Text(time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withOpacity(0.6)
                          : _kSec)),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
