import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

/// Gorsel yuklemenin tek giris noktasi.
///
/// `cloudinary_flutter` / `cloudinary_url_gen` paketleri yalnizca URL uretimi
/// ve gosterim (CldImage) icin; yukleme API'si icermiyorlar. Bu yuzden
/// Cloudinary'nin REST upload uc noktasina dogrudan multipart istek atiyoruz.
///
/// Yuklemeler imzasiz (unsigned) preset ile yapilir — bkz. [CloudinaryConfig].
/// Silme islemi imza gerektirdiginden istemciden yapilamaz; artik kullanilmayan
/// gorseller Cloudinary tarafinda temizlenir.
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _uploadUri = Uri.parse(
    'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
  );

  /// [folder] Cloudinary'de gorselin konacagi klasor (or. `event-covers`).
  /// Basarili olursa `secure_url` doner.
  Future<String> uploadImage({required File file, required String folder}) async {
    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on SocketException {
      throw Exception('Gorsel yuklenemedi: internet baglantisi kurulamadi.');
    } on http.ClientException catch (e) {
      throw Exception('Gorsel yuklenemedi: ${e.message}');
    }

    final body = _decode(response.body);

    if (response.statusCode != 200) {
      // Cloudinary hatayi {"error": {"message": "..."}} seklinde dondurur.
      final error = body['error'];
      final message = error is Map ? error['message'] as String? : null;
      throw Exception('Gorsel yuklenemedi: ${message ?? 'HTTP ${response.statusCode}'}');
    }

    final url = body['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Gorsel yuklenemedi: sunucu adres dondurmedi.');
    }
    return url;
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}
