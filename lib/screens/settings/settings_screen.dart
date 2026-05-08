import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/design_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;
  const SettingsScreen({super.key, required this.onNav, required this.onBack});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  final _api = ApiService();

  Map<String, dynamic>? _user;
  List<dynamic> _contacts = [];
  bool _anonymize = true;
  bool _stealth = false;
  bool _shake = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _auth.getUser();
    final c = await _api.getContacts();
    if (mounted) {
      setState(() {
        _user = u;
        _contacts = c;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const BnText('লগআউট', size: 16, weight: FontWeight.w700),
        content: const BnText('আপনি কি লগআউট করতে চান?',
            size: 13, color: AppColors.ink2),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red, foregroundColor: Colors.white),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _auth.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _addContact() {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final relC = TextEditingController();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(_).viewInsets.bottom + 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const BnText('নতুন যোগাযোগ',
                    size: 16, weight: FontWeight.w700),
                const SizedBox(height: 16),
                GovField(
                    label: 'নাম',
                    icon: Icons.person_outline,
                    controller: nameC),
                const SizedBox(height: 10),
                GovField(
                    label: 'ফোন',
                    icon: Icons.phone,
                    controller: phoneC,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                GovField(
                    label: 'সম্পর্ক',
                    icon: Icons.people_outline,
                    controller: relC),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameC.text.isEmpty || phoneC.text.isEmpty) return;
                        Navigator.pop(_);
                        final res = await _api.addContact(
                            name: nameC.text.trim(),
                            phone: phoneC.text.trim(),
                            relation: relC.text.trim().isEmpty
                                ? 'Contact'
                                : relC.text.trim(),
                            priority: 1);
                        final code = res['statusCode'] as int? ?? 0;
                        final ok = code == 200 || code == 201;
                        if (ok) _load();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0),
                      child: const BnText('যোগ করুন',
                          size: 14,
                          weight: FontWeight.w600,
                          color: Colors.white),
                    )),
              ]),
            ));
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?['name'] ?? 'User';
    final phone = _user?['phone'] ?? '+880';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
          bottom: false,
          child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border:
                    Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Row(children: [
                IconBtn(
                    icon: Icons.chevron_left,
                    onTap: widget.onBack,
                    bg: AppColors.bg),
                const SizedBox(width: 10),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      EnText('Secure Settings',
                          size: 17,
                          weight: FontWeight.w800,
                          letterSpacing: -0.2),
                      BnText('নিরাপত্তা ও গোপনীয়তা',
                          size: 11, color: AppColors.ink3),
                    ]),
              ]),
            ),

            // Body
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.green))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      children: [
                        // Profile card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.green,
                                    Color(0xFF00A26B)
                                  ],
                                ),
                              ),
                              child: Center(
                                child: EnText(
                                    name.isEmpty
                                        ? 'U'
                                        : name[0].toUpperCase(),
                                    size: 18,
                                    weight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  EnText(name,
                                      size: 15, weight: FontWeight.w700),
                                  Text(phone,
                                      style: AppText.mono(
                                          size: 11,
                                          color: AppColors.ink3)),
                                ])),
                            IconBtn(icon: Icons.edit_outlined),
                          ]),
                        ),

                        const SizedBox(height: 20),
                        const _SectionHeader(
                            t: 'Privacy', bn: 'গোপনীয়তা'),
                        _SettingTile(
                          icon: Icons.privacy_tip_outlined,
                          t: 'Anonymize my reports',
                          bn: 'রিপোর্ট গোপন রাখুন',
                          trailing: _Switch(
                              v: _anonymize,
                              onChange: (v) =>
                                  setState(() => _anonymize = v)),
                        ),
                        _SettingTile(
                          icon: Icons.app_blocking,
                          t: 'Stealth app icon',
                          bn: 'গোপন আইকন',
                          trailing: _Switch(
                              v: _stealth,
                              onChange: (v) =>
                                  setState(() => _stealth = v)),
                        ),
                        _SettingTile(
                          icon: Icons.vibration,
                          t: 'Shake to SOS',
                          bn: 'ঝাঁকি দিয়ে SOS',
                          trailing: _Switch(
                              v: _shake,
                              onChange: (v) =>
                                  setState(() => _shake = v)),
                        ),

                        const SizedBox(height: 16),
                        _SectionHeader(
                            t: 'Emergency Contacts (${_contacts.length}/5)',
                            bn: 'জরুরি যোগাযোগ',
                            action: _addContact),

                        if (_contacts.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(children: [
                              const Icon(Icons.person_add_outlined,
                                  size: 32, color: AppColors.ink3),
                              const SizedBox(height: 6),
                              const BnText('কোনো যোগাযোগ নেই',
                                  size: 12, color: AppColors.ink3),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: _addContact,
                                child: const EnText('+ Add now',
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: AppColors.green),
                              ),
                            ]),
                          )
                        else
                          ...List.generate(_contacts.length, (i) {
                            final c = Map.from(_contacts[i]);
                            final n = c['name'] ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(children: [
                                CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        AppColors.greenSoft,
                                    child: EnText(
                                        n.isEmpty
                                            ? '?'
                                            : n[0].toUpperCase(),
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: AppColors.green)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      EnText(n,
                                          size: 12.5,
                                          weight: FontWeight.w700),
                                      EnText(
                                          '${c['relation'] ?? ''} · ${c['phone'] ?? ''}',
                                          size: 10.5,
                                          color: AppColors.ink3),
                                    ])),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.red,
                                      size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    await _api.deleteContact(
                                        c['id']?.toString() ?? '');
                                    _load();
                                  },
                                ),
                              ]),
                            );
                          }),

                        const SizedBox(height: 16),
                        const _SectionHeader(t: 'Account', bn: 'অ্যাকাউন্ট'),
                        _SettingTile(
                            icon: Icons.help_outline,
                            t: 'Help & Support',
                            bn: 'সাহায্য'),
                        _SettingTile(
                            icon: Icons.info_outline,
                            t: 'About SafeHerBD',
                            bn: 'পরিচিতি'),

                        const SizedBox(height: 18),
                        // Logout
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout,
                                color: AppColors.red, size: 18),
                            label: const EnText('Sign Out',
                                size: 14,
                                weight: FontWeight.w700,
                                color: AppColors.red),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Quick exit
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Quick Exit = full logout + force-redirect
                              await _auth.logout();
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context, '/login', (route) => false);
                              }
                            },
                            icon: const Icon(Icons.exit_to_app, size: 18),
                            label: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  EnText('Quick Exit',
                                      size: 14,
                                      weight: FontWeight.w700,
                                      color: Colors.white),
                                  SizedBox(width: 6),
                                  BnText('· দ্রুত বের হন',
                                      size: 12, color: Colors.white),
                                ]),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                elevation: 0),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Column(children: [
                            const BnText('গণপ্রজাতন্ত্রী বাংলাদেশ সরকার',
                                size: 10, color: AppColors.ink3),
                            const SizedBox(height: 1),
                            EnText('Government of Bangladesh · v1.0.0',
                                size: 9.5,
                                color: AppColors.ink3,
                                letterSpacing: 0.4),
                          ]),
                        ),
                      ],
                    ),
            ),
          ])),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String t, bn;
  final VoidCallback? action;
  const _SectionHeader({required this.t, required this.bn, this.action});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
      child: Row(children: [
        EnText(t.toUpperCase(),
            size: 10.5,
            weight: FontWeight.w700,
            color: AppColors.ink3,
            letterSpacing: 0.6),
        const SizedBox(width: 5),
        BnText('· $bn', size: 11, color: AppColors.ink3),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: action,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 13, color: AppColors.green),
                    SizedBox(width: 2),
                    EnText('Add',
                        size: 11,
                        weight: FontWeight.w700,
                        color: AppColors.green),
                  ]),
            ),
          ),
      ]),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String t, bn;
  final Widget? trailing;
  const _SettingTile({
    required this.icon,
    required this.t,
    required this.bn,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.ink2),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                EnText(t, size: 13, weight: FontWeight.w600),
                BnText(bn, size: 11, color: AppColors.ink3),
              ])),
          if (trailing != null)
            trailing!
          else
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.ink3),
        ]),
      );
}

class _Switch extends StatelessWidget {
  final bool v;
  final ValueChanged<bool> onChange;
  const _Switch({required this.v, required this.onChange});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChange(!v),
      child: Container(
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: v ? AppColors.green : AppColors.line,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: v ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
