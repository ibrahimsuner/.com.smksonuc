import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/sinav_model.dart';
import '../../services/api_service.dart';
import '../ogrenci/sinav_detay.dart';

class OgretmenOgrenciDetay extends StatefulWidget {
  final dynamic ogrenci;
  const OgretmenOgrenciDetay({super.key, required this.ogrenci});

  @override
  State<OgretmenOgrenciDetay> createState() => _OgretmenOgrenciDetayState();
}

class _OgretmenOgrenciDetayState extends State<OgretmenOgrenciDetay> {
  int _aktifTab = 0;
  List<SinavModel> _sinavlar = [];
  bool _yukleniyor = true;

  final List<Map<String, dynamic>> _dersler = [
    {'ad': 'Türkçe', 'icon': '📖', 'color': AppColors.purple, 'max': 20},
    {'ad': 'Sosyal', 'icon': '🌍', 'color': AppColors.magenta, 'max': 20},
    {'ad': 'Din', 'icon': '☪️', 'color': AppColors.teal, 'max': 10},
    {'ad': 'İngilizce', 'icon': '🌐', 'color': AppColors.blue, 'max': 10},
    {'ad': 'Matematik', 'icon': '🔢', 'color': AppColors.orange, 'max': 20},
    {'ad': 'Fen', 'icon': '🔬', 'color': AppColors.green, 'max': 20},
  ];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final tcno = widget.ogrenci['tcno'] ?? '';
    final sonuc = await ApiService.ogrenciSinavlar(tcno);
    if (!mounted) return;
    if (sonuc['basari'] == true) {
      setState(() { _sinavlar = sonuc['sinavlar']; _yukleniyor = false; });
    } else {
      setState(() => _yukleniyor = false);
    }
  }

  // ÖNEMLİ: Sadece standart (sinavTuru == 'lgs') sınavlar LGS trendine
  // dahil ediliyor — bursluluk gibi farklı formatlı sınavlar farklı bir
  // ölçekte olabileceği için LGS puanı düşüş/yükseliş tespitine hiç
  // katılmıyor.
  String _lgsTrend() {
    final lgsFormatli = _sinavlar.where((s) => s.sinavTuru == 'lgs').toList();
    if (lgsFormatli.length < 3) return 'yetersiz';
    final son3 = lgsFormatli.reversed.take(3).toList().reversed.toList();
    if (son3[2].lgs < son3[1].lgs && son3[1].lgs < son3[0].lgs) return 'dususte';
    if (son3[2].lgs > son3[1].lgs && son3[1].lgs > son3[0].lgs) return 'yukseliste';
    return 'dengeli';
  }

  // ÖNEMLİ: O dersten SORU SORULMAYAN sınavlar (bursluluk vb.) bu
  // dersin trend hesabından tamamen çıkarılıyor. Kalan sınavlar, farklı
  // soru sayılarına sahip olabileceğinden ham net yerine ORAN
  // (net / soru sayısı) üzerinden kıyaslanıyor.
  List<Map<String, dynamic>> _dusenDersler() {
    return _dersler.where((d) {
      final ad = d['ad'] as String;
      final gecerli = _sinavlar.where((s) => _dersSoru(s, ad) > 0).toList();
      if (gecerli.length < 3) return false;
      final oranlar = gecerli.map((s) => _dersNeti(s, ad) / _dersSoru(s, ad)).toList();
      final son3 = oranlar.sublist(oranlar.length - 3);
      return son3[0] > son3[1] && son3[1] > son3[2];
    }).toList();
  }

  int _dersSoru(SinavModel s, String ad) {
    switch (ad) {
      case 'Türkçe': return s.turkceSoru;
      case 'Sosyal': return s.sosSoru;
      case 'Din': return s.dinSoru;
      case 'İngilizce': return s.ingSoru;
      case 'Matematik': return s.matSoru;
      case 'Fen': return s.fenSoru;
      default: return 0;
    }
  }

  double _dersNeti(SinavModel s, String ad) {
    switch (ad) {
      case 'Türkçe': return s.turkcen;
      case 'Sosyal': return s.sosn;
      case 'Din': return s.dinn;
      case 'İngilizce': return s.ingn;
      case 'Matematik': return s.matn;
      case 'Fen': return s.fenn;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trend = _lgsTrend();
    final dusenDersler = _dusenDersler();
    final son = _sinavlar.isNotEmpty ? _sinavlar.last : null;
    final onceki = _sinavlar.length > 1 ? _sinavlar[_sinavlar.length - 2] : null;
    final fark = son != null && onceki != null ? son.lgs - onceki.lgs : 0.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context, trend, dusenDersler, son, fark)),
          SliverToBoxAdapter(child: _tabBar()),
          if (_yukleniyor)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.purple)))
          else ...[
            SliverToBoxAdapter(child: _icerik(trend, dusenDersler, son)),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String trend, List dusenDersler, SinavModel? son, double fark) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.ogrenci['adisoyadi'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('No: ${widget.ogrenci['numarasi']} • ${widget.ogrenci['sinifi']}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (trend == 'dususte') _etiket('⚠️ LGS Düşüyor', AppColors.red),
                        if (trend == 'yukseliste') _etiket('✅ LGS Yükseliyor', AppColors.green),
                        if (dusenDersler.isNotEmpty) _etiket('⚠️ ${dusenDersler.length} Ders Düşüşte', AppColors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              if (son != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Son LGS', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                    Text(son.lgs.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
                    Text(
                      '${fark >= 0 ? "▲" : "▼"} ${fark.abs().toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fark >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF6B6B)),
                    ),
                  ],
                ),
            ],
          ),
          if (_sinavlar.isNotEmpty) ...[
            const SizedBox(height: 14),
            _miniBarChart(_sinavlar.map((s) => s.lgs).toList()),
          ],
        ],
      ),
    );
  }

  Widget _etiket(String text, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: renk.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _miniBarChart(List<double> data) {
    final max = data.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 58,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((e) {
          final h = (e.value / max * 40).clamp(4.0, 40.0);
          final isLast = e.key == data.length - 1;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isLast ? Colors.white : Colors.white.withOpacity(0.35),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 3),
                Text('${e.key + 1}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tabBar() {
    final tabs = ['Genel', 'Dersler', 'Sınavlar'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final aktif = _aktifTab == e.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _aktifTab = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: aktif ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: aktif ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)] : [],
                  ),
                  child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: aktif ? AppColors.purple : AppColors.gray)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _icerik(String trend, List<Map<String, dynamic>> dusenDersler, SinavModel? son) {
    switch (_aktifTab) {
      case 0: return _genel(trend, dusenDersler, son);
      case 1: return _derslerTab(son);
      case 2: return _sinavListesi();
      default: return const SizedBox();
    }
  }

  Widget _genel(String trend, List<Map<String, dynamic>> dusenDersler, SinavModel? son) {
    if (_sinavlar.isEmpty || son == null) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Sınav kaydı yok', style: TextStyle(color: AppColors.gray))));
    final lgsData = _sinavlar.map((s) => s.lgs).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          // Özet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GENEL ÖZET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
                const SizedBox(height: 12),
                Row(children: [
                  _ozzetKutu('Sınav', '${_sinavlar.length}', AppColors.purple),
                  const SizedBox(width: 8),
                  _ozzetKutu('En Yüksek', lgsData.reduce((a, b) => a > b ? a : b).toStringAsFixed(0), AppColors.green),
                  const SizedBox(width: 8),
                  _ozzetKutu('En Düşük', lgsData.reduce((a, b) => a < b ? a : b).toStringAsFixed(0), AppColors.red),
                  const SizedBox(width: 8),
                  _ozzetKutu('Ortalama', (lgsData.reduce((a, b) => a + b) / lgsData.length).toStringAsFixed(1), AppColors.orange),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Düşen dersler
          if (dusenDersler.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.red.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️ Sürekli Düşen Dersler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.red)),
                  const SizedBox(height: 12),
                  ...dusenDersler.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Text(d['icon'] as String, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(d['ad'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Düşüyor ▼', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red)),
                      ),
                    ]),
                  )),
                ],
              ),
            ),
          if (dusenDersler.isNotEmpty) const SizedBox(height: 12),

          // Son sınav sıralamaları
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SON SINAV SIRALAMALARI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
                const SizedBox(height: 12),
                ...[
                  {'icon': '🏫', 'label': 'Sınıf', 'deger': '${son.dereces}'},
                  {'icon': '🏢', 'label': 'Okul', 'deger': '${son.dereceo}'},
                  {'icon': '🏘️', 'label': 'İlçe', 'deger': '${son.dereceilce}'},
                  {'icon': '🌆', 'label': 'İl', 'deger': '${son.dereceil}'},
                  {'icon': '🇹🇷', 'label': 'Türkiye', 'deger': '${son.dereceg}'},
                ].map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Text(s['icon']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s['label']!, style: const TextStyle(fontSize: 13, color: AppColors.dark))),
                    Text(s['deger']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.purple)),
                  ]),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozzetKutu(String label, String deger, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: renk.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(deger, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: renk)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: renk, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _derslerTab(SinavModel? son) {
    if (son == null) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Sınav kaydı yok', style: TextStyle(color: AppColors.gray))));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DERS BAZLI GELİŞİM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
            const SizedBox(height: 14),
            ..._dersler.map((d) {
              final sonNet = _dersNeti(son, d['ad'] as String);
              final max = d['max'] as int;
              final trend = _sinavlar.length >= 3 ? (() {
                final s3 = _sinavlar.reversed.take(3).toList().reversed.toList();
                final v = s3.map((s) => _dersNeti(s, d['ad'] as String)).toList();
                if (v[2] < v[1] && v[1] < v[0]) return 'dususte';
                return 'ok';
              })() : 'ok';

              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: (d['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(d['icon'] as String, style: const TextStyle(fontSize: 16))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(d['ad'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                            if (trend == 'dususte') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: const Text('Düşüyor ▼', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.red)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: sonNet / max,
                              backgroundColor: AppColors.lightGray,
                              valueColor: AlwaysStoppedAnimation<Color>(trend == 'dususte' ? AppColors.red : d['color'] as Color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      )),
                      const SizedBox(width: 10),
                      Text(sonNet.toStringAsFixed(2), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: trend == 'dususte' ? AppColors.red : d['color'] as Color)),
                    ],
                  ),
                  if (_dersler.last != d) const Divider(color: AppColors.lightGray, height: 18),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _sinavListesi() {
    if (_sinavlar.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Sınav kaydı yok', style: TextStyle(color: AppColors.gray))));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: _sinavlar.reversed.toList().asMap().entries.map((e) {
          final s = e.value;
          final idx = _sinavlar.length - 1 - e.key;
          final prev = idx > 0 ? _sinavlar[idx - 1] : null;
          final fark = prev != null ? s.lgs - prev.lgs : 0.0;
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SinavDetay(sinav: s))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${idx + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purple))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.sinavadi, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                    Text('${s.sinavtarihi} • Net: ${s.ton.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  ],
                )),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(s.lgs.toStringAsFixed(0), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.purple)),
                  if (prev != null)
                    Text(
                      '${fark >= 0 ? "▲" : "▼"}${fark.abs().toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fark >= 0 ? AppColors.green : AppColors.red),
                    ),
                ]),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}