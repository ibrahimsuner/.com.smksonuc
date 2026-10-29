import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

// ════════════ KAZANIM ANALİZİ (ÖĞRENCİ / VELİ) ════════════
// veli.php'deki "Kazanım Analizi" modalının uygulama karşılığı.
// Eşikler web ile aynı: <%60 Tekrar et • <%80 Pekiştir • >=%80 İyi
class OgrenciKazanimAnaliz extends StatefulWidget {
  final String tcno;
  const OgrenciKazanimAnaliz({super.key, required this.tcno});

  @override
  State<OgrenciKazanimAnaliz> createState() => _OgrenciKazanimAnalizState();
}

class _OgrenciKazanimAnalizState extends State<OgrenciKazanimAnaliz> {
  bool _yukleniyor = true;
  String _hata = '';
  Map<String, dynamic> _ozet = {};
  List<dynamic> _sinavlar = [];
  int _seciliSinav = 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = ''; });
    final r = await ApiService.kazanimAnalizi(widget.tcno);
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _ozet = Map<String, dynamic>.from(r['ozet'] ?? {});
        _sinavlar = List<dynamic>.from(r['sinavlar'] ?? []);
        _seciliSinav = 0;
      } else {
        _hata = r['mesaj'] ?? 'Kazanım verisi alınamadı';
      }
      _yukleniyor = false;
    });
  }

  // ── Yardımcılar ──
  double? _d(dynamic v) => v == null ? null : double.tryParse(v.toString());

  String _yuzde(double v) => '%${v.toStringAsFixed(1).replaceAll('.', ',')}';

  String _tarih(String t) {
    if (t.length < 10) return t;
    final p = t.substring(0, 10).split('-');
    return p.length == 3 ? '${p[2]}.${p[1]}.${p[0]}' : t;
  }

  Color _durumRenk(double? b) {
    if (b == null) return AppColors.gray;
    if (b < 60) return AppColors.red;
    if (b < 80) return AppColors.orange;
    return AppColors.green;
  }

  String _durumMetin(double? b) {
    if (b == null) return 'Veri yok';
    if (b < 60) return 'Tekrar et';
    if (b < 80) return 'Pekiştir';
    return 'İyi';
  }

  String _norm(String s) => s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

  Map<String, dynamic> _dersStil(String ad) {
    final n = _norm(ad);
    if (n.contains('türk')) return {'icon': '📖', 'renk': AppColors.purple};
    if (n.contains('sosyal')) return {'icon': '🌍', 'renk': AppColors.magenta};
    if (n.contains('din')) return {'icon': '☪️', 'renk': AppColors.teal};
    if (n.contains('ingiliz') || n.contains('ing')) return {'icon': '🌐', 'renk': AppColors.blue};
    if (n.contains('mat')) return {'icon': '🔢', 'renk': AppColors.orange};
    if (n.contains('fen')) return {'icon': '🔬', 'renk': AppColors.green};
    return {'icon': '📘', 'renk': AppColors.gray};
  }

  // ════════════ BUILD ════════════
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
            SliverFillRemaining(child: _hataGorunumu())
          else if (_sinavlar.isEmpty)
            SliverFillRemaining(child: _bosGorunumu())
          else ...[
            SliverToBoxAdapter(child: _ozetKartlari()),
            SliverToBoxAdapter(child: _aciklama()),
            SliverToBoxAdapter(child: _sinavSecici()),
            SliverToBoxAdapter(child: _sinavIcerigi()),
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
          const Text('📘 KAZANIM ANALİZİ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text('Kazanım Bazlı Başarı Durumu', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _hataGorunumu() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😔', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(_hata, style: const TextStyle(color: AppColors.gray, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _yukle,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bosGorunumu() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📚', style: TextStyle(fontSize: 44)),
            SizedBox(height: 12),
            Text('Henüz kazanım analizi bulunmuyor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
            SizedBox(height: 6),
            Text('Bu öğrenci için kazanım verisi aktarılmış sınav bulunamadı.', style: TextStyle(color: AppColors.gray, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ════════════ ÖZET ════════════
  Widget _ozetKartlari() {
    final toplam = (_ozet['toplamKazanim'] ?? 0).toString();
    final tekrar = (_ozet['tekrarSayisi'] ?? 0).toString();
    final ort = _d(_ozet['ortalamaBasari']);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        _ozetKutu('İncelenen\nKazanım', toplam, AppColors.purple),
        const SizedBox(width: 8),
        _ozetKutu('Tekrar Önerilen\n(<%60)', tekrar, AppColors.red),
        const SizedBox(width: 8),
        _ozetKutu('Ortalama\nBaşarı', ort == null ? '—' : _yuzde(ort), AppColors.green),
      ]),
    );
  }

  Widget _ozetKutu(String label, String deger, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 10)],
        ),
        child: Column(children: [
          Text(deger, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: renk)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppColors.gray, fontWeight: FontWeight.w600, height: 1.3)),
        ]),
      ),
    );
  }

  Widget _aciklama() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
        child: const Text(
          'Sınavı seçip bir dersin üzerine dokunarak kazanım sonuçlarını açabilirsin. '
          'Kırmızı: tekrar çalışılmalı • Turuncu: pekiştirme • Yeşil: iyi düzey.',
          style: TextStyle(fontSize: 11.5, color: AppColors.gray, height: 1.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ════════════ SINAV SEÇİCİ ════════════
  Widget _sinavSecici() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SINAV SEÇ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sinavlar.length,
              itemBuilder: (context, i) {
                final s = _sinavlar[i];
                final secili = _seciliSinav == i;
                final enYeni = i == 0;
                return GestureDetector(
                  onTap: () => setState(() => _seciliSinav = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: secili ? AppColors.dark : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: secili ? AppColors.dark : AppColors.lightGray),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${s['sinavAdi']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secili ? Colors.white : AppColors.dark)),
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
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ════════════ SEÇİLİ SINAV İÇERİĞİ ════════════
  Widget _sinavIcerigi() {
    final sinav = _sinavlar[_seciliSinav];
    final dersler = List<dynamic>.from(sinav['dersler'] ?? []);
    final kod = (sinav['sinavKodu'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              '${_tarih((sinav['sinavTarihi'] ?? '').toString())}${kod.isNotEmpty ? '  •  Sınav kodu: $kod' : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w600),
            ),
          ),
          ...dersler.asMap().entries.map((e) => _dersKarti(e.value, '${_seciliSinav}_${e.key}')),
        ],
      ),
    );
  }

  Widget _dersKarti(dynamic ders, String key) {
    final ad = (ders['dersAdi'] ?? 'Ders').toString();
    final stil = _dersStil(ad);
    final renk = stil['renk'] as Color;
    final kazanimlar = List<dynamic>.from(ders['kazanimlar'] ?? []);
    final ort = _d(ders['ortalama']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.06), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<String>('kazanim_$key'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            iconColor: AppColors.gray,
            collapsedIconColor: AppColors.gray,
            leading: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: renk.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(stil['icon'] as String, style: const TextStyle(fontSize: 17))),
            ),
            title: Text(ad, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dark)),
            subtitle: Text(
              '${kazanimlar.length} kazanım${ort != null ? ' · Ort. ${_yuzde(ort)}' : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.gray),
            ),
            children: kazanimlar.map((k) => _kazanimSatiri(k)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _kazanimSatiri(dynamic k) {
    final b = _d(k['basari']);
    final renk = _durumRenk(b);
    final kontrol = k['kontrol'] == true;
    String say(dynamic v) => v == null ? '—' : v.toString();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${k['kazanim']}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.dark, height: 1.4, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: renk.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(_durumMetin(b), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: renk)),
              ),
            ],
          ),
          if (kontrol) ...[
            const SizedBox(height: 4),
            const Text('Kontrol edilmeli', style: TextStyle(fontSize: 9.5, color: AppColors.gray, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            _dyb('D', say(k['dogru']), AppColors.green),
            const SizedBox(width: 12),
            _dyb('Y', say(k['yanlis']), AppColors.red),
            const SizedBox(width: 12),
            _dyb('B', say(k['bos']), AppColors.gray),
            const Spacer(),
            Text(b == null ? '—' : _yuzde(b), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: renk)),
          ]),
          if (b != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (b / 100).clamp(0.0, 1.0),
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(renk),
                minHeight: 7,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dyb(String harf, String deger, Color renk) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$harf ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: renk)),
      Text(deger, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.dark)),
    ]);
  }
}
