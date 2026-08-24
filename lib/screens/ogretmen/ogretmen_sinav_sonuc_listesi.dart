import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

class OgretmenSinavSonucListesi extends StatefulWidget {
  const OgretmenSinavSonucListesi({super.key});

  @override
  State<OgretmenSinavSonucListesi> createState() => _OgretmenSinavSonucListesiState();
}

class _OgretmenSinavSonucListesiState extends State<OgretmenSinavSonucListesi> {
  bool _siniflarYukleniyor = true;
  List<String> _tumSiniflar = [];
  String? _seciliSeviye;
  String? _seciliHedef; // "5/A" gibi tek şube ya da "5" gibi tümü

  List<dynamic> _sinavlar = []; // [{sinavadi, sinavtarihi}, ...]
  String? _seciliSinavAdi;
  bool _sinavlarYukleniyor = false;

  bool _sonucYukleniyor = false;
  String _hata = '';
  String _sinavAdi = '';
  bool _tumSubelerModu = false;
  List<dynamic> _ogrenciler = [];

  @override
  void initState() {
    super.initState();
    _siniflariYukle();
  }

  String _seviyeCikar(String sinifi) {
    final parcalar = sinifi.split('/');
    return parcalar.isNotEmpty ? parcalar[0] : sinifi;
  }

  Future<void> _siniflariYukle() async {
    setState(() => _siniflarYukleniyor = true);
    final sonuc = await ApiService.sinifListesi();
    if (!mounted) return;
    if (sonuc['basari'] == true) {
      final siniflar = List<String>.from(sonuc['siniflar']);
      final seviyeler = siniflar.map(_seviyeCikar).toSet().toList()..sort();
      setState(() {
        _tumSiniflar = siniflar;
        _siniflarYukleniyor = false;
        _seciliSeviye = seviyeler.isNotEmpty ? seviyeler.first : null;
      });
      _subeSecVeYukle();
    } else {
      setState(() => _siniflarYukleniyor = false);
    }
  }

  List<String> get _subelerBuSeviyede {
    if (_seciliSeviye == null) return [];
    final liste = _tumSiniflar.where((s) => _seviyeCikar(s) == _seciliSeviye).toList();
    liste.sort();
    return liste;
  }

  void _subeSecVeYukle() {
    if (_seciliSeviye == null) return;
    final subeler = _subelerBuSeviyede;
    final secenekler = [_seciliSeviye!, ...subeler]; // ilk eleman = "Tümü"
    if (_seciliHedef == null || !secenekler.contains(_seciliHedef)) {
      // Varsayılan: Tümü (seviyenin kendisi)
      _seciliHedef = _seciliSeviye;
    }
    _sinavlariYukle();
  }

