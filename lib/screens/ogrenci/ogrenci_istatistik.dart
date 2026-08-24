import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/sinav_model.dart';
import '../../models/sinif_ortalama_model.dart';
import '../../services/api_service.dart';
import 'ogrenci_ana_sayfa.dart' show kHeaderStart, kHeaderMid, kHeaderEnd, kPrimary, kPrimaryLight, kPrimaryDark, kGray, kLightGray, kDark, kGreen, kRed, AnimatedNumber;

// ════════════ FADE + SLIDE GİRİŞ SARMALAYICISI ════════════
// Ana sayfadaki _AnimatedKart ile aynı his — kartlar sırayla
// aşağıdan yukarı belirir.
class _FadeSlide extends StatefulWidget {
  final Widget child;
  final int delay;
  const _FadeSlide({required this.child, this.delay = 0});
  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ════════════ ANİMASYONLU DİKEY ÇUBUK (mini LGS grafiği) ════════════
class _AnimatedVBar extends StatefulWidget {
  final double heightFactor; // 0-1 arası, dış widget hesaplayıp veriyor
  final double maxHeight;
  final bool vurgulu;
  final int delay;
  const _AnimatedVBar({required this.heightFactor, required this.maxHeight, required this.vurgulu, this.delay = 0});
  @override
  State<_AnimatedVBar> createState() => _AnimatedVBarState();
}

class _AnimatedVBarState extends State<_AnimatedVBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _a = Tween<double>(begin: 0, end: widget.heightFactor).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      height: (widget.maxHeight * _a.value).clamp(4.0, widget.maxHeight),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: widget.vurgulu ? Colors.white : Colors.white.withOpacity(0.35),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    ),
  );
}

// ════════════ ANİMASYONLU YATAY MİNİ TREND ÇUBUĞU ════════════
class _AnimatedTrendBar extends StatefulWidget {
  final double widthFactor; // 0-1
  final double maxHeight;
  final Color color;
  final bool vurgulu;
  final int delay;
  const _AnimatedTrendBar({required this.widthFactor, required this.maxHeight, required this.color, required this.vurgulu, this.delay = 0});
  @override
  State<_AnimatedTrendBar> createState() => _AnimatedTrendBarState();
}

