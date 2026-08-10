/// Cloudinary hesap ayarlari.
///
/// `apiSecret` bilerek burada yok: imzali yukleme icin gereken secret APK
/// icine gomulseydi decompile eden herkes hesaba dosya yukleyip silebilirdi.
/// Bunun yerine yuklemeler Dashboard'da tanimli **unsigned upload preset**
/// uzerinden yapiliyor; preset kendi klasor/boyut kisitlarini kendisi uygular.
///
/// Degerler `--dart-define` ile derleme aninda ezilebilir:
/// `flutter run --dart-define=CLOUDINARY_UPLOAD_PRESET=baska_preset`
class CloudinaryConfig {
  const CloudinaryConfig._();

  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'tpeecobl',
  );

  /// Yalnizca URL uretimi ve analitik icin; gizli bir deger degil.
  static const apiKey = String.fromEnvironment(
    'CLOUDINARY_API_KEY',
    defaultValue: '711417722288998',
  );

  /// Cloudinary Dashboard > Settings > Upload > Upload presets altinda
  /// "Signing Mode: Unsigned" olarak tanimli olmali.
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'akdenizcep_unsigned',
  );
}
