import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

class CocukKulubuKayitIslem extends StatefulWidget {
  const CocukKulubuKayitIslem({super.key});
  @override
  State<CocukKulubuKayitIslem> createState() => _CocukKulubuKayitIslemState();
}

class _CocukKulubuKayitIslemState extends State<CocukKulubuKayitIslem> {
  final _tc1Ctrl = TextEditingController();
  final _tc2Ctrl = TextEditingController();
  final _odenenCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();

  int _ogrenciSayisi = 1;
  bool _sorguYukleniyor = false;
  String _hata = '';
  String? _mod; // 'yeni_kayit' | 'ek_odeme'
  Map<String, dynamic>? _ogrenci1;
  Map<String, dynamic>? _ogrenci2;
  Map<String, dynamic>? _mevcutKayit;

  File? _dekont;
  bool _sozlesme1 = false;
  bool _sozlesme2 = false;
  bool _bilgiOnay = false;
  bool _kaydediliyor = false;

  Future<void> _sorgula() async {
    if (_tc1Ctrl.text.length != 11) {
      setState(() => _hata = '11 haneli TC kimlik numarası giriniz');
      return;
    }
    if (_ogrenciSayisi == 2 && _tc2Ctrl.text.length != 11) {
      setState(() => _hata = 'İkinci öğrenci için 11 haneli TC giriniz');
      return;
    }
    setState(() {
      _sorguYukleniyor = true; _hata = ''; _mod = null;
      _ogrenci1 = null; _ogrenci2 = null; _mevcutKayit = null;
    });
    final r = await ApiService.cocukKulubuTcSorgula(
      tcno1: _tc1Ctrl.text.trim(),
      ogrenciSayisi: _ogrenciSayisi,
      tcno2: _ogrenciSayisi == 2 ? _tc2Ctrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() {
      _sorguYukleniyor = false;
      if (r['basari'] == true) {
        _mod = r['mod'];
        if (_mod == 'ek_odeme') {
          _mevcutKayit = r['kayit'];
        } else {
          _ogrenci1 = r['ogrenci1'];
          _ogrenci2 = r['ogrenci2'];
        }
      } else {
        _hata = r['mesaj'] ?? 'Sorgu başarısız';
      }
    });
  }

  Future<void> _dekontSec() async {
    final sonuc = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (sonuc != null && sonuc.files.single.path != null) {
      setState(() => _dekont = File(sonuc.files.single.path!));
    }
  }

  Future<void> _yeniKayitGonder() async {
    if (_dekont == null) { _uyariGoster('Lütfen dekont/makbuz yükleyiniz'); return; }
    if (!_bilgiOnay) { _uyariGoster('Bilgilerin doğruluğunu onaylayınız'); return; }
    if (!_sozlesme1 || !_sozlesme2) { _uyariGoster('Sözleşmeleri okuyup kabul etmelisiniz'); return; }
    if (_odenenCtrl.text.trim().isEmpty) { _uyariGoster('Ödediğiniz tutarı giriniz'); return; }

    setState(() => _kaydediliyor = true);
    final alanlar = <String, String>{
      'ogrenci_sayisi': _ogrenciSayisi.toString(),
      'tcno1': _tc1Ctrl.text.trim(),
      'adisoyadi1': _ogrenci1!['adisoyadi'] ?? '',
      'sinifi1': _ogrenci1!['sinifi'] ?? '',
      'numarasi1': _ogrenci1!['numarasi'] ?? '',
      'odenen_tutar': _odenenCtrl.text.trim(),
      'aciklama': _aciklamaCtrl.text.trim(),
    };
    if (_ogrenciSayisi == 2 && _ogrenci2 != null) {
      alanlar['tcno2'] = _tc2Ctrl.text.trim();
      alanlar['adisoyadi2'] = _ogrenci2!['adisoyadi'] ?? '';
      alanlar['sinifi2'] = _ogrenci2!['sinifi'] ?? '';
      alanlar['numarasi2'] = _ogrenci2!['numarasi'] ?? '';
    }

    final r = await ApiService.cocukKulubuKayitKaydet(alanlar: alanlar, dekont: _dekont!);
    if (!mounted) return;
    setState(() => _kaydediliyor = false);

    if (r['basari'] == true) {
      _basariGoster(r['mesaj'] ?? 'Kaydınız alındı');
    } else {
      _uyariGoster(r['mesaj'] ?? 'İşlem başarısız');
    }
  }

