import 'package:flutter/material.dart';
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
      text: 'নমস্কার! আমি Mitra — আপনার confidential safety companion। '
            'আজকে আপনি কেমন আছেন? যা কিছু feel করছেন বা কোনো সাহায্য দরকার, '
            'আমাকে নিঃসংকোচে বলুন।',
      isCrisis: false,
    ),
  ];

  bool _sending = false;

  Future<void> _send() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(role: 'user', text: txt));
      _sending = true;
    });
    _scrollToBottom();

    final res = await _api.sendChatMessage(txt, sessionId: _sessionId);
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
              ? 'আমি শুনছি। আরেকটু বিস্তারিত বলুন, আমি সাহায্য করার চেষ্টা করব।'
              : reply,
          isCrisis: res['is_crisis'] == true,
        ));
      });
    } else {
      final detail = res == null ? 'network/server response পাওয়া যায়নি' : (res['message'] ?? 'request failed').toString();
      setState(() {
        _msgs.add(_Msg(
          role: 'assistant',
          text: 'দুঃখিত — Mitra server-এর সাথে সংযোগে সমস্যা হচ্ছে ($detail)। '
                'একটু পরে আবার চেষ্টা করুন। জরুরি হলে SOS button ব্যবহার করুন।',
        ));
      });
    }

    setState(() => _sending = false);
    _scrollToBottom();
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
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.ink), onPressed: widget.onBack),
        title: Row(children: [
          const CircleAvatar(
            radius: 16, backgroundColor: AppColors.greenSoft,
            child: Icon(Icons.spa, color: AppColors.green, size: 16),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mitra', style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 14.5)),
            Text('Confidential • 24/7', style: GoogleFonts.inter(color: AppColors.green, fontSize: 10.5)),
          ]),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.line),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(12),
            itemCount: _msgs.length + (_sending ? 1 : 0),
            itemBuilder: (_, i) {
              if (_sending && i == _msgs.length) return const _TypingBubble();
              return _MsgBubble(msg: _msgs[i], onCallHelpline: _callHelpline);
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
            minLines: 1, maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'Mitra-কে কিছু বলুন…',
              hintStyle: GoogleFonts.hindSiliguri(color: AppColors.ink3, fontSize: 13),
              filled: true, fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sending ? null : _send,
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
            child: _sending
                ? const Padding(padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ]),
    ),
  );
}

class _Msg {
  final String role;     // 'user' | 'assistant'
  final String text;
  final bool isCrisis;
  const _Msg({required this.role, required this.text, this.isCrisis = false});
}

class _MsgBubble extends StatelessWidget {
  final _Msg msg;
  final void Function(String) onCallHelpline;
  const _MsgBubble({required this.msg, required this.onCallHelpline});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.green
                       : (msg.isCrisis ? AppColors.redSoft : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: !isUser ? Border.all(color: msg.isCrisis ? AppColors.red.withValues(alpha: 0.3) : AppColors.line) : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (msg.isCrisis) ...[
            Row(children: [
              const Icon(Icons.favorite, color: AppColors.red, size: 14),
              const SizedBox(width: 6),
              Text('Crisis support',
                  style: GoogleFonts.inter(
                      color: AppColors.red, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 6),
          ],
          Text(msg.text,
              style: GoogleFonts.hindSiliguri(
                  color: isUser ? Colors.white : AppColors.ink, fontSize: 13.5, height: 1.45)),
          if (msg.isCrisis) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _HelplineBtn(label: '109 — মহিলা ও শিশু', onTap: () => onCallHelpline('109')),
              _HelplineBtn(label: '999 — Police', onTap: () => onCallHelpline('999')),
              _HelplineBtn(label: 'Kaan Pete Roi', onTap: () => onCallHelpline('9612119911')),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _HelplineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HelplineBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.phone, color: Colors.white, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.hindSiliguri(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
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
        const SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.green),
        ),
        const SizedBox(width: 8),
        Text('Mitra is typing…',
            style: GoogleFonts.inter(color: AppColors.ink3, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    ),
  );
}
