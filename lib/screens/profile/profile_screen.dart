import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gov_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _api  = ApiService();

  Map<String, dynamic>? _user;
  List<dynamic> _contacts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final user     = await _auth.getUser();
    final contacts = await _api.getContacts();
    if (mounted) setState(() {
      _user     = user;
      _contacts = contacts;
      _loading  = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('লগআউট', style: GoogleFonts.hindSiliguri(
            color: AppColors.t1, fontWeight: FontWeight.w700)),
        content: Text('আপনি কি নিশ্চিতভাবে লগআউট করতে চান?',
            style: GoogleFonts.hindSiliguri(color: AppColors.t2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('না', style: TextStyle(color: AppColors.t2)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.r),
            child: Text('হ্যাঁ, লগআউট'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showAddContactDialog() {
    final nameCtrl  = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl   = TextEditingController();
    int priority = 1;

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
          const SizedBox(height: 16),
          Text('নতুন যোগাযোগ যোগ করুন',
              style: GoogleFonts.hindSiliguri(
                  color: AppColors.t1, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl,
            style: TextStyle(color: AppColors.t1),
            decoration: const InputDecoration(labelText: 'নাম / Name',
                prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 10),
          TextField(controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: AppColors.t1),
            decoration: const InputDecoration(labelText: 'ফোন / Phone',
                prefixIcon: Icon(Icons.phone_rounded))),
          const SizedBox(height: 10),
          TextField(controller: relCtrl,
            style: TextStyle(color: AppColors.t1),
            decoration: const InputDecoration(labelText: 'সম্পর্ক / Relation (মা, বাবা, বন্ধু)',
                prefixIcon: Icon(Icons.people_outline))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
              Navigator.pop(context);
              final res = await _api.addContact(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                relation: relCtrl.text.trim().isEmpty ? 'Contact' : relCtrl.text.trim(),
                priority: priority,
              );
              final code = res['statusCode'] as int? ?? 0;
              final ok = code == 200 || code == 201;
              if (ok) _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'যোগাযোগ যোগ হয়েছে ✓' : 'সমস্যা হয়েছে',
                    style: GoogleFonts.hindSiliguri()),
                backgroundColor: ok ? AppColors.g : AppColors.r,
              ));
            },
            child: Text('যোগ করুন / Add',
                style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
          )),
        ]),
      ),
    );
  }

  Future<void> _deleteContact(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('মুছে ফেলুন', style: GoogleFonts.hindSiliguri(
            color: AppColors.t1, fontWeight: FontWeight.w700)),
        content: Text('$name কে তালিকা থেকে সরাবেন?',
            style: GoogleFonts.hindSiliguri(color: AppColors.t2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('না', style: TextStyle(color: AppColors.t2))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.r),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _api.deleteContact(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name  = _user?['name'] as String? ?? 'User';
    final phone = _user?['phone'] as String? ?? '—';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.g))
          : CustomScrollView(slivers: [

        SliverToBoxAdapter(child: HeroHeader(
          title: 'Profile',
          subtitle: 'আমার প্রোফাইল',
          trailing: IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
          ),
        )),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // ── Avatar + Name ──────────────────────────────────────
            GovCard(child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.g.withOpacity(0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(color: AppColors.g, fontSize: 24,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: GoogleFonts.dmSans(
                    color: AppColors.t1, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.phone_rounded, size: 14, color: AppColors.t3),
                  const SizedBox(width: 5),
                  Text(phone, style: GoogleFonts.dmSans(
                      color: AppColors.t2, fontSize: 13)),
                ]),
              ])),
            ])),
            const SizedBox(height: 16),

            // ── Emergency Contacts ─────────────────────────────────
            SectionTitle(
              en: 'Emergency Contacts',
              bn: 'জরুরি যোগাযোগ (${_contacts.length}/5)',
              trailing: IconButton(
                onPressed: _showAddContactDialog,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.g.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.g, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (_contacts.isEmpty)
              GovCard(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(children: [
                  Icon(Icons.person_add_outlined, size: 36, color: AppColors.t3),
                  const SizedBox(height: 8),
                  Text('কোনো জরুরি যোগাযোগ নেই',
                      style: GoogleFonts.hindSiliguri(color: AppColors.t2)),
                  const SizedBox(height: 4),
                  Text('+ বোতাম চেপে যোগ করুন',
                      style: GoogleFonts.hindSiliguri(
                          color: AppColors.t3, fontSize: 12)),
                ]),
              ))
            else
              ..._contacts.map((c) {
                final contact = Map.from(c);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    CircleAvatar(radius: 18,
                      backgroundColor: AppColors.g.withOpacity(0.12),
                      child: Text(
                        (contact['name'] as String? ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.g,
                            fontWeight: FontWeight.w700),
                      )),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(contact['name'] ?? '',
                          style: GoogleFonts.dmSans(
                              color: AppColors.t1, fontWeight: FontWeight.w600)),
                      Text('${contact['relation'] ?? ''} · ${contact['phone'] ?? ''}',
                          style: GoogleFonts.dmSans(
                              color: AppColors.t3, fontSize: 11)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.g.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('P${contact['priority_order'] ?? 1}',
                          style: const TextStyle(color: AppColors.g,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _deleteContact(
                        contact['id']?.toString() ?? '',
                        contact['name'] ?? '',
                      ),
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.r, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ]),
                );
              }),

            const SizedBox(height: 20),

            // ── Settings ───────────────────────────────────────────
            const SectionTitle(en: 'Settings', bn: 'সেটিংস'),
            const SizedBox(height: 8),

            GovCard(child: Column(children: [
              _SettingTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications', titleBn: 'বিজ্ঞপ্তি',
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.border),
              _SettingTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy', titleBn: 'গোপনীয়তা নীতি',
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.border),
              _SettingTile(
                icon: Icons.info_outline_rounded,
                title: 'About SafeHerBD', titleBn: 'পরিচিতি',
                onTap: () {},
              ),
            ])),
            const SizedBox(height: 12),

            // Logout button
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: AppColors.r),
              label: Text('লগআউট / Logout',
                  style: GoogleFonts.hindSiliguri(
                      color: AppColors.r, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.r),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )),
            const SizedBox(height: 20),
            const GovFooter(),
          ])),
        ),
      ]),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title, titleBn;
  final VoidCallback onTap;
  const _SettingTile({required this.icon, required this.title,
    required this.titleBn, required this.onTap});
  @override Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.g, size: 22),
      title: Text(title, style: GoogleFonts.dmSans(
          color: AppColors.t1, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(titleBn, style: GoogleFonts.hindSiliguri(
          color: AppColors.t3, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.t3, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
    );
  }
}
