import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';

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
  final _scrollCtrl = ScrollController();
  String? _sessionId;

  final List<_Msg> _msgs = [
    const _Msg(
      role: 'assistant',
      text: 'আস-সালামু আলাইকুম। আমি Mitra — আপনার confidential safety companion।\n\n'
          'আপনি চাইলে নিচের quick help ব্যবহার করতে পারেন, অথবা নিজের ভাষায় লিখুন।',
      isCrisis: false,
      intent: 'welcome',
    ),
  ];

  bool _sending = false;

  Future<void> _send([String? overrideText]) async {
    final txt = (overrideText ?? _ctrl.text).trim();
    if (txt.isEmpty || _sending) return;
    _ctrl.clear();

    setState(() {
      _msgs.add(_Msg(role: 'user', text: txt));
      _sending = true;
    });
    _scrollToBottom();

    Position? position;
    if (_shouldAttachLocation(txt)) {
      position = await _getCurrentPositionSafely();
      if (!mounted) return;
    }

    final res = await _api.sendChatMessage(
      txt,
      sessionId: _sessionId,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
    if (!mounted) return;

    if (res != null && res['success'] == true) {
      _sessionId = res['session_id']?.toString() ?? _sessionId;
      final reply = (res['reply'] ??
              res['answer'] ??
              res['message'] ??
              (res['data'] is Map ? (res['data']['reply'] ?? res['data']['answer']) : null))
          ?.toString();
      setState(() {
        _msgs.add(_Msg(
          role: 'assistant',
          text: (reply == null || reply.trim().isEmpty)
              ? 'আমি শুনছি। আরেকটু বিস্তারিত বলুন—আপনি কোথায় আছেন এবং কী ধরনের সাহায্য দরকার?'
              : reply,
          isCrisis: res['is_crisis'] == true,
          intent: res['intent']?.toString(),
        ));
      });
    } else {
      final detail = res == null ? 'network/server response পাওয়া যায়নি' : (res['message'] ?? 'request failed').toString();
      setState(() {
        _msgs.add(_Msg(
          role: 'assistant',
          text: 'দুঃখিত — Mitra server-এর সাথে সংযোগে সমস্যা হচ্ছে ($detail)।\n\n'
              'জরুরি হলে SafeHer SOS চাপুন অথবা 999-এ কল করুন।',
          isCrisis: true,
          intent: 'network_error',
        ));
      });
    }

    setState(() => _sending = false);
    _scrollToBottom();
  }

  bool _shouldAttachLocation(String text) {
    final t = text.toLowerCase();
    return t.contains('safe place') ||
        t.contains('nearby') ||
        t.contains('near me') ||
        t.contains('ashe pashe') ||
        t.contains('ase pashe') ||
        t.contains('pasher') ||
        t.contains('kache') ||
        t.contains('খুঁজে') ||
        t.contains('কাছের') ||
        t.contains('কাছাকাছি') ||
        t.contains('নিরাপদ জায়গা') ||
        t.contains('নিরাপদ জায়গা') ||
        t.contains('থানা') ||
        t.contains('হাসপাতাল') ||
        t.contains('pharmacy') ||
        t.contains('police station');
  }

  Future<Position?> _getCurrentPositionSafely() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      return null;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _callHelpline(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openRoute(String key) => widget.onNav(key);

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
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
        title: Row(children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.greenSoft,
            child: Icon(Icons.spa, color: AppColors.green, size: 16),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mitra', style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 14.5)),
            Text('Safety guidance • Bengali support', style: GoogleFonts.inter(color: AppColors.green, fontSize: 10.5)),
          ]),
        ]),
        actions: [
          IconButton(
            tooltip: 'SOS',
            onPressed: () => _openRoute('sos'),
            icon: const Icon(Icons.sos_rounded, color: AppColors.red),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.line),
        ),
      ),
      body: Column(children: [
        _MitraActionBar(onSend: _send, onNav: _openRoute),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(12),
            itemCount: _msgs.length + (_sending ? 1 : 0),
            itemBuilder: (_, i) {
              if (_sending && i == _msgs.length) return const _TypingBubble();
              return _MsgBubble(msg: _msgs[i], onCallHelpline: _callHelpline, onNav: _openRoute);
            },
          ),
        ),
        _buildComposer(),
      ]),
    );
  }

  Widget _buildComposer() => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'যেমন: আমি unsafe feel করছি…',
                  hintStyle: GoogleFonts.hindSiliguri(color: AppColors.ink3, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : () => _send(),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                child: _sending
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

class _MitraActionBar extends StatelessWidget {
  final Future<void> Function(String) onSend;
  final void Function(String) onNav;
  const _MitraActionBar({required this.onSend, required this.onNav});

  @override
  Widget build(BuildContext context) {
    const chips = [
      _PromptChipData('আমি বিপদে আছি', Icons.warning_amber_rounded, AppColors.red),
      _PromptChipData('Safe place খুঁজে দাও', Icons.place_rounded, AppColors.green),
      _PromptChipData('Harassment হলে কী করব?', Icons.shield_rounded, AppColors.purple),
      _PromptChipData('Legal help দরকার', Icons.gavel_rounded, AppColors.blue),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Quick safety help',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink3, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chips
                .map((chip) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _PromptChip(data: chip, onTap: () => onSend(chip.label)),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _NavMiniButton(label: 'SOS', icon: Icons.sos_rounded, color: AppColors.red, onTap: () => onNav('sos'))),
          const SizedBox(width: 8),
          Expanded(child: _NavMiniButton(label: 'Route', icon: Icons.route_rounded, color: AppColors.green, onTap: () => onNav('route'))),
          const SizedBox(width: 8),
          Expanded(child: _NavMiniButton(label: 'Legal', icon: Icons.gavel_rounded, color: AppColors.blue, onTap: () => onNav('legal'))),
        ]),
      ]),
    );
  }
}

