import 'package:flutter/material.dart';

import '../../../shared/utils/phone_launcher.dart';

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  static const _departmentContacts = [
    _PhoneContact(
      title: 'Koruma ve Güvenlik Şube Müdürlüğü',
      displayNumber: '0 242 310 16 65',
      phoneNumber: '02423101665',
    ),
    _PhoneContact(
      title: 'Güvenlik Amirliği',
      displayNumber: '0 242 310 15 97',
      phoneNumber: '02423101597',
    ),
    _PhoneContact(
      title: 'Güvenlik Şefliği',
      displayNumber: '0 242 310 16 68',
      phoneNumber: '02423101668',
    ),
    _PhoneContact(
      title: 'Güvenlik Trafik',
      displayNumber: '0 242 310 44 49',
      phoneNumber: '02423104449',
    ),
  ];

  static const _officeContacts = [
    _PhoneContact(
      title: 'Büro hattı 1',
      displayNumber: '0 242 310 16 65',
      phoneNumber: '02423101665',
    ),
    _PhoneContact(
      title: 'Büro hattı 2',
      displayNumber: '0 242 310 17 41',
      phoneNumber: '02423101741',
    ),
    _PhoneContact(
      title: 'Büro hattı 3',
      displayNumber: '0 242 310 16 66',
      phoneNumber: '02423101666',
    ),
    _PhoneContact(
      title: 'Büro hattı 4',
      displayNumber: '0 242 310 16 59',
      phoneNumber: '02423101659',
    ),
  ];

  static const _campusPosts = [
    _CampusPost(name: 'Meltem Kapısı', direction: 'Doğu', extension: '1664'),
    _CampusPost(name: 'Toros Kapısı', direction: 'Güney', extension: '3379'),
    _CampusPost(name: 'Uncalı Kapısı', direction: 'Batı', extension: '6921'),
    _CampusPost(
      name: 'Teknokent Kapısı',
      direction: 'Kuzey',
      extension: '6013',
    ),
  ];

  Future<void> _call(BuildContext context, String phoneNumber) async {
    final launched = await launchPhoneCall(phoneNumber);
    if (!launched && context.mounted) {
      _showLaunchError(context, 'Arama uygulaması açılamadı.');
    }
  }

  void _showLaunchError(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kampüs Güvenliği')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          132 + MediaQuery.of(context).padding.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HotlineCard(onCall: () => _call(context, '02423102222')),
                const SizedBox(height: 30),
                const _SectionHeader(
                  title: 'Güvenlik birimleri',
                  description: 'Konuna uygun birime doğrudan ulaş.',
                ),
                const SizedBox(height: 12),
                _ContactList(
                  contacts: _departmentContacts,
                  onCall: (number) => _call(context, number),
                ),
                const SizedBox(height: 30),
                const _SectionHeader(
                  title: 'Büro hizmetleri',
                  description: 'Müsait olan büro hattını arayabilirsin.',
                ),
                const SizedBox(height: 12),
                _OfficeLines(
                  contacts: _officeContacts,
                  onCall: (number) => _call(context, number),
                ),
                const SizedBox(height: 30),
                const _SectionHeader(
                  title: 'Yerleşke nöbet noktaları',
                  description: 'Kapı güvenliğine santral üzerinden ulaş.',
                ),
                const SizedBox(height: 12),
                _SwitchboardCard(
                  posts: _campusPosts,
                  onCallSwitchboard: () => _call(context, '02422274400'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HotlineCard extends StatelessWidget {
  final VoidCallback onCall;

  const _HotlineCard({required this.onCall});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Güvenlik İhbar Hattı, 0242 310 22 22',
      child: Material(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onCall,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.onError.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: colorScheme.onError,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GÜVENLİK İHBAR HATTI',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onError.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '0242 310 22 22',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onError,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yerleşke içinden dahili 112 veya 22 22',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onError.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.onError,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_in_talk_rounded,
                        size: 20,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Şimdi Ara',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String description;

  const _SectionHeader({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ContactList extends StatelessWidget {
  final List<_PhoneContact> contacts;
  final ValueChanged<String> onCall;

  const _ContactList({required this.contacts, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < contacts.length; index++) ...[
            _ContactRow(
              contact: contacts[index],
              onCall: () => onCall(contacts[index].phoneNumber),
            ),
            if (index != contacts.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final _PhoneContact contact;
  final VoidCallback onCall;

  const _ContactRow({required this.contact, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '${contact.title}, ${contact.displayNumber}, ara',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCall,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.title,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        contact.displayNumber,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '${contact.title} ara',
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_outlined),
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficeLines extends StatelessWidget {
  final List<_PhoneContact> contacts;
  final ValueChanged<String> onCall;

  const _OfficeLines({required this.contacts, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (var index = 0; index < contacts.length; index++) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () => onCall(contacts[index].phoneNumber),
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: Text(contacts[index].displayNumber),
                ),
              ),
              if (index != contacts.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwitchboardCard extends StatelessWidget {
  final List<_CampusPost> posts;
  final VoidCallback onCallSwitchboard;

  const _SwitchboardCard({
    required this.posts,
    required this.onCallSwitchboard,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colorScheme.primaryContainer.withValues(alpha: 0.46),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Nasıl aranır? ',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            TextSpan(
                              text:
                                  'Santrali ara, bağlantı kurulunca dört '
                                  'haneli dahiliyi tuşla.',
                            ),
                          ],
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onCallSwitchboard,
                    icon: const Icon(Icons.phone_in_talk_outlined, size: 19),
                    label: const Text('Santrali Ara  •  0242 227 44 00'),
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < posts.length; index++) ...[
            _CampusPostRow(post: posts[index]),
            if (index != posts.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
          ],
        ],
      ),
    );
  }
}

class _CampusPostRow extends StatelessWidget {
  final _CampusPost post;

  const _CampusPostRow({required this.post});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.name,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${post.direction} kapısı',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'DAHİLİ',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                post.extension,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhoneContact {
  final String title;
  final String displayNumber;
  final String phoneNumber;

  const _PhoneContact({
    required this.title,
    required this.displayNumber,
    required this.phoneNumber,
  });
}

class _CampusPost {
  final String name;
  final String direction;
  final String extension;

  const _CampusPost({
    required this.name,
    required this.direction,
    required this.extension,
  });
}
