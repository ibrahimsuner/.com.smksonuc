class ApiConstants {
  static const String baseUrl = 'https://smksonuc.com/api';

  static const String ogrenciGiris    = '$baseUrl/ogrenci_giris.php';
  static const String ogrenciSinavlar = '$baseUrl/ogrenci_sinavlar.php';
  static const String ogretmenGiris   = '$baseUrl/ogretmen_giris.php';
  static const String sinifListesi    = '$baseUrl/sinif_listesi.php';
  static const String ogrenciAra      = '$baseUrl/ogrenci_ara.php';
  static const String sinifOrtalama   = '$baseUrl/sinif_ortalama.php';
  static const String sinifDetay          = '$baseUrl/sinif_detay.php';
  static const String sinifOrtalamalarOzet = '$baseUrl/sinif_ortalamalar_ozet.php';
  static const String sinavSonucListesi = '$baseUrl/sinav_sonuc_listesi.php';
  static const String sinavAdlari       = '$baseUrl/sinav_adlari.php';
  static const String yapayZekaRaporu   = '$baseUrl/yapayzeka_json.php';

  // ── Şifre işlemleri ──
  static const String ogretmenSifreBelirle      = '$baseUrl/ogretmen_sifre_belirle.php';
  static const String ogretmenGuvenlikSoruGetir = '$baseUrl/ogretmen_guvenlik_soru_getir.php';
  static const String ogretmenSifreSifirla      = '$baseUrl/ogretmen_sifre_sifirla.php';
  // ── Bildirim (FCM) ──
  static const String tokenKaydet = '$baseUrl/token_kaydet.php';
  // ── Çocuk Kulübü ──
  static const String cocukKulubuSubeler          = '$baseUrl/cocuk_kulubu_subeler.php';
  static const String cocukKulubuSubeOgrencileri   = '$baseUrl/cocuk_kulubu_sube_ogrencileri.php';
  static const String cocukKulubuYoklamaKaydet     = '$baseUrl/cocuk_kulubu_yoklama_kaydet.php';
  static const String cocukKulubuYeniKayitlar      = '$baseUrl/cocuk_kulubu_yeni_kayitlar.php';
  // ── Kazanım Değerlendirme ──
  static const String kazanimSinavlari   = '$baseUrl/kazanim_sinavlari.php';
  static const String kazanimEksikGetir  = '$baseUrl/kazanim_eksik_getir.php';
// ── Çocuk Kulübü Kayıt (Veli tarafı) ──
  static const String cocukKulubuTcSorgula = '$baseUrl/cocuk_kulubu_tc_sorgula.php';
  static const String cocukKulubuKayitKaydet = '$baseUrl/cocuk_kulubu_kayit_kaydet.php';
  static const String cocukKulubuEkOdemeKaydetVeli = '$baseUrl/cocuk_kulubu_ek_odeme_kaydet_veli.php';
  static const String cocukKulubuDurumSorgula = '$baseUrl/cocuk_kulubu_durum_sorgula.php';
  // ── Admin Paneli ──
  static const String adminGiris             = '$baseUrl/admin_giris.php';
  static const String adminOgrenciListe      = '$baseUrl/admin_ogrenci_liste.php';
  static const String adminOgrenciEkle       = '$baseUrl/admin_ogrenci_ekle.php';
  static const String adminOgrenciGuncelle   = '$baseUrl/admin_ogrenci_guncelle.php';
  static const String adminOgrenciSil        = '$baseUrl/admin_ogrenci_sil.php';
  static const String adminBildirimMeta      = '$baseUrl/admin_bildirim_meta.php';
  static const String adminBildirimSinavGonder    = '$baseUrl/admin_bildirim_sinav_gonder.php';
  static const String adminBildirimOgretmenGonder = '$baseUrl/admin_bildirim_ogretmen_gonder.php';
  static const String adminDevamsizlikListe  = '$baseUrl/admin_devamsizlik_liste.php';
  static const String adminDevamsizlikGonder = '$baseUrl/admin_devamsizlik_gonder.php';
}
