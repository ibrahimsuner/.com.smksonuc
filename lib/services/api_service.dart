import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/ogrenci_model.dart';
import '../models/sinav_model.dart';
import '../models/ogretmen_model.dart';
import '../models/sinif_ortalama_model.dart';
import 'dart:io';
class ApiService {

  // BOM karakterini temizle
  static String _temizle(String raw) {
    return raw.trimLeft().replaceAll('\uFEFF', '');
  }

  // ── Öğrenci/Veli Girişi ──
  static Future<Map<String, dynamic>> ogrenciGiris(String tcno) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ogrenciGiris),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tcno': tcno}),
      ).timeout(const Duration(seconds: 15));

      final veri = jsonDecode(_temizle(response.body));
      if (veri['basari'] == true) {
        return {
          'basari': true,
          'ogrenci': OgrenciModel.fromJson(veri),
        };
      }
      return {'basari': false, 'mesaj': veri['mesaj'] ?? 'Giriş başarısız'};
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Öğrenci Sınavlarını Getir ──
  static Future<Map<String, dynamic>> ogrenciSinavlar(String tcno) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ogrenciSinavlar),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tcno': tcno}),
      ).timeout(const Duration(seconds: 15));

      final veri = jsonDecode(_temizle(response.body));
      if (veri['basari'] == true) {
        final sinavlar = (veri['sinavlar'] as List)
            .map((s) => SinavModel.fromJson(s))
            .toList();
        return {'basari': true, 'sinavlar': sinavlar};
      }
      return {'basari': false, 'mesaj': veri['mesaj'] ?? 'Veri alınamadı'};
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Sınıf Ortalamalarını Getir ──
  static Future<Map<String, dynamic>> sinifOrtalamalari(String tcno) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sinifOrtalama),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tcno': tcno}),
      ).timeout(const Duration(seconds: 15));

      final veri = jsonDecode(_temizle(response.body));
      if (veri['basari'] == true) {
        final ortalamalar = (veri['ortalamalar'] as List)
            .map((o) => SinifOrtalamaModel.fromJson(o))
            .toList();
        return {'basari': true, 'ortalamalar': ortalamalar};
      }
      return {'basari': false, 'mesaj': veri['mesaj'] ?? 'Veri alınamadı'};
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Sınıf Detayı (Öğretmen) ──
  static Future<Map<String, dynamic>> sinifDetay(String sinif) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sinifDetay),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sinif': sinif}),
      ).timeout(const Duration(seconds: 20));

      final veri = jsonDecode(_temizle(response.body));
      return veri;
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Sınıf Ortalamaları Özeti (Öğretmen ana sayfa) ──
  static Future<Map<String, dynamic>> sinifOrtalamalariOzet() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sinifOrtalamalarOzet),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));

      final veri = jsonDecode(_temizle(response.body));
      return veri;
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Öğretmen Girişi ──
  static Future<Map<String, dynamic>> ogretmenGiris(
      String tcno, String sifre) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ogretmenGiris),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tcno': tcno, 'sifre': sifre}),
      ).timeout(const Duration(seconds: 15));

      final veri = jsonDecode(_temizle(response.body));
      if (veri['basari'] == true) {
        return {
          'basari': true,
          'ogretmen': OgretmenModel.fromJson(veri),
          'sifreDegisti': veri['sifreDegisti'] ?? false,
        };
      }
      return {'basari': false, 'mesaj': veri['mesaj'] ?? 'Giriş başarısız'};
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Öğretmen Şifre Belirle / Değiştir ──
  // (İlk girişte zorunlu belirleme veya profilden gönüllü değişim için)
  static Future<Map<String, dynamic>> ogretmenSifreBelirle({
    required String tcno,
    required String eskiSifre,
    required String yeniSifre,
    String? guvenlikSorusu,
    String? guvenlikCevap,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ogretmenSifreBelirle),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tcno': tcno,
          'eskiSifre': eskiSifre,
          'yeniSifre': yeniSifre,
          if (guvenlikSorusu != null) 'guvenlikSorusu': guvenlikSorusu,
          if (guvenlikCevap != null) 'guvenlikCevap': guvenlikCevap,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Şifremi Unuttum — Adım 1: Güvenlik sorusunu getir ──
  static Future<Map<String, dynamic>> ogretmenGuvenlikSoruGetir(String tcno) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ogretmenGuvenlikSoruGetir),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tcno': tcno}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Şifremi Unuttum — Adım 2: Cevabı doğrula ve şifreyi sıfırla ──
  static Future<Map<String, dynamic>> ogretmenSifreSifirla({
    required String tcno,
    required String guvenlikCevap,
    required String yeniSifre,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ogretmenSifreSifirla),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tcno': tcno,
          'guvenlikCevap': guvenlikCevap,
          'yeniSifre': yeniSifre,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Sınıf Listesi (Öğretmen) ──
  static Future<Map<String, dynamic>> sinifListesi({String sinif = ''}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sinifListesi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sinif': sinif}),
      ).timeout(const Duration(seconds: 20));

      final veri = jsonDecode(_temizle(response.body));
      if (veri['basari'] == true) {
        return {
          'basari': true,
          'ogrenciler': veri['ogrenciler'],
          'siniflar': veri['siniflar'],
        };
      }
      return {'basari': false, 'mesaj': veri['mesaj'] ?? 'Veri alınamadı'};
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Öğrenci Arama (Öğretmen) ──
  static Future<Map<String, dynamic>> ogrenciAra(String arama) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ogrenciAra),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'arama': arama}),
      ).timeout(const Duration(seconds: 15));

      final veri = jsonDecode(_temizle(response.body));
      if (veri['basari'] == true) {
        return {
          'basari': true,
          'ogrenciler': veri['ogrenciler'],
        };
      }
      return {'basari': false, 'mesaj': veri['mesaj'] ?? 'Sonuç bulunamadı'};
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Sınav Sonuç Listesi (Öğretmen) ──
  static Future<Map<String, dynamic>> sinavSonucListesi(String sinif, {String? sinavadi}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sinavSonucListesi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sinif': sinif,
          if (sinavadi != null && sinavadi.isNotEmpty) 'sinavadi': sinavadi,
        }),
      ).timeout(const Duration(seconds: 20));

      final veri = jsonDecode(_temizle(response.body));
      return veri;
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Öğrenci için Yapay Zeka Akademik Raporu ──
  // Site tarafındaki (yapayzeka.php / PDF) ile AYNI hesaplama motorunu
  // (yapayzeka_hesapla.php) kullanan JSON endpoint'i çağırır; risk
  // seviyesi, trend ve "AI özet" paragrafları site ile birebir aynıdır.
  static Future<Map<String, dynamic>> yapayZekaRaporu(String tcno) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.yapayZekaRaporu),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tcno': tcno}),
      ).timeout(const Duration(seconds: 25));

      final veri = jsonDecode(_temizle(response.body));
      return veri;
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Bir şube/seviye için mevcut sınav adları listesi (en yeni önce) ──
  static Future<Map<String, dynamic>> sinavAdlari(String sinif) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sinavAdlari),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sinif': sinif}),
      ).timeout(const Duration(seconds: 15));

      final veri = jsonDecode(_temizle(response.body));
      return veri;
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }
  // ── FCM Token Kaydet ──
  static Future<Map<String, dynamic>> tokenKaydet({
    required String tcno,
    required String tip,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.tokenKaydet),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tcno': tcno, 'tip': tip, 'token': token}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }
  // ── Çocuk Kulübü: Şube Listesi ──
  static Future<Map<String, dynamic>> cocukKulubuSubeler() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.cocukKulubuSubeler),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Çocuk Kulübü: Şubedeki Öğrenciler ──
  static Future<Map<String, dynamic>> cocukKulubuSubeOgrencileri(String sube, {String? tarih}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.cocukKulubuSubeOgrencileri),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sube': sube,
          if (tarih != null) 'tarih': tarih,
        }),
      );

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Çocuk Kulübü: Yoklama Kaydet ──
  static Future<Map<String, dynamic>> cocukKulubuYoklamaKaydet({
    required String sube,
    required String tarih,
    required String kaydeden,
    required List<int> gelmeyenler,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.cocukKulubuYoklamaKaydet),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sube': sube,
          'tarih': tarih,
          'kaydeden': kaydeden,
          'gelmeyenler': gelmeyenler,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Çocuk Kulübü: Yeni Kayıtlar ──
  static Future<Map<String, dynamic>> cocukKulubuYeniKayitlar({int limit = 20}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.cocukKulubuYeniKayitlar),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'limit': limit}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Kazanım Değerlendirme: Sınav Listesi (seviyeye göre) ──
  static Future<Map<String, dynamic>> kazanimSinavlari(int seviye) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.kazanimSinavlari),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'seviye': seviye}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Kazanım Değerlendirme: Seçilen sınav için şube şube eksik kazanımlar ──
  static Future<Map<String, dynamic>> kazanimEksikGetir({
    required String sinavadi,
    required int seviye,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.kazanimEksikGetir),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sinavadi': sinavadi, 'seviye': seviye}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }
// ── Çocuk Kulübü Kayıt: TC Sorgula ──
  static Future<Map<String, dynamic>> cocukKulubuTcSorgula({
    required String tcno1,
    required int ogrenciSayisi,
    String? tcno2,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.cocukKulubuTcSorgula),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tcno1': tcno1,
          'ogrenci_sayisi': ogrenciSayisi,
          if (tcno2 != null) 'tcno2': tcno2,
        }),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

