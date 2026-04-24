import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

import 'package:infected_insta/core/widgets/shimmer.dart';
import 'package:infected_insta/data/repositories/message_repository.dart';
import 'package:infected_insta/data/repositories/user_repository.dart';
import 'package:infected_insta/features/call/screens/call_screen.dart';
import 'package:infected_insta/features/call/models/call_model.dart';
import 'package:infected_insta/features/create_post/providers/storage_provider.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

// ─── App theme colours ────────────────────────────────────────────────────────
const _kPurple  = Color(0xFFC039FF);
const _kPurple2 = Color(0xFF9B59B6);
const _kSurface = Color(0xFF1A1A2E);
const _kSurface2= Color(0xFF0D0D1A);

// Quick-react emoji set (Instagram-style)
const _kReactions = ['❤️', '😂', '😮', '😢', '😡', '👍'];

// ─────────────────────────────────────────────────────────────────────────────
//  INBOX SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});
  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final _repo     = MessageRepository();
  final _userRepo = UserRepository();

  List<Map<String, dynamic>> _convs  = [];
  List<Map<String, dynamic>> _notes  = [];   // Notes from people you follow
  bool _isLoading = true;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _userRepo.getCurrentUserId();
    if (uid == null) { setState(() => _isLoading = false); return; }
    final result = await _repo.getConversations(uid);
    await _loadNotes(uid);
    if (mounted) {
      result.fold(
        (_) => setState(() => _isLoading = false),
        (c) => setState(() { _convs = c; _isLoading = false; }),
      );
    }
  }

  Future<void> _loadNotes(String uid) async {
    try {
      // Notes: recent 24h text from people current user follows
      final res = await supabase
          .from('notes')
          .select('id, text, user_id, created_at, '
              'profiles!notes_user_id_fkey(username, avatar_url)')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(15);
      if (mounted) {
        setState(() {
          _notes = (res as List).map<Map<String, dynamic>>((r) {
            final p = r['profiles'] as Map<String, dynamic>? ?? {};
            return {
              'id': r['id'],
              'text': r['text'] ?? '',
              'userId': r['user_id'],
              'username': p['username'] ?? 'user',
              'avatar': p['avatar_url'] ?? '',
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _convs;
    return _convs.where((c) =>
        (c['username'] as String? ?? '')
            .toLowerCase()
            .contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final myName = supabase.auth.currentUser?.userMetadata?['username']
        as String? ?? 'Messages';

    return Scaffold(
      backgroundColor: _kSurface2,
      appBar: _buildAppBar(myName, context),
      body: RefreshIndicator(
        onRefresh: _load,
        color: _kPurple,
        child: _isLoading
            ? ListView.builder(itemCount: 6,
                itemBuilder: (_, __) => const UserTileSkeleton())
            : CustomScrollView(slivers: [
                // ── Notes row ───────────────────────────────────────────────
                if (_notes.isNotEmpty)
                  SliverToBoxAdapter(child: _NotesRow(notes: _notes)),

                // ── Search bar ──────────────────────────────────────────────
                SliverToBoxAdapter(child: _SearchBar(
                  ctrl: _searchCtrl,
                  onChanged: (q) => setState(() => _searchQuery = q),
                )),

                // ── Conversations ───────────────────────────────────────────
                if (_filtered.isEmpty)
                  SliverFillRemaining(child: _emptyInbox(context))
                else
                  SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) => _ConvTile(
                      conv: _filtered[i],
                      onTap: () => _openChat(_filtered[i], context),
                    ),
                    childCount: _filtered.length,
                  )),
              ]),
      ),
    );
  }

  AppBar _buildAppBar(String name, BuildContext context) {
    return AppBar(
      backgroundColor: _kSurface2,
      titleSpacing: 16,
      title: Row(children: [
        Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(width: 6),
        const FaIcon(FontAwesomeIcons.chevronDown, size: 14, color: Colors.white54),
      ]),
      actions: [
        // Notification bell
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.bell, size: 20),
          onPressed: () => context.push('/notifications'),
        ),
        // New message / compose
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 20),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NewMessageScreen()))
              .then((_) => _load()),
        ),
      ],
    );
  }

  Widget _emptyInbox(BuildContext ctx) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
      const FaIcon(FontAwesomeIcons.paperPlane, size: 56, color: Colors.white24),
      const SizedBox(height: 16),
      const Text('Your Messages', style: TextStyle(
          color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Send private photos and messages to a friend or group.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => const NewMessageScreen())),
        child: const Text('Send Message'),
      ),
    ]));
  }

  void _openChat(Map<String, dynamic> conv, BuildContext ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) =>
        ConversationChatScreen(
          conversationId: conv['id']?.toString() ?? '',
          username: conv['username'] as String? ?? 'User',
          userAvatar: conv['avatar'] as String? ?? '',
          otherUserId: conv['otherUserId'] as String? ?? '',
        )));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOTES ROW (Instagram-style top of inbox)