class _PromptChipData {
  final String label;
  final IconData icon;
  final Color color;
  const _PromptChipData(this.label, this.icon, this.color);
}

class _PromptChip extends StatelessWidget {
  final _PromptChipData data;
  final VoidCallback onTap;
  const _PromptChip({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: data.color.withValues(alpha: 0.18)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(data.icon, color: data.color, size: 14),
            const SizedBox(width: 6),
            Text(
              data.label,
              style: GoogleFonts.hindSiliguri(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ]),
        ),
      );
}

class _NavMiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NavMiniButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
          ]),
        ),
      );
}

class _Msg {
  final String role;
  final String text;
  final bool isCrisis;
  final String? intent;
  const _Msg({required this.role, required this.text, this.isCrisis = false, this.intent});
}

class _MsgBubble extends StatelessWidget {
  final _Msg msg;
  final void Function(String) onCallHelpline;
  final void Function(String) onNav;
  const _MsgBubble({required this.msg, required this.onCallHelpline, required this.onNav});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.green : (msg.isCrisis ? AppColors.redSoft : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: !isUser ? Border.all(color: msg.isCrisis ? AppColors.red.withValues(alpha: 0.3) : AppColors.line) : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!isUser) ...[
            Row(children: [
              Icon(msg.isCrisis ? Icons.favorite : Icons.spa, color: msg.isCrisis ? AppColors.red : AppColors.green, size: 14),
              const SizedBox(width: 6),
              Text(
                msg.isCrisis ? 'Priority safety support' : 'Mitra guidance',
                style: GoogleFonts.inter(
                  color: msg.isCrisis ? AppColors.red : AppColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ]),
            const SizedBox(height: 6),
          ],
          Text(
            msg.text,
            style: GoogleFonts.hindSiliguri(color: isUser ? Colors.white : AppColors.ink, fontSize: 13.5, height: 1.45),
          ),
          if (!isUser && _shouldShowActionButtons(msg)) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _HelplineBtn(label: '999', icon: Icons.local_phone_rounded, color: AppColors.red, onTap: () => onCallHelpline('999')),
              _HelplineBtn(label: '109', icon: Icons.support_agent_rounded, color: AppColors.purple, onTap: () => onCallHelpline('109')),
              _HelplineBtn(label: 'SOS', icon: Icons.sos_rounded, color: AppColors.red, onTap: () => onNav('sos')),
              _HelplineBtn(label: 'Route', icon: Icons.route_rounded, color: AppColors.green, onTap: () => onNav('route')),
              _HelplineBtn(label: 'Legal', icon: Icons.gavel_rounded, color: AppColors.blue, onTap: () => onNav('legal')),
            ]),
          ],
        ]),
      ),
    );
  }

  bool _shouldShowActionButtons(_Msg msg) {
    final intent = (msg.intent ?? '').toLowerCase();
    final text = msg.text.toLowerCase();
    return msg.isCrisis ||
        intent.contains('safe_place') ||
        intent.contains('route') ||
        intent.contains('legal') ||
        intent.contains('harassment') ||
        intent.contains('emergency') ||
        text.contains('999') ||
        text.contains('109') ||
        text.contains('sos') ||
        text.contains('বিপদ') ||
        text.contains('unsafe') ||
        text.contains('safe place') ||
        text.contains('নিরাপদ') ||
        text.contains('legal') ||
        text.contains('evidence');
  }
}

class _HelplineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HelplineBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.hindSiliguri(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
          ]),
        ),
      );
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.green)),
            const SizedBox(width: 8),
            Text(
              'Mitra is typing…',
              style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ]),
        ),
      );
}