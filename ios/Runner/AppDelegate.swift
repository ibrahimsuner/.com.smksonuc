import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Firebase başlat
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // Bildirim merkezi
    UNUserNotificationCenter.current().delegate = self

    // APNs'e cihazı kaydet
    application.registerForRemoteNotifications()

    // Firebase Messaging delegate
    Messaging.messaging().delegate = self

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  // APNs kayıt başarılı
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {

    let token = deviceToken
      .map { String(format: "%02.2hhx", $0) }
      .joined()

    print("========================================")
    print("[APNs] KAYIT BAŞARILI")
    print("[APNs] Device Token: \(token)")
    print("========================================")

    // APNs tokenını Firebase'e ver
    Messaging.messaging().apnsToken = deviceToken

    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  // APNs kayıt başarısız
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {

    print("========================================")
    print("[APNs] KAYIT BAŞARISIZ")
    print("[APNs] HATA: \(error.localizedDescription)")
    print("[APNs] HATA DETAYI: \(error)")
    print("========================================")

    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  // Firebase FCM token
  func messaging(
    _ messaging: Messaging,
    didReceiveRegistrationToken fcmToken: String?
  ) {

    print("========================================")
    print("[FCM] TOKEN GELDİ")
    print("[FCM] Token: \(fcmToken ?? "YOK")")
    print("========================================")
  }

  func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    GeneratedPluginRegistrant.register(
      with: engineBridge.pluginRegistry
    )
  }
}

// Firebase Messaging Delegate
extension AppDelegate: MessagingDelegate {
}
