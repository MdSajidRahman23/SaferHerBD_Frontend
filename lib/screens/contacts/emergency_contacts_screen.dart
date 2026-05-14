import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';

/// EmergencyContactsScreen — Manage the people who get notified during SOS.
///
/// Features:
///   • List all contacts ordered by priority
///   • Add new contact (name, phone, relation, priority, notify toggles)
///   • Edit existing contact
///   • Delete with confirmation
///   • Visual priority indicator (1 = primary, 2-5 = backup)
///   • Empty state with onboarding hint
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final _api = ApiService();
  List<dynamic> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    final list = await _api.getContacts();
    if (!mounted) return;
    setState(() {
      _contacts = list;
      _loading = false;
    });
  }

  int _priorityOf(dynamic contact) {
    if (contact is Map) {
      final raw = contact['priority_order'];
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? 1;
    }
    return 1;
  }

  Future<void> _addOrEditContact({Map<String, dynamic>? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactFormSheet(
        existing: existing,
        usedPriorities: _contacts.map(_priorityOf).toSet(),
        api: _api,
      ),
    );
    if (saved == true) _loadContacts();
  }

  Future<void> _deleteContact(Map<String, dynamic> contact) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete this contact?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${contact['name']} will no longer receive SOS alerts.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await _api.deleteContact(contact['id'].toString());
    if (!mounted) return;
    if (success) {
      _toast('Contact removed');
      _loadContacts();
    } else {
      _toast('Could not delete. Try again.', error: true);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Emergency Contacts',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          if (!_loading && _contacts.length < 5)
            IconButton(
              tooltip: 'Add emergency contact',
              icon: const Icon(Icons.add, color: Color(0xFF22C55E)),
              onPressed: () => _addOrEditContact(),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22C55E)),
            )
          : _contacts.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      floatingActionButton: _contacts.isEmpty
          ? null
          : (_contacts.length < 5
              ? FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF22C55E),
                  onPressed: () => _addOrEditContact(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Add Contact',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null),
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              color: Color(0xFF22C55E),
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No emergency contacts yet',
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add up to 5 trusted people. They will be stored safely and notified when you trigger SOS.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _addOrEditContact(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add Your First Contact',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LIST ──────────────────────────────────────────────────
  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadContacts,
      color: const Color(0xFF22C55E),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF22C55E),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lower priority number = notified first. SOS alerts go to all contacts simultaneously.',
                    style: GoogleFonts.hindSiliguri(
                      color: const Color(0xFF065F46),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._contacts.map(
            (c) => _ContactCard(
              contact: c as Map<String, dynamic>,
              onEdit: () => _addOrEditContact(existing: c),
              onDelete: () => _deleteContact(c),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── CONTACT CARD ──────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rawPriority = contact['priority_order'];
    final priority = rawPriority is num
        ? rawPriority.toInt()
        : int.tryParse(rawPriority?.toString() ?? '') ?? 1;
    final notifySos = contact['notify_on_sos'] == true ||
        contact['notify_on_sos'] == 1;
    final isPrimary = priority == 1;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary
              ? const Color(0xFF22C55E).withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Priority badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPrimary
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF22C55E).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$priority',
                style: GoogleFonts.inter(
                  color: isPrimary
                      ? Colors.white
                      : const Color(0xFF22C55E),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                        contact['name']?.toString() ?? '—',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PRIMARY',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.phone,
                        size: 12, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      contact['phone']?.toString() ?? '',
                      style: GoogleFonts.robotoMono(
                        color: const Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    if ((contact['relation'] ?? '').toString().isNotEmpty)
                      ...[
                      Text(
                        '  •  ',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        contact['relation'].toString(),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    if (notifySos) ...[
                      const Icon(Icons.shield,
                          size: 12, color: Color(0xFF22C55E)),
                      const SizedBox(width: 3),
                      Text(
                        'SOS alerts on',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.shield_outlined,
                          size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 3),
                      Text(
                        'SOS alerts off',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: Color(0xFF6B7280), size: 20),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, size: 16, color: Color(0xFFEF4444)),
                    SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: Color(0xFFEF4444))),
                  ]),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── ADD/EDIT FORM SHEET ───────────────────────────────────
class _ContactFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final Set<int> usedPriorities;
  final ApiService api;

  const _ContactFormSheet({
    required this.existing,
    required this.usedPriorities,
    required this.api,
  });

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _relation;
  late int _priority;
  late bool _notifySos;
  late bool _notifySafeArrival;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?['name']?.toString() ?? '');
    _phone = TextEditingController(text: e?['phone']?.toString() ?? '');
    _relation =
        TextEditingController(text: e?['relation']?.toString() ?? '');

    // Choose lowest unused priority for new contacts
    if (e != null) {
      final rawPriority = e['priority_order'];
      _priority = rawPriority is num
          ? rawPriority.toInt()
          : int.tryParse(rawPriority?.toString() ?? '') ?? 1;
    } else {
      _priority = [1, 2, 3, 4, 5]
          .firstWhere((p) => !widget.usedPriorities.contains(p), orElse: () => 5);
    }
    _notifySos = e == null
        ? true
        : (e['notify_on_sos'] == true || e['notify_on_sos'] == 1);
    _notifySafeArrival = e == null
        ? false
        : (e['notify_on_safe_arrival'] == true ||
            e['notify_on_safe_arrival'] == 1);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validation
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.length < 2) {
      _showErr('Name must be at least 2 characters');
      return;
    }
    final phoneRe = RegExp(r'^(\+?880|0)1[3-9]\d{8}$');
    if (!phoneRe.hasMatch(phone.replaceAll(' ', '').replaceAll('-', ''))) {
      _showErr('Enter a valid Bangladesh phone number');
      return;
    }

    setState(() => _saving = true);

    final data = {
      'name': name,
      'phone': phone,
      'relation': _relation.text.trim().isEmpty ? null : _relation.text.trim(),
      'priority_order': _priority,
      'notify_on_sos': _notifySos,
      'notify_on_safe_arrival': _notifySafeArrival,
    };

    Map<String, dynamic> result;
    if (widget.existing != null) {
      result = await widget.api.updateContactResult(
        widget.existing!['id'].toString(),
        data,
      );
    } else {
      result = await widget.api.createContactResult(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      _showErr(result['message']?.toString() ?? 'Could not save contact.');
    }
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
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
              Text(
                isEdit ? 'Edit Contact' : 'New Emergency Contact',
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 18),

              // Name
              const _Label('Name *'),
              _TextField(
                controller: _name,
                hint: 'e.g. Father, Sister, Roommate',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),

              // Phone
              const _Label('Phone *'),
              _TextField(
                controller: _phone,
                hint: '01XXXXXXXXX',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\s]')),
                  LengthLimitingTextInputFormatter(15),
                ],
              ),
              const SizedBox(height: 14),

              // Relation
              const _Label('Relation (optional)'),
              _TextField(
                controller: _relation,
                hint: 'e.g. Father, Friend, Roommate',
                icon: Icons.people_outline,
              ),
              const SizedBox(height: 18),

              // Priority
              const _Label('Priority order'),
              Row(
                children: List.generate(5, (i) {
                  final p = i + 1;
                  final used = widget.usedPriorities.contains(p) &&
                      (widget.existing == null ||
                          widget.existing!['priority_order'] != p);
                  final selected = _priority == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: used ? null : () => setState(() => _priority = p),
                      child: Container(
                        height: 48,
                        margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: used
                              ? const Color(0xFFF3F4F6)
                              : selected
                                  ? const Color(0xFF22C55E)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$p',
                          style: GoogleFonts.inter(
                            color: used
                                ? const Color(0xFFD1D5DB)
                                : selected
                                    ? Colors.white
                                    : const Color(0xFF111827),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                '1 = primary contact (notified first)',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 18),

              // Notify toggles
              _ToggleRow(
                icon: Icons.shield,
                title: 'Notify on SOS',
                subtitle: 'This contact gets the emergency alert',
                value: _notifySos,
                onChanged: (v) => setState(() => _notifySos = v),
              ),
              _ToggleRow(
                icon: Icons.check_circle_outline,
                title: 'Notify on safe arrival',
                subtitle: 'Send when I confirm I am safe',
                value: _notifySafeArrival,
                onChanged: (v) => setState(() => _notifySafeArrival = v),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEdit ? 'Save Changes' : 'Add Contact',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HELPERS ───────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      );
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: GoogleFonts.inter(
        color: const Color(0xFF111827),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF9CA3AF),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon,
            color: value
                ? const Color(0xFF22C55E)
                : const Color(0xFF9CA3AF),
            size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF22C55E),
          onChanged: onChanged,
        ),
      ]),
    );
  }
}