// ── Çocuk Kulübü Kayıt: Yeni Kayıt Kaydet ──
  static Future<Map<String, dynamic>> cocukKulubuKayitKaydet({
    required Map<String, String> alanlar,
    required File dekont,
  }) async {
    try {
      final istek = http.MultipartRequest('POST', Uri.parse(ApiConstants.cocukKulubuKayitKaydet));
      istek.fields.addAll(alanlar);
      istek.files.add(await http.MultipartFile.fromPath('dekont', dekont.path));
      final akis = await istek.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(akis);
      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

// ── Çocuk Kulübü Kayıt: Ek Ödeme Kaydet ──
  static Future<Map<String, dynamic>> cocukKulubuEkOdemeKaydetVeli({
    required int kayitId,
    required double ekTutar,
    required String aciklama,
    required File dekont,
  }) async {
    try {
      final istek = http.MultipartRequest('POST', Uri.parse(ApiConstants.cocukKulubuEkOdemeKaydetVeli));
      istek.fields['kayit_id'] = kayitId.toString();
      istek.fields['ek_tutar'] = ekTutar.toString();
      istek.fields['aciklama'] = aciklama;
      istek.files.add(await http.MultipartFile.fromPath('dekont', dekont.path));
      final akis = await istek.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(akis);
      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

// ── Çocuk Kulübü Kayıt: Durum Sorgula ──
  static Future<Map<String, dynamic>> cocukKulubuDurumSorgula(String tcSorgu) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.cocukKulubuDurumSorgula),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tc_sorgu': tcSorgu}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }
  // ── Admin: Giriş ──
  static Future<Map<String, dynamic>> adminGiris({
    required String kullaniciAdi,
    required String sifre,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminGiris),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'kullaniciAdi': kullaniciAdi, 'sifre': sifre}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Admin: Öğrenci Listesi / Arama ──
  static Future<Map<String, dynamic>> adminOgrenciListe({String arama = '', String sinif = ''}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminOgrenciListe),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'arama': arama, 'sinif': sinif}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Admin: Öğrenci Ekle ──
  static Future<Map<String, dynamic>> adminOgrenciEkle({
    required String tcno,
    required String adisoyadi,
    required String sinifi,
    required String numarasi,
    String veliTelefon = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminOgrenciEkle),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tcno': tcno, 'adisoyadi': adisoyadi, 'sinifi': sinifi,
          'numarasi': numarasi, 'veliTelefon': veliTelefon,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Admin: Öğrenci Güncelle ──
  static Future<Map<String, dynamic>> adminOgrenciGuncelle({
    required String eskiTcno,
    required String tcno,
    required String adisoyadi,
    required String sinifi,
    required String numarasi,
    String veliTelefon = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminOgrenciGuncelle),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eskiTcno': eskiTcno, 'tcno': tcno, 'adisoyadi': adisoyadi, 'sinifi': sinifi,
          'numarasi': numarasi, 'veliTelefon': veliTelefon,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Admin: Öğrenci Sil ──
  static Future<Map<String, dynamic>> adminOgrenciSil(String tcno) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminOgrenciSil),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tcno': tcno}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Admin: Bildirim ekranları için ortak veri (şubeler, sınavlar, öğretmenler) ──
  static Future<Map<String, dynamic>> adminBildirimMeta() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminBildirimMeta),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Admin: Sınav Sonucu Bildirimi Gönder (öğrenci/veli) ──
  static Future<Map<String, dynamic>> adminBildirimSinavGonder({
    required List<String> siniflar,
    required String sinavadi,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminBildirimSinavGonder),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'siniflar': siniflar, 'sinavadi': sinavadi}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Admin: Öğretmenlere Duyuru Gönder ──
  static Future<Map<String, dynamic>> adminBildirimOgretmenGonder({
    required List<String> ogretmenler,
    required String baslik,
    required String mesaj,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminBildirimOgretmenGonder),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ogretmenler': ogretmenler, 'baslik': baslik, 'mesaj': mesaj}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Admin: Çocuk Kulübü Devamsızlık — Bekleyen Liste ──
  static Future<Map<String, dynamic>> adminDevamsizlikListe() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminDevamsizlikListe),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }

  // ── Admin: Çocuk Kulübü Devamsızlık Bildirimi Gönder ──
  static Future<Map<String, dynamic>> adminDevamsizlikGonder(List<int> yoklamaIdler) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.adminDevamsizlikGonder),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'yoklamaIdler': yoklamaIdler}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(_temizle(response.body));
    } catch (e) {
      return {'basari': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }
}
