import 'package:flutter/material.dart';

class _ServiceHours {
  final String building;
  final String lunch;
  final String dinner;

  const _ServiceHours({
    required this.building,
    required this.lunch,
    this.dinner = '',
  });
}

class _PriceRow {
  final String label;
  final String price;

  const _PriceRow({required this.label, required this.price});
}

const _serviceHours = [
  _ServiceHours(
    building: 'Merkezi Yemekhane',
    lunch: '11.15 - 13.45',
    dinner: '16.30 - 18.30',
  ),
  _ServiceHours(
    building: 'Diş Hekimliği Fak. Yemekhanesi',
    lunch: '11.30 - 13.30',
  ),
  _ServiceHours(building: 'Edebiyat Fak. Yemekhanesi', lunch: '12.00 - 13.30'),
  _ServiceHours(building: 'İlahiyat Fak. Yemekhanesi', lunch: '11.30 - 13.30'),
  _ServiceHours(building: 'Yakut Çarşı Yemekhanesi', lunch: '12.00 - 13.30'),
];

const _studentPrices = [
  _PriceRow(label: 'Öğrenci Yemek Ücreti', price: '55.00 TL'),
  _PriceRow(label: 'Gün İçinde 2. Öğün Yemek Ücreti', price: '85.00 TL'),
];

const _staffPrices = [
  _PriceRow(label: '0 - 600 Ek Gösterge', price: '90.00 TL'),
  _PriceRow(label: '601 - 2800 (Dahil) Ek Gösterge', price: '95.00 TL'),
  _PriceRow(label: '2801 - 3000 (Dahil) Ek Gösterge', price: '105.00 TL'),
  _PriceRow(label: '3001 - 4200 (Dahil) Ek Gösterge', price: '115.00 TL'),
  _PriceRow(label: '4201 - 5400 (Dahil) Ek Gösterge', price: '120.00 TL'),
  _PriceRow(label: '5401 - 7000 ve Üstü Ek Gösterge', price: '130.00 TL'),
];

const _slipPrices = [
  _PriceRow(label: 'Günlük Fiş Yemek Ücreti', price: '235.00 TL'),
  _PriceRow(label: 'Personel İçin Gün İçinde 2. Geçiş', price: '140.00 TL'),
  _PriceRow(label: 'Personel İçin Gün İçinde 3. Geçiş', price: '235.00 TL'),
];

class CafeteriaInfoSheet extends StatefulWidget {
  const CafeteriaInfoSheet({super.key});

  @override
  State<CafeteriaInfoSheet> createState() => _CafeteriaInfoSheetState();
}

class _CafeteriaInfoSheetState extends State<CafeteriaInfoSheet> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: Column(
                  children: [
                    const _HeroBanner(),
                    const SizedBox(height: 16),
                    _InfoTabs(
                      selected: _tabIndex,
                      onChanged: (i) => setState(() => _tabIndex = i),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                  children: _tabIndex == 0
                      ? const [_HoursTab()]
                      : const [_PricesTab()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF135BEC), Color(0xFF5C4FE0)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF135BEC).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.info_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yemekhane Bilgileri',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Sağlık, Kültür ve Spor Dairesi Başkanlığı',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _InfoTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const labels = ['Saatler', 'Ücretler'];
    const icons = [Icons.schedule_rounded, Icons.payments_rounded];

    return Container(
      height: 60,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(labels.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF135BEC), Color(0xFF5C4FE0)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onChanged(i),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[i],
                          size: 19,
                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          labels[i],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        // Uzun basliklar iki satira iniyor; cubuk ilk satirla hizali kalsin.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 14,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                height: 1.35,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursTab extends StatelessWidget {
  const _HoursTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const _SectionTitle(title: 'Hizmet Saatleri'),
        for (var i = 0; i < _serviceHours.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ServiceHoursCard(hours: _serviceHours[i]),
        ],
      ],
    );
  }
}

class _PricesTab extends StatelessWidget {
  const _PricesTab();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const _SectionTitle(title: 'Öğrenci Yemek Ücretleri'),
        _PriceCard(rows: _studentPrices, accentColor: colorScheme.primary),
        const SizedBox(height: 24),
        const _SectionTitle(
          title: 'Personel Yemek Ücretleri (4/B Ek Gösterge)',
        ),
        _PriceCard(rows: _staffPrices, accentColor: const Color(0xFF5C4FE0)),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Günlük Fiş Yemek Ücretleri'),
        _PriceCard(rows: _slipPrices, accentColor: const Color(0xFFE8A317)),
      ],
    );
  }
}

class _ServiceHoursCard extends StatelessWidget {
  final _ServiceHours hours;

  const _ServiceHoursCard({required this.hours});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF135BEC), Color(0xFF5C4FE0)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF135BEC).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hours.building,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HoursPill(
                icon: Icons.wb_sunny_rounded,
                label: 'Öğle',
                hours: hours.lunch,
                color: const Color(0xFFE8A317),
              ),
              if (hours.dinner.isNotEmpty) ...[
                const SizedBox(width: 10),
                _HoursPill(
                  icon: Icons.nights_stay_rounded,
                  label: 'Akşam',
                  hours: hours.dinner,
                  color: const Color(0xFF5C4FE0),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HoursPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hours;
  final Color color;

  const _HoursPill({
    required this.icon,
    required this.label,
    required this.hours,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    hours,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final List<_PriceRow> rows;
  final Color accentColor;

  const _PriceCard({required this.rows, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(right: 13),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rows[i].price,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
