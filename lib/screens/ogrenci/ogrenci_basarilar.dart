import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/sinav_model.dart';

class OgrenciBasarilar extends StatefulWidget {
  final List<SinavModel> sinavlar;
  const OgrenciBasarilar({super.key, required this.sinavlar});

  @override
  State<OgrenciBasarilar> createState() => _OgrenciBasarilarState();
}

class _OgrenciBasarilarState extends State<OgrenciBasarilar> {
  Map<String, dynamic>? _secilenRozet;

  // Bir düşüşün ardından tekrar yükseliş var mı? (yerel minimum + toparlanma)
  bool _toparlandiMi(List<double> lgsData) {
    for (int i = 1; i < lgsData.length - 1; i++) {
      if (lgsData[i] < lgsData[i - 1] && lgsData[i + 1] > lgsData[i]) {
        return true;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> _rozetleriHesapla() {
    final s = widget.sinavlar;
    if (s.isEmpty) return [];
    final lgsData = s.map((x) => x.lgs).toList();
    final enYuksek = lgsData.reduce((a, b) => a > b ? a : b);
    final enYuksekNet = s.map((x) => x.ton).reduce((a, b) => a > b ? a : b);

    int maxArdisik = 0, simdiki = 0;
    for (int i = 1; i < lgsData.length; i++) {
      if (lgsData[i] > lgsData[i - 1]) {
        simdiki++;
        if (simdiki > maxArdisik) maxArdisik = simdiki;
      } else {
        simdiki = 0;
      }
    }

    return [
      {'id': 'ilk', 'ad': 'İlk Adım', 'aciklama': 'İlk deneme sınavını tamamladın', 'icon': '🎯', 'renk': AppColors.blue, 'kazanildi': s.isNotEmpty, 'sinavlar': s.isNotEmpty ? [s.first] : <SinavModel>[]},
      {'id': 'yukselis', 'ad': 'Yükselen Yıldız', 'aciklama': '3 sınav üst üste LGS puanın arttı', 'icon': '🚀', 'renk': AppColors.green, 'kazanildi': maxArdisik >= 3, 'sinavlar': <SinavModel>[]},
      {'id': 'p300', 'ad': '300+ Kulübü', 'aciklama': 'LGS puanın 300\'ü geçti', 'icon': '🥉', 'renk': const Color(0xFFCD7F32), 'kazanildi': enYuksek >= 300, 'sinavlar': s.where((x) => x.lgs >= 300).toList()},
      {'id': 'p350', 'ad': '350+ Kulübü', 'aciklama': 'LGS puanın 350\'yi geçti', 'icon': '🥈', 'renk': const Color(0xFFA8A8A8), 'kazanildi': enYuksek >= 350, 'sinavlar': s.where((x) => x.lgs >= 350).toList()},
      {'id': 'p400', 'ad': '400+ Kulübü', 'aciklama': 'LGS puanın 400\'ü geçti', 'icon': '🥇', 'renk': AppColors.yellow, 'kazanildi': enYuksek >= 400, 'sinavlar': s.where((x) => x.lgs >= 400).toList()},
      {'id': 'azimli', 'ad': 'Azimli', 'aciklama': '6 deneme sınavına katıldın', 'icon': '💪', 'renk': AppColors.purple, 'kazanildi': s.length >= 6, 'sinavlar': <SinavModel>[]},
      {'id': 'maraton', 'ad': 'Maraton Koşucusu', 'aciklama': '10 deneme sınavına katıldın', 'icon': '🏃', 'renk': AppColors.magenta, 'kazanildi': s.length >= 10, 'sinavlar': <SinavModel>[]},
      {'id': 'net60', 'ad': 'Net Avcısı', 'aciklama': 'Bir sınavda 60+ net yaptın', 'icon': '🎯', 'renk': AppColors.teal, 'kazanildi': enYuksekNet >= 60, 'sinavlar': s.where((x) => x.ton >= 60).toList()},

      // ── Yeni eklenen rozetler ──
      {'id': 'tampuan', 'ad': 'Tam Puan!', 'aciklama': 'Bir denemede 500 tam puan aldın', 'icon': '💯', 'renk': AppColors.red, 'kazanildi': lgsData.any((v) => v >= 500), 'sinavlar': s.where((x) => x.lgs >= 500).toList()},
      {'id': 'okulbirincisi', 'ad': 'Okul Birincisi', 'aciklama': 'Bir denemede okulunda birinci oldun', 'icon': '🏫', 'renk': AppColors.yellow, 'kazanildi': s.any((x) => x.dereceo == 1), 'sinavlar': s.where((x) => x.dereceo == 1).toList()},
      {'id': 'sinifbirincisi', 'ad': 'Sınıf Birincisi', 'aciklama': 'Bir denemede sınıfında birinci oldun', 'icon': '🥇', 'renk': AppColors.blue, 'kazanildi': s.any((x) => x.dereces == 1), 'sinavlar': s.where((x) => x.dereces == 1).toList()},
      {'id': 'ilcebirincisi', 'ad': 'İlçe Birincisi', 'aciklama': 'Bir denemede ilçende birinci oldun', 'icon': '🏆', 'renk': AppColors.orange, 'kazanildi': s.any((x) => x.dereceilce == 1), 'sinavlar': s.where((x) => x.dereceilce == 1).toList()},
      {'id': 'ilbirincisi', 'ad': 'İl Birincisi', 'aciklama': 'Bir denemede ilinde birinci oldun', 'icon': '👑', 'renk': const Color(0xFFFFD700), 'kazanildi': s.any((x) => x.dereceil == 1), 'sinavlar': s.where((x) => x.dereceil == 1).toList()},
      {'id': 'zirvede', 'ad': 'Zirvedesin', 'aciklama': 'Son sınavın, şimdiye kadarki en yüksek puanın', 'icon': '⛰️', 'renk': AppColors.green, 'kazanildi': s.last.lgs == enYuksek, 'sinavlar': s.last.lgs == enYuksek ? [s.last] : <SinavModel>[]},
      {'id': 'toparlanma', 'ad': 'Toparlanma Ustası', 'aciklama': 'Bir düşüşün ardından puanını tekrar yükselttin', 'icon': '🔄', 'renk': AppColors.teal, 'kazanildi': _toparlandiMi(lgsData), 'sinavlar': <SinavModel>[]},
    ];
  }

  // Rozet türüne göre, o sınavda hangi değerin gösterileceğini belirler.
  // Örn. "tampuan" ve "p300" gibi rozetlerde LGS puanı, "okulbirincisi"
  // gibi sıralama rozetlerinde ilgili derece gösterilir.
  String _rozetDegerMetni(String id, SinavModel x) {
    switch (id) {
      case 'okulbirincisi':
        return 'Okul: ${x.dereceo}.';
      case 'sinifbirincisi':
        return 'Sınıf: ${x.dereces}.';
      case 'ilcebirincisi':
        return 'İlçe: ${x.dereceilce}.';
      case 'ilbirincisi':
        return 'İl: ${x.dereceil}.';
      case 'net60':
        return '${x.ton.toStringAsFixed(2)} net';
      default:
        return '${x.lgs.toStringAsFixed(2)} puan';
    }
  }


  @override
  Widget build(BuildContext context) {
    final rozetler = _rozetleriHesapla();
    final kazanilanlar = rozetler.where((r) => r['kazanildi'] == true).toList();
    final enYuksek = widget.sinavlar.isNotEmpty ? widget.sinavlar.map((s) => s.lgs).reduce((a, b) => a > b ? a : b) : 0.0;
    final enYuksekSinav = widget.sinavlar.isNotEmpty ? widget.sinavlar.firstWhere((s) => s.lgs == enYuksek) : null;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 54, 20, 32),
                child: Column(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 38)),
                    const SizedBox(height: 8),
                    const Text('Başarılarım', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Kazandığın rozetler ve özel başarılar', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Column(
                        children: [
                          Text('${kazanilanlar.length}/${rozetler.length}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          Text('Rozet Kazanıldı', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kişisel rekor
                    if (enYuksekSinav != null) ...[
                      const Text('KİŞİSEL REKORLARIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.purpleL, AppColors.purpleD]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          children: [
                            const Text('🌟', style: TextStyle(fontSize: 36)),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('En Yüksek LGS Puanın', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                Text(enYuksek.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                                Text(enYuksekSinav.sinavadi, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Rozetler
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TÜM ROZETLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1.5)),
                        Text('${kazanilanlar.length} kazanıldı', style: const TextStyle(fontSize: 11, color: AppColors.purple, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3, shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10, mainAxisSpacing: 10,
                      // "Maraton Koşucusu" / "Toparlanma Ustası" gibi uzun
                      // rozet isimleri varsayılan kare hücrede (aspectRatio 1.0)
                      // 2 satıra sarıp ikon+boşluk+2 satır toplamının hücre
                      // yüksekliğini aşmasına (BOTTOM OVERFLOWED) yol
                      // açıyordu. 0.82 ile hücreye biraz daha yükseklik
                      // veriliyor.
                      childAspectRatio: 0.82,
                      children: rozetler.map((r) => GestureDetector(
                        onTap: () => setState(() => _secilenRozet = r),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: r['kazanildi'] == true ? Colors.white : AppColors.lightGray,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: r['kazanildi'] == true ? [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10)] : [],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Opacity(
                                    opacity: r['kazanildi'] == true ? 1 : 0.4,
                                    child: Container(
                                      width: 52, height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: r['kazanildi'] == true ? (r['renk'] as Color).withOpacity(0.15) : AppColors.lightGray,
                                        boxShadow: r['kazanildi'] == true ? [BoxShadow(color: (r['renk'] as Color).withOpacity(0.3), blurRadius: 8)] : [],
                                      ),
                                      child: Center(child: Text(r['kazanildi'] == true ? r['icon'] as String : '🔒', style: const TextStyle(fontSize: 24))),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Uzun isimler için de her ihtimalde taşma
                                  // engellendi: en fazla 2 satır, sığmazsa "..."
                                  Text(
                                    r['ad'] as String,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, height: 1.2, color: r['kazanildi'] == true ? AppColors.dark : AppColors.gray),
                                  ),
                                ],
                              ),
                              if (r['kazanildi'] == true)
                                Positioned(
                                  top: 0, right: 0,
                                  child: Container(
                                    width: 18, height: 18,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
                                    child: const Center(child: Text('✓', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),

                    // İlerleme çubuğu
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Genel İlerleme', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark)),
                              // NaN/Infinity çökmesi düzeltildi: rozetler boşken
                              // (sinavlar boşsa _rozetleriHesapla [] döner) 0/0
                              // hesaplaması NaN üretip .round() çağrısında
                              // çöküyordu. rozetler.isEmpty durumunda %0 gösteriliyor.
                              Text('%${rozetler.isEmpty ? 0 : ((kazanilanlar.length / rozetler.length) * 100).round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.purple)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: rozetler.isEmpty ? 0 : kazanilanlar.length / rozetler.length,
                              backgroundColor: AppColors.lightGray,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('${rozetler.length - kazanilanlar.length} rozet daha kazanabilirsin! 💪', style: const TextStyle(fontSize: 11, color: AppColors.gray), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Rozet detay modal
        if (_secilenRozet != null)
          GestureDetector(
            onTap: () => setState(() => _secilenRozet = null),
            child: Container(
              color: Colors.black54,
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _secilenRozet!['kazanildi'] == true ? (_secilenRozet!['renk'] as Color).withOpacity(0.15) : AppColors.lightGray,
                            boxShadow: _secilenRozet!['kazanildi'] == true ? [BoxShadow(color: (_secilenRozet!['renk'] as Color).withOpacity(0.3), blurRadius: 16)] : [],
                          ),
                          child: Center(child: Text(_secilenRozet!['kazanildi'] == true ? _secilenRozet!['icon'] as String : '🔒', style: const TextStyle(fontSize: 42))),
                        ),
                        const SizedBox(height: 16),
                        Text(_secilenRozet!['ad'] as String, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.dark)),
                        const SizedBox(height: 8),
                        Text(_secilenRozet!['aciklama'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _secilenRozet!['kazanildi'] == true ? AppColors.green.withOpacity(0.12) : AppColors.lightGray,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _secilenRozet!['kazanildi'] == true ? '✓ Kazanıldı' : '🔒 Henüz Kazanılmadı',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _secilenRozet!['kazanildi'] == true ? AppColors.green : AppColors.gray),
                          ),
                        ),
                        // Hangi sınav(lar)da kazanıldığı — birden fazla
                        // sınavda kazanılmış olabileceği için liste halinde
                        // gösteriliyor, çok uzunsa kaydırılabilir.
                        if ((_secilenRozet!['sinavlar'] as List<SinavModel>).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Kazandığın Sınavlar (${(_secilenRozet!['sinavlar'] as List<SinavModel>).length})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: SingleChildScrollView(
                              child: Column(
                                children: (_secilenRozet!['sinavlar'] as List<SinavModel>).map((x) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGray,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(x.sinavadi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark)),
                                              Text(x.sinavtarihi, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _rozetDegerMetni(_secilenRozet!['id'] as String, x),
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _secilenRozet!['renk'] as Color),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _secilenRozet = null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightGray, foregroundColor: AppColors.gray,
                              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}