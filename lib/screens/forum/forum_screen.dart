import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/design_widgets.dart';

class ForumScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;
  const ForumScreen({super.key, required this.onNav, required this.onBack});
  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _api = ApiService();
  String _tab = 'Nearby';
  List<dynamic> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await _api.getForumPosts();
    if (mounted) {
      setState(() {
        _posts = p;
        _loading = false;
      });
    }
  }

  Future<void> _showCreatePostSheet() async {
    final ctrl = TextEditingController();
    String selectedTag = 'general';
    bool posting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (sheetCtx, setSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scroll) => Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scroll,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.greenSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_note,
                              color: AppColors.green, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              EnText('Share with community',
                                  size: 15,
                                  weight: FontWeight.w800,
                                  letterSpacing: -0.2),
                              BnText('AI মডারেশন · নিরাপদ ভাবে',
                                  size: 11, color: AppColors.ink3),
                            ]),
                      ]),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: TextField(
                          controller: ctrl,
                          maxLines: 5,
                          maxLength: 1000,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 14, color: AppColors.ink),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText:
                                'আপনার অভিজ্ঞতা শেয়ার করুন... কোন এলাকা, কী হয়েছে?',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const EnText('TAG',
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.ink3,
                          letterSpacing: 0.4),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: const [
                          'safety',
                          'harassment',
                          'transport',
                          'general',
                          'help',
                        ].map((t) {
                          final on = selectedTag == t;
                          return GestureDetector(
                            onTap: () => setSheet(() => selectedTag = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: on
                                    ? AppColors.green
                                    : AppColors.bg,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                    color: on
                                        ? AppColors.green
                                        : AppColors.line),
                              ),
                              child: EnText(t,
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: on
                                      ? Colors.white
                                      : AppColors.ink2),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: posting
                              ? null
                              : () async {
                                  if (ctrl.text.trim().length < 5) {
                                    ScaffoldMessenger.of(sheetCtx)
                                        .showSnackBar(const SnackBar(
                                            content: BnText(
                                                'কমপক্ষে ৫ অক্ষর লিখুন',
                                                color: Colors.white)));
                                    return;
                                  }
                                  setSheet(() => posting = true);
                                  final res = await _api.createPost(
                                    ctrl.text.trim(),
                                    tags: [selectedTag],
                                  );
                                  if (!sheetCtx.mounted) return;
                                  setSheet(() => posting = false);
                                  if (res['success'] == true) {
                                    Navigator.pop(sheetCtx);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      backgroundColor: AppColors.green,
                                      content: BnText(
                                          (res['message'] ??
                                                  'পোস্ট প্রকাশিত')
                                              .toString(),
                                          color: Colors.white),
                                    ));
                                    _load();
                                  } else {
                                    ScaffoldMessenger.of(sheetCtx)
                                        .showSnackBar(SnackBar(
                                      backgroundColor: AppColors.red,
                                      content: BnText(
                                          (res['message'] ?? 'ব্যর্থ')
                                              .toString(),
                                          color: Colors.white),
                                    ));
                                  }
                                },
                          icon: posting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.send,
                                  size: 16, color: Colors.white),
                          label: const EnText('Post to Community',
                              size: 14,
                              weight: FontWeight.w700,
                              color: Colors.white),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              elevation: 0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: BnText(
                          'AI আপনার পোস্ট পরীক্ষা করবে। হয়রানি বা hateful content auto-flag হবে।',
                          size: 10.5,
                          color: AppColors.ink3,
                        ),
                      ),
                    ]),
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _likePost(String id) async {
    final res = await _api.likePost(id);
    if (mounted && res['success'] == true) {
      _load();
    }
  }

  Future<void> _showRepliesSheet(Map post) async {
    final id = post['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final replyCtrl = TextEditingController();
    bool sending = false;
    List<dynamic> replies = await _api.getReplies(id);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (sheetCtx, setSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scroll) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      const EnText('Replies',
                          size: 15, weight: FontWeight.w800),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.greenSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: EnText('${replies.length}',
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.green),
                      ),
                    ]),
                  ]),
                ),
                const Divider(height: 1, color: AppColors.line),
                Expanded(
                  child: replies.isEmpty
                      ? Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.chat_bubble_outline,
                                    size: 36, color: AppColors.ink3),
                                SizedBox(height: 8),
                                BnText('কোনো উত্তর নেই — প্রথম হোন',
                                    size: 12, color: AppColors.ink3),
                              ]))
                      : ListView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: replies.length,
                          itemBuilder: (_, i) {
                            final r = Map.from(replies[i]);
                            final author =
                                (r['author_name'] ?? 'Anonymous').toString();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.greenSoft,
                                      child: EnText(
                                          author.isEmpty
                                              ? '?'
                                              : author[0].toUpperCase(),
                                          size: 11,
                                          weight: FontWeight.w700,
                                          color: AppColors.green),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.bg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                EnText(author,
                                                    size: 12,
                                                    weight:
                                                        FontWeight.w700),
                                                const Spacer(),
                                                BnText(
                                                    Helpers.timeAgo(
                                                        r['created_at']
                                                            ?.toString()),
                                                    size: 9,
                                                    color: AppColors.ink3),
                                              ]),
                                              const SizedBox(height: 4),
                                              BnText(
                                                  (r['reply_text'] ?? '')
                                                      .toString(),
                                                  size: 12,
                                                  color: AppColors.ink2,
                                                  height: 1.5),
                                            ]),
                                      ),
                                    ),
                                  ]),
                            );
                          }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: TextField(
                          controller: replyCtrl,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 13, color: AppColors.ink),
                          decoration: const InputDecoration(
                            hintText: 'উত্তর লিখুন...',
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: sending
                          ? null
                          : () async {
                              if (replyCtrl.text.trim().isEmpty) return;
                              setSheet(() => sending = true);
                              final res = await _api.replyToPost(
                                  id, replyCtrl.text.trim());
                              if (!sheetCtx.mounted) return;
                              if (res['success'] == true) {
                                replyCtrl.clear();
                                replies = await _api.getReplies(id);
                              }
                              setSheet(() => sending = false);
                            },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(20)),
                        child: sending
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send,
                                size: 16, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          );
        });
      },
    );

    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.green,
        onPressed: _showCreatePostSheet,
        elevation: 4,
        icon: const Icon(Icons.edit, color: Colors.white, size: 18),
        label: const EnText('Post',
            size: 13, weight: FontWeight.w700, color: Colors.white),
      ),
      body: SafeArea(
          bottom: false,
          child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconBtn(
                          icon: Icons.chevron_left, onTap: widget.onBack),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                EnText('Safe Community',
                                    size: 19,
                                    weight: FontWeight.w800,
                                    letterSpacing: -0.3),
                                BnText('নিরাপদ কমিউনিটি',
                                    size: 11, color: AppColors.ink3),
                              ])),
                      IconBtn(
                          icon: Icons.refresh,
                          onTap: () => _load()),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                        children: ['Nearby', 'Trending', 'Following', 'Verified']
                            .map((t) {
                      final on = _tab == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: on
                                  ? AppColors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: on
                                  ? null
                                  : Border.all(color: AppColors.line),
                            ),
                            child: EnText(t,
                                size: 11.5,
                                weight: FontWeight.w600,
                                color: on
                                    ? Colors.white
                                    : AppColors.ink2),
                          ),
                        ),
                      );
                    }).toList()),
                  ]),
            ),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.green))
                  : _posts.isEmpty
                      ? RefreshIndicator(
                          color: AppColors.green,
                          onRefresh: _load,
                          child: ListView(children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Column(children: const [
                                Icon(Icons.forum_outlined,
                                    size: 48, color: AppColors.ink3),
                                SizedBox(height: 12),
                                BnText('এখনো কোনো পোস্ট নেই',
                                    size: 13, color: AppColors.ink3),
                                SizedBox(height: 4),
                                EnText('Be the first to share',
                                    size: 12, color: AppColors.ink3),
                              ]),
                            ),
                          ]),
                        )
                      : RefreshIndicator(
                          color: AppColors.green,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 14, 16, 90),
                            itemCount: _posts.length,
                            itemBuilder: (_, i) => _PostCard(
                              post: Map.from(_posts[i]),
                              onLike: () => _likePost(
                                  _posts[i]['id']?.toString() ?? ''),
                              onReplies: () =>
                                  _showRepliesSheet(_posts[i]),
                            ),
                          ),
                        ),
            ),

            BottomNavBar(active: 'community', onNav: widget.onNav),
          ])),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map post;
  final VoidCallback onLike;
  final VoidCallback onReplies;
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onReplies,
  });

  @override
  Widget build(BuildContext context) {
    final user = post['user'] as Map?;
    final author = (user?['name'] as String?)?.trim().isNotEmpty == true
        ? user!['name']
        : 'Anonymous';
    final content = (post['content_body'] ?? '').toString();
    final createdAt = post['created_at']?.toString();
    final likes = post['likes'] as int? ?? 0;
    final likedByMe = post['liked_by_me'] as bool? ?? false;
    final replyCount = post['reply_count'] as int? ?? 0;
    final isFlagged = post['is_flagged'] as bool? ?? false;

    // Tag from tags_json
    String tag = 'general';
    String tone = 'green';
    final tags = post['tags_json'];
    if (tags is List && tags.isNotEmpty) {
      tag = tags.first.toString();
      if (tag.contains('harass') || tag.contains('snatch')) tone = 'red';
      if (tag.contains('safety') || tag.contains('catcall')) tone = 'amber';
    }

    final tagColors = {
      'red': AppColors.red,
      'amber': AppColors.amber,
      'green': AppColors.green,
    };
    final tagBg = {
      'red': AppColors.redSoft,
      'amber': const Color(0xFFFEF3C7),
      'green': AppColors.greenSoft,
    };
    final tagColor = tagColors[tone] ?? AppColors.green;
    final tagBgColor = tagBg[tone] ?? AppColors.greenSoft;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.green.withOpacity(0.7),
                  AppColors.greenDeep,
                ],
              ),
            ),
            child: Center(
              child: EnText(
                  author.isEmpty ? '?' : author[0].toUpperCase(),
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnText(author, size: 13, weight: FontWeight.w700),
                    BnText(Helpers.timeAgo(createdAt),
                        size: 10, color: AppColors.ink3),
                  ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: tagBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: EnText(tag,
                size: 9.5,
                weight: FontWeight.w700,
                color: tagColor,
                letterSpacing: 0.3),
          ),
        ]),
        const SizedBox(height: 10),
        if (isFlagged)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.redSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.shield_outlined,
                        size: 13, color: AppColors.red),
                    SizedBox(width: 4),
                    EnText('AI moderator flagged sensitive content',
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: AppColors.red),
                  ]),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: 0.35,
                    child: BnText(content,
                        size: 12.5, color: AppColors.ink2, height: 1.5),
                  ),
                ]),
          )
        else
          BnText(content, size: 12.5, color: AppColors.ink, height: 1.5),
        const SizedBox(height: 10),
        Row(children: [
          GestureDetector(
            onTap: onLike,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                likedByMe ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: likedByMe ? AppColors.red : AppColors.ink2,
              ),
              const SizedBox(width: 4),
              EnText('$likes',
                  size: 11.5,
                  weight: FontWeight.w600,
                  color:
                      likedByMe ? AppColors.red : AppColors.ink2),
            ]),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: onReplies,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 14, color: AppColors.ink2),
              const SizedBox(width: 4),
              EnText('$replyCount',
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: AppColors.ink2),
            ]),
          ),
          const Spacer(),
          const Icon(Icons.share_outlined,
              size: 16, color: AppColors.ink3),
        ]),
      ]),
    );
  }
}
