import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OfflineSafetyScreen extends StatefulWidget {
  const OfflineSafetyScreen({super.key});

  @override
  State<OfflineSafetyScreen> createState() => _OfflineSafetyScreenState();
}

class _OfflineSafetyScreenState extends State<OfflineSafetyScreen> {
  String _templateType = 'unsafe_now';
  final TextEditingController _locationController = TextEditingController(text: 'My current location');
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _contactController = TextEditingController(text: '01700000000');
  String _generatedMessage = 'I feel unsafe and may need help. Please check on me. Location: My current location.';
  bool _cardPrepared = false;

  @override
  void dispose() {
    _locationController.dispose();
    _noteController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _generateMessage() {
    final location = _locationController.text.trim().isEmpty ? 'my current location' : _locationController.text.trim();
    final note = _noteController.text.trim();

    String msg;
    switch (_templateType) {
      case 'safe_walk':
        msg = 'I am starting a Safe Walk. Please monitor my journey. Location: $location.';
        break;
      case 'need_call':
        msg = 'Please call me now. I may need help. Location: $location.';
        break;
      case 'arrived_safe':
        msg = 'I have reached safely. Location: $location.';
        break;
      default:
        msg = 'I feel unsafe and may need help. Please check on me. Location: $location.';
    }

    if (note.isNotEmpty) {
      msg = '$msg Note: $note';
    }

    setState(() => _generatedMessage = msg);
    _copyText(msg, 'Emergency message copied.');
  }

  void _copyText(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  void _prepareCard() {
    setState(() => _cardPrepared = true);
    _copyText(
      'SafeHerBD Safety Card\nEmergency contact: ${_contactController.text}\nHelplines: 999, 109, 1098, 16430\nGuardian note: Please call me and check my last shared location if I am unsafe.',
      'Safety card copied for offline sharing.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        title: const Text('Offline Safety Kit', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _hero(),
            const SizedBox(height: 14),
            _section('Emergency message templates'),
            _templateCard(),
            const SizedBox(height: 14),
            _section('Offline safety card'),
            _safetyCard(),
            const SizedBox(height: 14),
            _section('Offline checklist'),
            _checkItem('Keep phone charged before travelling at night.'),
            _checkItem('Save at least two emergency contacts.'),
            _checkItem('Know helplines: 999, 109, 1098, 16430.'),
            _checkItem('Use Safe Walk before entering a risky route.'),
            _checkItem('Copy emergency message before going offline.'),
            const SizedBox(height: 14),
            _section('Phone action workflow'),
            _actionTile(Icons.copy_outlined, 'Copy message', 'Copy text to send through SMS, Messenger, WhatsApp, or any app.'),
            _actionTile(Icons.call_outlined, 'Manual call support', 'Use phone dialer for helplines or guardians. This demo avoids paid API services.'),
            _actionTile(Icons.location_on_outlined, 'Location label', 'Attach current location label when available from the device.'),
            _actionTile(Icons.offline_bolt_outlined, 'Works offline', 'Templates and checklist can be used even when internet is unstable.'),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.offline_bolt_outlined, color: Colors.white, size: 34),
          SizedBox(height: 12),
          Text('Offline Safety Kit', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Prepare message templates, safety card, helplines, and checklist without paid APIs or external services.', style: TextStyle(color: Colors.white, height: 1.35)),
        ],
      ),
    );
  }

  Widget _templateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _templateType,
            decoration: const InputDecoration(labelText: 'Template type', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'unsafe_now', child: Text('I feel unsafe')),
              DropdownMenuItem(value: 'safe_walk', child: Text('Starting Safe Walk')),
              DropdownMenuItem(value: 'need_call', child: Text('Call me now')),
              DropdownMenuItem(value: 'arrived_safe', child: Text('Arrived safely')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _templateType = value);
            },
          ),
          const SizedBox(height: 10),
          TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location label', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _noteController, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Extra note', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
            child: Text(_generatedMessage, style: const TextStyle(height: 1.35)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(onPressed: _generateMessage, icon: const Icon(Icons.copy_outlined), label: const Text('Generate and copy message')),
          ),
        ],
      ),
    );
  }

  Widget _safetyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _contactController, decoration: const InputDecoration(labelText: 'Emergency contact', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          Text(_cardPrepared ? 'Safety card prepared and copied.' : 'Prepare a simple safety card for offline sharing.', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _prepareCard, icon: const Icon(Icons.badge_outlined), label: const Text('Prepare safety card'))),
        ],
      ),
    );
  }

  Widget _checkItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: _box(),
      child: Row(children: [const Icon(Icons.check_circle_outline, color: Color(0xFF059669)), const SizedBox(width: 10), Expanded(child: Text(text))]),
    );
  }

  Widget _actionTile(IconData icon, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF0F766E)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(body, style: const TextStyle(color: Color(0xFF64748B), height: 1.35))])),
      ]),
    );
  }

  Widget _section(String title) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF172033))));

  BoxDecoration _box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE7EAF1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 6))]);
}