  Future<void> _ekOdemeGonder() async {
    if (_dekont == null) { _uyariGoster('Lütfen dekont/makbuz yükleyiniz'); return; }
    final tutar = double.tryParse(_odenenCtrl.text.trim());
    if (tutar == null || tutar <= 0) { _uyariGoster('Geçerli bir tutar giriniz'); return; }

    setState(() => _kaydediliyor = true);
    final r = await ApiService.cocukKulubuEkOdemeKaydetVeli(
      kayitId: int.parse(_mevcutKayit!['id'].toString()),
      ekTutar: tutar,
      aciklama: _aciklamaCtrl.text.trim(),
      dekont: _dekont!,
    );
    if (!mounted) return;
    setState(() => _kaydediliyor = false);

    if (r['basari'] == true) {
      _basariGoster(r['mesaj'] ?? 'Ek ödemeniz kaydedildi');
    } else {
      _uyariGoster(r['mesaj'] ?? 'İşlem başarısız');
    }
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: AppColors.red));
  }

  void _basariGoster(String mesaj) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('✅', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            const Text('Başarılı!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.dark)),
            const SizedBox(height: 8),
            Text(mesaj, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                child: const Text('Tamam'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _sozlesmeGoster(String baslik, String icerik, VoidCallback onKabul) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(child: Text(icerik, style: const TextStyle(fontSize: 12.5, height: 1.6, color: AppColors.dark))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { onKabul(); Navigator.pop(ctx); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                child: const Text('Okudum, Anladım, Kabul Ediyorum'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sorgulamaFormu(),
                  if (_hata.isNotEmpty) Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_hata, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
                  ),
                  if (_mod == 'ek_odeme' && _mevcutKayit != null) _ekOdemeBolumu(),
                  if (_mod == 'yeni_kayit' && _ogrenci1 != null) _yeniKayitBolumu(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.teal, AppColors.purple, AppColors.purpleD]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.2))),
              child: const Text('← Geri', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('📝 Kayıt / Ödeme', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('TC kimlik no ile öğrenci sorgulayın', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sorgulamaFormu() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kaç öğrenci kaydedeceksiniz?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray)),
          Row(children: [
            Expanded(child: RadioListTile<int>(
              value: 1, groupValue: _ogrenciSayisi, dense: true, contentPadding: EdgeInsets.zero,
              title: const Text('Tek Öğrenci (8.800 TL)', style: TextStyle(fontSize: 12)),
              onChanged: (v) => setState(() { _ogrenciSayisi = v!; _mod = null; }),
            )),
          ]),
          Row(children: [
            Expanded(child: RadioListTile<int>(
              value: 2, groupValue: _ogrenciSayisi, dense: true, contentPadding: EdgeInsets.zero,
              title: const Text('İki Kardeş (13.200 TL)', style: TextStyle(fontSize: 12)),
              onChanged: (v) => setState(() { _ogrenciSayisi = v!; _mod = null; }),
            )),
          ]),
          const SizedBox(height: 8),
          TextField(controller: _tc1Ctrl, keyboardType: TextInputType.number, maxLength: 11,
              decoration: const InputDecoration(labelText: 'Birinci Öğrenci TC No', counterText: '', border: OutlineInputBorder())),
          if (_ogrenciSayisi == 2) ...[
            const SizedBox(height: 10),
            TextField(controller: _tc2Ctrl, keyboardType: TextInputType.number, maxLength: 11,
                decoration: const InputDecoration(labelText: 'İkinci Öğrenci (Kardeş) TC No', counterText: '', border: OutlineInputBorder())),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sorguYukleniyor ? null : _sorgula,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _sorguYukleniyor
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('🔍 Sorgula'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ekOdemeBolumu() {
    final ucret = double.tryParse(_mevcutKayit!['ucret'].toString()) ?? 0;
    final odenen = double.tryParse((_mevcutKayit!['odenen_tutar'] ?? 0).toString()) ?? 0;
    final kalan = ucret - odenen;
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.06), borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_mevcutKayit!['adisoyadi']} — mevcut kaydınız bulundu', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 6),
              Text('Beklenen: ${ucret.toStringAsFixed(0)} TL   •   Ödenen: ${odenen.toStringAsFixed(0)} TL   •   Kalan: ${kalan.toStringAsFixed(0)} TL',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray)),
            ],
          ),
        ),
        if (kalan > 0) ...[
          const SizedBox(height: 16),
          _dekontKutusu(),
          const SizedBox(height: 12),
          TextField(controller: _odenenCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ek Ödediğiniz Tutar (TL)', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _aciklamaCtrl, maxLines: 2,
              decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _kaydediliyor ? null : _ekOdemeGonder,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _kaydediliyor
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Ek Ödemeyi Kaydet'),
            ),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('🎉 Ödemeniz tamamlanmış durumda!', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _yeniKayitBolumu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _ogrenciKart(_ogrenci1!, '8.800 TL'),
        if (_ogrenci2 != null) ...[
          const SizedBox(height: 10),
          _ogrenciKart(_ogrenci2!, '4.400 TL (%50 İndirimli)'),
        ],
        const SizedBox(height: 16),
        _dekontKutusu(),
        const SizedBox(height: 12),
        TextField(controller: _odenenCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Ödediğiniz Toplam Tutar (TL)', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _aciklamaCtrl, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _bilgiOnay, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Bilgilerin doğru olduğunu onaylıyorum', style: TextStyle(fontSize: 12)),
          onChanged: (v) => setState(() => _bilgiOnay = v ?? false),
        ),
        CheckboxListTile(
          value: _sozlesme1, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
          title: GestureDetector(
            onTap: () => _sozlesmeGoster('Katılım Sözleşmesi', _katilimSozlesmesi, () => setState(() => _sozlesme1 = true)),
            child: const Text('Çocuk Kulübü Katılım Sözleşmesini okudum, kabul ediyorum', style: TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
          ),
          onChanged: (v) => _sozlesmeGoster('Katılım Sözleşmesi', _katilimSozlesmesi, () => setState(() => _sozlesme1 = true)),
        ),
        CheckboxListTile(
          value: _sozlesme2, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
          title: GestureDetector(
            onTap: () => _sozlesmeGoster('Yönetmelik', _yonetmelik, () => setState(() => _sozlesme2 = true)),
            child: const Text('Çocuk Kulübü Yönetmeliğini okudum, kabul ediyorum', style: TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
          ),
          onChanged: (v) => _sozlesmeGoster('Yönetmelik', _yonetmelik, () => setState(() => _sozlesme2 = true)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _kaydediliyor ? null : _yeniKayitGonder,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _kaydediliyor
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('✅ Kaydı Tamamla'),
          ),
        ),
      ],
    );
  }

  Widget _ogrenciKart(Map<String, dynamic> o, String ucret) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.teal.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(o['adisoyadi'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Text('Sınıf: ${o['sinifi']}  •  No: ${o['numarasi']}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          const SizedBox(height: 6),
          Text(ucret, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal)),
        ],
      ),
    );
  }

  Widget _dekontKutusu() {
    return GestureDetector(
      onTap: _dekontSec,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _dekont != null ? AppColors.teal.withOpacity(0.08) : AppColors.lightGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _dekont != null ? AppColors.teal : AppColors.gray.withOpacity(0.3), style: BorderStyle.solid),
        ),
        child: Row(children: [
          Icon(_dekont != null ? Icons.check_circle : Icons.upload_file, color: _dekont != null ? AppColors.teal : AppColors.gray),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _dekont != null ? 'Dekont seçildi: ${_dekont!.path.split('/').last}' : '📎 Dekont / Makbuz Yükle (JPG, PNG, PDF)',
              style: TextStyle(fontSize: 12, color: _dekont != null ? AppColors.teal : AppColors.gray, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }

  static const _katilimSozlesmesi = '''
ÇOCUK KULÜBÜ KATILIM SÖZLEŞMESİ

Madde 1 - Taraflar: İşbu sözleşme Harbiye Semihe Mehmet Karaali Ortaokulu ile veli arasında akdedilmiştir.
Madde 2 - Konu: Öğrencinin Çocuk Kulübü faaliyetlerine katılımına ilişkin hak ve yükümlülükler.
Madde 3 - Ödeme: Katılım ücreti tek öğrenci için 8.800 TL, iki kardeş için toplam 13.200 TL'dir. İkinci kardeşe %50 indirim uygulanır.
Madde 4 - Katılım: Öğrenci, faaliyetlere düzenli katılmayı taahhüt eder.
Madde 5 - Sorumluluklar: Okul öğrencinin güvenliğini sağlar; veli zamanında teslim/alım yapar.
Madde 6 - Fesih: Ödenen ücretler iade edilmez. Mazeretsiz 20 gün devam etmeyen ya da aylık ücretini yatırmayan öğrencinin kulüple ilişiği kesilir.
Madde 7 - Uyuşmazlık: Belirtilmeyen hususlarda yönerge hükümleri uygulanır.
''';

  static const _yonetmelik = '''
ÇOCUK KULÜBÜ YÖNETMELİĞİ

Madde 1 - Amaç: Çocuk Kulübü işleyişine ilişkin usul ve esaslar.
Madde 2 - Faaliyet Saatleri: Hafta içi her gün 15:10-17:00.
Madde 3 - Devam: Düzenli katılım zorunludur, devamsızlık okula bildirilmelidir.
Madde 4 - Davranış: Okul kurallarına uyulması, saygılı davranılması esastır.
Madde 5 - Güvenlik: Veli belirtilen saatlerde teslim almakla yükümlüdür.
Madde 6 - Sağlık: Kronik rahatsızlıklar yazılı olarak bildirilmelidir.
Madde 7 - Yürürlük: Bu yönetmelik ilgili eğitim-öğretim yılı başından itibaren yürürlüktedir.
''';
}