class _AnimatedTrendBarState extends State<_AnimatedTrendBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _a = Tween<double>(begin: 0, end: widget.widthFactor).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: 6,
      height: (widget.maxHeight * _a.value).clamp(4.0, widget.maxHeight),
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(widget.vurgulu ? 1 : 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

// ════════════ SEN vs SINIF — YATAY ÇİFT ÇUBUK ════════════
// Bir metrik için öğrencinin ve sınıfın değerini yan yana, animasyonlu
// iki çubukla karşılaştırır. Üstteki çubuk (renkli) = öğrenci,
// alttaki (gri) = sınıf ortalaması.
class _KiyasSatiri extends StatefulWidget {
  final String ad;
  final String icon;
  final double senDeger;
  final double sinifDeger;
  final double maxDeger;
  final int decimals;
  final Color renk;
  final int delay;
  const _KiyasSatiri({
    required this.ad,
    required this.icon,
    required this.senDeger,
    required this.sinifDeger,
    required this.maxDeger,
    required this.renk,
    this.decimals = 2,
    this.delay = 0,
  });

  @override
  State<_KiyasSatiri> createState() => _KiyasSatiriState();
}

class _KiyasSatiriState extends State<_KiyasSatiri> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final senFark = widget.senDeger - widget.sinifDeger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(widget.ad, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kDark)),
              const Spacer(),
              Text(
                '${senFark >= 0 ? "▲" : "▼"} ${senFark.abs().toStringAsFixed(widget.decimals)}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: senFark >= 0 ? kGreen : kRed),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _a,
            builder: (_, __) => Column(
              children: [
                Row(children: [
                  SizedBox(
                    width: 34,
                    child: Text('Sen', style: TextStyle(fontSize: 9, color: widget.renk, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (widget.senDeger / widget.maxDeger).clamp(0.0, 1.0) * _a.value,
                        backgroundColor: kLightGray,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.renk),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(widget.senDeger.toStringAsFixed(widget.decimals),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: widget.renk)),
                  ),
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  const SizedBox(
                    width: 34,
                    child: Text('Sınıf', style: TextStyle(fontSize: 9, color: kGray, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (widget.sinifDeger / widget.maxDeger).clamp(0.0, 1.0) * _a.value,
                        backgroundColor: kLightGray,
                        valueColor: const AlwaysStoppedAnimation<Color>(kGray),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(widget.sinifDeger.toStringAsFixed(widget.decimals),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kGray)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OgrenciIstatistik extends StatefulWidget {
  final List<SinavModel> sinavlar;
  final bool yukleniyor;
  final String tcno;

  const OgrenciIstatistik({
    super.key,
    required this.sinavlar,
    required this.yukleniyor,
    required this.tcno,
  });

  @override
  State<OgrenciIstatistik> createState() => _OgrenciIstatistikState();
}

class _OgrenciIstatistikState extends State<OgrenciIstatistik> {
  List<SinifOrtalamaModel> _ortalamalar = [];
  bool _ortalamaYukleniyor = true;

  @override
  void initState() {
    super.initState();
    _ortalamalariYukle();
  }

  Future<void> _ortalamalariYukle() async {
    if (widget.tcno.isEmpty) {
      setState(() => _ortalamaYukleniyor = false);
      return;
    }
    final r = await ApiService.sinifOrtalamalari(widget.tcno);
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _ortalamalar = r['ortalamalar'];
      }
      _ortalamaYukleniyor = false;
    });
  }

  // Sınıf ortalamasını sinavadi eşleşmesiyle bul.
  // NOT: sinif_ortalama.php artık her satırda öğrencinin GÜNCEL şubesini
  // döndürüyor, bu yüzden sadece sinavadi eşleşmesi yeterli ve doğru.
  SinifOrtalamaModel? _sinifBul(String sinavadi, String sinifi) {
    for (final o in _ortalamalar) {
      if (o.sinavadi == sinavadi) return o;
    }
    return null;
  }

  // "Sınıfınla Kıyaslama" bölümü hâlâ ham net kullanıyor (backend
  // sinif_ortalama.php henüz oran bazlı değil), bu yüzden o bölümün
  // çubuk ölçeği dersAnaliz'in (artık oran/1.0 olan) 'max' alanından
  // AYRI tutuluyor.
  double _kiyasMax(String ad) {
    switch (ad) {
      case 'Din':
      case 'İngilizce':
        return 10.0;
      default:
        return 20.0;
    }
  }

  double _net(SinavModel s, String key) {
    switch (key) {
      case 'turkce': return s.turkcen;
      case 'sosyal': return s.sosn;
      case 'din': return s.dinn;
      case 'ing': return s.ingn;
      case 'mat': return s.matn;
      case 'fen': return s.fenn;
      default: return 0;
    }
  }

  int _soru(SinavModel s, String key) {
    switch (key) {
      case 'turkce': return s.turkceSoru;
      case 'sosyal': return s.sosSoru;
      case 'din': return s.dinSoru;
      case 'ing': return s.ingSoru;
      case 'mat': return s.matSoru;
      case 'fen': return s.fenSoru;
      default: return 0;
    }
  }

  // O dersten SORU SORULMAYAN sınavları (bursluluk vb.) tamamen
  // dışarıda bırakıp, kalanları ORAN (net / soru sayısı) olarak
  // döndürür. Böylece farklı soru sayılı/formatlı sınavlar birbirine
  // karışmadan, adil şekilde kıyaslanabilir.
  List<double> _oranListesi(List<SinavModel> sinavlar, String key) {
    final gecerli = sinavlar.where((s) => _soru(s, key) > 0).toList();
    if (gecerli.isEmpty) return [];
    return gecerli.map((s) => _net(s, key) / _soru(s, key)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sinavlar = widget.sinavlar;
    final yukleniyor = widget.yukleniyor;
    if (yukleniyor) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryLight));
    }
    if (sinavlar.isEmpty) {
      return const Center(child: Text('Henüz sınav kaydı yok', style: TextStyle(color: kGray)));
    }

    // ÖNEMLİ: LGS puanı bazlı tüm hesaplamalar (genel özet kartları,
    // üstteki mini grafik, Türkiye sıralaması gelişimi) artık sadece
    // standart (sinavTuru == 'lgs') sınavları kapsıyor — bursluluk gibi
    // farklı formatlı sınavlar farklı bir ölçekte olabileceğinden bu
    // hesaplara hiç dahil edilmiyor.
    final lgsSinavlar = sinavlar.where((s) => s.sinavTuru == 'lgs').toList();
    final lgsVar = lgsSinavlar.isNotEmpty;
    final lgsData = lgsSinavlar.map((s) => s.lgs).toList();
    final enYuksek = lgsVar ? lgsData.reduce((a, b) => a > b ? a : b) : 0.0;
    final enDusuk = lgsVar ? lgsData.reduce((a, b) => a < b ? a : b) : 0.0;
    final ortalama = lgsVar ? lgsData.reduce((a, b) => a + b) / lgsData.length : 0.0;
    final ilkSon = lgsVar ? lgsData.last - lgsData.first : 0.0;

    // ÖNEMLİ: Ders bazlı gelişim artık ham net yerine ORAN (net / soru
    // sayısı) üzerinden hesaplanıyor; o dersten soru sorulmayan sınavlar
    // (bursluluk vb.) filtreleniyor. 'data' artık 0-1 arası bir oran
    // olduğu için 'max' da 1.0'a çekildi.
    final dersAnaliz = [
      {'ad': 'Türkçe', 'icon': '📖', 'color': kPrimary, 'data': _oranListesi(sinavlar, 'turkce'), 'max': 1.0},
      {'ad': 'Sosyal', 'icon': '🌍', 'color': AppColors.magenta, 'data': _oranListesi(sinavlar, 'sosyal'), 'max': 1.0},
      {'ad': 'Din', 'icon': '☪️', 'color': AppColors.teal, 'data': _oranListesi(sinavlar, 'din'), 'max': 1.0},
      {'ad': 'İngilizce', 'icon': '🌐', 'color': AppColors.blue, 'data': _oranListesi(sinavlar, 'ing'), 'max': 1.0},
      {'ad': 'Matematik', 'icon': '🔢', 'color': AppColors.orange, 'data': _oranListesi(sinavlar, 'mat'), 'max': 1.0},
      {'ad': 'Fen', 'icon': '🔬', 'color': kGreen, 'data': _oranListesi(sinavlar, 'fen'), 'max': 1.0},
    ];

    for (final d in dersAnaliz) {
      final data = d['data'] as List<double>;
      if (data.isEmpty) {
        // Bu öğrencinin bu dersten hiç soru sorulan sınavı yok (örn.
        // sadece bursluluk sınavına girdi) — güvenli varsayılan.
        d['fark'] = 0.0;
        d['ortalama'] = 0.0;
      } else {
        d['fark'] = data.last - data.first;
        d['ortalama'] = data.reduce((a, b) => a + b) / data.length;
      }
    }

    // Sınıf ortalaması eşleştirmesi: her sınav+sınıf çifti için o
    // sınavın sınıf ortalaması verisi varsa listeye ekleniyor. Eşleşme
    // yoksa (henüz backend'den veri gelmediyse ya da hata olduysa)
    // kıyaslama bölümü hiç gösterilmiyor, sayfanın geri kalanı
    // etkilenmiyor.
    final eslesenler = <MapEntry<SinavModel, SinifOrtalamaModel>>[];
    for (final s in sinavlar) {
      final o = _sinifBul(s.sinavadi, s.sinifi);
      if (o != null) eslesenler.add(MapEntry(s, o));
    }
    final kiyasVar = eslesenler.isNotEmpty;
    double _ort(Iterable<double> v) => v.isEmpty ? 0.0 : v.reduce((a, b) => a + b) / v.length;
    final senLgsOrt = kiyasVar ? _ort(eslesenler.map((e) => e.key.lgs)) : 0.0;
    final sinifLgsOrt = kiyasVar ? _ort(eslesenler.map((e) => e.value.lgs)) : 0.0;

    final enGelisen = dersAnaliz.reduce((a, b) => (a['fark'] as double) > (b['fark'] as double) ? a : b);
    final enGerileyen = dersAnaliz.reduce((a, b) => (a['fark'] as double) < (b['fark'] as double) ? a : b);

    final siraData = lgsSinavlar.map((s) => s.dereceg).toList();
    final siraFark = lgsVar ? siraData.first - siraData.last : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // Header — ana sayfayla aynı koyu/doygun palet
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [kHeaderStart, kHeaderMid, kHeaderEnd],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('İSTATİSTİK & ANALİZ', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, letterSpacing: 2)),
                const SizedBox(height: 4),
                const Text('Genel Gelişim Durumu', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                // Mini bar chart — yüksekliği içeriğe göre yeterli hale getirildi
                // (eskiden 60 sabitti, çubuk(50)+boşluk(4)+etiket(~11) toplamı
                // aşıp "BOTTOM OVERFLOWED" hatası veriyordu).
                if (lgsVar)
                  _miniBarChart(lgsData)
                else
                  Text('Henüz LGS formatlı sınav yok', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genel özet kartları
                const Text('GENEL ÖZET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGray, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _FadeSlide(delay: 0, child: _ozzetKart('🚀', 'En Yüksek LGS', enYuksek, kGreen, 0))),
                        const SizedBox(width: 10),
                        Expanded(child: _FadeSlide(delay: 80, child: _ozzetKart('📉', 'En Düşük LGS', enDusuk, kRed, 0))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _FadeSlide(delay: 160, child: _ozzetKart('📊', 'Ortalama LGS', ortalama, kPrimary, 1))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FadeSlide(
                            delay: 240,
                            child: _ozzetKartFark(ilkSon >= 0 ? '📈' : '📉', 'İlk-Son Fark', ilkSon, ilkSon >= 0 ? kGreen : kRed),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sınıfınla Kıyaslama — backend'den veri gelmişse gösterilir
                if (_ortalamaYukleniyor)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(color: kPrimaryLight, strokeWidth: 2)),
                  )
                else if (kiyasVar) ...[
                  const Text('SINIFINLA KIYASLAMA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGray, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  _FadeSlide(
                    delay: 0,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.07), blurRadius: 14)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Genel LGS kıyaslaması
                          _KiyasSatiri(
                            ad: 'Genel LGS Puanı',
                            icon: '🎯',
                            senDeger: senLgsOrt,
                            sinifDeger: sinifLgsOrt,
                            maxDeger: 500,
                            decimals: 1,
                            renk: kPrimary,
                            delay: 0,
                          ),
                          const Divider(color: kLightGray, height: 24),
                          // Ders bazlı kıyaslama
                          ...dersAnaliz.asMap().entries.map((e) {
                            final i = e.key;
                            final d = e.value;
                            final key = d['ad'] as String;
                            double senNet, sinifNet;
                            switch (key) {
                              case 'Türkçe':
                                senNet = _ort(eslesenler.map((x) => x.key.turkcen));
                                sinifNet = _ort(eslesenler.map((x) => x.value.turkcen));
                                break;
                              case 'Sosyal':
                                senNet = _ort(eslesenler.map((x) => x.key.sosn));
                                sinifNet = _ort(eslesenler.map((x) => x.value.sosn));
                                break;
                              case 'Din':
                                senNet = _ort(eslesenler.map((x) => x.key.dinn));
                                sinifNet = _ort(eslesenler.map((x) => x.value.dinn));
                                break;
                              case 'İngilizce':
                                senNet = _ort(eslesenler.map((x) => x.key.ingn));
                                sinifNet = _ort(eslesenler.map((x) => x.value.ingn));
                                break;
                              case 'Matematik':
                                senNet = _ort(eslesenler.map((x) => x.key.matn));
                                sinifNet = _ort(eslesenler.map((x) => x.value.matn));
                                break;
                              default:
                                senNet = _ort(eslesenler.map((x) => x.key.fenn));
                                sinifNet = _ort(eslesenler.map((x) => x.value.fenn));
                            }
                            return Column(
                              children: [
                                _KiyasSatiri(
                                  ad: key,
                                  icon: d['icon'] as String,
                                  senDeger: senNet,
                                  sinifDeger: sinifNet,
                                  maxDeger: _kiyasMax(key),
                                  decimals: 2,
                                  renk: d['color'] as Color,
                                  delay: 100 + i * 60,
                                ),
                                if (i < dersAnaliz.length - 1) const Divider(color: kLightGray, height: 8),
                              ],
                            );
                          }),
                          const SizedBox(height: 6),
                          Text(
                            '${eslesenler.last.value.ogrenciSayisi} öğrenci ile kıyaslandı',
                            style: const TextStyle(fontSize: 10, color: kGray, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Ders bazlı gelişim
                const Text('DERS BAZLI GELİŞİM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGray, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.07), blurRadius: 14)],
                  ),
                  child: Column(
                    children: dersAnaliz.asMap().entries.map((e) {
                      final i = e.key;
                      final d = e.value;
                      final fark = d['fark'] as double;
                      final data = d['data'] as List<double>;
                      final max = d['max'] as double;
                      // Çok fazla sınav olsa bile satırın taşmaması için
                      // trend çubuğunda en fazla son 8 sınav gösteriliyor.
                      final gosterilen = data.length > 8 ? data.sublist(data.length - 8) : data;
                      return _FadeSlide(
                        delay: i * 70,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: (d['color'] as Color).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(child: Text(d['icon'] as String, style: const TextStyle(fontSize: 17))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d['ad'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDark)),
                                    Text('Ort: %${((d['ortalama'] as double) * 100).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: kGray)),
                                  ],
                                )),
                                // Mini trend göstergesi — animasyonlu
                                SizedBox(
                                  height: 30,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: gosterilen.asMap().entries.map((entry) {
                                      return _AnimatedTrendBar(
                                        widthFactor: (entry.value / max).clamp(0.0, 1.0),
                                        maxHeight: 30,
                                        color: d['color'] as Color,
                                        vurgulu: entry.key == gosterilen.length - 1,
                                        delay: 300 + i * 70 + entry.key * 40,
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${fark >= 0 ? "▲" : "▼"}%${(fark.abs() * 100).toStringAsFixed(1)}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fark >= 0 ? kGreen : kRed),
                                ),
                              ],
                            ),
                            if (i < dersAnaliz.length - 1) const Divider(color: kLightGray, height: 20),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // En gelişen / en gerileyen
                Row(
                  children: [
                    Expanded(child: _FadeSlide(delay: 0, child: _basariKart('🏆 EN ÇOK GELİŞEN', enGelisen, kGreen, true))),
                    const SizedBox(width: 10),
                    Expanded(child: _FadeSlide(delay: 100, child: _basariKart('⚠️ DİKKAT GEREKEN', enGerileyen, kRed, false))),
                  ],
                ),
                const SizedBox(height: 16),

                // Sıralama gelişimi — sadece LGS formatlı sınav varsa gösterilir
                if (lgsVar) ...[
                  const Text('SIRALAMA GELİŞİMİ (TÜRKİYE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGray, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  _FadeSlide(
                    delay: 0,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kHeaderMid, kHeaderEnd]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('İlk Sınav', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            AnimatedNumber(
                              value: siraData.first.toDouble(),
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ]),
                          const Expanded(child: Center(child: Text('→', style: TextStyle(color: Colors.white54, fontSize: 22)))),
                          Column(children: [
                            const Text('Son Sınav', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            AnimatedNumber(
                              value: siraData.last.toDouble(),
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ]),
                          const Expanded(child: SizedBox()),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            const Text('Değişim', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text(
                              '${siraFark >= 0 ? "▲" : "▼"} ${siraFark.abs()}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: siraFark >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF6B6B)),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Yükseklik 60 → 76 yapıldı: max çubuk (50) + boşluk (4) + sayı etiketi
  // satırı (~12-14, font+line-height) toplamda 60'ı geçebiliyordu ve bu
  // "BOTTOM OVERFLOWED BY x PIXELS" hatasına yol açıyordu. Ekstra pay
  // bırakıldı ki farklı ekran yoğunluklarında da güvenli olsun.
  Widget _miniBarChart(List<double> data) {
    final max = data.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 76,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((e) {
          final hFactor = (e.value / max).clamp(0.0, 1.0);
          final isLast = e.key == data.length - 1;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedVBar(
                  heightFactor: hFactor,
                  maxHeight: 50,
                  vurgulu: isLast,
                  delay: e.key * 40,
                ),
                const SizedBox(height: 4),
                Text('${e.key + 1}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Eski tasarımda emoji üstte, Spacer() ile rakam en altta itiliyordu.
  // Sabit yükseklikli kartta (childAspectRatio) içerik toplamı kartın
  // yüksekliğinin çok altında kaldığından, Spacer ortada büyük bir boş
  // alan bırakıyor ve gölge de çok soluk olduğu için bu boşluk "GENEL
  // ÖZET" başlığıyla kartlar arasında beyaz bir alanmış gibi
  // algılanıyordu. Yatay/kompakt düzene çevrildi: ikon solda renkli
  // rozet içinde, rakam+etiket sağda — dikey boşluk kalmıyor.
  Widget _ozzetKart(String emoji, String label, double deger, Color renk, int decimals) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: renk.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedNumber(value: deger, decimals: decimals, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: renk)),
                Text(label, style: const TextStyle(fontSize: 10, color: kGray, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // İlk-Son Fark kartı: negatif/pozitif işaretiyle birlikte gösterilmesi
  // gerektiği için AnimatedNumber'ın mutlak değerini kullanıp işareti
  // ayrıca ekliyoruz.
  Widget _ozzetKartFark(String emoji, String label, double fark, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: renk.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(fark >= 0 ? '+' : '-', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: renk)),
                  AnimatedNumber(value: fark.abs(), decimals: 1, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: renk)),
                ]),
                Text(label, style: const TextStyle(fontSize: 10, color: kGray, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _basariKart(String baslik, Map<String, dynamic> ders, Color renk, bool pozitif) {
    final fark = ders['fark'] as double;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: renk.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: renk)),
          const SizedBox(height: 8),
          Text(ders['icon'] as String, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(ders['ad'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kDark)),
          Text('${pozitif ? "+" : ""}%${(fark * 100).toStringAsFixed(1)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: renk)),
        ],
      ),
    );
  }
}