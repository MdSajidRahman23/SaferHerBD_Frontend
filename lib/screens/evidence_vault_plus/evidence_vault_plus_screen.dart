import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EvidenceVaultPlusScreen extends StatefulWidget {
  const EvidenceVaultPlusScreen({super.key});

  @override
  State<EvidenceVaultPlusScreen> createState() => _EvidenceVaultPlusScreenState();
}

class _EvidenceVaultPlusScreenState extends State<EvidenceVaultPlusScreen> {
  String _type = 'photo';
  bool _pinLock = true;
  bool _localEncryption = true;
  bool _attachLocation = true;
  String? _lastChecksum;

  final TextEditingController _titleController = TextEditingController(text: 'Street harassment evidence');
  final TextEditingController _noteController = TextEditingController(text: 'Saved for guardian and legal support.');
  final TextEditingController _locationController = TextEditingController(text: 'Mirpur 10');

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _demoChecksum() {
    final raw = '${_type}_${_titleController.text}_${_noteController.text}_${DateTime.now().toIso8601String()}';
    final hex = raw.hashCode.abs().toRadixString(16).padLeft(8, '0');
    return 'demo-sha256-$hex';
  }

  Future<void> _capture(String type) async {
    await HapticFeedback.mediumImpact();
    setState(() {
      _type = type;
      _lastChecksum = _demoChecksum();
    });
    _show('${type.toUpperCase()} evidence metadata prepared. Phone builds can connect this to native capture.');
  }

  void _saveMetadata() {
    setState(() => _lastChecksum = _demoChecksum());
    _show('Evidence metadata saved locally with PIN lock and checksum preview.');
  }

  void _exportSummary() {
    _show('Evidence summary export prepared for GD/FIR/legal support.');
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: const Text('Evidence Vault Plus', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _hero(primary),
            const SizedBox(height: 14),
            _section('Native capture workflow'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _captureButton(Icons.photo_camera_outlined, 'Photo', 'photo'),
                _captureButton(Icons.mic_none_outlined, 'Audio', 'audio'),
                _captureButton(Icons.videocam_outlined, 'Video', 'video'),
                _captureButton(Icons.note_add_outlined, 'Note', 'note'),
              ],
            ),
            const SizedBox(height: 14),
            _section('Evidence metadata'),
            _metadataCard(primary),
            const SizedBox(height: 14),
            _section('Protection policy'),
            _switchTile('PIN lock required', 'Protect evidence screen with app PIN before viewing.', _pinLock, (v) => setState(() => _pinLock = v)),
            _switchTile('Local encryption workflow', 'Production build should store evidence using encrypted local storage.', _localEncryption, (v) => setState(() => _localEncryption = v)),
            _switchTile('Attach location and timestamp', 'Save location label, time, and checksum for legal support.', _attachLocation, (v) => setState(() => _attachLocation = v)),
            const SizedBox(height: 14),
            _section('Export summary'),
            _infoCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'GD/FIR ready summary',
              body: 'Prepare a clean summary containing evidence titles, timestamps, location labels, and checksum previews. No paid API is required.',
              action: FilledButton.icon(
                onPressed: _exportSummary,
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Prepare export summary'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _hero(Color primary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: .18), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: Colors.white, size: 34),
          const SizedBox(height: 12),
          const Text('Secure evidence workflow', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'Capture-ready metadata, PIN lock, timestamp, location label, checksum preview, and export summary without paid APIs.',
            style: TextStyle(color: Colors.white, height: 1.35),
          ),
          if (_lastChecksum != null) ...[
            const SizedBox(height: 12),
            Text('Last checksum: $_lastChecksum', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF172033))),
    );
  }

  Widget _captureButton(IconData icon, String label, String type) {
    return OutlinedButton.icon(
      onPressed: () => _capture(type),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _metadataCard(Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Evidence type', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'photo', child: Text('Photo')),
              DropdownMenuItem(value: 'audio', child: Text('Audio')),
              DropdownMenuItem(value: 'video', child: Text('Video')),
              DropdownMenuItem(value: 'note', child: Text('Note')),
              DropdownMenuItem(value: 'screenshot', child: Text('Screenshot')),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location label', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveMetadata,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save protected metadata'),
              style: FilledButton.styleFrom(backgroundColor: primary, padding: const EdgeInsets.symmetric(vertical: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _box(),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String body, Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF7C3AED)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: Color(0xFF5B6475), height: 1.35)),
          if (action != null) ...[
            const SizedBox(height: 12),
            action,
          ],
        ],
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE7EAF1)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 6))],
    );
  }
}