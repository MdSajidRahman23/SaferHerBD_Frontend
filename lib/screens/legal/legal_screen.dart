import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/design_widgets.dart';

class LegalScreen extends StatefulWidget {
  final void Function(String) onNav;
  final VoidCallback onBack;
  const LegalScreen({super.key, required this.onNav, required this.onBack});
  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  String? _open;

  static const _laws = [
    _Law(
        id: 'dv',
        t: 'Domestic Violence Act',
        bn: 'পারিবারিক সহিংসতা আইন',
        y: 2010,
        sum:
            'Protection orders, residence orders, and monetary relief for victims of physical, mental, or economic abuse.',
        tag: 'Active',
        refs: 28),
    _Law(
        id: 'cyber',
        t: 'Cyber Security Act',
        bn: 'সাইবার নিরাপত্তা আইন',
        y: 2023,
        sum:
            'Penalizes online harassment, blackmail, deepfakes, and non-consensual image sharing. §25, §26, §28.',
        tag: 'Updated',
        refs: 41),
    _Law(
        id: 'ws',
        t: 'Women & Children Repression Act',
        bn: 'নারী ও শিশু নির্যাতন দমন আইন',
        y: 2000,
        sum:
            'Comprehensive law on rape, dowry violence, acid attacks, and trafficking. Special tribunals.',
        tag: 'Active',
        refs: 67),
    _Law(
        id: 'dowry',
        t: 'Dowry Prohibition Act',
        bn: 'যৌতুক নিরোধ আইন',
        y: 2018,
        sum:
            'Demanding, giving, or taking dowry is punishable with up to 5 years imprisonment and fine.',
        tag: 'Active',
        refs: 19),
    _Law(
        id: 'hara',
        t: 'Sexual Harassment Guidelines',
        bn: 'যৌন হয়রানি নির্দেশিকা',
        y: 2009,
        sum:
            'High Court directive — every workplace and educational institution must form a complaint committee.',
        tag: 'Directive',
        refs: 33),
    _Law(
        id: 'mar',
        t: 'Child Marriage Restraint Act',
        bn: 'বাল্যবিবাহ নিরোধ আইন',
        y: 2017,
        sum:
            'Marriage age 18 for women, 21 for men. Punishment for parents and registrars.',
        tag: 'Active',
        refs: 14),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        // Government-style green header
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              18,
              MediaQuery.of(context).padding.top + 14,
              18,
              22),
          decoration: const BoxDecoration(color: AppColors.green),
          child: Stack(children: [
            // Decorative seal pattern
            Positioned(
              right: -30,
              top: -30,
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    IconBtn(
                        icon: Icons.chevron_left,
                        dark: true,
                        onTap: widget.onBack),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                          EnText('GOVERNMENT OF BANGLADESH',
                              size: 10,
                              weight: FontWeight.w700,
                              color: Color(0xB3FFFFFF),
                              letterSpacing: 1),
                          SizedBox(height: 1),
                          EnText('Legal Empowerment Hub',
                              size: 17,
                              weight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2),
                          BnText('আইনি ক্ষমতায়ন কেন্দ্র',
                              size: 11, color: Color(0xD9FFFFFF)),
                        ])),
                  ]),
                  const SizedBox(height: 14),
                  // Search bar
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(children: const [
                      Icon(Icons.search, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      EnText('Search laws, sections, hotlines...',
                          size: 12, color: Color(0xCCFFFFFF)),
                    ]),
                  ),
                ]),
          ]),
        ),

        // Hotlines strip
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          color: AppColors.card,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _HotlineChip(num: '999', label: 'Emergency'),
              _HotlineChip(num: '109', label: 'Women Helpline'),
              _HotlineChip(num: '333', label: 'Citizens Hub'),
              _HotlineChip(num: '1098', label: 'Child Helpline'),
            ]),
          ),
        ),

        // Laws list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            itemCount: _laws.length,
            itemBuilder: (_, i) {
              final l = _laws[i];
              final open = _open == l.id;
              return GestureDetector(
                onTap: () => setState(() => _open = open ? null : l.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: open
                            ? AppColors.green.withOpacity(0.5)
                            : AppColors.line,
                        width: open ? 1.5 : 1),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.greenSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.gavel,
                                color: AppColors.green, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Expanded(
                                      child: EnText(l.t,
                                          size: 13.5,
                                          weight: FontWeight.w700)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: l.tag == 'Updated'
                                          ? const Color(0xFFFFEDD5)
                                          : AppColors.greenSoft,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: EnText(l.tag,
                                        size: 8.5,
                                        weight: FontWeight.w700,
                                        color: l.tag == 'Updated'
                                            ? const Color(0xFFC2410C)
                                            : AppColors.green,
                                        letterSpacing: 0.3),
                                  ),
                                ]),
                                const SizedBox(height: 1),
                                Row(children: [
                                  BnText(l.bn,
                                      size: 11, color: AppColors.ink3),
                                  const Text(' · ',
                                      style: TextStyle(
                                          color: AppColors.ink3,
                                          fontSize: 10)),
                                  EnText('${l.y}',
                                      size: 11, color: AppColors.ink3),
                                  const Text(' · ',
                                      style: TextStyle(
                                          color: AppColors.ink3,
                                          fontSize: 10)),
                                  EnText('${l.refs} cases referenced',
                                      size: 11, color: AppColors.ink3),
                                ]),
                              ])),
                          Icon(open
                              ? Icons.expand_less
                              : Icons.expand_more,
                              color: AppColors.ink3),
                        ]),
                        if (open) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: AppColors.line),
                          const SizedBox(height: 10),
                          EnText(l.sum,
                              size: 12.5,
                              color: AppColors.ink2,
                              height: 1.55),
                          const SizedBox(height: 10),
                          Row(children: [
                            _SmallBtn(
                                icon: Icons.book_outlined,
                                label: 'Read full text'),
                            const SizedBox(width: 8),
                            _SmallBtn(
                                icon: Icons.phone_outlined,
                                label: 'Call legal aid'),
                          ]),
                        ],
                      ]),
                ),
              );
            },
          ),
        ),

        BottomNavBar(active: 'legal', onNav: widget.onNav),
      ]),
    );
  }
}

class _Law {
  final String id, t, bn, sum, tag;
  final int y, refs;
  const _Law({
    required this.id,
    required this.t,
    required this.bn,
    required this.y,
    required this.sum,
    required this.tag,
    required this.refs,
  });
}

class _HotlineChip extends StatelessWidget {
  final String num;
  final String label;
  const _HotlineChip({required this.num, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.phone, size: 11, color: AppColors.green),
          const SizedBox(width: 4),
          EnText(num,
              size: 12, weight: FontWeight.w800, color: AppColors.green),
          const SizedBox(width: 5),
          EnText(label, size: 10.5, color: AppColors.ink2),
        ]),
      );
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SmallBtn({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: AppColors.ink2),
                const SizedBox(width: 5),
                EnText(label,
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppColors.ink2),
              ]),
        ),
      );
}
