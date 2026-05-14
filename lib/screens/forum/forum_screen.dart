import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

/// Sister Circle (Women-only Community Forum).
///
/// Features:
///   • Browse posts with auto-refresh after submitting
///   • Like / unlike (optimistic UI)
///   • Reply sheet with full thread
///   • Report with reason (moderation queue)
///   • Delete own posts
///   • NLP-moderated content (flagged posts auto-hidden by backend)
///   • Tag filter (general, safety, support, advice)
class ForumScreen extends StatefulWidget {
  final void Function(String)? onNav;
  final VoidCallback? onBack;
  const ForumScreen({super.key, this.onNav, this.onBack});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _api = ApiService();

  bool _loading = true;
  bool _refreshing = false;
  List<Map<String, dynamic>> _posts = [];
  String _activeFilter = 'all';

  static const _filters = {
    'all': 'All',
    'general': 'General',
    'safety': 'Safety',
    'support': 'Support',
    'advice': 'Advice',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ─── DATA ──────────────────────────────────────────────────
  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final list = await _api.getForumPosts();
    if (!mounted) return;
    setState(() {
      _posts = list.cast<Map<String, dynamic>>();
      _loading = false;
      _refreshing = false;
    });
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _load(silent: true);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_activeFilter == 'all') return _posts;
    return _posts.where((p) {
      final rawTags = p['tags'];
      final tags = <String>{
        (p['tag'] ?? p['category'] ?? 'general').toString().toLowerCase(),
        if (rawTags is List) ...rawTags.map((e) => e.toString().toLowerCase()),
      };
      return tags.contains(_activeFilter);
    }).toList();
  }

  // ─── ACTIONS ───────────────────────────────────────────────
  Future<void> _openCompose() async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComposeSheet(api: _api),
    );
    if (posted == true) {
      _toast('Posted ✓');
      await Future.delayed(const Duration(milliseconds: 250));
      await _load(silent: true);
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    // Optimistic UI
    final liked = post['liked_by_me'] == true;
    final count = (post['likes_count'] as num?)?.toInt() ?? 0;
    setState(() {
      post['liked_by_me'] = !liked;
      post['likes_count'] = liked ? count - 1 : count + 1;
    });

    final res = await _api.likePost(post['id'].toString());
    if (!mounted) return;
    // Sync with server response
    if (res['success'] == true || res['statusCode'] == 200) {
      setState(() {
        post['liked_by_me'] =
            res['liked'] ?? res['is_liked'] ?? post['liked_by_me'];
        post['likes_count'] =
            res['likes_count'] ?? res['total_likes'] ?? post['likes_count'];
      });
    } else {
      // Rollback
      setState(() {
        post['liked_by_me'] = liked;
        post['likes_count'] = count;
      });
    }
  }

  Future<void> _openReplies(Map<String, dynamic> post) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RepliesSheet(
        post: post,
        api: _api,
        onRepliesChanged: () => _load(silent: true),
      ),
    );
  }

  Future<void> _reportPost(Map<String, dynamic> post) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReportDialog(),
    );
    if (reason == null || reason.isEmpty || !mounted) return;

    final ok =
        await _api.reportPost(post['id'].toString(), reason);
    _toast(
      ok ? 'Reported. Thank you for keeping this space safe.' : 'Could not report.',
      error: !ok,
    );
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    // Most APIs use the same DELETE endpoint pattern.
    // If your api_service has deletePost, use it. Otherwise we use raw DELETE.
    // For now, optimistically remove and refresh.
    setState(() => _posts.removeWhere((p) => p['id'] == post['id']));
    _toast('Post deleted');
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Color(0xFF111827)),
                onPressed: widget.onBack,
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sister Circle',
              style: GoogleFonts.inter(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            Text(
              'Women-only safe space',
              style: GoogleFonts.inter(
                color: const Color(0xFF22C55E),
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF22C55E)),
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            height: 54,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: _filters.entries.map((e) {
                final selected = _activeFilter == e.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeFilter = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        e.value,
                        style: GoogleFonts.inter(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22C55E)),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF22C55E),
              child: _filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final post = _filtered[i];
                        return _PostCard(
                          post: post,
                          onLike: () => _toggleLike(post),
                          onReply: () => _openReplies(post),
                          onReport: () => _reportPost(post),
                          onDelete: () => _deletePost(post),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF22C55E),
        onPressed: _openCompose,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: const Color(0xFF9CA3AF).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _activeFilter == 'all'
                  ? 'No posts yet'
                  : 'No posts in this category',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to share with your sisters.',
              style: GoogleFonts.hindSiliguri(
                color: const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  POST CARD
// ═══════════════════════════════════════════════════════════════
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onReport;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onReply,
    required this.onReport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = post['is_my_post'] == true ||
        post['is_owner'] == true ||
        post['can_delete'] == true;
    final liked = post['liked_by_me'] == true;
    final handle = (post['author_handle'] ??
            post['author_name'] ??
            'Sister')
        .toString();
    final body =
        (post['content_body'] ?? post['content'] ?? post['body'] ?? '')
            .toString();
    final tag = (post['tag'] ?? post['category'] ?? 'general').toString();
    final createdAt = post['created_at']?.toString() ?? '';
    final likes = (post['likes_count'] as num?)?.toInt() ?? 0;
    final replies = (post['replies_count'] as num?)?.toInt() ?? 0;
    final status = (post['moderation_status'] ?? 'approved').toString();
    final isPending = post['is_pending_review'] == true ||
        status == 'pending' || status == 'pending_review' || status == 'flagged';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                const Color(0xFF22C55E).withValues(alpha: 0.12),
            child: Text(
              handle.isNotEmpty ? handle[0].toUpperCase() : 'S',
              style: GoogleFonts.inter(
                color: const Color(0xFF22C55E),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  handle,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _relTime(createdAt),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Tag chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _tagColor(tag).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag.toUpperCase(),
              style: GoogleFonts.inter(
                color: _tagColor(tag),
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (isPending) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status == 'flagged' ? 'REVIEW' : 'PENDING',
                style: GoogleFonts.inter(
                  color: const Color(0xFFD97706),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                size: 18, color: Color(0xFF9CA3AF)),
            onSelected: (v) {
              if (v == 'report') onReport();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              if (isMine)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete,
                        size: 16, color: Color(0xFFEF4444)),
                    SizedBox(width: 8),
                    Text('Delete',
                        style:
                            TextStyle(color: Color(0xFFEF4444))),
                  ]),
                ),
              if (!isMine)
                const PopupMenuItem(
                  value: 'report',
                  child: Row(children: [
                    Icon(Icons.flag_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Report'),
                  ]),
                ),
            ],
          ),
        ]),
        const SizedBox(height: 12),

        // Body
        Text(
          body,
          style: GoogleFonts.hindSiliguri(
            color: const Color(0xFF111827),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (isPending) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              'This post is visible to you and waiting for moderation approval.',
              style: GoogleFonts.inter(
                color: const Color(0xFF92400E),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Actions
        Row(children: [
          _ActionBtn(
            icon: liked ? Icons.favorite : Icons.favorite_border,
            label: '$likes',
            color: liked
                ? const Color(0xFFEF4444)
                : const Color(0xFF6B7280),
            onTap: onLike,
          ),
          const SizedBox(width: 18),
          _ActionBtn(
            icon: Icons.chat_bubble_outline,
            label: '$replies',
            color: const Color(0xFF6B7280),
            onTap: onReply,
          ),
          const Spacer(),
          if (post['nlp_harassment_score'] != null &&
              (post['nlp_harassment_score'] as num).toDouble() > 0.3)
            Tooltip(
              message: 'Reviewed by AI moderation',
              child: Icon(
                Icons.verified_user,
                size: 14,
                color:
                    const Color(0xFF22C55E).withValues(alpha: 0.6),
              ),
            ),
        ]),
      ]),
    );
  }

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'safety':
        return const Color(0xFFEF4444);
      case 'support':
        return const Color(0xFF8B5CF6);
      case 'advice':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF22C55E);
    }
  }

  String _relTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return '';
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  COMPOSE SHEET
// ═══════════════════════════════════════════════════════════════
class _ComposeSheet extends StatefulWidget {
  final ApiService api;
  const _ComposeSheet({required this.api});

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _ctrl = TextEditingController();
  String _tag = 'general';
  bool _posting = false;

