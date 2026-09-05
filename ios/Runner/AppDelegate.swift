import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // APNs'e cihaz kaydı
    application.registerForRemoteNotifications()

    nativeLog("[APNs] registerForRemoteNotifications çağrıldı")

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  // APNs kayıt BAŞARILI
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {

    let token = deviceToken
      .map { String(format: "%02.2hhx", $0) }
      .joined()

    nativeLog("[APNs] KAYIT BAŞARILI")
    nativeLog("[APNs] Device Token: \(token)")

    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  // APNs kayıt BAŞARISIZ
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {

    nativeLog("[APNs] KAYIT BAŞARISIZ")
    nativeLog("[APNs] HATA: \(error.localizedDescription)")
    nativeLog("[APNs] HATA DETAYI: \(error)")

    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  // Native logları debug_log.php'ye gönder
  private func nativeLog(_ message: String) {

    print(message)

    guard let url = URL(
      string: "https://smksonuc.com/api/debug_log.php"
    ) else {
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(
      "application/x-www-form-urlencoded; charset=utf-8",
      forHTTPHeaderField: "Content-Type"
    )

    let encodedMessage = message
      .addingPercentEncoding(
        withAllowedCharacters: .urlQueryAllowed
      ) ?? message

    let body = "platform=iOS-NATIVE&message=\(encodedMessage)"
    request.httpBody = body.data(using: .utf8)

    URLSession.shared.dataTask(with: request).resume()
  }

  func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    GeneratedPluginRegistrant.register(
      with: engineBridge.pluginRegistry
    )
  }
}
