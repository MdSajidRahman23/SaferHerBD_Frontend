import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/design_widgets.dart';

class ChatbotScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;
  const ChatbotScreen({super.key, required this.onNav, required this.onBack});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _api = ApiService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  String? _sessionId;
  bool _typing = false;

  final List<_Msg> _messages = [
    _Msg(
        text: "আসসালামু আলাইকুম! 🌿 I'm Mitra — your safety companion.",
        bot: true),
    _Msg(
        text:
            'আমি কীভাবে সাহায্য করতে পারি? আপনি বাংলা বা English-এ কথা বলতে পারেন।',
        bot: true),
  ];

  final _quickReplies = const [
    'আমি ভয় পাচ্ছি',
    'কাছের নিরাপদ স্থান',
    'নিরাপত্তা পরামর্শ',
    'I feel unsafe',
  ];

  Future<void> _send([String? quick]) async {
    final text = quick ?? _ctrl.text.trim();
    if (text.isEmpty || _typing) return;

    setState(() {
      _messages.add(_Msg(text: text, bot: false));
      _typing = true;
    });
    _ctrl.clear();
    _scrollDown();

    // Special handling: location query — use device GPS
    final isLoc = text.contains('নিরাপদ স্থান') ||
        text.contains('কাছের') ||
        text.toLowerCase().contains('safe place') ||
        text.contains('কোথায়');

    String? reply;
    List<dynamic>? sources;

    if (isLoc && !kIsWeb) {
      Position? pos;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse) {
            pos = await Geolocator.getCurrentPosition()
                .timeout(const Duration(seconds: 5));
          }
        }
      } catch (_) {}
      reply = _buildSafePlaceReply(pos);
      sources = ['জরুরি হটলাইন', 'নিকটতম থানা'];
    } else {
      // Send to backend
      final response = await _api.sendChatMessage(text, sessionId: _sessionId);
      if (response != null) {
        reply = response['reply'] as String?;
        // Save session_id for continuity
        final newSessionId = response['session_id'] as String?;
        if (newSessionId != null && newSessionId.isNotEmpty) {
          _sessionId = newSessionId;
        }
        if (response['citations'] is List) {
          sources = response['citations'] as List;
        }
      }
      reply ??= _localFallback(text);
    }

    if (mounted) {
      setState(() {
        _typing = false;
        _messages.add(_Msg(
          text: reply!,
          bot: true,
          sources: sources?.map((s) {
            if (s is String) return s;
            if (s is Map) return (s['source'] ?? s['text'] ?? '').toString();
            return s.toString();
          }).where((s) => s.isNotEmpty).toList(),
        ));
      });
      _scrollDown();
    }
  }

  String _buildSafePlaceReply(Position? pos) {
    final loc = pos != null
        ? '📍 আপনার অবস্থান: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}\n\n'
        : '';
    return '${loc}কাছের নিরাপদ স্থান:\n\n🚔 পুলিশ স্টেশন — হটলাইন ৯৯৯\n🏥 হাসপাতাল — ৯৯৯\n👩‍⚕️ মহিলা সহায়তা কেন্দ্র — ১৬৪৯২\n👶 শিশু হেল্পলাইন — ১০৯৮\n\n⚠️ তাৎক্ষণিক বিপদে SOS বোতাম চাপুন।';
  }

  String _localFallback(String t) {
    final m = t.toLowerCase();
    if (m.contains('ভয়') || m.contains('fear') || m.contains('bhoy')) {
      return 'ভয় পাওয়া স্বাভাবিক। ৪ সেকেন্ড শ্বাস নিন, ৪ সেকেন্ড ধরে রাখুন, ৬ সেকেন্ড ছাড়ুন। আপনি কি এখন নিরাপদ আছেন? 🌿';
    }
    if (m.contains('পরামর্শ') || m.contains('tips') || m.contains('advice')) {
      return 'নিরাপত্তা পরামর্শ:\n• রাতে একা চলাচল এড়িয়ে চলুন\n• Safe Route ফিচার ব্যবহার করুন\n• Emergency Contacts আপডেট রাখুন\n• Shake করলেই SOS trigger হবে 📱';
    }
    if (m.contains('হ্যালো') || m.contains('hi') || m.contains('hello')) {
      return 'আস-সালামু আলাইকুম! আমি মিত্র — আপনার নিরাপত্তা সহচর। কেমন আছেন আজ? 🌿';
    }
    return 'আপনার কথা মনোযোগ দিয়ে শুনছি। বিস্তারিত বলুন — আমি সাহায্য করার চেষ্টা করব। 🤝';
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(children: [
              IconBtn(icon: Icons.chevron_left, onTap: widget.onBack),
              const SizedBox(width: 10),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.green, Color(0xFF00A26B)],
                  ),
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EnText('Mitra',
                            size: 16, weight: FontWeight.w800),
                        Row(children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: AppColors.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          const EnText('AI safety companion · বাংলা/English',
                              size: 11, color: AppColors.ink3),
                        ]),
                      ])),
              IconBtn(
                icon: Icons.refresh,
                onTap: () {
                  setState(() {
                    _messages.clear();
                    _messages.addAll([
                      _Msg(
                          text: 'নতুন কথোপকথন শুরু হলো। কেমন আছেন? 🌿',
                          bot: true),
                    ]);
                    _sessionId = null;
                  });
                },
              ),
            ]),
          ),

          Expanded(
              child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            itemCount: _messages.length + (_typing ? 1 : 0),
            itemBuilder: (_, i) {
              if (_typing && i == _messages.length) {
                return const _TypingBubble();
              }
              return _ChatBubble(msg: _messages[i]);
            },
          )),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
                children: _quickReplies.map((q) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _send(q),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: BnText(q,
                        size: 12,
                        weight: FontWeight.w500,
                        color: AppColors.ink2),
                  ),
                ),
              );
            }).toList()),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16,
                MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 14, color: AppColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'এখানে টাইপ করুন...',
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const Icon(Icons.mic_none,
                        size: 18, color: AppColors.ink3),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _typing ? null : () => _send(),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: _typing ? AppColors.ink3 : AppColors.green,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: _typing
                          ? null
                          : [
                              BoxShadow(
                                  color: AppColors.green.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4)),
                            ]),
                  child: const Icon(Icons.send,
                      color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool bot;
  final List<String>? sources;
  _Msg({required this.text, required this.bot, this.sources});
}

class _ChatBubble extends StatelessWidget {
  final _Msg msg;
  const _ChatBubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
          mainAxisAlignment:
              msg.bot ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg.bot) ...[
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(10)),
                child: const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 14))),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                  crossAxisAlignment: msg.bot
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: msg.bot ? AppColors.card : AppColors.green,
                        border: msg.bot
                            ? Border.all(color: AppColors.line)
                            : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(msg.bot ? 4 : 16),
                          bottomRight: Radius.circular(msg.bot ? 16 : 4),
                        ),
                      ),
                      child: BnText(msg.text,
                          size: 13.5,
                          color: msg.bot ? AppColors.ink : Colors.white,
                          height: 1.6),
                    ),
                    if (msg.sources != null && msg.sources!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: msg.sources!
                              .map((s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenSoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: BnText(s,
                                        size: 10,
                                        weight: FontWeight.w600,
                                        color: AppColors.green),
                                  ))
                              .toList()),
                    ],
                  ]),
            ),
          ]),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(10)),
          child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 14))),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.line),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
                    final scale =
                        (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.4, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: AppColors.ink3,
                                shape: BoxShape.circle),
                          )),
                    );
                  }))),
        ),
      ]),
    );
  }
}
