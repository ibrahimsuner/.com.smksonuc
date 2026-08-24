import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';
import '../../models/sinav_model.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../login_screen.dart';
import 'ogrenci_istatistik.dart';
import 'ogrenci_basarilar.dart';
import 'ogrenci_profil.dart';
import 'sinav_detay.dart';

// ════════════ SABITLER ════════════
const kPrimaryDark   = Color(0xFF1E1B4B);
const kPrimary       = Color(0xFF312E81);
const kPrimaryLight  = Color(0xFF4338CA);
const kBg            = Color(0xFFF4F6FB);
const kCardBg        = Colors.white;
const kGray          = Color(0xFF8892A4);
const kLightGray     = Color(0xFFEEF0F7);
const kDark          = Color(0xFF1E1E2E);
const kGreen         = Color(0xFF22C55E);
const kRed           = Color(0xFFEF4444);
const kYellow        = Color(0xFFFBBF24);

// Header için ayrı, daha koyu ve doygun bir palet.
// Eski gradyan çok açık tonlarla başlayıp üstüne blur + opak beyaz
// daireler + büyük/opak gölgeler eklendiği için "soluk beyaz sis"
// etkisi oluşuyordu. Bu palet daha koyu/doygun, kontrast daha yüksek.
const kHeaderStart = Color(0xFF2D2A7A);
const kHeaderMid   = Color(0xFF3730A3);
const kHeaderEnd   = Color(0xFF14123A);

// ════════════ SAYI ANİMASYONU ════════════
class AnimatedNumber extends StatefulWidget {
  final double value;
  final int decimals;
  final TextStyle style;
  final Duration duration;
  const AnimatedNumber({super.key, required this.value, this.decimals = 0, required this.style, this.duration = const Duration(milliseconds: 1500)});

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}
class _AnimatedNumberState extends State<AnimatedNumber> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _a = Tween<double>(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Text(
      widget.decimals > 0 ? _a.value.toStringAsFixed(widget.decimals) : _a.value.toInt().toString(),
      style: widget.style,
    ),
  );
}

// ════════════ GLASS KUTU ════════════
// useBlur=false: statik/koyu arka planların üstünde blur gereksiz ve
// netliği düşürüyor. Sadece gerçekten hareketli/kaydırılan içeriğin
// üstünde (ör. bottom sheet arkası) blur kullanılmalı.
class GlassBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double opacity, borderRadius, blur;
  final bool useBlur;
  const GlassBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.opacity = 0.18,
    this.borderRadius = 16,
    this.blur = 12,
    this.useBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.2),
      ),
      child: child,
    );

    if (!useBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}

// ════════════ ANA SAYFA ════════════
class OgrenciAnaSayfa extends StatefulWidget {
  final Map<String, String> oturum;
  const OgrenciAnaSayfa({super.key, required this.oturum});
  @override State<OgrenciAnaSayfa> createState() => _OgrenciAnaSayfaState();
}

class _OgrenciAnaSayfaState extends State<OgrenciAnaSayfa> {
  int _sekme = 0;
  List<SinavModel> _sinavlar = [];
  bool _yukleniyor = true;
  String _hata = '';

