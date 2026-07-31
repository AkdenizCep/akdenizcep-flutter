import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // google_maps_flutter bu cagri olmadan bos/gri bir harita cizer.
    // Anahtar kaynak kontrolunde tutulmaz: ios/Flutter/Secrets.xcconfig
    // icindeki MAPS_API_KEY, Info.plist'e $(MAPS_API_KEY) ile islenir ve
    // burada okunur. Anahtar Cloud Console'da bundle id ile kisitlanmalidir.
    if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "MapsApiKey") as? String,
       !mapsApiKey.isEmpty {
      GMSServices.provideAPIKey(mapsApiKey)
    } else {
      NSLog("[Maps] MAPS_API_KEY tanimli degil — harita bos cizilecek. "
        + "ios/Flutter/Secrets.xcconfig dosyasini olustur.")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
