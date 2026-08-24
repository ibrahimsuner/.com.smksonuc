import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import 'cocuk_kulubu_sube_detay.dart';

// ════════════ YOKLAMA — ŞUBE SEÇİMİ ════════════
// Eskiden CocukKulubuAnaSayfa içindeydi; artık ana sayfa sadece menü,
// yoklama akışı buraya taşındı.
class CocukKulubuYoklama extends StatefulWidget {
  final Map<String, String> oturum;
  const CocukKulubuYoklama({super.key, required this.oturum});

  @override
  State<CocukKulubuYoklama> createState() => _CocukKulubuYoklamaState();
}

class _CocukKulubuYoklamaState extends State<CocukKulubuYoklama> {
  bool _subelerYukleniyor = true;
  List<dynamic> _subeler = [];
  String _subeHata = '';

  @override
  void initState() {
    super.initState();
    _subeleriYukle();
  }

  Future<void> _subeleriYukle() async {
    setState(() { _subelerYukleniyor = true; _subeHata = ''; });
    final r = await ApiService.cocukKulubuSubeler();
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _subeler = r['subeler'];
      } else {
        _subeHata = r['mesaj'] ?? 'Şubeler yüklenemedi';
      }
      _subelerYukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _subeleriYukle,
        color: AppColors.purple,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _subelerIcerik()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD],
        ),
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
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Text('← Geri', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('📋', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yoklama', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Şube Seç ve Yoklama Al', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════ ŞUBELER ════════════
  Widget _subelerIcerik() {
    if (_subelerYukleniyor) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator(color: AppColors.purple)));
    }
    if (_subeHata.isNotEmpty) {
      return Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(_subeHata, style: const TextStyle(color: AppColors.gray))));
    }
    if (_subeler.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: Column(children: [
          Text('📭', style: TextStyle(fontSize: 44)),
          SizedBox(height: 12),
          Text('Henüz açık şube yok', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
        ])),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AÇIK ŞUBELER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subeler.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15,
            ),
            itemBuilder: (context, i) {
              final s = _subeler[i];
              final tamamlandi = s['bugunTamamlandi'] == true;
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CocukKulubuSubeDetay(sube: s['sube'], oturum: widget.oturum),
                  ));
                  _subeleriYukle();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 10)],
                    border: Border.all(color: tamamlandi ? AppColors.green.withOpacity(0.3) : AppColors.lightGray),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(s['sube'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark))),
                        if (tamamlandi) const Text('✅', style: TextStyle(fontSize: 16)),
                      ]),
                      const Spacer(),
                      Text('${s['ogrencisayisi']}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.purple)),
                      const Text('Öğrenci', style: TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tamamlandi ? AppColors.green.withOpacity(0.1) : AppColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tamamlandi ? 'Bugün alındı' : 'Yoklama bekliyor',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tamamlandi ? AppColors.green : AppColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
