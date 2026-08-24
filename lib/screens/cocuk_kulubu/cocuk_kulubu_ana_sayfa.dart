import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/session_service.dart';
import '../login_screen.dart';
import '../ogretmen/ogretmen_ana_sayfa.dart';
import 'cocuk_kulubu_yoklama.dart';
import 'cocuk_kulubu_kazanim_degerlendirme.dart';

// ════════════ ÇOCUK KULÜBÜ — ANA SAYFA (LANDING) ════════════
// Şube listesini doğrudan göstermiyor. Öğretmene "Yoklama" ve
// "Kazanım Değerlendirme" iki büyük kutu sunuyor; öğretmen hangisine
// girecekse ona dokunuyor. Açılışta sayfa boş görünmesin diye kutular
// hemen, veri beklemeden gösteriliyor.
//
// Öğretmen ve Çocuk Kulübü aynı hesapla (aynı tcno) giriş yaptığı için,
// header'daki "Öğretmen Paneline Geç" ikonuyla şifre girmeden diğer
// panele atlanabiliyor — oturum bilgisi güncellenip doğrudan yönlendirme
// yapılıyor.
class CocukKulubuAnaSayfa extends StatelessWidget {
  final Map<String, String> oturum;
  const CocukKulubuAnaSayfa({super.key, required this.oturum});

  Future<void> _cikis(BuildContext context) async {
    await SessionService.oturumSil();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _cikisOnayla(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              const Text('Çıkış Yapmak Üzeresin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightGray, foregroundColor: AppColors.gray, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: const Text('Vazgeç', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { Navigator.pop(ctx); _cikis(context); },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // Şifre istemeden Öğretmen paneline geçiş: oturumun 'tip' bilgisini
  // 'ogretmen' olarak güncelleyip doğrudan o ekrana yönlendiriyoruz.
  // Kimlik bilgileri (tcno, adisoyadi, brans) zaten aynı hesaba ait
  // olduğu için tekrar giriş yapmaya gerek yok.
  Future<void> _ogretmenPanelineGec(BuildContext context) async {
    final yeniOturum = Map<String, String>.from(oturum);
    yeniOturum['tip'] = 'ogretmen';

    await SessionService.oturumKaydet(
      tip: 'ogretmen',
      tcno: oturum['tcno'] ?? '',
      adisoyadi: oturum['adisoyadi'] ?? '',
      brans: oturum['brans'] ?? '',
    );

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OgretmenAnaSayfa(oturum: yeniOturum)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context)),
          SliverToBoxAdapter(child: _kutular(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('🧩', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Çocuk Kulübü', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Ne yapmak istersin?', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _cikisOnayla(context),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),

          // ── Öğretmen paneline şifresiz geçiş ──
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _ogretmenPanelineGec(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Öğretmen Paneline Geç', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════ İKİ BÜYÜK KUTU ════════════
  Widget _kutular(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          _ozellikKutusu(
            context,
            emoji: '📋',
            baslik: 'Yoklama',
            aciklama: 'Şubelere göre devamsızlık al ve takip et',
            renkler: const [AppColors.purpleL, AppColors.purple],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CocukKulubuYoklama(oturum: oturum)),
            ),
          ),
          const SizedBox(height: 16),
          _ozellikKutusu(
            context,
            emoji: '📚',
            baslik: 'Kazanım Değerlendirme',
            aciklama: 'Sınav sonrası şube şube eksik kazanımları gör',
            renkler: const [AppColors.orange, Color(0xFFE65100)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CocukKulubuKazanimDegerlendirme()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozellikKutusu(
      BuildContext context, {
        required String emoji,
        required String baslik,
        required String aciklama,
        required List<Color> renkler,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: renkler),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: renkler.first.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(18)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 30))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(aciklama, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, height: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 26),
          ],
        ),
      ),
    );
  }
}
