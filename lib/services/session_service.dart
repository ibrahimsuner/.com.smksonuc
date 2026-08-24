import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _tipKey       = 'kullanici_tip';
  static const String _tcnoKey      = 'kullanici_tcno';
  static const String _adKey        = 'kullanici_ad';
  static const String _subeKey      = 'kullanici_sube';
  static const String _noKey        = 'kullanici_no';
  static const String _bransKey     = 'kullanici_brans';

  // Oturumu kaydet
  static Future<void> oturumKaydet({
    required String tip,      // 'ogrenci' veya 'ogretmen'
    required String tcno,
    required String adisoyadi,
    String sube   = '',
    String no     = '',
    String brans  = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tipKey,   tip);
    await prefs.setString(_tcnoKey,  tcno);
    await prefs.setString(_adKey,    adisoyadi);
    await prefs.setString(_subeKey,  sube);
    await prefs.setString(_noKey,    no);
    await prefs.setString(_bransKey, brans);
  }

  // Oturumu oku
  static Future<Map<String, String>?> oturumOku() async {
    final prefs = await SharedPreferences.getInstance();
    final tip = prefs.getString(_tipKey);
    if (tip == null) return null;

    return {
      'tip':       tip,
      'tcno':      prefs.getString(_tcnoKey)  ?? '',
      'adisoyadi': prefs.getString(_adKey)    ?? '',
      'sube':      prefs.getString(_subeKey)  ?? '',
      'no':        prefs.getString(_noKey)    ?? '',
      'brans':     prefs.getString(_bransKey) ?? '',
    };
  }

  // Oturumu sil (çıkış)
  static Future<void> oturumSil() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Oturum var mı?
  static Future<bool> oturumVarMi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tipKey) != null;
  }
}