  @override void initState() { super.initState(); _yukle(); }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = ''; });
    final r = await ApiService.ogrenciSinavlar(widget.oturum['tcno']!);
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) { _sinavlar = r['sinavlar']; }
      else { _hata = r['mesaj']; }
      _yukleniyor = false;
    });
  }

  Future<void> _cikis() async {
    await SessionService.oturumSil();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // ÖNEMLİ: Sadece standart (sinavTuru == 'lgs') sınavlar LGS trendine
  // dahil ediliyor — bursluluk gibi farklı formatlı sınavlar farklı bir
  // ölçekte olabileceği için LGS puanı düşüş/yükseliş tespitine hiç
  // katılmıyor.
  String get _lgsTrend {
    final lgsFormatli = _sinavlar.where((s) => s.sinavTuru == 'lgs').toList();
    if (lgsFormatli.length < 3) return 'yetersiz';
    final s = lgsFormatli.reversed.take(3).toList().reversed.toList();
    if (s[2].lgs < s[1].lgs && s[1].lgs < s[0].lgs) return 'dususte';
    if (s[2].lgs > s[1].lgs && s[1].lgs > s[0].lgs) return 'yukseliste';
    return 'dengeli';
  }

  // ÖNEMLİ: O dersten SORU SORULMAYAN sınavlar (bursluluk vb.) bu
  // dersin trend hesabından tamamen çıkarılıyor. Kalan sınavlar ORAN
  // (net / soru sayısı) üzerinden kıyaslanıyor.
  List<Map<String,dynamic>> get _dusenDersler {
    const dersler = [
      {'key':'turkce','ad':'Türkçe','icon':'📖'},
      {'key':'sosyal','ad':'Sosyal','icon':'🌍'},
      {'key':'din','ad':'Din','icon':'☪️'},
      {'key':'ing','ad':'İngilizce','icon':'🌐'},
      {'key':'mat','ad':'Matematik','icon':'🔢'},
      {'key':'fen','ad':'Fen','icon':'🔬'},
    ];
    return dersler.where((d) {
      final key = d['key']!;
      final gecerli = _sinavlar.where((s) => _soru(s, key) > 0).toList();
      if (gecerli.length < 3) return false;
      final oranlar = gecerli.map((s) => _net(s, key) / _soru(s, key)).toList();
      final son3 = oranlar.sublist(oranlar.length - 3);
      return son3[0] > son3[1] && son3[1] > son3[2];
    }).toList();
  }

  int _soru(SinavModel s, String k) {
    switch (k) {
      case 'turkce': return s.turkceSoru;
      case 'sosyal': return s.sosSoru;
      case 'din': return s.dinSoru;
      case 'ing': return s.ingSoru;
      case 'mat': return s.matSoru;
      case 'fen': return s.fenSoru;
      default: return 0;
    }
  }

  double _net(SinavModel s, String k) {
    switch (k) {
      case 'turkce': return s.turkcen;
      case 'sosyal': return s.sosn;
      case 'din': return s.dinn;
      case 'ing': return s.ingn;
      case 'mat': return s.matn;
      case 'fen': return s.fenn;
      default: return 0;
    }
  }

  void _detay(SinavModel s) => Navigator.push(context, PageRouteBuilder(
    pageBuilder: (_, a, __) => SinavDetay(sinav: s),
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1,0), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ));

  @override
  Widget build(BuildContext context) {
    // Status bar her zaman şeffaf kalsın
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: kBg,
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: _sekme,
        children: [
          _AnaSayfa(
            oturum: widget.oturum, sinavlar: _sinavlar,
            yukleniyor: _yukleniyor, hata: _hata,
            lgsTrend: _lgsTrend, dusenDersler: _dusenDersler,
            onYenile: _yukle, onDetay: _detay,
          ),
          OgrenciIstatistik(sinavlar: _sinavlar, yukleniyor: _yukleniyor, tcno: widget.oturum['tcno'] ?? ''),
          OgrenciBasarilar(sinavlar: _sinavlar),
          OgrenciProfil(oturum: widget.oturum, onCikis: _cikis),
        ],
      ),
      bottomNavigationBar: _BottomNav(aktif: _sekme, onTap: (i) => setState(() => _sekme = i)),
    );
  }
}

// ════════════ BOTTOM NAV ════════════
class _BottomNav extends StatelessWidget {
  final int aktif;
  final Function(int) onTap;
  const _BottomNav({required this.aktif, required this.onTap});

