import Flutter
import UIKit
import Foundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    nativeLog("[NATIVE] APNs registerForRemoteNotifications çağrıldı")

    application.registerForRemoteNotifications()

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {

    let token = deviceToken
      .map { String(format: "%02.2hhx", $0) }
      .joined()

    nativeLog("[NATIVE] [APNs] KAYIT BAŞARILI")
    nativeLog("[NATIVE] [APNs] Device Token: \(token)")

    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {

    nativeLog("[NATIVE] [APNs] KAYIT BAŞARISIZ")
    nativeLog("[NATIVE] [APNs] HATA: \(error.localizedDescription)")
    nativeLog("[NATIVE] [APNs] HATA DETAYI: \(error)")

    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  private func nativeLog(_ mesaj: String) {

    print(mesaj)

    guard let url = URL(
      string: "https://smksonuc.com/api/debug_log.php"
    ) else {
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(
      "application/json",
      forHTTPHeaderField: "Content-Type"
    )

    let body: [String: String] = [
      "mesaj": mesaj,
      "platform": "iOS"
    ]

    request.httpBody = try? JSONSerialization.data(
      withJSONObject: body,
      options: []
    )

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
