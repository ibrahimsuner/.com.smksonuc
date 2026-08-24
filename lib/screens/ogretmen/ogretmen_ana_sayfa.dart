import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../login_screen.dart';
import 'ogretmen_ogrenci_detay.dart';
import 'ogretmen_sinif_detay.dart';
import 'ogretmen_sinav_sonuc_listesi.dart';
import '../cocuk_kulubu/cocuk_kulubu_ana_sayfa.dart';


class OgretmenAnaSayfa extends StatefulWidget {
  final Map<String, String> oturum;
  const OgretmenAnaSayfa({super.key, required this.oturum});

  @override
  State<OgretmenAnaSayfa> createState() => _OgretmenAnaSayfaState();
}

class _OgretmenAnaSayfaState extends State<OgretmenAnaSayfa> {
  int _navIndex = 0;

  List<dynamic> _ogrenciler = [];
  List<String> _siniflar = [];
  bool _yukleniyor = true;

  // Ana sayfa dashboard toggle: 0 = Sınıf Ortalamaları, 1 = Genel İstatistik
  int _anaSayfaSecim = 1;
  List<dynamic> _sinifOrtalamalari = [];
  bool _sinifOrtYukleniyor = false;
  String _sonSinavAdi = '';
  String? _seciliSeviye;
  String? _siniflarSeciliSeviye;
  String? _sinifOrtSeciliSeviye;

