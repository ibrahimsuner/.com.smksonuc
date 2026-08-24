import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'ogrenci/ogrenci_ana_sayfa.dart';
import 'ogretmen/ogretmen_ana_sayfa.dart';
import 'ogretmen/ogretmen_ilk_sifre_belirle.dart';
import 'sifremi_unuttum.dart';
import '../services/bildirim_service.dart';
import 'cocuk_kulubu/cocuk_kulubu_ana_sayfa.dart';
import 'admin/admin_giris_screen.dart';
import 'cocuk_kulubu_kayit/cocuk_kulubu_kayit_ana_sayfa.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String? _seciliTip; // 'ogrenci', 'ogretmen' veya 'cocukkulubu'
  final _tcController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _yukleniyor = false;
  String _hata = '';
  bool _sifreGizli = true;

  @override
  void dispose() {
    _tcController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    setState(() { _yukleniyor = true; _hata = ''; });

    Map<String, dynamic> sonuc;

    if (_seciliTip == 'ogrenci') {
      if (_tcController.text.length != 11) {
        setState(() { _hata = 'TC kimlik numarası 11 haneli olmalıdır'; _yukleniyor = false; });
        return;
      }
      sonuc = await ApiService.ogrenciGiris(_tcController.text.trim());
    } else {
      if (_tcController.text.isEmpty || _sifreController.text.isEmpty) {
        setState(() { _hata = 'TC no ve şifre boş olamaz'; _yukleniyor = false; });
        return;
      }
      sonuc = await ApiService.ogretmenGiris(
        _tcController.text.trim(),
        _sifreController.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() => _yukleniyor = false);

    if (sonuc['basari'] == true) {
      if (_seciliTip == 'ogrenci') {
        final ogr = sonuc['ogrenci'];
        await SessionService.oturumKaydet(
          tip: 'ogrenci',
          tcno: ogr.tcno,
          adisoyadi: ogr.adisoyadi,
          sube: ogr.sinifi,
          no: ogr.numarasi,
        );
        await BildirimService.kullaniciyaBagla(ogr.tcno, 'ogrenci');
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => OgrenciAnaSayfa(oturum: {
            'tip': 'ogrenci',
            'tcno': ogr.tcno,
            'adisoyadi': ogr.adisoyadi,
            'sube': ogr.sinifi,
            'no': ogr.numarasi,
          }),
        ));
      } else {
        // 'ogretmen' ve 'cocukkulubu' aynı öğretmen hesabıyla (aynı API
        // ile) giriş yapıyor; sadece giriş sonrası gidilen ekran farklı.
        final ogr = sonuc['ogretmen'];
        final sifreDegisti = sonuc['sifreDegisti'] == true;
        final girisTuru = _seciliTip!; // 'ogretmen' ya da 'cocukkulubu'

        await SessionService.oturumKaydet(
          tip: girisTuru,
          tcno: ogr.tcno,
          adisoyadi: ogr.adisoyadi,
          brans: ogr.brans,
        );
        // Bildirim/FCM tarafı hesabın gerçek türünü ('ogretmen') bilmeli,
        // yoksa öğretmen duyuruları bu kullanıcıya gitmez.
        await BildirimService.kullaniciyaBagla(ogr.tcno, 'ogretmen');
        if (!mounted) return;
        final oturumMap = <String, String>{
          'tip': girisTuru,
          'tcno': ogr.tcno,
          'adisoyadi': ogr.adisoyadi,
          'brans': ogr.brans,
        };

        if (!sifreDegisti) {
          // Admin şifresiyle ilk giriş — zorunlu şifre/güvenlik sorusu belirleme
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => OgretmenIlkSifreBelirle(
              tcno: ogr.tcno,
              eskiSifre: _sifreController.text.trim(),
              oturum: oturumMap,
              hedef: girisTuru,
            ),
          ));
        } else if (girisTuru == 'cocukkulubu') {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => CocukKulubuAnaSayfa(oturum: oturumMap),
          ));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => OgretmenAnaSayfa(oturum: oturumMap),
          ));
        }
      }
    } else {
      setState(() => _hata = sonuc['mesaj'] ?? 'Giriş başarısız');
    }
  }

  void _bilgiGoster(String baslik, String icerik) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0F7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(baslik, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1E2E))),
              const SizedBox(height: 12),
              Text(icerik, style: const TextStyle(fontSize: 13, color: Color(0xFF8892A4), height: 1.6)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEF0F7),
                    foregroundColor: const Color(0xFF8892A4),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 56),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.png', width: 64, height: 64, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Harbiye', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, letterSpacing: 3)),
                  const SizedBox(height: 4),
                  const Text('Semihe Mehmet Karaali', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  const Text('Ortaokulu', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [AppColors.red, AppColors.orange, AppColors.yellow, AppColors.green, AppColors.magenta, AppColors.purple]
                        .map((c) => Container(width: 20, height: 4, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))))
                        .toList(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  // ── Giriş Türü Kartı ──
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Veli / Öğrenci bölümü ──
                          // (İleride buraya ikinci bir "Öğrenci Çocuk
                          // Kulübü" girişi eklenecek — bu yüzden tek
                          // eleman olsa da Row olarak bırakıldı.)
                          const Text('VELİ / ÖĞRENCİ GİRİŞİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
                          const SizedBox(height: 10),
                           Row(
                            children: [
                              _rolButonu('ogrenci', '🎒', 'Öğrenci / Veli', AppColors.purple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CocukKulubuKayitAnaSayfa()),
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: AppColors.teal, width: 2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 42, height: 42,
                                          decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(12)),
                                          child: const Center(child: Text('🧸', style: TextStyle(fontSize: 20))),
                                        ),
                                        const SizedBox(height: 7),
                                        const Text('Çocuk Kulübü\nKayıt', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          const Divider(color: AppColors.lightGray, height: 1),
                          const SizedBox(height: 18),

                          // ── Öğretmen bölümü ──
                          const Text('ÖĞRETMEN GİRİŞİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _rolButonu('ogretmen', '👨‍🏫', 'Öğretmen', AppColors.orange),
                              const SizedBox(width: 8),
                              _rolButonu('cocukkulubu', '🧩', 'Çocuk\nKulübü', AppColors.teal),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Giriş Formu ──
                  if (_seciliTip != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TC No alanı
                          const Text('TC KİMLİK NUMARASI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _tcController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                            style: const TextStyle(fontSize: 18, letterSpacing: 4, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              hintText: '00000000000',
                              hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 4),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.lightGray)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.purple, width: 2)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightGray)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_seciliTip == 'ogrenci') ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('${_tcController.text.length}/11 hane', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                                const Spacer(),
                                Row(
                                  children: List.generate(11, (i) => Container(
                                    width: 6, height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i < _tcController.text.length ? AppColors.purple : AppColors.lightGray,
                                    ),
                                  )),
                                ),
                              ],
                            ),
                          ],

                          // Şifre alanı (öğretmen ve çocuk kulübü için)
                          if (_seciliTip == 'ogretmen' || _seciliTip == 'cocukkulubu') ...[
                            const SizedBox(height: 14),
                            const Text('ŞİFRE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _sifreController,
                              obscureText: _sifreGizli,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.orange, width: 2)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightGray)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                suffixIcon: IconButton(
                                  icon: Icon(_sifreGizli ? Icons.visibility_off : Icons.visibility, color: AppColors.gray),
                                  onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SifremiUnuttum()),
                                ),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: const Text('Şifremi Unuttum?', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ),
                          ],

                          // Hata mesajı
                          if (_hata.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_hata, style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w600))),
                                ],
                              ),
                            ),
                          ],

                          // Giriş butonu
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _yukleniyor ? null : _girisYap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _girisButonRengi(),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 8,
                                shadowColor: _girisButonRengi().withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _yukleniyor
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text('Giriş Yap →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Hakkımızda / İletişim ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _bilgiGoster('🏫 Hakkımızda',
                            'Harbiye Semihe Mehmet Karaali Ortaokulu, 2014 yılından bu yana eğitim öğretim faaliyetlerini sürdürmektedir. Öğrencilerimizin akademik gelişimini düzenli deneme sınavlarıyla takip ediyor, veli ve öğretmenlerimizle şeffaf bir iletişim kuruyoruz.'),
                        child: const Text('🏫 Hakkımızda', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                      const Text('•', style: TextStyle(color: AppColors.gray)),
                      TextButton(
                        onPressed: () => _bilgiGoster('📞 İletişim',
                            'Adres: Harbiye Mah. Okul Sk. No:1\n\nTelefon: 0212 XXX XX XX\n\nE-posta: info@smksonuc.com\n\nWeb: www.smksonuc.com'),
                        child: const Text('📞 İletişim', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                  const Text('© 2024 Harbiye SMK Ortaokulu', style: TextStyle(color: AppColors.gray, fontSize: 11)),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGirisScreen())),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Yönetici Girişi', style: TextStyle(color: AppColors.gray, fontSize: 11, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _girisButonRengi() {
    switch (_seciliTip) {
      case 'ogretmen':
        return AppColors.orange;
      case 'cocukkulubu':
        return AppColors.teal;
      default:
        return AppColors.purple;
    }
  }

  Widget _rolButonu(String tip, String emoji, String label, Color renk) {
    final secili = _seciliTip == tip;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _seciliTip = tip; _hata = ''; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: secili ? renk.withOpacity(0.1) : Colors.white,
            border: Border.all(color: secili ? renk : AppColors.lightGray, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: secili ? [BoxShadow(color: renk.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: secili ? renk : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(height: 7),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secili ? renk : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}