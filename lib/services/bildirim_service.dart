import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../navigator_key.dart';
import '../screens/splash_screen.dart';
import 'api_service.dart';
import 'session_service.dart';

// GEÇİCİ DEBUG LOG - sorunu bulduktan sonra bu fonksiyonu ve
// çağrıldığı yerleri kaldır.
// KENDİ SİTE ADRESİNİ BURAYA YAZ:
const String _debugLogUrl = 'https://smksonuc.com/api/debug_log.php';

Future<void> _uzaktanLog(String mesaj) async {
  try {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    await http.post(
      Uri.parse(_debugLogUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mesaj': mesaj, 'platform': platform}),
    ).timeout(const Duration(seconds: 5));
  } catch (_) {
    // log gönderilemezse sessizce geç, uygulamayı etkilemesin
  }
}


// Arka planda bildirim gelince çalışır
@pragma('vm:entry-point')
Future<void> _arkaplanBildirimHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint(
    'Arka plan bildirimi: ${message.notification?.title}',
  );
}


class BildirimService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _yerelBildirim =
  FlutterLocalNotificationsPlugin();

  static const String _kanalId = 'smksonuc_channel';
  static const String _kanalAdi = 'SMK Sonuç Bildirimleri';


  // Firebase ve bildirim sistemini başlat
  static Future<void> initialize() async {
    try {
      debugPrint('🔵 Firebase başlatılıyor...');

      await Firebase.initializeApp();

      debugPrint('✅ Firebase hazır');


      // Arka plan bildirimleri
      FirebaseMessaging.onBackgroundMessage(
        _arkaplanBildirimHandler,
      );


      // Yerel bildirim sistemini hazırla
      await _yerelBildirimKur();


      // Dinleyicileri kur
      _dinleyicileriKur();


      // Bildirim iznini iste - token almadan ÖNCE bitmesini bekliyoruz,
      // yoksa iOS'ta APNs token henüz hazır olmadan getToken() çağrılıp
      // hataya yol açabiliyor.
      await _izinIste();


      // FCM Token al
      // await kullanmıyoruz, uygulamayı bekletmez
      _tokenAlVeKaydet();


      // Uygulama tamamen kapalıyken bildirime tıklanarak açıldıysa
      try {
        final baslangicMesaji =
        await _messaging.getInitialMessage();

        if (baslangicMesaji != null) {
          debugPrint(
            '🔔 Uygulama bildirim ile açıldı',
          );

          _verigoreYonlendir(
            baslangicMesaji.data,
          );
        }
      } catch (e) {
        debugPrint(
          'Başlangıç bildirimi kontrol hatası: $e',
        );
      }

    } catch (e, stackTrace) {
      debugPrint(
        '❌ Bildirim sistemi başlatılamadı: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );
    }
  }


  // Yerel bildirim sistemini kur
  static Future<void> _yerelBildirimKur() async {
    try {
      const androidAyar =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosAyar =
      DarwinInitializationSettings();

      const ayarlar = InitializationSettings(
        android: androidAyar,
        iOS: iosAyar,
      );


      await _yerelBildirim.initialize(
        ayarlar,

        onDidReceiveNotificationResponse:
            (NotificationResponse response) {

          final payload = response.payload;

          if (payload != null &&
              payload.isNotEmpty) {

            try {
              final data =
              jsonDecode(payload)
              as Map<String, dynamic>;

              _verigoreYonlendir(data);

            } catch (e) {
              debugPrint(
                'Bildirim verisi okunamadı: $e',
              );
            }
          }
        },
      );


      // Android bildirim kanalı
      final androidUygulama =
      _yerelBildirim
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();


      if (androidUygulama != null) {

        const kanal =
        AndroidNotificationChannel(
          _kanalId,
          _kanalAdi,

          description:
          'Yeni sınav sonucu ve önemli duyurular',

          importance: Importance.high,
        );


        await androidUygulama
            .createNotificationChannel(
          kanal,
        );
      }

    } catch (e) {
      debugPrint(
        '❌ Yerel bildirim sistemi hatası: $e',
      );
    }
  }


  // Bildirim izni iste
  static Future<void> _izinIste() async {
    try {

      final settings =
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );


      if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {

        debugPrint(
          '✅ Bildirim izni verildi',
        );
        await _uzaktanLog('İzin verildi: ${settings.authorizationStatus}');

      } else {

        debugPrint(
          'ℹ️ Bildirim izin durumu: '
              '${settings.authorizationStatus}',
        );
        await _uzaktanLog('İzin durumu: ${settings.authorizationStatus}');
      }

    } catch (e) {

      debugPrint(
        '❌ Bildirim izin hatası: $e',
      );
      await _uzaktanLog('İzin hatası: $e');
    }
  }


  // FCM Token al ve kaydet
  static Future<String?> _tokenAlVeKaydet() async {
    try {

      debugPrint(
        '🔄 FCM Token alınıyor...',
      );
      await _uzaktanLog('Token alma başladı');

      // iOS'ta getToken() çağrılmadan önce APNs token'ın sisteme
      // set edilmiş olması gerekiyor. Bu, izin verildikten hemen sonra
      // henüz hazır olmayabiliyor (Apple sunucularıyla el sıkışma
      // birkaç saniye sürebiliyor). Bu yüzden hazır olana kadar
      // kısa aralıklarla deniyoruz (en fazla ~15 saniye).
      if (Platform.isIOS) {
        String? apnsToken;
        for (int deneme = 0; deneme < 15; deneme++) {
          try {
            apnsToken = await _messaging.getAPNSToken();
          } catch (e) {
            await _uzaktanLog('APNs token deneme $deneme hatası: $e');
          }

          if (apnsToken != null) {
            await _uzaktanLog('APNs token $deneme. denemede geldi: $apnsToken');
            break;
          }

          await Future.delayed(const Duration(seconds: 1));
        }

        if (apnsToken == null) {
          await _uzaktanLog('APNs token 15 saniye sonunda hâlâ NULL, vazgeçiliyor');
          return null;
        }
      }


      final token =
      await _messaging
          .getToken()
          .timeout(
        const Duration(seconds: 15),
      );

      await _uzaktanLog('getToken() sonucu: ${token ?? "NULL"}');


      if (token != null) {

        debugPrint(
          '✅ FCM Token alındı',
        );


        final prefs =
        await SharedPreferences.getInstance();


        await prefs.setString(
          'fcm_token',
          token,
        );


        // Kullanıcı oturumu varsa tokenı sunucuya bağla
        final oturum =
        await SessionService.oturumOku();


        if (oturum != null) {

          await kullaniciyaBagla(
            oturum['tcno']!,
            oturum['tip']!,
          );
        }


        return token;
      }

    } catch (e) {

      debugPrint(
        '❌ Token alınamadı: $e',
      );
      await _uzaktanLog('Token alma hatası (catch): $e');
    }


    return null;
  }


  // Kaydedilmiş tokenı getir
  static Future<String?> tokenGetir() async {

    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(
      'fcm_token',
    );
  }


  // Bildirim dinleyicilerini kur
  static void _dinleyicileriKur() {

    // Uygulama açıkken gelen bildirim
    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) {

        debugPrint(
          '📨 Ön plan bildirimi: '
              '${message.notification?.title}',
        );


        _yerelBildirimGoster(
          message,
        );
      },
    );


    // Arka plandayken bildirime tıklanırsa
    FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) {

        debugPrint(
          '🔔 Bildirime tıklandı: '
              '${message.data}',
        );


        _verigoreYonlendir(
          message.data,
        );
      },
    );


    // Token yenilenirse
    _messaging.onTokenRefresh.listen(
          (newToken) async {

        try {

          debugPrint(
            '🔄 FCM Token yenilendi',
          );


          final prefs =
          await SharedPreferences.getInstance();


          await prefs.setString(
            'fcm_token',
            newToken,
          );


          final oturum =
          await SessionService.oturumOku();


          if (oturum != null) {

            await kullaniciyaBagla(
              oturum['tcno']!,
              oturum['tip']!,
            );
          }

        } catch (e) {

          debugPrint(
            'Token yenileme hatası: $e',
          );
        }
      },
    );
  }


  // Uygulama açıkken bildirim göster
  static Future<void>
  _yerelBildirimGoster(
      RemoteMessage message,
      ) async {

    try {

      final baslik =
          message.notification?.title ??
              'SMK Sonuç';


      final govde =
          message.notification?.body ?? '';


      const androidDetay =
      AndroidNotificationDetails(
        _kanalId,
        _kanalAdi,

        importance: Importance.high,
        priority: Priority.high,
      );


      const detaylar =
      NotificationDetails(
        android: androidDetay,
        iOS: DarwinNotificationDetails(),
      );


      await _yerelBildirim.show(
        DateTime.now()
            .millisecondsSinceEpoch ~/
            1000,

        baslik,
        govde,
        detaylar,

        payload: jsonEncode(
          message.data,
        ),
      );

    } catch (e) {

      debugPrint(
        'Bildirim gösterilemedi: $e',
      );
    }
  }


  // Bildirim verisine göre yönlendirme
  static void _verigoreYonlendir(
      Map<String, dynamic> data,
      ) {

    navigatorKey.currentState
        ?.pushAndRemoveUntil(

      MaterialPageRoute(
        builder: (_) =>
        const SplashScreen(),
      ),

          (route) => false,
    );
  }


  // Tokenı kullanıcıya bağla
  static Future<void>
  kullaniciyaBagla(
      String tcno,
      String tip,
      ) async {

    final token =
    await tokenGetir();

    await _uzaktanLog('kullaniciyaBagla çağrıldı, kayıtlı token: ${token ?? "YOK"}');

    if (token == null) return;


    try {

      final sonuc =
      await ApiService.tokenKaydet(
        tcno: tcno,
        tip: tip,
        token: token,
      );


      if (sonuc['basari'] == true) {

        debugPrint(
          '✅ Token kullanıcıya bağlandı: $tcno',
        );

      } else {

        debugPrint(
          '❌ Token bağlanamadı: '
              '${sonuc['mesaj']}',
        );
      }

    } catch (e) {

      debugPrint(
        '❌ Token bağlanamadı: $e',
      );
    }
  }
}