  static const _items = [
    {'icon': Icons.home_rounded, 'label': 'Ana Sayfa'},
    {'icon': Icons.bar_chart_rounded, 'label': 'İstatistik'},
    {'icon': Icons.emoji_events_rounded, 'label': 'Başarılar'},
    {'icon': Icons.person_rounded, 'label': 'Profil'},
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0,-4))],
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: _items.asMap().entries.map((e) {
            final i = e.key; final item = e.value; final act = aktif == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: act ? 52 : 40, height: 32,
                    decoration: BoxDecoration(
                      color: act ? kPrimaryLight.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item['icon'] as IconData, color: act ? kPrimaryLight : kGray, size: act ? 24 : 22),
                  ),
                  const SizedBox(height: 3),
                  Text(item['label'] as String, style: TextStyle(fontSize: 10, fontWeight: act ? FontWeight.w800 : FontWeight.w500, color: act ? kPrimaryLight : kGray)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}

// ════════════ ANA SAYFA İÇERİĞİ ════════════
class _AnaSayfa extends StatelessWidget {
  final Map<String,String> oturum;
  final List<SinavModel> sinavlar;
  final bool yukleniyor;
  final String hata, lgsTrend;
  final List<Map<String,dynamic>> dusenDersler;
  final Future<void> Function() onYenile;
  final Function(SinavModel) onDetay;

  const _AnaSayfa({
    required this.oturum, required this.sinavlar, required this.yukleniyor,
    required this.hata, required this.lgsTrend, required this.dusenDersler,
    required this.onYenile, required this.onDetay,
  });

  int get _uyariSayisi => (lgsTrend == 'dususte' ? 1 : 0) + dusenDersler.length;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onYenile, color: kPrimaryLight,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header - edge to edge ──
          SliverToBoxAdapter(child: _Header(
            oturum: oturum, sinavlar: sinavlar,
            uyariSayisi: _uyariSayisi, lgsTrend: lgsTrend, dusenDersler: dusenDersler,
          )),
          if (yukleniyor)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kPrimaryLight)))
          else if (hata.isNotEmpty)
            SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('😔', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(hata, style: const TextStyle(color: kGray), textAlign: TextAlign.center)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onYenile, style: ElevatedButton.styleFrom(backgroundColor: kPrimaryLight, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Tekrar Dene')),
            ])))
          else if (sinavlar.isEmpty)
              const SliverFillRemaining(child: Center(child: Text('Henüz sınav kaydı yok', style: TextStyle(color: kGray))))
            else ...[
                SliverToBoxAdapter(child: _SonSinavKarti(sinav: sinavlar.last, onceki: sinavlar.length > 1 ? sinavlar[sinavlar.length-2] : null, onDetay: () => onDetay(sinavlar.last))),
                SliverToBoxAdapter(child: _OncekiSinavlar(sinavlar: sinavlar, onDetay: onDetay)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
        ],
      ),
    );
  }
}

// ════════════ HEADER ════════════
class _Header extends StatelessWidget {
  final Map<String,String> oturum;
  final List<SinavModel> sinavlar;
  final int uyariSayisi;
  final String lgsTrend;
  final List<Map<String,dynamic>> dusenDersler;