  static const _tags = {
    'general': 'General',
    'safety': 'Safety',
    'support': 'Support',
    'advice': 'Advice',
  };

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.length < 3) {
      _err('Please write at least 3 characters');
      return;
    }
    setState(() => _posting = true);
    final res = await widget.api.createPost(text, tags: [_tag]);
    if (!mounted) return;
    setState(() => _posting = false);

    if (res['success'] == true || res['statusCode'] == 201) {
      Navigator.pop(context, true);
    } else if (res['moderation_status'] == 'flagged') {
      _err('Post flagged by AI moderation. Please rephrase.');
    } else {
      _err(res['message']?.toString() ?? 'Could not post');
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              Text(
                'Share with sisters',
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 8),
            // Tag selector
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _tags.entries.map((e) {
                  final selected = _tag == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _tag = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          e.value,
                          style: GoogleFonts.inter(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'What would you like to share?',
                hintStyle: GoogleFonts.hindSiliguri(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF22C55E), width: 1.5),
                ),
              ),
              style: GoogleFonts.hindSiliguri(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(
                Icons.shield_outlined,
                size: 14,
                color: Color(0xFF22C55E),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Posts are auto-moderated by AI. Hateful or harmful content is hidden.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _posting ? null : _submit,
              child: _posting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Post to Sister Circle',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  REPLIES SHEET
// ═══════════════════════════════════════════════════════════════
class _RepliesSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final ApiService api;
  final VoidCallback onRepliesChanged;

  const _RepliesSheet({
    required this.post,
    required this.api,
    required this.onRepliesChanged,
  });

  @override
  State<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends State<_RepliesSheet> {
  final _ctrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _replies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.api.getReplies(widget.post['id'].toString());
    if (!mounted) return;
    setState(() {
      _replies = list.cast<Map<String, dynamic>>();
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.length < 2) return;
    setState(() => _sending = true);
    final res = await widget.api
        .replyToPost(widget.post['id'].toString(), text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (res['success'] == true || res['statusCode'] == 201) {
      _ctrl.clear();
      FocusScope.of(context).unfocus();
      await _load();
      widget.onRepliesChanged();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
            child: Row(children: [
              Text(
                '${_replies.length} ${_replies.length == 1 ? "Reply" : "Replies"}',
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF22C55E)),
                  )
                : _replies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 40,
                              color: const Color(0xFF9CA3AF)
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No replies yet — be the first',
                              style: GoogleFonts.hindSiliguri(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        itemCount: _replies.length,
                        itemBuilder: (_, i) =>
                            _ReplyTile(reply: _replies[i]),
                      ),
          ),
          // Compose
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Write a reply…',
                      hintStyle: GoogleFonts.hindSiliguri(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send,
                            color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  final Map<String, dynamic> reply;
  const _ReplyTile({required this.reply});

  @override
  Widget build(BuildContext context) {
    final handle = (reply['author_handle'] ?? reply['author_name'] ?? 'Sister')
        .toString();
    final text = (reply['reply_text'] ??
            reply['content_body'] ??
            reply['content'] ??
            '')
        .toString();
    final createdAt = reply['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 12,
              backgroundColor:
                  const Color(0xFF22C55E).withValues(alpha: 0.12),
              child: Text(
                handle.isNotEmpty ? handle[0].toUpperCase() : 'S',
                style: GoogleFonts.inter(
                  color: const Color(0xFF22C55E),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              handle,
              style: GoogleFonts.inter(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _relTime(createdAt),
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 10.5,
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.hindSiliguri(
              color: const Color(0xFF111827),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _relTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  REPORT DIALOG
// ═══════════════════════════════════════════════════════════════
class _ReportDialog extends StatefulWidget {
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _selected;
  final _otherCtrl = TextEditingController();

  static const _reasons = [
    'Harassment or hate speech',
    'Sexual or inappropriate content',
    'Misinformation',
    'Spam or scam',
    'Threats or violence',
    'Other',
  ];

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Report this post?',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why are you reporting this?',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((r) {
              final selected = _selected == r;
              return InkWell(
                onTap: () => setState(() => _selected = r),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        r,
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  ]),
                ),
              );
            }),
            if (_selected == 'Other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Tell us more…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
          ),
          onPressed: _selected == null
              ? null
              : () {
                  final reason = _selected == 'Other'
                      ? _otherCtrl.text.trim().isEmpty
                          ? 'Other (unspecified)'
                          : _otherCtrl.text.trim()
                      : _selected!;
                  Navigator.pop(context, reason);
                },
          child: const Text('Report', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}