// ─────────────────────────────────────────────────────────────────────────────
class _NotesRow extends StatelessWidget {
  final List<Map<String, dynamic>> notes;
  const _NotesRow({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text('Notes', style: TextStyle(
            color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: notes.length + 1, // +1 for "Your note"
          itemBuilder: (_, i) {
            if (i == 0) return _YourNoteItem();
            return _NoteItem(note: notes[i - 1]);
          },
        ),
      ),
      const Divider(color: Colors.white10, height: 1),
    ]);
  }
}

class _YourNoteItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddNote(context),
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(alignment: Alignment.bottomRight, children: [
            // Purple gradient ring
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [_kPurple, _kPurple2]),
                boxShadow: [BoxShadow(
                    color: _kPurple.withValues(alpha: 0.4),
                    blurRadius: 8, spreadRadius: 1)],
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: _kSurface,
                child: const FaIcon(FontAwesomeIcons.user,
                    size: 20, color: Colors.white54),
              ),
            ),
            Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(
                  color: _kPurple, shape: BoxShape.circle),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.plus, size: 9, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 5),
          const Text('Your note', textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.white54)),
        ]),
      ),
    );
  }

  void _showAddNote(BuildContext ctx) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Leave a note',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 4),
          const Text('Share a thought — disappears in 24h',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(
              hintText: 'What\'s on your mind?',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: _kSurface2,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              counterStyle: const TextStyle(color: Colors.white30),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                final uid = supabase.auth.currentUser?.id;
                if (uid == null || ctrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await supabase.from('notes').insert({
                    'user_id': uid,
                    'text': ctrl.text.trim(),
                    'created_at': DateTime.now().toIso8601String(),
                    'expires_at': DateTime.now()
                        .add(const Duration(hours: 24)).toIso8601String(),
                  });
                } catch (_) {}
              },
              child: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  final Map<String, dynamic> note;
  const _NoteItem({required this.note});

  @override
  Widget build(BuildContext context) {
    final text   = note['text'] as String? ?? '';
    final avatar = note['avatar'] as String? ?? '';
    final name   = note['username'] as String? ?? '';

    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 12),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(alignment: Alignment.topCenter, children: [
          // Avatar with gradient ring
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_kPurple, _kPurple2]),
              boxShadow: [BoxShadow(
                  color: _kPurple.withValues(alpha: 0.35),
                  blurRadius: 6)],
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              backgroundColor: _kSurface,
              backgroundImage: avatar.isNotEmpty
                  ? CachedNetworkImageProvider(avatar) : null,
              child: avatar.isEmpty
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white)) : null,
            ),
          ),
          // Note text bubble
          if (text.isNotEmpty)
            Positioned(
              top: -6,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 72),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(text,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Colors.white)),
              ),
            ),
        ]),
        const SizedBox(height: 5),
        Text(name, textAlign: TextAlign.center,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.white38),
          hintText: 'Search',
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF1E1E2E),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                  onPressed: () { ctrl.clear(); onChanged(''); })
              : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONVERSATION TILE
