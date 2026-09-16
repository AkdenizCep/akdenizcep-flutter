import 'package:flutter/material.dart';

import '../../../shared/utils/phone_launcher.dart';
import 'components/security_contact_section.dart';

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SecurityContactSection(
                  title: 'Güvenlik ihbar hattı',
                  description: 'Kampüs içindeki güvenlik durumlarını bildir.',
                  urgent: true,
                  children: [
                    SecurityContactTile(
                      title: 'Güvenlik İhbar Hattı',
                      detail: '0 242 310 22 22',
                      note: 'Yerleşke içinden dahili 112 veya 22 22',
                      urgent: true,
                      onCall: () => _call(context, '02423102222'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SecurityContactSection(
                  title: 'Güvenlik birimleri',
                  description: 'Konuna uygun birime doğrudan ulaş.',
                  children: [
                    for (final contact in _departmentContacts)
                      SecurityContactTile(
                        title: contact.title,
                        detail: contact.displayNumber,
                        onCall: () => _call(context, contact.phoneNumber),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SecurityContactSection(
                  title: 'Büro hizmetleri',
                  description: 'Müsait olan büro hattını arayabilirsin.',
                  children: [
                    for (final contact in _officeContacts)
                      SecurityContactTile(
                        title: contact.title,
                        detail: contact.displayNumber,
                        onCall: () => _call(context, contact.phoneNumber),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SecurityContactSection(
                  title: 'Yerleşke nöbet noktaları',
                  description:
                      'Santrali ara, bağlantı kurulunca dört haneli '
                      'dahiliyi tuşla.',
                  children: [
                    SecurityContactTile(
                      title: 'Üniversite santrali',
                      detail: '0 242 227 44 00',
                      onCall: () => _call(context, '02422274400'),
                    ),
                    for (final post in _campusPosts)
                      SecurityContactTile(
                        title: post.name,
                        detail:
                            '${post.direction} kapısı · Dahili ${post.extension}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
