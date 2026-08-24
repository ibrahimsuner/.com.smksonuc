import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import 'ogretmen_ogrenci_detay.dart';

class OgretmenSinifDetay extends StatefulWidget {
  final String sinif;
  const OgretmenSinifDetay({super.key, required this.sinif});

  @override
  State<OgretmenSinifDetay> createState() => _OgretmenSinifDetayState();
}

class _OgretmenSinifDetayState extends State<OgretmenSinifDetay> {
  bool _yukleniyor = true;
  String _hata = '';
  List<dynamic> _ortalamalar = [];
  Map<String, dynamic>? _genelOrtalama;
  List<dynamic> _ogrenciler = [];
  List<dynamic> _dusenOgrenciler = [];

  int _aktifTab = 0;

  final List<Map<String, dynamic>> _dersler = [
    {'ad': 'Türkçe', 'key': 'turkcen', 'icon': '📖', 'color': AppColors.purple},
    {'ad': 'Sosyal', 'key': 'sosn', 'icon': '🌍', 'color': AppColors.magenta},
    {'ad': 'Din', 'key': 'dinn', 'icon': '☪️', 'color': AppColors.teal},
    {'ad': 'İngilizce', 'key': 'ingn', 'icon': '🌐', 'color': AppColors.blue},
    {'ad': 'Matematik', 'key': 'matn', 'icon': '🔢', 'color': AppColors.orange},
    {'ad': 'Fen', 'key': 'fenn', 'icon': '🔬', 'color': AppColors.green},
  ];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = ''; });
    final r = await ApiService.sinifDetay(widget.sinif);
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _ortalamalar = r['ortalamalar'];
        _genelOrtalama = r['genelOrtalama'];
        _ogrenciler = r['ogrenciler'];
        _dusenOgrenciler = r['dusenOgrenciler'];
      } else {
        _hata = r['mesaj'] ?? 'Veri alınamadı';
      }
      _yukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          if (_yukleniyor)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.purple)))
          else if (_hata.isNotEmpty)
            SliverFillRemaining(child: Center(child: Padding(padding: const EdgeInsets.all(30), child: Text(_hata, style: const TextStyle(color: AppColors.gray)))))
          else ...[
              SliverToBoxAdapter(child: _tabBar()),
              SliverToBoxAdapter(child: _icerik()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD]),
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
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(widget.sinif, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${widget.sinif} Şubesi', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                Text(
                  _genelOrtalama != null ? '${_ogrenciler.length} öğrenci • ${_genelOrtalama!['sinavsayisi']} sınav' : '${_ogrenciler.length} öğrenci',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ])),
              if (_genelOrtalama != null)
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Genel LGS Ort.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                  Text(((_genelOrtalama!['lgs'] as num)).toDouble().toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                ]),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════ GEÇİŞLİ SEKMELER ════════════
  Widget _tabBar() {
    final tabs = [
      {'icon': '⚠️', 'label': 'Dikkat'},
      {'icon': '🏆', 'label': 'En Başarılı'},
      {'icon': '📋', 'label': 'Öğrenciler'},
      {'icon': '📊', 'label': 'Ortalamalar'},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final aktif = _aktifTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _aktifTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                  decoration: BoxDecoration(
                    color: aktif ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: aktif ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)] : [],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(t['icon'] as String, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      t['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: aktif ? AppColors.purple : AppColors.gray),
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _icerik() {
    switch (_aktifTab) {
      case 0: return _dikkatTab();
      case 1: return _enBasariliTab();
      case 2: return _ogrencilerTab();
      case 3: return _ortalamalarTab();
      default: return const SizedBox();
    }
  }

  // ════════════ SEKME 0: DİKKAT (düşüşteki öğrenciler) ════════════
  Widget _dikkatTab() {
    if (_dusenOgrenciler.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Center(child: Padding(padding: EdgeInsets.all(30), child: Column(children: [
          Text('✅', style: TextStyle(fontSize: 44)),
          SizedBox(height: 12),
          Text('Takip Gereken Öğrenci Yok', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
          SizedBox(height: 4),
          Text('Son 3 sınavda kesintisiz düşüş gösteren kimse bulunamadı', style: TextStyle(color: AppColors.gray, fontSize: 12), textAlign: TextAlign.center),
        ]))),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.red.withOpacity(0.25))),
            child: Row(children: [
              const Text('⚠️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Takip Edilmesi Gereken ${_dusenOgrenciler.length} Öğrenci', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.red)),
                const Text('Son 3 sınavda LGS veya ana derslerden birinde kesintisiz düşüş', style: TextStyle(fontSize: 11, color: AppColors.gray)),
              ])),
            ]),
          ),
          const SizedBox(height: 10),
          ..._dusenOgrenciler.map((d) => GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OgretmenOgrenciDetay(ogrenci: d))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.red.withOpacity(0.15))),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['adisoyadi'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                    Text('No: ${d['numarasi']}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5, runSpacing: 5,
                      children: (d['sebepler'] as List).map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text('$s ▼', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.red)),
                      )).toList(),
                    ),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: AppColors.gray),
              ]),
            ),
          )),
        ],
      ),
    );
  }

  // ════════════ SEKME 1: EN BAŞARILI ════════════
  Widget _enBasariliTab() {
    if (_ogrenciler.isEmpty) {
      return const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Veri yok', style: TextStyle(color: AppColors.gray))));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏆 SINIFIN EN BAŞARILILARI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 10),
          ..._ogrenciler.take(10).toList().asMap().entries.map((e) {
            final medals = ['🥇', '🥈', '🥉'];
            final rozet = e.key < 3 ? medals[e.key] : '${e.key + 1}.';
            final o = e.value;
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OgretmenOgrenciDetay(ogrenci: o))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  gradient: e.key < 3 ? LinearGradient(colors: [AppColors.purple.withOpacity(0.08), AppColors.purple.withOpacity(0.02)]) : null,
                  color: e.key < 3 ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: e.key < 3 ? AppColors.purple.withOpacity(0.15) : AppColors.lightGray),
                ),
                child: Row(children: [
                  SizedBox(width: 32, child: Text(rozet, style: TextStyle(fontSize: e.key < 3 ? 17 : 13, fontWeight: FontWeight.w800, color: e.key < 3 ? null : AppColors.gray))),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o['adisoyadi'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                    Text('No: ${o['numarasi']}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  ])),
                  Text((o['sonLgs'] as num).toDouble().toStringAsFixed(0), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.purple)),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ════════════ SEKME 2: ÖĞRENCİLER (tam liste) ════════════
  Widget _ogrencilerTab() {
    if (_ogrenciler.isEmpty) {
      return const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Öğrenci bulunamadı', style: TextStyle(color: AppColors.gray))));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ÖĞRENCİ LİSTESİ (LGS SIRASINA GÖRE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 10),
          ..._ogrenciler.asMap().entries.map((e) {
            final i = e.key;
            final o = e.value;
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OgretmenOgrenciDetay(ogrenci: o))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.purple))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o['adisoyadi'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                    Text('No: ${o['numarasi']}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  ])),
                  Text((o['sonLgs'] as num).toDouble().toStringAsFixed(0), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.purple)),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ════════════ SEKME 3: ORTALAMALAR (ders bazlı + genel) ════════════
  Widget _ortalamalarTab() {
    if (_genelOrtalama == null) {
      return const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Veri yok', style: TextStyle(color: AppColors.gray))));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DERS BAZLI SINIF ORTALAMASI (TÜM SINAVLAR)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.06), blurRadius: 10)]),
            child: Column(
              children: _dersler.asMap().entries.map((e) {
                final i = e.key;
                final d = e.value;
                final net = (_genelOrtalama![d['key']] as num).toDouble();
                final maxNet = (d['ad'] == 'Din' || d['ad'] == 'İngilizce') ? 10.0 : 20.0;
                return Column(children: [
                  Row(children: [
                    Text(d['icon'] as String, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    SizedBox(width: 76, child: Text(d['ad'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: (net / maxNet).clamp(0.0, 1.0), backgroundColor: AppColors.lightGray, valueColor: AlwaysStoppedAnimation<Color>(d['color'] as Color), minHeight: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 40, child: Text(net.toStringAsFixed(2), textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: d['color'] as Color))),
                  ]),
                  if (i < _dersler.length - 1) const SizedBox(height: 10),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          const Text('GENEL BİLGİLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              _ozetKart('LGS Ortalaması', (_genelOrtalama!['lgs'] as num).toDouble().toStringAsFixed(1), AppColors.purple),
              _ozetKart('Toplam Net Ort.', (_genelOrtalama!['ton'] as num).toDouble().toStringAsFixed(2), AppColors.blue),
              _ozetKart('Girilen Sınav', '${_genelOrtalama!['sinavsayisi']}', AppColors.orange),
              _ozetKart('Öğrenci Sayısı', '${_ogrenciler.length}', AppColors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ozetKart(String label, String deger, Color renk) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: renk.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(deger, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: renk)),
        Text(label, style: TextStyle(fontSize: 10, color: renk, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]),
    );
  }
}