// ─────────────────────────────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final Map<String, dynamic> conv;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatar    = conv['avatar'] as String? ?? '';
    final username  = conv['username'] as String? ?? 'User';
    final lastMsg   = conv['last_message'] as String? ?? '';
    final updatedAt = conv['updated_at'] as String?;
    final myId      = supabase.auth.currentUser?.id;
    final lastSender= conv['last_sender_id'] as String?;
    final isUnread  = lastSender != null && lastSender != myId && lastMsg.isNotEmpty;

    return InkWell(
      onTap: onTap,
      splashColor: _kPurple.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          // ── Avatar (with purple glow if unread) ──
          Stack(children: [
            Container(
              decoration: isUnread ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: _kPurple.withValues(alpha: 0.5),
                    blurRadius: 10, spreadRadius: 1)],
              ) : null,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2A2A3E),
                backgroundImage: avatar.isNotEmpty
                    ? CachedNetworkImageProvider(avatar) : null,
                child: avatar.isEmpty
                    ? Text(username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white,
                            fontSize: 18, fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
            // Online dot
            if (conv['is_online'] == true)
              Positioned(bottom: 2, right: 2,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kSurface2, width: 1.5)),
                )),
          ]),
          const SizedBox(width: 14),

          // ── Content ──
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(username, style: TextStyle(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                fontSize: 15)),
            const SizedBox(height: 2),
            Row(children: [
              Expanded(child: Text(
                _previewText(lastMsg, lastSender == myId),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isUnread ? Colors.white70 : Colors.white38,
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                    fontSize: 13),
              )),
              const SizedBox(width: 6),
              if (isUnread) ...[
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: _kPurple, shape: BoxShape.circle)),
                const SizedBox(width: 4),
              ],
              Text(_fmtTime(updatedAt),
                  style: TextStyle(
                      fontSize: 11,
                      color: isUnread ? _kPurple : Colors.white24)),
            ]),
          ])),

          // ── Camera / video call quick actions ──
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CallScreen(
                  calleeId: conv['otherUserId'] as String? ?? '',
                  calleeName: username,
                  calleeAvatar: avatar,
                  callType: CallType.video,
                ))),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                shape: BoxShape.circle),
              child: const FaIcon(FontAwesomeIcons.video,
                  size: 15, color: Colors.white60),
            ),
          ),
        ]),
      ),
    );
  }

  String _previewText(String text, bool isMe) {
    if (text.isEmpty) return 'Start a conversation';
    final prefix = isMe ? 'You: ' : '';
    if (text.startsWith('http') && (text.contains('.jpg') ||
        text.contains('.png') || text.contains('supabase'))) {
      return '$prefix📷 Photo';
    }
    if (text.startsWith('AUDIO:')) return '$prefix🎤 Voice message';
    return '$prefix$text';
  }

  String _fmtTime(String? raw) {
    if (raw == null) return '';
    final t = DateTime.tryParse(raw) ?? DateTime.now();
    final d = DateTime.now().difference(t);
    if (d.inDays >= 7)  return '${t.month}/${t.day}';
    if (d.inDays > 0)   return '${d.inDays}d';
    if (d.inHours > 0)  return '${d.inHours}h';
    if (d.inMinutes > 0)return '${d.inMinutes}m';
    return 'now';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONVERSATION CHAT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ConversationChatScreen extends StatefulWidget {
  final String conversationId;
  final String username;
  final String? userAvatar;
  final String otherUserId;

  const ConversationChatScreen({
    super.key,
    required this.conversationId,
    required this.username,
    this.userAvatar,
    this.otherUserId = '',
  });

  @override
  State<ConversationChatScreen> createState() => _ConversationChatScreenState();
}

class _ConversationChatScreenState extends State<ConversationChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _repo       = MessageRepository();

  late final String _myId;
  bool _isSending   = false;
  bool _isTyping    = false;
  bool _otherTyping = false;
  Timer? _typingTimer;
  StreamSubscription? _typingSub;

  // Reply state
  Map<String, dynamic>? _replyTo;

  // Voice recording state
  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _myId = supabase.auth.currentUser?.id ?? '';
    _markRead();
    if (widget.otherUserId.isNotEmpty) {
      _typingSub = _repo.watchTyping(widget.conversationId, widget.otherUserId)
          .listen((t) { if (mounted) setState(() => _otherTyping = t); });
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    _typingSub?.cancel();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    if (widget.otherUserId.isNotEmpty) {
      _repo.sendTyping(widget.conversationId, _myId, false);
    }
    super.dispose();
  }

  void _markRead() =>
      _repo.markConversationRead(widget.conversationId, _myId);

  void _onTypingChanged(String val) {
    if (!_isTyping && val.isNotEmpty) {
      _isTyping = true;
      _repo.sendTyping(widget.conversationId, _myId, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isTyping = false;
      _repo.sendTyping(widget.conversationId, _myId, false);
    });
    setState(() {});
  }

  Future<void> _send({String? imageUrl, String? audioUrl}) async {
    final text = imageUrl != null || audioUrl != null
        ? (audioUrl != null ? 'AUDIO:$audioUrl' : imageUrl!)
        : _msgCtrl.text.trim();
    if (text.isEmpty) return;
    if (_isSending) return;

    final replyRef = _replyTo;
    setState(() { _isSending = true; _replyTo = null; });
    _msgCtrl.clear();
    _isTyping = false;
    _repo.sendTyping(widget.conversationId, _myId, false);

    await _repo.sendMessage(widget.conversationId, {
      'text': text,
      'reply_to_id': replyRef?['id'],
      'reply_text': replyRef?['text'],
      'reply_sender': replyRef?['sender_name'],
    });

    if (mounted) setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    try {
      final path = 'dm/$_myId/${const Uuid().v4()}.jpg';
      final url  = await SupabaseStorageService(supabase)
          .uploadFile(file.path, path, bucket: 'messages');
      await _send(imageUrl: url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image failed: $e')));
      }
    }
  }

  // ── Voice recording ────────────────────────────────────────────────────────
  final _audioRecorder = AudioRecorder();

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) return;
      final dir  = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = path;
      _recordDuration = Duration.zero;
      await _audioRecorder.start(
        RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: path,
      );
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordDuration += const Duration(seconds: 1));
      });
      setState(() => _isRecording = true);
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordTimer?.cancel();
    await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (cancel || _recordingPath == null) { _recordingPath = null; return; }
    try {
      final path = 'dm/$_myId/${const Uuid().v4()}.m4a';
      final url  = await SupabaseStorageService(supabase)
          .uploadFile(_recordingPath!, path, bucket: 'messages');
      _recordingPath = null;
      await _send(audioUrl: url);
    } catch (_) { _recordingPath = null; }
  }

  // ── Add/remove reaction ────────────────────────────────────────────────────
  Future<void> _react(String msgId, String emoji) async {
    try {
      // Upsert: one reaction per user per message
      await supabase.from('message_reactions').upsert({
        'message_id': msgId,
        'user_id': _myId,
        'emoji': emoji,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'message_id,user_id');
    } catch (_) {}
  }

  Future<void> _removeReaction(String msgId) async {
    try {
      await supabase.from('message_reactions').delete()
          .match({'message_id': msgId, 'user_id': _myId});
    } catch (_) {}
  }

  // ── Unsend ─────────────────────────────────────────────────────────────────
  Future<void> _unsend(String msgId) async {
    try {
      await supabase.from('messages')
          .update({'text': '', 'is_deleted': true}).eq('id', msgId);
    } catch (_) {}
  }

  // ── Long-press message sheet ───────────────────────────────────────────────
  void _showMsgOptions(BuildContext ctx, Map<String, dynamic> msg) {
    final isMe = msg['isMe'] == true;
    final msgId = msg['id']?.toString() ?? '';

    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),

          // ── Reaction strip ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _kReactions.map((e) => GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _react(msgId, e);
                },
                child: Text(e, style: const TextStyle(fontSize: 30)),
              )).toList(),
            ),
          ),
          const Divider(color: Colors.white12),

          // ── Action items ──
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.reply, size: 18),
            title: const Text('Reply'),
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _replyTo = msg);
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.copy, size: 18),
            title: const Text('Copy'),
            onTap: () {
              Navigator.pop(ctx);
              Clipboard.setData(ClipboardData(
                  text: msg['text'] as String? ?? ''));
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Copied'),
                      duration: Duration(seconds: 1)));
            },
          ),
          if (isMe)
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.trash,
                  size: 18, color: Colors.redAccent),
              title: const Text('Unsend',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () { Navigator.pop(ctx); _unsend(msgId); },
            ),
          const SizedBox(height: 8),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar  = widget.userAvatar ?? '';
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: _kSurface2,
      appBar: _buildAppBar(avatar, primary, context),
      body: Column(children: [
        // ── Messages list ──────────────────────────────────────────────────
        Expanded(child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _repo.getMessagesStream(widget.conversationId, _myId),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView.builder(itemCount: 6,
                  itemBuilder: (_, __) => const _MsgBubbleSkeleton());
            }
            final msgs = snap.data ?? [];
            if (msgs.isEmpty) return _buildEmptyState(avatar);

            _scrollToBottom();

            return ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final msg  = msgs[i];
                final prev = i > 0 ? msgs[i - 1] : null;
                final showDate = _shouldShowDate(msg, prev);
                return Column(children: [
                  if (showDate) _DateDivider(ts: msg['created_at']),
                  GestureDetector(
                    onLongPress: () => _showMsgOptions(context, msg),
                    onHorizontalDragEnd: (d) {
                      if (d.primaryVelocity != null && d.primaryVelocity! > 200) {
                        setState(() => _replyTo = msg);
                        HapticFeedback.selectionClick();
                      }
                    },
                    child: _MsgBubble(
                      msg: msg,
                      primary: primary,
                      onReact: (e) => _react(msg['id']?.toString() ?? '', e),
                    ),
                  ),
                ]);
              },
            );
          },
        )),

        // ── Typing indicator ───────────────────────────────────────────────
        if (_otherTyping)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(children: [
              CircleAvatar(radius: 13, backgroundColor: const Color(0xFF2A2A3E),
                  backgroundImage: (widget.userAvatar?.isNotEmpty == true)
                      ? CachedNetworkImageProvider(widget.userAvatar!) : null),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min,
                    children: [
                  _TypingDot(delay: 0),
                  SizedBox(width: 4),
                  _TypingDot(delay: 150),
                  SizedBox(width: 4),
                  _TypingDot(delay: 300),
                ]),
              ),
            ]),
          ),

        // ── Reply preview bar ──────────────────────────────────────────────
        if (_replyTo != null)
          _ReplyPreview(
            msg: _replyTo!,
            onClose: () => setState(() => _replyTo = null),
          ),

        // ── Voice recording UI ─────────────────────────────────────────────
        if (_isRecording)
          _RecordingBar(
            duration: _recordDuration,
            onCancel: () => _stopRecording(cancel: true),
            onSend: () => _stopRecording(),
          ),

        // ── Input bar ──────────────────────────────────────────────────────
        if (!_isRecording)
          _InputBar(
            ctrl: _msgCtrl,
            isSending: _isSending,
            onChanged: _onTypingChanged,
            onSend: _send,
            onImage: _pickImage,
            onRecordStart: _startRecording,
          ),
      ]),
    );
  }

  AppBar _buildAppBar(String avatar, Color primary, BuildContext ctx) {
    return AppBar(
      backgroundColor: _kSurface2,
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () => ctx.push('/profile/${widget.username}'),
        child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2A2A3E),
            backgroundImage: avatar.isNotEmpty
                ? CachedNetworkImageProvider(avatar) : null,
            child: avatar.isEmpty
                ? Text(widget.username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white)) : null,
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
            Text(widget.username,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (_otherTyping)
              Text('typing…', style: TextStyle(fontSize: 11, color: primary))
            else
              const Text('Active now',
                  style: TextStyle(fontSize: 11, color: Colors.white38)),
          ]),
        ]),
      ),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.phone, size: 20),
          onPressed: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => CallScreen(
                calleeId: widget.otherUserId,
                calleeName: widget.username,
                calleeAvatar: avatar,
                callType: CallType.audio))),
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.video, size: 20),
          onPressed: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => CallScreen(
                calleeId: widget.otherUserId,
                calleeName: widget.username,
                calleeAvatar: avatar,
                callType: CallType.video))),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String avatar) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        children: [
      CircleAvatar(radius: 40, backgroundColor: const Color(0xFF2A2A3E),
          backgroundImage: avatar.isNotEmpty
              ? CachedNetworkImageProvider(avatar) : null,
          child: avatar.isEmpty
              ? Text(widget.username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 28)) : null),
      const SizedBox(height: 12),
      Text(widget.username,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 4),
      Text('Say hi to ${widget.username}! 👋',
          style: const TextStyle(color: Colors.white38)),
    ]));
  }

  bool _shouldShowDate(Map<String, dynamic> msg, Map<String, dynamic>? prev) {
    if (prev == null) return true;
    final t1 = DateTime.tryParse(msg['created_at'] ?? '') ?? DateTime.now();
    final t2 = DateTime.tryParse(prev['created_at'] ?? '') ?? DateTime.now();
    return t1.difference(t2).inMinutes > 20;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MESSAGE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _MsgBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final Color primary;
  final Function(String emoji) onReact;

  const _MsgBubble({required this.msg, required this.primary, required this.onReact});

  @override
  Widget build(BuildContext context) {
    final isMe     = msg['isMe'] == true;
    final text     = msg['text'] as String? ?? '';
    final isDeleted= msg['is_deleted'] == true;
    final replyText= msg['reply_text'] as String?;
    final replySender = msg['reply_sender'] as String?;
    final reactions = msg['reactions'] as List? ?? [];
    final isRead   = msg['is_read'] == true;

    final isImage  = !isDeleted && text.startsWith('http') &&
        (text.contains('.jpg') || text.contains('.png') ||
            text.contains('supabase') || text.contains('storage'));
    final isAudio  = !isDeleted && text.startsWith('AUDIO:');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.74),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ── Bubble ──────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [_kPurple, Color(0xFF7B2FBE)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: isMe ? null : const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(20),
                  topRight:    const Radius.circular(20),
                  bottomLeft:  Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: isMe ? [BoxShadow(
                    color: _kPurple.withValues(alpha: 0.3),
                    blurRadius: 8, offset: const Offset(0, 2))] : null,
              ),
              child: Column(children: [
                // Reply preview inside bubble
                if (replyText != null && replyText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                    ),
                    child: Row(children: [
                      Container(width: 3, height: 32,
                          color: Colors.white60,
                          margin: const EdgeInsets.only(right: 8)),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(replySender ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 11, color: Colors.white70)),
                        Text(replyText,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12,
                                color: Colors.white60)),
                      ])),
                    ]),
                  ),

                // Message body
                if (isDeleted)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Text('Message unsent',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontStyle: FontStyle.italic, fontSize: 14)),
                  )
                else if (isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(replyText != null ? 0 : 20),
                      topRight: Radius.circular(replyText != null ? 0 : 20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    child: CachedNetworkImage(
                        imageUrl: text, width: 220, height: 220,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(width: 220, height: 220,
                            color: const Color(0xFF1E1E2E))),
                  )
                else if (isAudio)
                  _AudioBubble(
                      audioUrl: text.replaceFirst('AUDIO:', ''),
                      isMe: isMe)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Text(text,
                        style: TextStyle(
                            color: isMe ? Colors.white
                                : Colors.white.withValues(alpha: 0.9),
                            fontSize: 15, height: 1.3)),
                  ),
              ]),
            ),

            // ── Reactions row ───────────────────────────────────────────────
            if (reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min,
                      children: _buildReactions(reactions)),
                ),
              ),

            // ── Meta (time + read) ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 2, right: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_fmtTime(msg['created_at']),
                    style: const TextStyle(
                        fontSize: 10, color: Colors.white24)),
                if (isMe) ...[
                  const SizedBox(width: 3),
                  Icon(isRead ? Icons.done_all : Icons.done,
                      size: 12,
                      color: isRead ? Colors.blue[300] : Colors.white24),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReactions(List reactions) {
    // Group by emoji
    final counts = <String, int>{};
    for (final r in reactions) {
      final e = r['emoji'] as String? ?? '';
      counts[e] = (counts[e] ?? 0) + 1;
    }
    return counts.entries.map((e) => Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text('${e.key} ${e.value}',
          style: const TextStyle(fontSize: 12)),
    )).toList();
  }

  String _fmtTime(dynamic raw) {
    if (raw == null) return '';
    final t = raw is String
        ? (DateTime.tryParse(raw) ?? DateTime.now()) : DateTime.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AUDIO BUBBLE (voice message playback UI)
// ─────────────────────────────────────────────────────────────────────────────
class _AudioBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  const _AudioBubble({required this.audioUrl, required this.isMe});

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  double _progress = 0;
  Duration _total = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.setUrl(widget.audioUrl).then((_) {
      if (mounted) setState(() => _total = _player.duration ?? Duration.zero);
    });
    _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        _position = pos;
        _progress = _total.inMilliseconds > 0
            ? pos.inMilliseconds / _total.inMilliseconds : 0;
      });
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() { _isPlaying = false; _progress = 0; });
        _player.seek(Duration.zero);
      }
    });
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(20, (i) {
              final h = 4.0 + (sin(i * 0.8) * 8).abs();
              final filled = i / 20 < _progress;
              return Container(width: 3, height: h,
                decoration: BoxDecoration(
                  color: filled ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(2)));
            })),
          const SizedBox(height: 3),
          Text(_total > Duration.zero ? _fmt(_position) : 'Voice message',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATE DIVIDER
// ─────────────────────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final dynamic ts;
  const _DateDivider({required this.ts});

  @override
  Widget build(BuildContext context) {
    final t = ts is String
        ? (DateTime.tryParse(ts) ?? DateTime.now()) : DateTime.now();
    final now  = DateTime.now();
    String label;
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      label = 'Today';
    } else if (t.year == now.year && t.month == now.month &&
        t.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = '${t.day}/${t.month}/${t.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider(color: Colors.white12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: const TextStyle(color: Colors.white24, fontSize: 11)),
        ),
        const Expanded(child: Divider(color: Colors.white12)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REPLY PREVIEW BAR
// ─────────────────────────────────────────────────────────────────────────────
class _ReplyPreview extends StatelessWidget {
  final Map<String, dynamic> msg;
  final VoidCallback onClose;
  const _ReplyPreview({required this.msg, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final text = msg['text'] as String? ?? '';
    final preview = text.startsWith('http')
        ? '📷 Photo'
        : text.startsWith('AUDIO:') ? '🎤 Voice message'
        : (text.length > 60 ? '${text.substring(0, 60)}…' : text);

    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(children: [
        Container(width: 3, height: 36,
            color: _kPurple,
            margin: const EdgeInsets.only(right: 12)),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg['isMe'] == true ? 'You' : 'Reply',
              style: const TextStyle(color: _kPurple,
                  fontWeight: FontWeight.bold, fontSize: 12)),
          Text(preview,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: Colors.white38),
          onPressed: onClose,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RECORDING BAR
// ─────────────────────────────────────────────────────────────────────────────
class _RecordingBar extends StatelessWidget {
  final Duration duration;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  const _RecordingBar({
    required this.duration,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final secs = duration.inSeconds;
    final label =
        '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: const Color(0xFF1A1A2E),
      child: Row(children: [
        GestureDetector(
          onTap: onCancel,
          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        const SizedBox(width: 12),
        // Animated red dot
        const _PulsingDot(),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const Expanded(child: SizedBox()),
        GestureDetector(
          onTap: onSend,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
                color: _kPurple, shape: BoxShape.circle),
            child: const FaIcon(FontAwesomeIcons.paperPlane,
                size: 16, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(width: 10, height: 10,
          decoration: const BoxDecoration(
              color: Colors.redAccent, shape: BoxShape.circle)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INPUT BAR
// ─────────────────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isSending;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onSend;
  final Future<void> Function() onImage;
  final Future<void> Function() onRecordStart;

  const _InputBar({
    required this.ctrl,
    required this.isSending,
    required this.onChanged,
    required this.onSend,
    required this.onImage,
    required this.onRecordStart,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = ctrl.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        border: Border(top: BorderSide(color: Color(0xFF1E1E2E))),
      ),
      child: SafeArea(child: Row(children: [
        // Camera / gallery
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.image, size: 20,
              color: Colors.white54),
          onPressed: onImage,
        ),

        // Text field
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(children: [
            Expanded(child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              maxLines: 4,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Message…',
                hintStyle: TextStyle(color: Colors.white30),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10),
              ),
            )),
            // Emoji hint
            if (!hasText)
              const Text('😊', style: TextStyle(fontSize: 20)),
          ]),
        )),

        const SizedBox(width: 6),

        // Send / mic / heart
        if (isSending)
          const SizedBox(width: 40, height: 40,
              child: Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      color: _kPurple))))
        else if (hasText)
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(
                  color: _kPurple, shape: BoxShape.circle),
              child: const Center(child: FaIcon(FontAwesomeIcons.paperPlane,
                  size: 16, color: Colors.white)),
            ),
          )
        else
          // Long-press = record, tap = like ❤️
          GestureDetector(
            onLongPressStart: (_) => onRecordStart(),
            onTap: onSend, // sends heart (empty message placeholder)
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Text('❤️', style: TextStyle(fontSize: 26)),
            ),
          ),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TYPING DOT
// ─────────────────────────────────────────────────────────────────────────────
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay),
        () { if (mounted) _c.forward(); });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _a.value),
      child: Container(width: 7, height: 7,
          decoration: const BoxDecoration(
              color: Colors.white54, shape: BoxShape.circle)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MSG BUBBLE SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class _MsgBubbleSkeleton extends StatelessWidget {
  const _MsgBubbleSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: const [
        ShimmerBox(height: 36, isCircle: true),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          ShimmerBox(width: 180, height: 40, borderRadius: 20),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NEW MESSAGE SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});
  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final _searchCtrl = TextEditingController();
  final _userRepo   = UserRepository();
  final _msgRepo    = MessageRepository();
  List<Map<String, dynamic>> _users    = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }

  Future<void> _load() async {
    final uid = _userRepo.getCurrentUserId();
    if (uid == null) { setState(() => _isLoading = false); return; }
    final r = await _userRepo.getSuggestedUsers(uid);
    r.fold((_) => setState(() => _isLoading = false),
        (u) => setState(() { _users = u; _filtered = u; _isLoading = false; }));
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _filtered = q.isEmpty ? _users
          : _users.where((u) => (u['username'] ?? '')
              .toLowerCase().contains(q.toLowerCase())).toList());
      if (q.isNotEmpty && _filtered.isEmpty) {
        _userRepo.searchUsers(q).then((r) {
          r.fold((_) {}, (u) { if (mounted) setState(() => _filtered = u); });
        });
      }
    });
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    final myId    = supabase.auth.currentUser?.id;
    final otherId = user['id'] as String? ?? '';
    if (myId == null || otherId.isEmpty) return;
    final r = await _msgRepo.getOrCreateConversation(myId, otherId);
    r.fold((_) {}, (convId) {
      if (mounted) {
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => ConversationChatScreen(
            conversationId: convId,
            username: user['username'] ?? 'User',
            userAvatar: user['avatar_url'] ?? '',
            otherUserId: otherId,
          )));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface2,
      appBar: AppBar(backgroundColor: _kSurface2,
          title: const Text('New Message',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            const Text('To: ', style: TextStyle(color: Colors.white54, fontSize: 16)),
            Expanded(child: TextField(
              controller: _searchCtrl, autofocus: true,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Search…',
                hintStyle: TextStyle(color: Colors.white30),
                border: InputBorder.none,
              ),
            )),
          ]),
        ),
        const Divider(color: Colors.white12),
        if (!_isLoading && _searchCtrl.text.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(alignment: Alignment.centerLeft,
                child: Text('Suggested', style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white54))),
          ),
        Expanded(
          child: _isLoading
              ? ListView.builder(itemCount: 5,
                  itemBuilder: (_, __) => const UserTileSkeleton())
              : _filtered.isEmpty
                  ? Center(child: Text(
                      _searchCtrl.text.isEmpty
                          ? 'No suggestions' : 'No results for "${_searchCtrl.text}"',
                      style: const TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final u = _filtered[i];
                        final avatar   = u['avatar_url'] as String? ?? '';
                        final username = u['username'] as String? ?? 'User';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2A2A3E),
                            backgroundImage: avatar.isNotEmpty
                                ? CachedNetworkImageProvider(avatar) : null,
                            child: avatar.isEmpty
                                ? Text(username[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white))
                                : null,
                          ),
                          title: Text(username,
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(u['full_name'] ?? username,
                              style: const TextStyle(color: Colors.white38,
                                  fontSize: 12)),
                          onTap: () => _startChat(u),
                        );
                      }),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STUBS (router-required)
// ─────────────────────────────────────────────────────────────────────────────
class MessageRequestsScreen extends StatelessWidget {
  const MessageRequestsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kSurface2,
    appBar: AppBar(backgroundColor: _kSurface2,
        title: const Text('Message Requests')),
    body: const Center(child: Text('No message requests',
        style: TextStyle(color: Colors.white38))),
  );
}

class StoryShareScreen extends StatelessWidget {
  const StoryShareScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kSurface2,
    appBar: AppBar(backgroundColor: _kSurface2,
        title: const Text('Share to Story')),
    body: const Center(child: Text('Coming soon',
        style: TextStyle(color: Colors.white38))),
  );
}
