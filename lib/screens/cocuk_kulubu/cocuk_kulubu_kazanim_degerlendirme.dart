import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

// ════════════ KAZANIM DEĞERLENDİRME ════════════
// Öğretmenin sınav sonrası kazanım analizinde eksik çıkan kazanımları
// şube şube, ders ders görüntülediği ekran. Veri girişi ayrı bir web
// panelinden (kazanim_paneli.php) yapılır; burası salt-okunur gösterim.
class CocukKulubuKazanimDegerlendirme extends StatefulWidget {
  const CocukKulubuKazanimDegerlendirme({super.key});

  @override
  State<CocukKulubuKazanimDegerlendirme> createState() =>
      _CocukKulubuKazanimDegerlendirmeState();
}

class _CocukKulubuKazanimDegerlendirmeState
    extends State<CocukKulubuKazanimDegerlendirme> {
  int _seciliSeviye = 5; // ilk açılışta 5. sınıflar otomatik seçili

  bool _sinavlarYukleniyor = true;
  List<dynamic> _sinavlar = [];
  String? _seciliSinav;

  bool _sonucYukleniyor = false;
  String _hata = '';
  Map<String, dynamic> _subeler = {}; // şube -> ders -> [kazanım metinleri]

  static const Map<String, Map<String, dynamic>> _dersBilgi = {
    'Türkçe':    {'icon': '📖', 'renk': AppColors.purple},
    'Sosyal':    {'icon': '🌍', 'renk': AppColors.magenta},
    'Din':       {'icon': '☪️', 'renk': AppColors.teal},
    'İngilizce': {'icon': '🌐', 'renk': AppColors.blue},
    'Matematik': {'icon': '🔢', 'renk': AppColors.orange},
    'Fen':       {'icon': '🔬', 'renk': AppColors.green},
  };

  @override
  void initState() {
    super.initState();
    _sinavlariYukle();
  }

  Future<void> _sinavlariYukle() async {
    setState(() {
      _sinavlarYukleniyor = true;
      _sinavlar = [];
      _seciliSinav = null;
      _subeler = {};
      _hata = '';
    });
    final r = await ApiService.kazanimSinavlari(_seciliSeviye);
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _sinavlar = r['sinavlar'] ?? [];
        _seciliSinav = _sinavlar.isNotEmpty ? _sinavlar.first['sinavadi'] : null;
      }
      _sinavlarYukleniyor = false;
    });
    if (_seciliSinav != null) _sonuclariYukle();
  }

  Future<void> _sonuclariYukle() async {
    if (_seciliSinav == null) return;
    setState(() {
      _sonucYukleniyor = true;
      _hata = '';
    });
    final r = await ApiService.kazanimEksikGetir(
      sinavadi: _seciliSinav!,
      seviye: _seciliSeviye,
    );
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _subeler = Map<String, dynamic>.from(r['subeler'] ?? {});
      } else {
        _hata = r['mesaj'] ?? 'Veri alınamadı';
      }
      _sonucYukleniyor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _seviyeSekmeleri()),
          SliverToBoxAdapter(child: _sinavSecici()),
          if (_sonucYukleniyor)
            const SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 60),
              sliver: SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
              ),
            )
          else if (_sinavlarYukleniyor)
            const SliverToBoxAdapter(child: SizedBox())
          else if (_sinavlar.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Center(
                    child: Column(children: [
                      const Text('📭', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 10),
                      Text(
                        '$_seciliSeviye. sınıflar için henüz kazanım değerlendirmesi girilmemiş',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.gray),
                      ),
                    ]),
                  ),
                ),
              )
            else if (_hata.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Center(child: Text(_hata, style: const TextStyle(color: AppColors.gray))),
                  ),
                )
              else if (_subeler.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text('🎉 Bu sınavda eksik kazanım işaretlenmemiş',
                            style: TextStyle(color: AppColors.gray)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) {
                          final subeAdlari = _subeler.keys.toList()..sort();
                          final sube = subeAdlari[i];
                          return _subeKarti(sube, Map<String, dynamic>.from(_subeler[sube]));
                        },
                        childCount: _subeler.length,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
              child: const Text('← Geri',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('📚 KAZANIM DEĞERLENDİRME',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text('Şubelere Göre Eksik Kazanımlar',
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _seviyeSekmeleri() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [5, 6, 7, 8].map((sv) {
          final secili = _seciliSeviye == sv;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_seciliSeviye == sv) return;
                setState(() => _seciliSeviye = sv);
                _sinavlariYukle();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: secili ? AppColors.purple : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                ),
                child: Text(
                  '$sv. Sınıflar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secili ? Colors.white : AppColors.gray),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sinavSecici() {
    if (_sinavlarYukleniyor) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
            ),
          ),
        ),
      );
    }
    if (_sinavlar.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _sinavlar.length,
          itemBuilder: (context, i) {
            final ad = _sinavlar[i]['sinavadi'] as String;
            final secili = _seciliSinav == ad;
            return GestureDetector(
              onTap: () {
                setState(() => _seciliSinav = ad);
                _sonuclariYukle();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: secili ? AppColors.dark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: secili ? AppColors.dark : AppColors.lightGray),
                ),
                child: Text(ad,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secili ? Colors.white : AppColors.dark)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _subeKarti(String sube, Map<String, dynamic> derslerMap) {
    final toplamKazanim = derslerMap.values.fold<int>(0, (t, l) => t + (l as List).length);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.06), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(sube, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purple)),
            ),
            const SizedBox(width: 8),
            Text('$toplamKazanim eksik kazanım', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          ]),
          const SizedBox(height: 12),
          ...derslerMap.entries.map((e) => _dersBlok(e.key, List<dynamic>.from(e.value))),
        ],
      ),
    );
  }

  Widget _dersBlok(String ders, List<dynamic> kazanimlar) {
    final bilgi = _dersBilgi[ders] ?? {'icon': '📘', 'renk': AppColors.gray};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(bilgi['icon'] as String, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(ders, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: bilgi['renk'] as Color)),
          ]),
          const SizedBox(height: 6),
          ...kazanimlar.map((metin) => Padding(
            padding: const EdgeInsets.only(left: 21, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 5, height: 5,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: (bilgi['renk'] as Color).withOpacity(0.5)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metin.toString(),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.dark, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
