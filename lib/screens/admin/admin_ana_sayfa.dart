import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/session_service.dart';
import '../login_screen.dart';
import 'admin_ogrenci_yonetimi.dart';
import 'admin_bildirim_sinav.dart';
import 'admin_bildirim_ogretmen.dart';
import 'admin_bildirim_devamsizlik.dart';

class AdminAnaSayfa extends StatelessWidget {
  final Map<String, String> oturum;
  const AdminAnaSayfa({super.key, required this.oturum});

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
          colors: [Color(0xFF2C2C3A), Color(0xFF1A1A24), Color(0xFF0D0D14)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 30),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('🛡️', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yönetici Paneli', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Hoş geldin, ${oturum['adisoyadi'] ?? 'Yönetici'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _cikisOnayla(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kutular(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          _ozellikKutusu(
            context,
            emoji: '👥',
            baslik: 'Öğrenci Yönetimi',
            aciklama: 'Ekle, güncelle, sil — okulun tüm öğrenci kaydı',
            renkler: const [AppColors.purpleL, AppColors.purple],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOgrenciYonetimi())),
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 4, bottom: 4),
              child: Text('BİLDİRİM GÖNDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
            ),
          ),
          _ozellikKutusu(
            context,
            emoji: '📊',
            baslik: 'Sınav Sonucu Bildirimi',
            aciklama: 'Şube seç, sınav seç, öğrenci/veliye gönder',
            renkler: const [AppColors.blue, Color(0xFF1565C0)],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBildirimSinav())),
          ),
          const SizedBox(height: 14),
          _ozellikKutusu(
            context,
            emoji: '📢',
            baslik: 'Öğretmenlere Duyuru',
            aciklama: 'Serbest metinli mesaj, seçtiğin öğretmen(ler)e',
            renkler: const [AppColors.orange, Color(0xFFE65100)],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBildirimOgretmen())),
          ),
          const SizedBox(height: 14),
          _ozellikKutusu(
            context,
            emoji: '📋',
            baslik: 'Çocuk Kulübü Devamsızlık',
            aciklama: 'Derse gelmeyen öğrencilerin velisine bildirim',
            renkler: const [AppColors.teal, Color(0xFF00695C)],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBildirimDevamsizlik())),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: renkler),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: renkler.first.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(15)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(aciklama, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5, height: 1.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