  String _aramaMetni = '';
  List<dynamic> _aramaListesi = [];
  bool _aramaYukleniyor = false;
  final _aramaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    final sonuc = await ApiService.sinifListesi();
    if (!mounted) return;
    if (sonuc['basari'] == true) {
      setState(() {
        _ogrenciler = sonuc['ogrenciler'];
        _siniflar = List<String>.from(sonuc['siniflar']);
        _yukleniyor = false;
      });
    } else {
      setState(() => _yukleniyor = false);
    }
  }

  Future<void> _sinifOrtalamalariYukle() async {
    if (_sinifOrtalamalari.isNotEmpty || _sinifOrtYukleniyor) return;
    setState(() => _sinifOrtYukleniyor = true);
    final sonuc = await ApiService.sinifOrtalamalariOzet();
    if (!mounted) return;
    setState(() {
      if (sonuc['basari'] == true) {
        _sinifOrtalamalari = sonuc['siniflar'];
        _sonSinavAdi = sonuc['sinavadi'] ?? '';
      }
      _sinifOrtYukleniyor = false;
    });
  }

  Future<void> _ara(String q) async {
    if (q.length < 2) { setState(() => _aramaListesi = []); return; }
    setState(() => _aramaYukleniyor = true);
    final sonuc = await ApiService.ogrenciAra(q);
    if (!mounted) return;
    List<dynamic> liste = sonuc['basari'] == true ? List.from(sonuc['ogrenciler']) : [];
    final ql = q.toLowerCase();
    liste.sort((a, b) {
      final an = (a['adisoyadi'] ?? '').toString().toLowerCase();
      final bn = (b['adisoyadi'] ?? '').toString().toLowerCase();
      final aBaslar = an.startsWith(ql) ? 0 : 1;
      final bBaslar = bn.startsWith(ql) ? 0 : 1;
      if (aBaslar != bBaslar) return aBaslar - bBaslar;
      return an.compareTo(bn);
    });
    setState(() {
      _aramaListesi = liste;
      _aramaYukleniyor = false;
    });
  }

  Future<void> _cikis() async {
    await SessionService.oturumSil();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // Şifre istemeden Çocuk Kulübü paneline geçiş: oturumun 'tip' bilgisini
  // 'cocukkulubu' olarak güncelleyip doğrudan o ekrana yönlendiriyoruz.
  // Kimlik bilgileri (tcno, adisoyadi, brans) zaten aynı hesaba ait
  // olduğu için tekrar giriş yapmaya gerek yok.
  Future<void> _cocukKulubunePaneliGec() async {
    final yeniOturum = Map<String, String>.from(widget.oturum);
    yeniOturum['tip'] = 'cocukkulubu';

    await SessionService.oturumKaydet(
      tip: 'cocukkulubu',
      tcno: widget.oturum['tcno'] ?? '',
      adisoyadi: widget.oturum['adisoyadi'] ?? '',
      brans: widget.oturum['brans'] ?? '',
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CocukKulubuAnaSayfa(oturum: yeniOturum)),
    );
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _anaSayfaTab(),
          _siniflarTab(),
          _aramaTab(),
          _profilTab(),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ════════════ ALT NAVİGASYON ════════════
  Widget _bottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Ana Sayfa'},
      {'icon': Icons.groups_rounded, 'label': 'Sınıflar'},
      {'icon': Icons.search_rounded, 'label': 'Ara'},
      {'icon': Icons.person_rounded, 'label': 'Profil'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final act = _navIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _navIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: act ? 52 : 40, height: 32,
                      decoration: BoxDecoration(
                        color: act ? AppColors.purple.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(e.value['icon'] as IconData, color: act ? AppColors.purple : AppColors.gray, size: act ? 24 : 22),
                    ),
                    const SizedBox(height: 3),
                    Text(e.value['label'] as String, style: TextStyle(fontSize: 10, fontWeight: act ? FontWeight.w800 : FontWeight.w500, color: act ? AppColors.purple : AppColors.gray)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ════════════ ANA SAYFA (DASHBOARD) ════════════
  Widget _anaSayfaTab() {
    if (_yukleniyor) return const Center(child: CircularProgressIndicator(color: AppColors.purple));

    final lgsler = _ogrenciler.map((o) => (o['sonLgs'] as num?)?.toDouble() ?? 0.0).toList();
    final genelOrt = lgsler.isEmpty ? 0.0 : lgsler.reduce((a, b) => a + b) / lgsler.length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('👨‍🏫', style: TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Hoş geldin,', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(widget.oturum['adisoyadi'] ?? 'Öğretmen', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    GestureDetector(
                      onTap: _cocukKulubunePaneliGec,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🧩', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 6),
                            Text('Çocuk Kulübü Paneli', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(children: [
                  _statKutu('Toplam\nÖğrenci', '${_ogrenciler.length}'),
                  const SizedBox(width: 8),
                  _statKutu('Sınıf\nSayısı', '${_siniflar.length}'),
                  const SizedBox(width: 8),
                  _statKutu('Genel LGS\nOrt.', genelOrt.toStringAsFixed(1)),
                ]),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Row(
              children: [
                Expanded(child: _dashboardButon('🏆 Genel İstatistik', 1)),
                const SizedBox(width: 10),
                Expanded(child: _dashboardButon('📊 Sınıf Ortalamaları', 0)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sinavSonucListesiButonu(),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _anaSayfaSecim == 0 ? _sinifOrtalamalariGorunum() : _genelIstatistikGorunum(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _dashboardButon(String label, int index) {
    final aktif = _anaSayfaSecim == index;
    return GestureDetector(
      onTap: () {
        setState(() => _anaSayfaSecim = index);
        if (index == 0) _sinifOrtalamalariYukle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: aktif ? AppColors.purple : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(aktif ? 0.3 : 0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: aktif ? Colors.white : AppColors.dark)),
      ),
    );
  }

  Widget _sinavSonucListesiButonu() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OgretmenSinavSonucListesi()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.purple.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('📋', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text('Sınav Sonuç Listeleri', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dark)),
            SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: AppColors.gray),
          ],
        ),
      ),
    );
  }

  // Çocuk Kulübü'ne şifresiz geçiş — header'daki isim satırının yanındaki
  // küçük butondan tetikleniyor (bkz. yukarıdaki _cocukKulubunePaneliGec).

  Widget _sinifOrtalamalariGorunum() {
    if (_sinifOrtYukleniyor) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator(color: AppColors.purple)));
    }
    if (_sinifOrtalamalari.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sinifOrtalamalariYukle());
      return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Yükleniyor...', style: TextStyle(color: AppColors.gray))));
    }
    final renkler = [
      const Color(0xFF6B4FE8), const Color(0xFF3D2B8E), const Color(0xFF009688),
      const Color(0xFF2196F3), const Color(0xFFFF9800), const Color(0xFFE91E8C),
      const Color(0xFF4CAF50), const Color(0xFF00838F),
    ];

    final seviyeler = _sinifOrtalamalari.map((s) => _seviyeCikar(s['sinifi'] as String)).toSet().toList()..sort();
    _sinifOrtSeciliSeviye ??= seviyeler.isNotEmpty ? seviyeler.first : null;

    final gosterilenler = _sinifOrtSeciliSeviye == null
        ? <dynamic>[]
        : _sinifOrtalamalari.where((s) => _seviyeCikar(s['sinifi'] as String) == _sinifOrtSeciliSeviye).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Expanded(child: Text('SINIF LGS ORTALAMALARI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1))),
          if (_sonSinavAdi.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(_sonSinavAdi, style: const TextStyle(fontSize: 10, color: AppColors.purple, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 12),

        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: seviyeler.map((sv) {
              final secili = _sinifOrtSeciliSeviye == sv;
              return GestureDetector(
                onTap: () => setState(() => _sinifOrtSeciliSeviye = sv),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: secili ? AppColors.purple : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                  ),
                  child: Text('$sv. Sınıf', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: secili ? Colors.white : AppColors.gray)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        if (gosterilenler.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Bu seviyede şube yok', style: TextStyle(color: AppColors.gray))))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gosterilenler.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05,
            ),
            itemBuilder: (context, i) {
              final s = gosterilenler[i];
              final ort = (s['ortalama'] as num).toDouble();
              final renk = renkler[i % renkler.length];
              final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : null;
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OgretmenSinifDetay(sinif: s['sinifi']))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [renk, renk.withOpacity(0.75)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: renk.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(s['sinifi'], style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                        ),
                        if (medal != null) Text(medal, style: const TextStyle(fontSize: 20)),
                      ]),
                      const Spacer(),
                      Text(ort.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      Text('LGS Ortalaması', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
                        child: Text('${s['ogrencisayisi']} öğrenci', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _seviyeCikar(String sinifi) {
    final parcalar = sinifi.split('/');
    return parcalar.isNotEmpty ? parcalar[0] : sinifi;
  }

  Widget _genelIstatistikGorunum() {
    if (_ogrenciler.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('Veri yok', style: TextStyle(color: AppColors.gray))));
    final lgsler = _ogrenciler.map((o) => (o['sonLgs'] as num?)?.toDouble() ?? 0.0).toList();
    final enYuksek = lgsler.reduce((a, b) => a > b ? a : b);
    final enDusuk = lgsler.reduce((a, b) => a < b ? a : b);

    final seviyeler = _siniflar.map(_seviyeCikar).toSet().toList()..sort();
    _seciliSeviye ??= seviyeler.isNotEmpty ? seviyeler.first : null;

    final seviyeOgrencileri = _seciliSeviye == null
        ? <dynamic>[]
        : (_ogrenciler.where((o) => _seviyeCikar(o['sinifi'] ?? '') == _seciliSeviye).toList()
      ..sort((a, b) => ((b['sonLgs'] as num?)?.toDouble() ?? 0).compareTo((a['sonLgs'] as num?)?.toDouble() ?? 0)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 10)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OKUL GENEL ÖZETİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8, mainAxisSpacing: 8,
                childAspectRatio: 2,
                children: [
                  _istatKart('Öğrenci', '${_ogrenciler.length}', AppColors.purple),
                  _istatKart('LGS Ort.', (lgsler.reduce((a, b) => a + b) / lgsler.length).toStringAsFixed(1), AppColors.blue),
                  _istatKart('En Yüksek', enYuksek.toStringAsFixed(0), AppColors.green),
                  _istatKart('En Düşük', enDusuk.toStringAsFixed(0), AppColors.red),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('SINIF SEVİYESİNE GÖRE İLK 20', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: seviyeler.map((sv) {
              final secili = _seciliSeviye == sv;
              return GestureDetector(
                onTap: () => setState(() => _seciliSeviye = sv),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: secili ? AppColors.purple : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                  ),
                  child: Text('$sv. Sınıf', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: secili ? Colors.white : AppColors.gray)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        if (seviyeOgrencileri.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Bu seviyede öğrenci yok', style: TextStyle(color: AppColors.gray))))
        else
          ...seviyeOgrencileri.take(20).toList().asMap().entries.map((e) {
            final medals = ['🥇', '🥈', '🥉'];
            final rozet = e.key < 3 ? medals[e.key] : '${e.key + 1}.';
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OgretmenOgrenciDetay(ogrenci: e.value))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                child: Row(children: [
                  SizedBox(width: 32, child: Text(rozet, style: TextStyle(fontSize: e.key < 3 ? 17 : 13, fontWeight: FontWeight.w800, color: e.key < 3 ? null : AppColors.gray))),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.value['adisoyadi'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                    Text(e.value['sinifi'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  ])),
                  Text('${(e.value['sonLgs'] as num?)?.toStringAsFixed(0) ?? '-'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.purple)),
                ]),
              ),
            );
          }),
      ],
    );
  }

  Widget _istatKart(String label, String deger, Color renk) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: renk.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(deger, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: renk)),
        Text(label, style: TextStyle(fontSize: 10, color: renk, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _statKutu(String label, String deger) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(children: [
          Text(deger, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 9), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ════════════ SINIFLAR ════════════
  Widget _siniflarTab() {
    if (_yukleniyor) return const Center(child: CircularProgressIndicator(color: AppColors.purple));

    final seviyeler = _siniflar.map(_seviyeCikar).toSet().toList()..sort();
    _siniflarSeciliSeviye ??= seviyeler.isNotEmpty ? seviyeler.first : null;

    final gosterilenSiniflar = _siniflarSeciliSeviye == null
        ? <String>[]
        : _siniflar.where((s) => _seviyeCikar(s) == _siniflarSeciliSeviye).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('SINIFLAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 2)),
                SizedBox(height: 4),
                Text('Sınıf Listesi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: seviyeler.map((sv) {
                final secili = _siniflarSeciliSeviye == sv;
                return GestureDetector(
                  onTap: () => setState(() => _siniflarSeciliSeviye = sv),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: secili ? AppColors.purple : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                    ),
                    child: Center(
                      child: Text('$sv. Sınıf', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: secili ? Colors.white : AppColors.gray)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (gosterilenSiniflar.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('Bu seviyede şube yok', style: TextStyle(color: AppColors.gray))),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                final sinif = gosterilenSiniflar[i];
                final ogrOfSinif = _ogrenciler.where((o) => o['sinifi'] == sinif).toList();
                final lgsler = ogrOfSinif.map((o) => (o['sonLgs'] as num?)?.toDouble() ?? 0.0).toList();
                final ort = lgsler.isEmpty ? 0.0 : lgsler.reduce((a, b) => a + b) / lgsler.length;
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OgretmenSinifDetay(sinif: sinif))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.06), blurRadius: 10)]),
                    child: Row(children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.purpleL, AppColors.purple]), borderRadius: BorderRadius.circular(14)),
                        child: Center(child: Text(sinif, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text('$sinif Şubesi', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(ort.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.purple)),
                        const Text('LGS Ort.', style: TextStyle(fontSize: 9, color: AppColors.gray)),
                      ]),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: AppColors.gray),
                    ]),
                  ),
                );
              }, childCount: gosterilenSiniflar.length),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  // ════════════ ARAMA ════════════
  Widget _aramaTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 54, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ARA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 2)),
                const SizedBox(height: 4),
                const Text('Öğrenci Ara', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                  child: TextField(
                    controller: _aramaCtrl,
                    decoration: const InputDecoration(
                      hintText: 'İsim, soyisim veya okul numarası...',
                      prefixIcon: Icon(Icons.search, color: AppColors.gray),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (v) { setState(() => _aramaMetni = v); _ara(v); },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: _aramaSonucSliver(),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _aramaSonucSliver() {
    if (_aramaYukleniyor) {
      return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: AppColors.purple))));
    }
    if (_aramaMetni.length < 2) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(padding: EdgeInsets.all(30), child: Column(children: [
          Text('🔍', style: TextStyle(fontSize: 44)),
          SizedBox(height: 12),
          Text('Öğrenci Ara', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
          SizedBox(height: 4),
          Text('En az 2 karakter girin — isim veya numara', style: TextStyle(color: AppColors.gray), textAlign: TextAlign.center),
        ]))),
      );
    }
    if (_aramaListesi.isEmpty) {
      return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(30), child: Text('Sonuç bulunamadı', style: TextStyle(color: AppColors.gray)))));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, i) => _ogrenciKart(_aramaListesi[i], i + 1),
        childCount: _aramaListesi.length,
      ),
    );
  }

  Widget _ogrenciKart(dynamic ogr, int sira) {
    final lgs = (ogr['sonLgs'] as num?)?.toStringAsFixed(0) ?? '-';
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OgretmenOgrenciDetay(ogrenci: ogr))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.purple.withOpacity(0.15), AppColors.purple.withOpacity(0.08)]), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('$sira', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purple))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ogr['adisoyadi'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
            Text('${ogr['sinifi']} • No: ${ogr['numarasi']}', style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w600)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(lgs, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.purple)),
            const Text('LGS', style: TextStyle(fontSize: 9, color: AppColors.gray)),
          ]),
        ]),
      ),
    );
  }

  // ════════════ PROFİL ════════════
  Widget _profilTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 60),
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15), border: Border.all(color: Colors.white, width: 3)),
                child: const Center(child: Text('👨‍🏫', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 12),
              Text(widget.oturum['adisoyadi'] ?? 'Öğretmen', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const Text('Öğretmen', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.06), blurRadius: 12)]),
                    child: Column(children: [
                      _profilSatir('🔑', 'Şifre Değiştir', '', onTap: _sifreDegistirDialog),
                      const Divider(color: AppColors.lightGray, height: 1),
                      _profilSatir('🚪', 'Çıkış Yap', '', tehlike: true, onTap: _cikisOnayla),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Center(child: Text('SMK Sonuç v1.0.0', style: TextStyle(color: AppColors.gray, fontSize: 11))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cikisOnayla() {
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
                    onPressed: () { Navigator.pop(ctx); _cikis(); },
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

  // ── Şifre Değiştir diyaloğu ──
  void _sifreDegistirDialog() {
    final eski = TextEditingController();
    final yeni = TextEditingController();
    final yeniTekrar = TextEditingController();
    String hata = '';
    bool yukleniyor = false;
    bool eskiGizli = true, yeniGizli = true, yeniTekrarGizli = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔑', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text('Şifre Değiştir', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: eski,
                    obscureText: eskiGizli,
                    decoration: InputDecoration(
                      hintText: 'Mevcut şifre',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(eskiGizli ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.gray),
                        onPressed: () => setSt(() => eskiGizli = !eskiGizli),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: yeni,
                    obscureText: yeniGizli,
                    decoration: InputDecoration(
                      hintText: 'Yeni şifre (en az 6 karakter)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(yeniGizli ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.gray),
                        onPressed: () => setSt(() => yeniGizli = !yeniGizli),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: yeniTekrar,
                    obscureText: yeniTekrarGizli,
                    decoration: InputDecoration(
                      hintText: 'Yeni şifre (tekrar)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(yeniTekrarGizli ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.gray),
                        onPressed: () => setSt(() => yeniTekrarGizli = !yeniTekrarGizli),
                      ),
                    ),
                  ),
                  if (hata.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(hata, style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                      child: TextButton(
                        onPressed: yukleniyor ? null : () => Navigator.pop(ctx),
                        child: const Text('Vazgeç', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: yukleniyor ? null : () async {
                          if (eski.text.isEmpty) { setSt(() => hata = 'Mevcut şifreni gir'); return; }
                          if (yeni.text.length < 6) { setSt(() => hata = 'Yeni şifre en az 6 karakter olmalı'); return; }
                          if (yeni.text != yeniTekrar.text) { setSt(() => hata = 'Yeni şifreler eşleşmiyor'); return; }

                          setSt(() { yukleniyor = true; hata = ''; });
                          final r = await ApiService.ogretmenSifreBelirle(
                            tcno: widget.oturum['tcno']!,
                            eskiSifre: eski.text.trim(),
                            yeniSifre: yeni.text.trim(),
                          );
                          if (r['basari'] == true) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Şifren başarıyla güncellendi')),
                              );
                            }
                          } else {
                            setSt(() { yukleniyor = false; hata = r['mesaj'] ?? 'İşlem başarısız'; });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple, foregroundColor: Colors.white,
                          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: yukleniyor
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profilSatir(String icon, String label, String alt, {VoidCallback? onTap, bool tehlike = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: tehlike ? AppColors.red.withOpacity(0.1) : AppColors.purple.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tehlike ? AppColors.red : AppColors.dark)),
            if (alt.isNotEmpty) Text(alt, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.gray),
        ]),
      ),
    );
  }
}