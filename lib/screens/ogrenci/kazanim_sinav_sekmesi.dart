import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

// ════════════ SINAV DETAYI — KAZANIM SEKMESİ ════════════
// veli.php'deki "Kazanım Analizi" modalının, TEK bir sınava ait hali.
// SinavDetay ekranındaki 3. sekmede gösterilir.
// Eşikler web ile aynı: <%60 Tekrar et • <%80 Pekiştir • >=%80 İyi
class KazanimSinavSekmesi extends StatefulWidget {
  final String tcno;
  final String sinavadi;
  final String sinavtarihi;
  final String kod;
  const KazanimSinavSekmesi({
    super.key,
    required this.tcno,
    required this.sinavadi,
    this.sinavtarihi = '',
    this.kod = '',
  });

  @override
  State<KazanimSinavSekmesi> createState() => _KazanimSinavSekmesiState();
}

class _KazanimSinavSekmesiState extends State<KazanimSinavSekmesi> {
  // Sekmeler arası geçişte tekrar tekrar sunucuya gitmesin diye önbellek.
  static final Map<String, Map<String, dynamic>> _onbellek = {};

  bool _yukleniyor = true;
  String _hata = '';
  Map<String, dynamic> _ozet = {};
  List<dynamic> _dersler = [];

  String get _anahtar => '${widget.tcno}|${widget.sinavadi}|${widget.sinavtarihi}|${widget.kod}';

  @override
  void initState() {
    super.initState();
    final c = _onbellek[_anahtar];
    if (c != null) {
      _uygula(c);
      _yukleniyor = false;
    } else {
      _yukle();
    }
  }

  void _uygula(Map<String, dynamic> r) {
    _ozet = Map<String, dynamic>.from(r['ozet'] ?? {});
    final sinavlar = List<dynamic>.from(r['sinavlar'] ?? []);
    _dersler = sinavlar.expand((s) => List<dynamic>.from(s['dersler'] ?? [])).toList();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = ''; });
    final r = await ApiService.kazanimAnalizi(
      widget.tcno,
      sinavadi: widget.sinavadi,
      sinavtarihi: widget.sinavtarihi,
      kod: widget.kod,
    );
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _onbellek[_anahtar] = Map<String, dynamic>.from(r);
        _uygula(r);
      } else {
        _hata = r['mesaj'] ?? 'Kazanım verisi alınamadı';
      }
      _yukleniyor = false;
    });
  }

  // ── Yardımcılar ──
  double? _d(dynamic v) => v == null ? null : double.tryParse(v.toString());

  String _yuzde(double v) => '%${v.toStringAsFixed(1).replaceAll('.', ',')}';

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
    if (_yukleniyor) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }
    if (_hata.isNotEmpty) return _hataGorunumu();
    if (_dersler.isEmpty) return _bosGorunumu();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ozetKartlari(),
          const SizedBox(height: 12),
          _aciklama(),
          const SizedBox(height: 12),
          ..._dersler.asMap().entries.map((e) => _dersKarti(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _hataGorunumu() {
    return Padding(
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
    );
  }

  Widget _bosGorunumu() {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📚', style: TextStyle(fontSize: 44)),
          SizedBox(height: 12),
          Text('Bu sınav için kazanım analizi yok', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
          SizedBox(height: 6),
          Text('Bu sınavın kazanım verisi henüz aktarılmamış olabilir.', style: TextStyle(color: AppColors.gray, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ════════════ ÖZET ════════════
  Widget _ozetKartlari() {
    final toplam = (_ozet['toplamKazanim'] ?? 0).toString();
    final tekrar = (_ozet['tekrarSayisi'] ?? 0).toString();
    final ort = _d(_ozet['ortalamaBasari']);
    return Row(children: [
      _ozetKutu('İncelenen\nKazanım', toplam, AppColors.purple),
      const SizedBox(width: 8),
      _ozetKutu('Tekrar Önerilen\n(<%60)', tekrar, AppColors.red),
      const SizedBox(width: 8),
      _ozetKutu('Ortalama\nBaşarı', ort == null ? '—' : _yuzde(ort), AppColors.green),
    ]);
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
      child: const Text(
        'Bir dersin üzerine dokunarak kazanım sonuçlarını açabilirsin. '
        'Kırmızı: tekrar çalışılmalı • Turuncu: pekiştirme • Yeşil: iyi düzey.',
        style: TextStyle(fontSize: 11.5, color: AppColors.gray, height: 1.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ════════════ DERS KARTI ════════════
  Widget _dersKarti(dynamic ders, int index) {
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
            key: ValueKey('kz_ders_$index'),
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