  const _Header({required this.oturum, required this.sinavlar, required this.uyariSayisi, required this.lgsTrend, required this.dusenDersler});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [kHeaderStart, kHeaderMid, kHeaderEnd],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        // Eski gölge (blurRadius 20+, opacity yüksek) kartın dışına
        // taşarak beyaz/soluk bir hale oluşturuyordu. Burada tek,
        // sıkı ve düşük opaklıklı bir gölge yeterli.
        boxShadow: [
          BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      // Stack'i ClipRRect ile sınırlıyoruz ki dekoratif daireler
      // köşelerden taşıp kenarlarda bulanık/beyazımsı bir kenarlık
      // oluşturmasın.
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: Stack(children: [
          // Dekoratif daireler — opaklık ciddi düşürüldü, artık
          // rengi soluklaştırmıyor, sadece hafif bir doku katıyor.
          Positioned(top: -50, right: -30, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.025)))),
          Positioned(bottom: -20, left: -20, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.02)))),
          Positioned(top: 80, right: 80, child: Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.025)))),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
            child: Column(children: [
              // Öğrenci bilgisi + uyarı butonu
              Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0,4))],
                  ),
                  child: const Center(child: Text('🎒', style: TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    oturum['adisoyadi'] ?? '',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0,1))],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('Şube: ${oturum['sube']} • No: ${oturum['no']}',
                      style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 13, fontWeight: FontWeight.w500)),
                ])),
                // Uyarı butonu
                GestureDetector(
                  onTap: () => _uyariGoster(context),
                  child: uyariSayisi > 0
                      ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFB71C1C)]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: kRed.withOpacity(0.45), blurRadius: 10, offset: const Offset(0,3))],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                      const SizedBox(width: 6),
                      Text('$uyariSayisi Uyarı', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ]),
                  )
                      : GlassBox(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    opacity: 0.2, borderRadius: 30,
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('✅', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text('Yolunda', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),

              // İstatistik kutuları
              if (sinavlar.isNotEmpty) ...[
                const SizedBox(height: 22),
                Row(children: [
                  _GlassStat('Toplam\nSınav', sinavlar.length.toDouble(), 0),
                  const SizedBox(width: 8),
                  _GlassStat('En Yüksek\nLGS', sinavlar.map((s)=>s.lgs).reduce((a,b)=>a>b?a:b), 0),
                  const SizedBox(width: 8),
                  _GlassStat('Ort.\nNet', sinavlar.map((s)=>s.ton).reduce((a,b)=>a+b)/sinavlar.length, 1),
                  const SizedBox(width: 8),
                  _GlassStat('🇹🇷\nSıra', sinavlar.last.dereceg.toDouble(), 0),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  void _uyariGoster(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _UyariPanel(lgsTrend: lgsTrend, dusenDersler: dusenDersler, sinavlar: sinavlar),
    );
  }
}

// Blur kaldırıldı: statik koyu gradyanın üstünde blur yalnızca
// netliği düşürüp beyazımsı bir katman hissi veriyordu. Kontrast
// (opacity 0.14 → 0.22, border 0.22 → 0.35) artırıldı, ince bir
// gölge eklendi — cam hissi blur olmadan da korunuyor.
class _GlassStat extends StatelessWidget {
  final String label;
  final double value;
  final int decimals;
  const _GlassStat(this.label, this.value, this.decimals);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        AnimatedNumber(
          value: value, decimals: decimals,
          style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 9, fontWeight: FontWeight.w700, height: 1.3), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ════════════ SON SINAV KARTI ════════════
class _SonSinavKarti extends StatelessWidget {
  final SinavModel sinav;
  final SinavModel? onceki;
  final VoidCallback onDetay;
  const _SonSinavKarti({required this.sinav, this.onceki, required this.onDetay});

  @override
  Widget build(BuildContext context) {
    final fark = onceki != null ? sinav.lgs - onceki!.lgs : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('SON SINAV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGray, letterSpacing: 2))),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [kHeaderMid, kPrimary, kHeaderEnd], stops: [0.0, 0.5, 1.0]),
            borderRadius: BorderRadius.circular(28),
            // Eski gölge (blurRadius 28, opacity 0.55) çok geniş ve
            // opaktı; kartın etrafında yaygın bir beyaz/mor bulanıklık
            // yaratıyordu. Sıkı ve daha düşük opaklıklı tek gölgeye
            // indirildi.
            boxShadow: [
              BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(children: [
              Positioned(top:-20, right:-10, child: Container(width:130, height:130, decoration: BoxDecoration(shape:BoxShape.circle, color:Colors.white.withOpacity(0.03)))),
              Column(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Son Sınav', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 10, letterSpacing: 2.5)),
                    const SizedBox(height: 4),
                    Text(sinav.sinavadi, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(sinav.sinavtarihi, style: TextStyle(color: Colors.white.withOpacity(0.58), fontSize: 11)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('LGS Puanı', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
                    AnimatedNumber(value: sinav.lgs, decimals: 2, style: const TextStyle(
                      color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0,2))],
                    )),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: fark >= 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: fark >= 0 ? kGreen.withOpacity(0.5) : kRed.withOpacity(0.5)),
                      ),
                      child: Text(
                        '${fark >= 0 ? "▲" : "▼"} ${fark.abs().toStringAsFixed(2)} puan',
                        style: TextStyle(color: fark >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF6B6B), fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ]),
                ]),
                const SizedBox(height: 18),
                // D/Y/Net
                Row(children: [
                  _DYKutu('Top. Doğru', sinav.tod.toDouble(), 0, const Color(0xFF69F0AE)),
                  const SizedBox(width: 8),
                  _DYKutu('Top. Yanlış', sinav.toy.toDouble(), 0, const Color(0xFFFF6B6B)),
                  const SizedBox(width: 8),
                  _DYKutu('Top. Net', sinav.ton, 2, const Color(0xFFFFD54F)),
                ]),
                const SizedBox(height: 10),
                // Sıralamalar
                Row(children: [
                  _SiraKutu('Sınıf', sinav.dereces.toDouble()),
                  _SiraKutu('Okul', sinav.dereceo.toDouble()),
                  _SiraKutu('İlçe', sinav.dereceilce.toDouble()),
                  _SiraKutu('İl', sinav.dereceil.toDouble()),
                  _SiraKutu('🇹🇷', sinav.dereceg.toDouble()),
                ]),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDetay,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryLight, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 6, shadowColor: kPrimary.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Son Sınav Detaylı Analizi →', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          ),
        ),
      ]),
    );
  }
}

