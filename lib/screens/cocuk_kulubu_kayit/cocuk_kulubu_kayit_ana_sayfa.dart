import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'cocuk_kulubu_kayit_islem.dart';
import 'cocuk_kulubu_kayit_durum.dart';

class CocukKulubuKayitAnaSayfa extends StatelessWidget {
  const CocukKulubuKayitAnaSayfa({super.key});

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
          colors: [AppColors.teal, AppColors.purple, AppColors.purpleD],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Text('← Geri', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('🧸', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Çocuk Kulübü', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('Kayıt ve Ödeme İşlemleri', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ]),
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
            emoji: '📝',
            baslik: 'Kayıt Ol / Ödeme Yap',
            aciklama: 'TC kimlik no ile öğrenci kaydı oluştur ya da mevcut kaydına ek ödeme yap',
            renkler: const [AppColors.teal, Color(0xFF00695C)],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CocukKulubuKayitIslem())),
          ),
          const SizedBox(height: 16),
          _ozellikKutusu(
            context,
            emoji: '🔍',
            baslik: 'Kayıt Durumu Sorgula',
            aciklama: 'TC kimlik no ile başvuru durumunu ve şubeyi öğren',
            renkler: const [AppColors.purpleL, AppColors.purple],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CocukKulubuKayitDurum())),
          ),
        ],
      ),
    );
  }

  Widget _ozellikKutusu(BuildContext context, {
    required String emoji, required String baslik, required String aciklama,
    required List<Color> renkler, required VoidCallback onTap,
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
        child: Row(children: [
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
        ]),
      ),
    );
  }
}