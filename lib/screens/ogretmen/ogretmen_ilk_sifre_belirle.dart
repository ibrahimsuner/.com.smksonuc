import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../ogretmen/ogretmen_ana_sayfa.dart';
import '../cocuk_kulubu/cocuk_kulubu_ana_sayfa.dart';

class OgretmenIlkSifreBelirle extends StatefulWidget {
  final String tcno;
  final String eskiSifre;
  final Map<String, String> oturum;
  // Şifre kaydı başarılı olunca gidilecek ekran: 'ogretmen' ya da 'cocukkulubu'.
  final String hedef;
  const OgretmenIlkSifreBelirle({
    super.key, required this.tcno, required this.eskiSifre, required this.oturum,
    this.hedef = 'ogretmen',
  });

  @override
  State<OgretmenIlkSifreBelirle> createState() => _OgretmenIlkSifreBelirleState();
}

class _OgretmenIlkSifreBelirleState extends State<OgretmenIlkSifreBelirle> {
  final _yeniSifre = TextEditingController();
  final _yeniSifreTekrar = TextEditingController();
  final _soru = TextEditingController();
  final _cevap = TextEditingController();
  bool _yukleniyor = false;
  String _hata = '';

  Future<void> _kaydet() async {
    setState(() { _hata = ''; });

    if (_yeniSifre.text.length < 6) {
      setState(() => _hata = 'Yeni şifre en az 6 karakter olmalı'); return;
    }
    if (_yeniSifre.text != _yeniSifreTekrar.text) {
      setState(() => _hata = 'Şifreler eşleşmiyor'); return;
    }
    if (_soru.text.trim().isEmpty || _cevap.text.trim().isEmpty) {
      setState(() => _hata = 'Güvenlik sorusu ve cevabı zorunludur'); return;
    }

    setState(() => _yukleniyor = true);
    final r = await ApiService.ogretmenSifreBelirle(
      tcno: widget.tcno,
      eskiSifre: widget.eskiSifre,
      yeniSifre: _yeniSifre.text.trim(),
      guvenlikSorusu: _soru.text.trim(),
      guvenlikCevap: _cevap.text.trim(),
    );
    if (!mounted) return;
    setState(() => _yukleniyor = false);

    if (r['basari'] == true) {
      if (widget.hedef == 'cocukkulubu') {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => CocukKulubuAnaSayfa(oturum: widget.oturum),
        ));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => OgretmenAnaSayfa(oturum: widget.oturum),
        ));
      }
    } else {
      setState(() => _hata = r['mesaj'] ?? 'İşlem başarısız');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // geri tuşuyla atlanamasın
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text('🔐', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 12),
                const Text('Şifreni Belirle', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
                const SizedBox(height: 6),
                const Text(
                  'İlk kez giriş yapıyorsun. Devam etmeden önce kendi şifreni ve şifremi unuttum ekranında kullanılacak güvenlik sorunu belirlemen gerekiyor.',
                  style: TextStyle(color: AppColors.gray, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),

                const Text('YENİ ŞİFRE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray)),
                const SizedBox(height: 8),
                TextField(controller: _yeniSifre, obscureText: true, decoration: _dekor('En az 6 karakter')),
                const SizedBox(height: 14),

                const Text('YENİ ŞİFRE (TEKRAR)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray)),
                const SizedBox(height: 8),
                TextField(controller: _yeniSifreTekrar, obscureText: true, decoration: _dekor('Tekrar gir')),
                const SizedBox(height: 20),

                const Text('GÜVENLİK SORUSU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray)),
                const SizedBox(height: 8),
                TextField(controller: _soru, decoration: _dekor('Örn: İlk öğretmenlik yaptığın okul?')),
                const SizedBox(height: 14),

                const Text('CEVABIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray)),
                const SizedBox(height: 8),
                TextField(controller: _cevap, decoration: _dekor('Cevabını yaz')),

                if (_hata.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(_hata, style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _yukleniyor ? null : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _yukleniyor
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Kaydet ve Devam Et', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dekor(String hint) => InputDecoration(
    hintText: hint,
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}