// Blur kaldırıldı — koyu gradyan kartın üstünde blur sadece
// bulanıklaştırıyordu; kontrast artırılarak (opacity 0.1 → 0.14,
// border 0.15 → 0.2) aynı "cam" his blur olmadan korunuyor.
class _DYKutu extends StatelessWidget {
  final String label; final double value; final int decimals; final Color renk;
  const _DYKutu(this.label, this.value, this.decimals, this.renk);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: Column(children: [
      AnimatedNumber(value: value, decimals: decimals, style: TextStyle(color: renk, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
    ]),
  ));
}

class _SiraKutu extends StatelessWidget {
  final String label; final double value;
  const _SiraKutu(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    margin: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.16)),
    ),
    child: Column(children: [
      AnimatedNumber(value: value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      const SizedBox(height: 1),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9)),
    ]),
  ));
}

// ════════════ ÖNCEKİ SINAVLAR ════════════
class _OncekiSinavlar extends StatelessWidget {
  final List<SinavModel> sinavlar;
  final Function(SinavModel) onDetay;
  const _OncekiSinavlar({required this.sinavlar, required this.onDetay});

  static const List<Color> _renkler = [Color(0xFF4338CA), Color(0xFFE91E8C), Color(0xFF009688), Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFF4CAF50)];
  static const List<double> _maxlar = [20, 20, 10, 10, 20, 20];

  List<double> _netler(SinavModel s) => [s.turkcen, s.sosn, s.dinn, s.ingn, s.matn, s.fenn];

  @override
  Widget build(BuildContext context) {
    final liste = sinavlar.reversed.skip(1).toList();
    if (liste.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('ÖNCEKİ SINAVLAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGray, letterSpacing: 2))),
        ...liste.asMap().entries.map((e) {
          final i = e.key; final s = e.value;
          final idx = sinavlar.indexOf(s);
          final prev = idx > 0 ? sinavlar[idx-1] : null;
          final fark = prev != null ? s.lgs - prev.lgs : 0.0;
          final netler = _netler(s);
          return _AnimatedKart(
            delay: i * 80,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: kPrimary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0,4)),
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
                ],
              ),
              child: Material(
                color: Colors.transparent, borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onDetay(s),
                  splashColor: kPrimaryLight.withOpacity(0.08),
                  highlightColor: kPrimaryLight.withOpacity(0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(children: [
                      // Numara
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [kPrimaryLight.withOpacity(0.12), kPrimary.withOpacity(0.06)]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kPrimaryLight.withOpacity(0.15)),
                        ),
                        child: Center(child: Text('${idx+1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kPrimaryLight))),
                      ),
                      const SizedBox(width: 12),
                      // Bilgi + barlar
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.sinavadi, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDark)),
                        const SizedBox(height: 2),
                        Text(s.sinavtarihi, style: const TextStyle(fontSize: 11, color: kGray)),
                        const SizedBox(height: 9),
                        _AnimatedBarlar(netler: netler, renkler: _renkler, maxlar: _maxlar, delay: i*80),
                      ])),
                      const SizedBox(width: 12),
                      // Puan + detay
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(s.lgs.toStringAsFixed(0), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimaryLight)),
                        if (fark != 0) ...[
                          const SizedBox(height: 2),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(fark >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                color: fark >= 0 ? kGreen : kRed, size: 12),
                            Text(fark.abs().toStringAsFixed(1),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fark >= 0 ? kGreen : kRed)),
                          ]),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [kPrimaryLight, kPrimary]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: kPrimaryLight.withOpacity(0.3), blurRadius: 5, offset: const Offset(0,2))],
                          ),
                          child: const Text('Detay →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ]),
    );
  }
}