  Future<void> _sinavlariYukle() async {
    if (_seciliHedef == null) return;
    setState(() { _sinavlarYukleniyor = true; _sinavlar = []; _seciliSinavAdi = null; });
    final r = await ApiService.sinavAdlari(_seciliHedef!);
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _sinavlar = r['sinavlar'] ?? [];
        // Liste tarihe göre en yeniden eskiye geliyor, varsayılan en yenisi
        _seciliSinavAdi = _sinavlar.isNotEmpty ? _sinavlar.first['sinavadi'] : null;
      }
      _sinavlarYukleniyor = false;
    });
    _sonuclariYukle();
  }

  Future<void> _sonuclariYukle() async {
    if (_seciliHedef == null) return;
    setState(() { _sonucYukleniyor = true; _hata = ''; });
    final r = await ApiService.sinavSonucListesi(_seciliHedef!, sinavadi: _seciliSinavAdi);
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _ogrenciler = r['ogrenciler'] ?? [];
        _sinavAdi = r['sinavadi'] ?? '';
        _tumSubelerModu = r['tumSubeler'] == true;
      } else {
        _ogrenciler = [];
        _sinavAdi = '';
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
          if (_siniflarYukleniyor)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.purple)))
          else ...[
            SliverToBoxAdapter(child: _seviyeSekmeleri()),
            SliverToBoxAdapter(child: _subeSekmeleri()),
            SliverToBoxAdapter(child: _sinavSecici()),
            SliverToBoxAdapter(child: _sinavBilgisi()),
            if (_sonucYukleniyor)
              const SliverPadding(
                padding: EdgeInsets.symmetric(vertical: 60),
                sliver: SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.purple))),
              )
            else if (_hata.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Center(child: Text(_hata, style: const TextStyle(color: AppColors.gray))),
                ),
              )
            else if (_ogrenciler.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('Bu seçim için sınav sonucu bulunamadı', style: TextStyle(color: AppColors.gray))),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) => _OgrenciSonucSatiri(ogrenci: _ogrenciler[i], sira: i + 1),
                      childCount: _ogrenciler.length,
                    ),
                  ),
                ),
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
          const Text('📋 SINAV SONUÇ LİSTELERİ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text('Şubelere Göre Sınav Sonuçları', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _seviyeSekmeleri() {
    final seviyeler = _tumSiniflar.map(_seviyeCikar).toSet().toList()..sort();
    if (seviyeler.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: seviyeler.map((sv) {
            final secili = _seciliSeviye == sv;
            return GestureDetector(
              onTap: () {
                setState(() { _seciliSeviye = sv; _seciliHedef = null; });
                _subeSecVeYukle();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: secili ? AppColors.purple : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                ),
                child: Center(child: Text('$sv. Sınıflar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: secili ? Colors.white : AppColors.gray))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _subeSekmeleri() {
    if (_seciliSeviye == null) return const SizedBox();
    final subeler = _subelerBuSeviyede;
    final secenekler = [_seciliSeviye!, ...subeler]; // ilk eleman = "Tümü"

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: secenekler.asMap().entries.map((e) {
            final i = e.key;
            final deger = e.value;
            final tumuMu = i == 0;
            final secili = _seciliHedef == deger;
            return GestureDetector(
              onTap: () {
                setState(() => _seciliHedef = deger);
                _sinavlariYukle();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: secili ? (tumuMu ? AppColors.purple : AppColors.orange) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: secili ? (tumuMu ? AppColors.purple : AppColors.orange) : AppColors.lightGray),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tumuMu) ...[
                      Icon(Icons.groups_rounded, size: 14, color: secili ? Colors.white : AppColors.gray),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      tumuMu ? 'Tümü' : deger,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secili ? Colors.white : AppColors.dark),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _sinavSecici() {
    if (_sinavlarYukleniyor) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: SizedBox(height: 20, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple)))),
      );
    }
    if (_sinavlar.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SINAV SEÇ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sinavlar.length,
              itemBuilder: (context, i) {
                final s = _sinavlar[i];
                final ad = s['sinavadi'] as String;
                final secili = _seciliSinavAdi == ad;
                final enYeni = i == 0;
                return GestureDetector(
                  onTap: () {
                    setState(() => _seciliSinavAdi = ad);
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ad, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: secili ? Colors.white : AppColors.dark)),
                        if (enYeni) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: secili ? Colors.white.withOpacity(0.2) : AppColors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Son', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: secili ? Colors.white : AppColors.green)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sinavBilgisi() {
    if (_sinavAdi.isEmpty) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(_sinavAdi, style: const TextStyle(fontSize: 11, color: AppColors.purple, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _tumSubelerModu
                  ? '${_ogrenciler.length} öğrenci • Tüm şubeler • LGS\'ye göre sıralı'
                  : '${_ogrenciler.length} öğrenci • LGS\'ye göre sıralı',
              style: const TextStyle(fontSize: 11, color: AppColors.gray),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════ ÖĞRENCİ SATIRI — SOL SABİT + SAĞ KAYAN ════════════
class _OgrenciSonucSatiri extends StatefulWidget {
  final dynamic ogrenci;
  final int sira;
  const _OgrenciSonucSatiri({required this.ogrenci, required this.sira});

  @override
  State<_OgrenciSonucSatiri> createState() => _OgrenciSonucSatiriState();
}

class _OgrenciSonucSatiriState extends State<_OgrenciSonucSatiri> {
  final ScrollController _sc = ScrollController();
  static const double _adimGenislik = 92;

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _ileriKaydir() {
    if (!_sc.hasClients) return;
    final maks = _sc.position.maxScrollExtent;
    final hedef = (_sc.offset + _adimGenislik * 2).clamp(0.0, maks);
    final gidilecek = (_sc.offset >= maks - 1) ? 0.0 : hedef;
    _sc.animateTo(gidilecek, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  double _n(String key) => (widget.ogrenci[key] as num?)?.toDouble() ?? 0.0;
  int _i(String key) => (widget.ogrenci[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    const medals = ['🥇', '🥈', '🥉'];
    final rozet = widget.sira <= 3 ? medals[widget.sira - 1] : '${widget.sira}';

    final dersler = [
      {'ad': 'Türkçe', 'icon': '📖', 'd': _i('turkced'), 'y': _i('turkcey'), 'n': _n('turkcen'), 'renk': AppColors.purple},
      {'ad': 'Sosyal', 'icon': '🌍', 'd': _i('sosd'), 'y': _i('sosy'), 'n': _n('sosn'), 'renk': AppColors.magenta},
      {'ad': 'Din', 'icon': '☪️', 'd': _i('dind'), 'y': _i('diny'), 'n': _n('dinn'), 'renk': AppColors.teal},
      {'ad': 'İngilizce', 'icon': '🌐', 'd': _i('ingd'), 'y': _i('ingy'), 'n': _n('ingn'), 'renk': AppColors.blue},
      {'ad': 'Matematik', 'icon': '🔢', 'd': _i('matd'), 'y': _i('maty'), 'n': _n('matn'), 'renk': AppColors.orange},
      {'ad': 'Fen', 'icon': '🔬', 'd': _i('fend'), 'y': _i('feny'), 'n': _n('fenn'), 'renk': AppColors.green},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: SizedBox(
        height: 92,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── SABİT SOL BÖLÜM ──
            Container(
              width: 128,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.lightGray, width: 1.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    Text(rozet, style: TextStyle(fontSize: widget.sira <= 3 ? 16 : 11, fontWeight: FontWeight.w800, color: widget.sira <= 3 ? null : AppColors.gray)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(6)),
                      child: Text(widget.ogrenci['sinifi'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.purple)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    widget.ogrenci['adisoyadi'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.dark),
                  ),
                  const SizedBox(height: 2),
                  Text('No: ${widget.ogrenci['numarasi'] ?? '-'}', style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                ],
              ),
            ),
            // ── SAĞ KAYAN BÖLÜM ──
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    controller: _sc,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    children: [
                      ...dersler.map(_dersKarti),
                      _toplamKarti(),
                      _lgsKarti(),
                      _siralamaKarti(),
                      const SizedBox(width: 30),
                    ],
                  ),
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    child: GestureDetector(
                      onTap: _ileriKaydir,
                      child: Container(
                        width: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft, end: Alignment.centerRight,
                            colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.95)],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 22, height: 22,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.purple),
                            child: const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartKabuk({required Widget child}) {
    return Container(
      width: 84,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }

  Widget _dersKarti(Map<String, dynamic> d) {
    return _kartKabuk(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(d['icon'] as String, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 3),
            Flexible(child: Text(d['ad'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gray), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Text((d['n'] as double).toStringAsFixed(2), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: d['renk'] as Color)),
          Text('${d['d']}D ${d['y']}Y', style: const TextStyle(fontSize: 9, color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _toplamKarti() {
    return _kartKabuk(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊 Toplam', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gray)),
          const SizedBox(height: 4),
          Text(_n('ton').toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.dark)),
          Text('${_i('tod')}D ${_i('toy')}Y', style: const TextStyle(fontSize: 9, color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _lgsKarti() {
    return Container(
      width: 84,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.purpleL, AppColors.purple]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('LGS Puanı', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(_n('lgs').toStringAsFixed(2), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _siralamaKarti() {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏆 Sıralamalar', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gray)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _siraMini('Sınıf', _i('dereces')),
            _siraMini('Okul', _i('dereceo')),
            _siraMini('İlçe', _i('dereceilce')),
          ]),
          const SizedBox(height: 3),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _siraMini('İl', _i('dereceil')),
            _siraMini('🇹🇷', _i('dereceg')),
          ]),
        ],
      ),
    );
  }

  Widget _siraMini(String label, int deger) {
    return Column(
      children: [
        Text('$deger', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.purple)),
        Text(label, style: const TextStyle(fontSize: 7, color: AppColors.gray)),
      ],
    );
  }
}