import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';

class ForumScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;
  const ForumScreen({super.key, required this.onNav, required this.onBack});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _api = ApiService();
  final _composeCtrl = TextEditingController();

  bool _loading = true;
  bool _posting = false;
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.getForumPosts();
    if (!mounted) return;
    setState(() {
      _posts = list;
      _loading = false;
    });
  }

  Future<void> _submitPost() async {
    final text = _composeCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    final res = await _api.createPost(text);
    if (!mounted) return;
    setState(() => _posting = false);

    if (res['success'] == true || res['statusCode'] == 201) {
      _composeCtrl.clear();
      FocusScope.of(context).unfocus();
      _toast(res['moderation_status'] == 'flagged'
          ? 'Posted (queued for review)'
          : 'Posted');
      _load();
    } else {
      _toast(res['message']?.toString() ?? 'Failed to post', error: true);
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final res = await _api.likePost(post['id'].toString());
    if (res['success'] == true) {
      setState(() {
        post['liked_by_me'] = res['liked'] ?? !(post['liked_by_me'] ?? false);
        post['likes_count'] = res['likes_count'] ?? post['likes_count'] ?? 0;
      });
    }
  }

  Future<void> _showReplies(Map<String, dynamic> post) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RepliesSheet(post: post, api: _api, onAdded: _load),
    );
  }

  Future<void> _confirmReport(Map<String, dynamic> post) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report Post', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Why are you reporting?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || reasonCtrl.text.isEmpty || !mounted) return;
    final success = await _api.reportPost(post['id'].toString(), reasonCtrl.text);
    _toast(success ? 'Reported. Thank you.' : 'Report failed.', error: !success);
  }

  Future<void> _confirmDelete(Map<String, dynamic> post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete post?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await _api.deletePost(post['id'].toString());
    if (success) {
      setState(() => _posts.removeWhere((p) => p['id'] == post['id']));
      _toast('Post deleted');
    } else {
      _toast('Delete failed', error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.red : AppColors.green,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    _composeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: widget.onBack,
        ),
        title: Text('Sister Circle',
            style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.line),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.green,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                : _posts.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _posts.length,
                        itemBuilder: (_, i) => _PostCard(
                          post: _posts[i] as Map<String, dynamic>,
                          onLike: _toggleLike,
                          onReply: _showReplies,
                          onReport: _confirmReport,
                          onDelete: _confirmDelete,
                        ),
                      ),
          ),
        ),
        _buildComposer(),
      ]),
    );
  }

  Widget _buildEmpty() => ListView(children: [
        const SizedBox(height: 100),
        Center(
            child: Column(children: [
          Icon(Icons.forum_outlined, size: 60, color: AppColors.ink3.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('No posts yet',
              style: GoogleFonts.inter(color: AppColors.ink2, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Be the first to share with the Sister Circle.',
              style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12)),
        ])),
      ]);

  Widget _buildComposer() => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _composeCtrl,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Share with sisters…',
                  hintStyle: GoogleFonts.inter(color: AppColors.ink3, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _posting ? null : _submitPost,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                child: _posting
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      );
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final void Function(Map<String, dynamic>) onLike;
  final void Function(Map<String, dynamic>) onReply;
  final void Function(Map<String, dynamic>) onReport;
  final void Function(Map<String, dynamic>) onDelete;
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onReply,
    required this.onReport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final liked = post['liked_by_me'] == true;
    final isMine = post['is_my_post'] == true;
    final handle = post['author_handle']?.toString() ?? 'Sister';
    final body = post['content_body']?.toString() ?? '';
    final createdAt = post['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.greenSoft,
            child: Text(
              handle.isNotEmpty ? handle[0].toUpperCase() : 'S',
              style: GoogleFonts.inter(color: AppColors.green, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(handle,
                  style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(_relTime(createdAt),
                  style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 11)),
            ]),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.ink3),
            onSelected: (v) {
              if (v == 'report') onReport(post);
              if (v == 'delete') onDelete(post);
            },
            itemBuilder: (_) => [
              if (isMine) const PopupMenuItem(value: 'delete', child: Text('Delete')),
              if (!isMine) const PopupMenuItem(value: 'report', child: Text('Report')),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        Text(body, style: GoogleFonts.hindSiliguri(color: AppColors.ink, fontSize: 13.5, height: 1.5)),
        const SizedBox(height: 10),
        Row(children: [
          GestureDetector(
            onTap: () => onLike(post),
            child: Row(children: [
              Icon(liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? AppColors.red : AppColors.ink3, size: 18),
              const SizedBox(width: 4),
              Text('${post['likes_count'] ?? 0}',
                  style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 18),
          GestureDetector(
            onTap: () => onReply(post),
            child: Row(children: [
              const Icon(Icons.chat_bubble_outline, color: AppColors.ink3, size: 18),
              const SizedBox(width: 4),
              Text('${post['replies_count'] ?? 0}',
                  style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12)),
            ]),
          ),
        ]),
      ]),
    );
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

class _RepliesSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final ApiService api;
  final VoidCallback onAdded;
  const _RepliesSheet({required this.post, required this.api, required this.onAdded});
  @override
  State<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends State<_RepliesSheet> {
  final _ctrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  List<dynamic> _replies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.api.getReplies(widget.post['id'].toString());
    if (!mounted) return;
    setState(() {
      _replies = list;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final res = await widget.api.replyToPost(widget.post['id'].toString(), text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (res['success'] == true || res['statusCode'] == 201) {
      _ctrl.clear();
      _load();
      widget.onAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Text('Replies',
                  style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                : _replies.isEmpty
                    ? Center(child: Text('No replies yet',
                        style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 13)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: _replies.length,
                        itemBuilder: (_, i) {
                          final r = _replies[i] as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r['author_handle']?.toString() ?? 'Sister',
                                  style: GoogleFonts.inter(
                                      color: AppColors.ink2, fontWeight: FontWeight.w700, fontSize: 11)),
                              const SizedBox(height: 3),
                              Text(r['reply_text']?.toString() ?? '',
                                  style: GoogleFonts.hindSiliguri(color: AppColors.ink, fontSize: 12.5)),
                            ]),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Reply…',
                      filled: true,
                      fillColor: AppColors.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 18),
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
