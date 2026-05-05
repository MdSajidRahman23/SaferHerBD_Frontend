import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gov_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api  = ApiService();
  final _auth = AuthService();
  String _userName = '';
  List<dynamic> _safetyIndex = [];
  bool _loading = true;

  final _alerts = const [
    _Alert('⚠️', 'High incident zone near Mirpur-1 after 9PM',         '২ ঘণ্টা আগে', AppColors.r),
    _Alert('✅', 'Safe corridor: Uttara → Gulshan via DIT Road',         '৫ ঘণ্টা আগে', AppColors.g),
    _Alert('🔔', 'Community report: Suspicious activity near Farmgate', '৮ ঘণ্টা আগে', AppColors.gold),
  ];

  @override void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final user  = await _auth.getUser();
    final index = await _api.getSafetyIndex();
    if (mounted) setState(() {
      _userName    = user?['name'] ?? 'User';
      _safetyIndex = index.isEmpty ? _seedCities() : index;
      _loading     = false;
    });
  }

  List<Map> _seedCities() => [
    {'city':'Dhaka',     'city_bn':'ঢাকা',     'score':68,'trend':'up',     'incidents':245},
    {'city':'Chattogram','city_bn':'চট্টগ্রাম','score':72,'trend':'up',     'incidents':156},
    {'city':'Sylhet',    'city_bn':'সিলেট',    'score':78,'trend':'stable', 'incidents':89},
    {'city':'Rajshahi',  'city_bn':'রাজশাহী',  'score':81,'trend':'up',     'incidents':67},
    {'city':'Khulna',    'city_bn':'খুলনা',    'score':75,'trend':'down',   'incidents':102},
  ];

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'শুভ সকাল ☀️';
    if (h < 17) return 'শুভ অপরাহ্ন 🌤️';
    return 'শুভ সন্ধ্যা 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.g,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHero()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const SectionTitle(en: 'Quick Access', bn: 'দ্রুত প্রবেশ'),
              const SizedBox(height: 10),
              _buildQuickGrid(),
              const SizedBox(height: 18),
              Row(children: const [
                _StatBox('<2s', 'SOS Response', 'NFR-1 ✓', AppColors.r),
                SizedBox(width: 10),
                _StatBox('99%', 'Uptime',       'NFR-3 ✓', AppColors.g),
                SizedBox(width: 10),
                _StatBox('24/7','AI Support',   'সদা সক্রিয়', AppColors.orange),
              ]),
              const SizedBox(height: 18),
              const SectionTitle(en: 'Live Alerts', bn: 'সর্বশেষ সতর্কতা'),
              const SizedBox(height: 10),
              ..._alerts.map((a) => _AlertTile(alert: a)),
              const SizedBox(height: 18),
              const SectionTitle(en: 'City-wise Safety Index', bn: 'শহরভিত্তিক নিরাপত্তা সূচক'),
              const SizedBox(height: 10),
              if (_loading)
                const Padding(padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: AppColors.g)))
              else
                ..._safetyIndex.map((c) => _CityTile(city: Map.from(c))),
              const SizedBox(height: 20),
              const GovFooter(),
            ])),
          ),
        ]),
      ),
    );
  }

  Widget _buildHero() {
    return HeroHeader(
      title: _userName.isEmpty ? 'Welcome' : _userName,
      subtitle: _greeting,
      trailing: const StatusPill(
        label: 'নিরাপদ', color: AppColors.aqua, light: true,
      ),
      children: [
        const SizedBox(height: 16),
        // Safety Score Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('এলাকার নিরাপত্তা স্কোর', style: GoogleFonts.hindSiliguri(
                  color: Colors.white70, fontSize: 12)),
              const Text('Area Safety Score', style: TextStyle(
                  color: Colors.white38, fontSize: 10)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.74,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(AppColors.aqua),
                  minHeight: 6,
                ),
              ),
            ])),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('74', style: GoogleFonts.dmSans(
                  color: Colors.white, fontSize: 50,
                  fontWeight: FontWeight.w800, height: 1)),
              const Text('Moderate Safe', style: TextStyle(
                  color: AppColors.aqua, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ],
    );
  }

  Widget _buildQuickGrid() {
    final items = [
      _Quick(Icons.warning_amber_rounded, 'SOS Alert',  'জরুরি সাহায্য', AppColors.r,      1),
      _Quick(Icons.alt_route_rounded,     'Safe Route', 'নিরাপদ পথ',    AppColors.g,      2),
      _Quick(Icons.people_rounded,        'Community',  'সম্প্রদায়',    AppColors.purple, 3),
      _Quick(Icons.chat_bubble_rounded,   'Support',    'মানসিক সহায়তা', AppColors.orange, 4),
    ];
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.3, mainAxisSpacing: 10, crossAxisSpacing: 10,
      children: items.map((q) => GovCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(
              color: q.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(q.icon, color: q.color, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(q.title, style: GoogleFonts.dmSans(
                  color: AppColors.t1, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(q.titleBn, style: GoogleFonts.hindSiliguri(
                  color: AppColors.t3, fontSize: 11)),
            ])),
        ]),
      )).toList(),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String val, lbl, sub; final Color color;
  const _StatBox(this.val, this.lbl, this.sub, this.color);
  @override Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(children: [
      Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(lbl, style: GoogleFonts.dmSans(color: AppColors.t2, fontSize: 9),
          textAlign: TextAlign.center),
      Text(sub, style: TextStyle(color: color.withOpacity(0.6), fontSize: 9)),
    ]),
  ));
}

