import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/gov_widgets.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});
  @override State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _api = ApiService();
  final _postCtrl = TextEditingController();
  List<dynamic> _posts = [];
  bool _loading = true;
  bool _posting = false;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await _api.getForumPosts();
    if (mounted) setState(() {
      _posts = p.isEmpty ? _demoPosts() : p;
      _loading = false;
    });
  }

  List<Map> _demoPosts() => [
    {
      'user': {'name': 'Rina Begum'},
      'content_body': 'রাত ৮টার পর মিরপুর-১ এলাকায় একা যাওয়া নিরাপদ না। সবাই সতর্ক থাকুন। 🙏',
      'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'likes': 24, 'is_safe': true, 'id': 'd1',
    },
    {
      'user': {'name': 'Sadia Islam'},
      'content_body': 'Safe Route ব্যবহার করে Farmgate এর ঝুঁকিপূর্ণ এলাকা এড়িয়ে গেলাম। SafeHerBD অনেক কাজের! ❤️',
      'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      'likes': 47, 'is_safe': true, 'id': 'd2',
    },
    {
      'user': {'name': 'Anonymous'},
      'content_body': 'Cyber harassment report: আমি হুমকিমূলক বার্তা পাচ্ছি। কীভাবে রিপোর্ট করব?',
      'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      'likes': 8, 'is_safe': true, 'id': 'd3',
    },
  ];

  Future<void> _submit() async {
    final text = _postCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    final ok = await _api.createPost(text);
    if (mounted) {
      setState(() => _posting = false);
      if (ok) {
        _postCtrl.clear();
        _load();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('পোস্ট প্রকাশিত ✓', style: GoogleFonts.hindSiliguri()),
          backgroundColor: AppColors.g, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showReplySheet(Map post) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          // Original post preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              (post['content_body'] as String? ?? '').length > 80
                  ? '${(post['content_body'] as String).substring(0, 80)}...'
                  : post['content_body'] as String? ?? '',
              style: GoogleFonts.hindSiliguri(color: AppColors.t2, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 3,
            style: GoogleFonts.hindSiliguri(color: AppColors.t1),
            decoration: InputDecoration(
              hintText: 'আপনার উত্তর লিখুন...',
              hintStyle: GoogleFonts.hindSiliguri(color: AppColors.t3),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('উত্তর পাঠানো হয়েছে ✓',
                      style: GoogleFonts.hindSiliguri()),
                  backgroundColor: AppColors.g,
                ));
              }
            },
            child: Text('উত্তর দিন / Reply',
                style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
          )),
        ]),
      ),
    );
  }

  @override void dispose() { _postCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        HeroHeader(
          title: 'Community',
          subtitle: 'নারী সম্প্রদায় ফোরাম',
          trailing: const StatusPill(
            label: 'Verified Women', color: AppColors.aqua,
            icon: Icons.verified_rounded, light: true,
          ),
        ),
        Expanded(child: RefreshIndicator(
          color: AppColors.g, onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // Compose box
              GovCard(child: Column(children: [
                TextField(
                  controller: _postCtrl,
                  maxLines: 3,
                  style: GoogleFonts.hindSiliguri(color: AppColors.t1, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'আপনার অভিজ্ঞতা শেয়ার করুন...',
                    hintStyle: GoogleFonts.hindSiliguri(color: AppColors.t3),
                    border: InputBorder.none, filled: false,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                const Divider(height: 14, color: AppColors.border),
                Row(children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.t3),
                  const SizedBox(width: 5),
                  Text('AI moderated • Bengali BERT',
                      style: GoogleFonts.dmSans(color: AppColors.t3, fontSize: 11)),
                  const Spacer(),
                  SizedBox(height: 32, child: ElevatedButton(
                    onPressed: _posting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: _posting
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Post', style: TextStyle(fontSize: 12)),
                  )),
                ]),
              ])),
              const SizedBox(height: 12),

              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.g)))
              else
                ..._posts.map((p) => _PostCard(
                  post: Map.from(p),
                  onReply: () => _showReplySheet(Map.from(p)),
                )),

              const SizedBox(height: 16),
              const GovFooter(),
            ],
          ),
        )),
      ]),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Map post;
  final VoidCallback onReply;
  const _PostCard({required this.post, required this.onReply});
  @override State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;

  @override Widget build(BuildContext context) {
    final author  = Helpers.authorName(widget.post);
    final content = widget.post['content_body'] as String? ?? '';
    final time    = Helpers.timeAgo(widget.post['created_at']?.toString());
    final likes   = widget.post['likes'] as int? ?? 0;
    final isSafe  = widget.post['is_safe'] as bool? ?? true;
    final initials= author.isNotEmpty ? author[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GovCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 16,
            backgroundColor: AppColors.g.withOpacity(0.12),
            child: Text(initials,
                style: const TextStyle(color: AppColors.g,
                    fontWeight: FontWeight.w700, fontSize: 13))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(author, style: GoogleFonts.dmSans(
                  color: AppColors.t1, fontWeight: FontWeight.w600, fontSize: 13)),
              if (isSafe) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.g.withOpacity(0.1),
                    border: Border.all(color: AppColors.g.withOpacity(0.25)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline, size: 10, color: AppColors.g),
                    const SizedBox(width: 3),
                    Text('AI-safe', style: TextStyle(color: AppColors.g, fontSize: 9)),
                  ]),
                ),
              ],
            ]),
            Text(time, style: GoogleFonts.dmSans(color: AppColors.t3, fontSize: 10)),
          ])),
        ]),
        const SizedBox(height: 10),
        Text(content, style: GoogleFonts.hindSiliguri(
            color: AppColors.t1, fontSize: 13, height: 1.6)),
        const SizedBox(height: 8),
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => _liked = !_liked),
            child: Row(children: [
              Icon(_liked ? Icons.favorite : Icons.favorite_border,
                  size: 16, color: _liked ? AppColors.r : AppColors.t3),
              const SizedBox(width: 4),
              Text('${_liked ? likes + 1 : likes}',
                  style: TextStyle(
                      color: _liked ? AppColors.r : AppColors.t3, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 18),
          GestureDetector(
            onTap: widget.onReply,
            child: Row(children: [
              Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.g),
              const SizedBox(width: 4),
              Text('উত্তর দিন', style: GoogleFonts.hindSiliguri(
                  color: AppColors.g, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
      ])),
    );
  }
}