// ════════════ ANİMASYONLU KART WRAPPER ════════════
class _AnimatedKart extends StatefulWidget {
  final Widget child; final int delay;
  const _AnimatedKart({required this.child, required this.delay});
  @override State<_AnimatedKart> createState() => _AnimatedKartState();
}
class _AnimatedKartState extends State<_AnimatedKart> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child));
}

// ════════════ ANİMASYONLU DERS BARLARI ════════════
class _AnimatedBarlar extends StatefulWidget {
  final List<double> netler;
  final List<Color> renkler;
  final List<double> maxlar;
  final int delay;
  const _AnimatedBarlar({required this.netler, required this.renkler, required this.maxlar, required this.delay});
  @override State<_AnimatedBarlar> createState() => _AnimatedBarlarState();
}
class _AnimatedBarlarState extends State<_AnimatedBarlar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _a = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay + 200), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Row(
      children: List.generate(widget.netler.length, (i) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          height: 5,
          decoration: BoxDecoration(color: kLightGray, borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            widthFactor: ((widget.netler[i] / widget.maxlar[i]) * _a.value).clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: widget.renkler[i], borderRadius: BorderRadius.circular(3),
                boxShadow: [BoxShadow(color: widget.renkler[i].withOpacity(0.5), blurRadius: 4)],
              ),
            ),
          ),
        ),
      )),
    ),
  );
}

// ════════════ UYARI PANELİ ════════════
class _UyariPanel extends StatelessWidget {
  final String lgsTrend;
  final List<Map<String,dynamic>> dusenDersler;
  final List<SinavModel> sinavlar;
  const _UyariPanel({required this.lgsTrend, required this.dusenDersler, required this.sinavlar});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, decoration: BoxDecoration(color: kLightGray, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 18),
      Row(children: [
        Container(width: 48, height: 48,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [kRed.withOpacity(0.25), kRed.withOpacity(0.1)]), borderRadius: BorderRadius.circular(15)),
            child: const Center(child: Text('🚨', style: TextStyle(fontSize: 24)))),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Performans Uyarıları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kDark)),
          Text('Son 3 sınav bazlı otomatik analiz', style: TextStyle(fontSize: 12, color: kGray)),
        ]),
      ]),
      const SizedBox(height: 16),
      if (lgsTrend == 'dususte')
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kRed.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Text('📉', style: TextStyle(fontSize: 18)), SizedBox(width: 8), Text('LGS Puanı Sürekli Düşüyor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kDark))]),
            const SizedBox(height: 6),
            const Text('Son 3 sınavda kesintisiz düşüş.', style: TextStyle(fontSize: 12, color: kGray)),
            const SizedBox(height: 10),
            Row(children: sinavlar.where((s) => s.sinavTuru == 'lgs').toList().reversed.take(3).toList().reversed.toList().asMap().entries.map((e) => Expanded(child: Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: e.key == 2 ? kRed.withOpacity(0.1) : kBg, borderRadius: BorderRadius.circular(10),
                  border: e.key == 2 ? Border.all(color: kRed.withOpacity(0.4)) : null,
                ),
                child: Column(children: [
                  Text(e.value.lgs.toStringAsFixed(0), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: e.key == 2 ? kRed : kDark)),
                  Text('${e.key+1}.S', style: const TextStyle(fontSize: 9, color: kGray)),
                ]),
              )),
              if (e.key < 2) const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('↘', style: TextStyle(color: kRed, fontSize: 14))),
            ]))).toList()),
          ]),
        ),
      ...dusenDersler.map((d) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.orange.withOpacity(0.2))),
        child: Row(children: [
          Text(d['icon']!, style: const TextStyle(fontSize: 18)), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['ad']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const Text('Net puanında düşüş', style: TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
          ]),
        ]),
      )),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimaryLight, kPrimaryDark]), borderRadius: BorderRadius.circular(16)),
        child: const Row(children: [
          Text('💡', style: TextStyle(fontSize: 22)), SizedBox(width: 10),
          Expanded(child: Text('Öğretmeninizle görüşerek zayıf konuları birlikte belirleyin.', style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4))),
        ]),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: kLightGray, foregroundColor: kGray, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 8),
    ]),
  );
}