class _Alert {
  final String icon, msg, time;
  final Color color;
  const _Alert(this.icon, this.msg, this.time, this.color);
}

class _AlertTile extends StatelessWidget {
  final _Alert alert;
  const _AlertTile({required this.alert});
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      Container(width: 38, height: 38,
        decoration: BoxDecoration(
          color: alert.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(alert.icon, style: const TextStyle(fontSize: 18))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(alert.msg, style: GoogleFonts.dmSans(
            color: AppColors.t1, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4)),
        Text(alert.time, style: GoogleFonts.hindSiliguri(
            color: AppColors.t3, fontSize: 10)),
      ])),
      const SizedBox(width: 8),
      Container(width: 4, height: 36,
          decoration: BoxDecoration(
            color: alert.color,
            borderRadius: BorderRadius.circular(2),
          )),
    ]),
  );
}

class _CityTile extends StatelessWidget {
  final Map city;
  const _CityTile({required this.city});
  Color _c(int s) => s >= 80 ? AppColors.g : s >= 60 ? AppColors.gold : AppColors.r;
  @override Widget build(BuildContext context) {
    final score = city['score'] as int? ?? 0;
    final color = _c(score);
    final trend = city['trend'] as String? ?? 'stable';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        SizedBox(width: 50, height: 50,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: score / 100, strokeWidth: 3,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color)),
            Text('$score', style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(city['city'] ?? '', style: GoogleFonts.dmSans(
              color: AppColors.t1, fontWeight: FontWeight.w600, fontSize: 14)),
          Text(city['city_bn'] ?? '', style: GoogleFonts.hindSiliguri(
              color: AppColors.t3, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${city['incidents'] ?? 0} incidents',
              style: GoogleFonts.dmSans(color: AppColors.t3, fontSize: 10)),
          const SizedBox(height: 4),
          Icon(
            trend == 'up' ? Icons.trending_up_rounded :
            trend == 'down' ? Icons.trending_down_rounded :
            Icons.trending_flat_rounded,
            size: 18,
            color: trend == 'up' ? AppColors.g :
                   trend == 'down' ? AppColors.r : AppColors.gold,
          ),
        ]),
      ]),
    );
  }
}

class _Quick {
  final IconData icon; final String title, titleBn; final Color color; final int idx;
  const _Quick(this.icon, this.title, this.titleBn, this.color, this.idx);
}
