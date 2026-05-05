import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gov_widgets.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _api    = ApiService();
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  String? _sessionId;
  bool _typing = false;
  Position? _lastPosition;

  final List<_Msg> _messages = [
    _Msg('আস-সালামু আলাইকুম! আমি আশা। মানসিক সহায়তা ও নিরাপত্তায় আপনাকে সাহায্য করতে এখানে আছি।\n\nআপনি কি এখন নিরাপদ আছেন? 🌿', isBot: true),
  ];

  final _quickReplies = const [
    'আমি ভয় পাচ্ছি',
    'কাছের নিরাপদ স্থান খুঁজুন',
    'নিরাপত্তার পরামর্শ',
    'আমি ভালো আছি',
  ];

  // ── Safe Places Database (Bangladesh) ──────────────────────────
  static const _safePlaces = [
    _SafePlace('থানা / Police Station', '100', Icons.local_police_rounded, AppColors.g),
    _SafePlace('হাসপাতাল / Hospital', '16000', Icons.local_hospital_rounded, AppColors.r),
    _SafePlace('মহিলা সহায়তা কেন্দ্র', '16492', Icons.support_agent_rounded, AppColors.purple),
    _SafePlace('ফায়ার সার্ভিস', '999', Icons.fire_truck_rounded, AppColors.orange),
    _SafePlace('নিকটতম মসজিদ / Mosque', null, Icons.location_on_rounded, AppColors.g),
    _SafePlace('শপিং মল / Mall', null, Icons.shopping_bag_outlined, AppColors.gold),
  ];

  Future<Position?> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 6));
    } catch (_) { return null; }
  }

  // Generate safe place response with Google Maps links
  String _buildSafePlaceResponse(Position? pos) {
    final buf = StringBuffer();
    buf.writeln('আপনার কাছের নিরাপদ স্থানগুলো:\n');

    if (pos != null) {
      buf.writeln('📍 আপনার অবস্থান: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}\n');
    }

    for (final place in _safePlaces) {
      buf.write('${place.icon == Icons.local_police_rounded ? "🚔" : place.icon == Icons.local_hospital_rounded ? "🏥" : place.icon == Icons.support_agent_rounded ? "👩‍⚕️" : "📍"} **${place.name}**');
      if (place.hotline != null) buf.write(' — হটলাইন: ${place.hotline}');
      buf.writeln();
    }

    if (pos != null) {
      final lat = pos.latitude;
      final lng = pos.longitude;
      buf.writeln('\n🗺️ Google Maps এ কাছের থানা খুঁজুন:');
      buf.writeln('maps.google.com/search/police+station/@$lat,$lng');
    }

    buf.writeln('\n⚠️ তাৎক্ষণিক বিপদে SOS বোতাম চাপুন অথবা ৯৯৯ এ কল করুন।');
    return buf.toString();
  }

  Future<void> _send([String? quick]) async {
    final text = quick ?? _ctrl.text.trim();
    if (text.isEmpty || _typing) return;

    setState(() {
      _messages.add(_Msg(text, isBot: false));
      _typing = true;
    });
    _ctrl.clear();
    _scrollDown();

    // Special handling: location-based safe place search
    final isLocationQuery = text.contains('নিরাপদ স্থান') ||
        text.contains('কাছের') || text.contains('safe place') ||
        text.contains('কোথায় যাব') || text.contains('ashe pashe');

    if (isLocationQuery) {
      // Get real GPS location first
      final pos = await _getLocation();
      _lastPosition = pos ?? _lastPosition;
      final reply = _buildSafePlaceResponse(pos);
      if (mounted) {
        setState(() {
          _typing = false;
          _messages.add(_Msg(reply, isBot: true, isLocation: true));
        });
        _scrollDown();
      }
      return;
    }

    // Normal flow: try backend API, then fallback
    final response = await _api.sendChatMessage(text, sessionId: _sessionId);

    String? reply;
    if (response != null) {
      reply = response['reply'] as String?;
      _sessionId = response['session_id'] as String? ?? _sessionId;
    }

    // Fallback chain
    reply ??= _getFallback(text);

    if (mounted) {
      setState(() {
        _typing = false;
        _messages.add(_Msg(reply!, isBot: true));
      });
      _scrollDown();
    }
  }

  String _getFallback(String text) {
    final t = text.toLowerCase();
    if (t.contains('ভয়') || t.contains('bhoy') || t.contains('fear') || t.contains('scared'))
      return 'আপনার ভয় পাওয়াটা সম্পূর্ণ স্বাভাবিক। একটু শ্বাস নিন — আপনি এখন কোথায় আছেন? নিরাপদ কোনো স্থানে যেতে পারলে ভালো হয়।\n\n🛡️ যদি বিপদে থাকেন, এখনই SOS বোতাম চাপুন।';
    if (t.contains('পরামর্শ') || t.contains('advice') || t.contains('tips'))
      return 'কিছু গুরুত্বপূর্ণ পরামর্শ:\n\n• রাতে একা চলাচল এড়িয়ে চলুন\n• Safe Route ফিচার ব্যবহার করুন\n• Emergency Contacts আপডেট রাখুন\n• ৯৯৯ নম্বর মনে রাখুন\n• Shake করলে SOS trigger হবে 📱';
    if (t.contains('ভালো') || t.contains('okay') || t.contains('fine'))
      return 'আলহামদুলিল্লাহ! ভালো থাকুন সবসময়। 💚 মনে রাখবেন — SafeHerBD সবসময় আপনার পাশে আছে।';
    if (t.contains('stress') || t.contains('চাপ') || t.contains('কষ্ট'))
      return 'মানসিক চাপ অনুভব করা স্বাভাবিক। একটু বিরতি নিন — ৪ সেকেন্ড শ্বাস নিন, ৪ সেকেন্ড ধরে রাখুন, ৬ সেকেন্ড ছাড়ুন।\n\nআপনি একা নন। আমি শুনছি — কী হয়েছে বলুন। 🌿';
    if (t.contains('999') || t.contains('police') || t.contains('পুলিশ'))
      return 'জরুরি নম্বরসমূহ:\n\n🚔 পুলিশ: 999\n🏥 অ্যাম্বুলেন্স: 999\n🔥 ফায়ার: 999\n👩‍⚕️ মহিলা সহায়তা: 16492\n📞 National Emergency: 999\n\nতাৎক্ষণিক বিপদে SOS বোতাম চাপুন।';
    return 'আপনার কথা মনোযোগ দিয়ে শুনছি। একটু বিস্তারিত বলুন — আমি আপনাকে সাহায্য করার চেষ্টা করব। 🤝';
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        HeroHeader(
          title: 'Mental Support',
          subtitle: 'মানসিক সহায়তা',
          trailing: const StatusPill(label: 'Online 24/7',
              color: AppColors.aqua, light: true),
        ),
        // Asha bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.surface,
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.orange, Color(0xFFc05820)]),
                borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('🤝', style: TextStyle(fontSize: 18)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Asha', style: GoogleFonts.dmSans(
                  color: AppColors.t1, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('AI Mental Health & Safety Companion',
                  style: GoogleFonts.dmSans(color: AppColors.t3, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
              child: Text('RAG + Groq LLM',
                  style: GoogleFonts.dmSans(
                      color: AppColors.purple, fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Messages
        Expanded(child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: _messages.length + (_typing ? 1 : 0),
          itemBuilder: (_, i) {
            if (_typing && i == _messages.length) return const _TypingBubble();
            return _ChatBubble(msg: _messages[i]);
          },
        )),

        // Quick replies
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: _quickReplies.map((r) => GestureDetector(
            onTap: () => _send(r),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.g.withOpacity(0.08),
                border: Border.all(color: AppColors.g.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(20)),
              child: Text(r, style: GoogleFonts.hindSiliguri(
                  color: AppColors.t2, fontSize: 12)),
            ),
          )).toList()),
        ),

        // Input
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16,
              MediaQuery.of(context).padding.bottom + 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              style: GoogleFonts.hindSiliguri(color: AppColors.t1),
              decoration: InputDecoration(
                hintText: 'এখানে টাইপ করুন...',
                hintStyle: GoogleFonts.hindSiliguri(color: AppColors.t3)),
              onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _send(),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SafePlace {
  final String name;
  final String? hotline;
  final IconData icon;
  final Color color;
  const _SafePlace(this.name, this.hotline, this.icon, this.color);
}

class _Msg {
  final String text;
  final bool isBot;
  final bool isLocation;
  const _Msg(this.text, {required this.isBot, this.isLocation = false});
}

class _ChatBubble extends StatelessWidget {
  final _Msg msg;
  const _ChatBubble({required this.msg});
  @override Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (msg.isBot) ...[
            Container(width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
              child: const Center(child: Text('🤝', style: TextStyle(fontSize: 14)))),
            const SizedBox(width: 8),
          ],
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.isBot ? AppColors.surface : AppColors.g,
              border: msg.isBot
                  ? Border.all(color: msg.isLocation
                      ? AppColors.g.withOpacity(0.3)
                      : AppColors.border)
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(msg.isBot ? 4 : 14),
                bottomRight: Radius.circular(msg.isBot ? 14 : 4),
              ),
            ),
            child: Text(msg.text, style: GoogleFonts.hindSiliguri(
                color: msg.isBot ? AppColors.t1 : Colors.white,
                fontSize: 13, height: 1.6)),
          )),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override State<_TypingBubble> createState() => _TypingBubbleState();
}
class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 28, height: 28,
        decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Text('🤝', style: TextStyle(fontSize: 14)))),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14), topRight: Radius.circular(14),
            bottomLeft: Radius.circular(4), bottomRight: Radius.circular(14))),
        child: AnimatedBuilder(animation: _c, builder: (_, __) =>
          Row(mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
              final scale = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.3, 1.0);
              return Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(scale: scale,
                  child: Container(width: 6, height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: AppColors.t3))));
            }))),
      ),
    ]),
  );
}
