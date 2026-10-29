import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

/// Öğretmen paneli için sınıf düzeyine ve sınava göre eksik kazanım ekranı.
/// API yalnızca eksik kazanım metinlerini döndürdüğü için bu ekran yüzde/başarı
/// oranı üretmez; sunucudan gelen veriyi şube ve ders bazında gösterir.
class OgretmenKazanimAnalizi extends StatefulWidget {
  const OgretmenKazanimAnalizi({super.key});

  @override
  State<OgretmenKazanimAnalizi> createState() => _OgretmenKazanimAnaliziState();
}

class _OgretmenKazanimAnaliziState extends State<OgretmenKazanimAnalizi> {
  int _seviye = 5;
  bool _sinavlarYukleniyor = true;
  bool _detayYukleniyor = false;
  String _hata = '';
  String _detayHata = '';
  List<dynamic> _sinavlar = [];
  String? _sinavAdi;
  String? _sinavSecimAnahtari;
  Map<String, dynamic>? _seciliSinav;
  Map<String, dynamic> _subeler = {};

  @override
  void initState() {
    super.initState();
    _sinavlariYukle();
  }

  Future<void> _sinavlariYukle() async {
    setState(() {
      _sinavlarYukleniyor = true;
      _hata = '';
      _sinavlar = [];
      _sinavAdi = null;
      _sinavSecimAnahtari = null;
      _seciliSinav = null;
      _subeler = {};
      _detayHata = '';
    });
    final r = await ApiService.kazanimSinavlari(_seviye);
    if (!mounted) return;
    if (r['basari'] == true) {
      final liste = List<dynamic>.from(r['sinavlar'] ?? []);

      // Sınavları en yeni tarih en üstte olacak şekilde sırala.
      // YYYY-MM-DD ve dd.MM.yyyy tarih biçimlerini destekler.
      DateTime? tarihCoz(dynamic value) {
        final raw = (value ?? '').toString().trim();
        if (raw.isEmpty) return null;

        final iso = DateTime.tryParse(raw);
        if (iso != null) return iso;

        final parcalar = raw.split('.');
        if (parcalar.length == 3) {
          final gun = int.tryParse(parcalar[0]);
          final ay = int.tryParse(parcalar[1]);
          final yil = int.tryParse(parcalar[2]);
          if (gun != null && ay != null && yil != null) {
            return DateTime(yil, ay, gun);
          }
        }
        return null;
      }

      liste.sort((a, b) {
        final sinavA = Map<String, dynamic>.from(a as Map);
        final sinavB = Map<String, dynamic>.from(b as Map);
        final tarihA = tarihCoz(sinavA['sinav_tarihi']);
        final tarihB = tarihCoz(sinavB['sinav_tarihi']);

        if (tarihA == null && tarihB == null) return 0;
        if (tarihA == null) return 1;
        if (tarihB == null) return -1;

        return tarihB.compareTo(tarihA); // Yeni -> eski
      });

      setState(() {
        _sinavlar = liste;
        _sinavlarYukleniyor = false;
        if (liste.isEmpty) _hata = 'Bu sınıf düzeyinde kazanım değerlendirmesi bulunan sınav yok.';
      });
      if (liste.isNotEmpty) {
        final ilk = Map<String, dynamic>.from(liste.first as Map);
        final ad = (ilk['sinav_adi'] ?? ilk['sinavadi'] ?? '').toString();
        if (ad.isNotEmpty) await _detayYukle(ilk);
      }
    } else {
      setState(() {
        _sinavlarYukleniyor = false;
        _hata = (r['mesaj'] ?? 'Sınav listesi alınamadı.').toString();
      });
    }
  }

  Future<void> _detayYukle(Map<String, dynamic> sinav) async {
    final ad = (sinav['sinav_adi'] ?? sinav['sinavadi'] ?? '').toString();
    final key = '${sinav['sinav_tarihi'] ?? ''}|$ad';
    setState(() {
      _seciliSinav = sinav;
      _sinavSecimAnahtari = key;
      _sinavAdi = ad;
      _detayYukleniyor = true;
      _detayHata = '';
      _subeler = {};
    });
    final r = await ApiService.kazanimEksikGetir(sinavadi: ad, seviye: _seviye, sinavTarihi: (sinav['sinav_tarihi'] ?? '').toString());
    if (!mounted) return;
    if (r['basari'] == true) {
      final raw = r['subeler'];
      setState(() {
        _subeler = raw is Map ? Map<String, dynamic>.from(raw) : {};
        _detayYukleniyor = false;
        if (_subeler.isEmpty) _detayHata = 'Bu sınav için kazanım sonucu bulunamadı.';
      });
    } else {
      setState(() {
        _detayYukleniyor = false;
        _detayHata = (r['mesaj'] ?? 'Kazanım verileri alınamadı.').toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _baslik()),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _secimKart(),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _icerik(),
          )),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  Widget _baslik() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD],
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
    child: const Row(children: [
      DecoratedBox(
        decoration: BoxDecoration(color: Color(0x25FFFFFF), borderRadius: BorderRadius.all(Radius.circular(14))),
        child: SizedBox(width: 48, height: 48, child: Icon(Icons.track_changes_rounded, color: Colors.white, size: 27)),
      ),
      SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ÖĞRETMEN PANELİ', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
        SizedBox(height: 4),
        Text('Kazanım Analizi', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
      ])),
    ]),
  );

  Widget _secimKart() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.06), blurRadius: 12)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('SINIF DÜZEYİ', style: TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w800, letterSpacing: 1)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [5, 6, 7, 8].map((n) {
        final secili = _seviye == n;
        return ChoiceChip(
          label: Text('$n. Sınıf'), selected: secili,
          selectedColor: AppColors.purple,
          labelStyle: TextStyle(color: secili ? Colors.white : AppColors.gray, fontWeight: FontWeight.w700, fontSize: 12),
          onSelected: _sinavlarYukleniyor ? null : (_) { setState(() => _seviye = n); _sinavlariYukle(); },
          side: BorderSide(color: secili ? AppColors.purple : AppColors.lightGray),
        );
      }).toList()),
      const SizedBox(height: 14),
      const Text('SINAV', style: TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w800, letterSpacing: 1)),
      const SizedBox(height: 6),
      if (_sinavlarYukleniyor)
        const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(color: AppColors.purple)))
      else if (_sinavlar.isEmpty)
        Text(_hata.isEmpty ? 'Sınav bulunamadı.' : _hata, style: const TextStyle(color: AppColors.gray, fontSize: 12))
      else
        DropdownButtonFormField<String>(
          value: _sinavSecimAnahtari,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true, fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          hint: const Text('Sınav seçin'),
          items: _sinavlar.map((raw) {
            final s = Map<String, dynamic>.from(raw as Map);
            final ad = (s['sinav_adi'] ?? s['sinavadi'] ?? '').toString();
            final tarih = (s['sinav_tarihi'] ?? '').toString();
            final kod = (s['sinav_kodu'] ?? '').toString();
            final key = '$tarih|$ad';
            final label = '$ad${tarih.isNotEmpty ? ' — ${_tarihGoster(tarih)}' : ''}${kod.isNotEmpty ? ' ($kod)' : ''}';
            return DropdownMenuItem<String>(value: key, child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.dark)));
          }).where((e) => e.value != null && e.value!.isNotEmpty).toList(),
          onChanged: (key) {
            if (key == null) return;
            final secilen = _sinavlar.map((x) => Map<String, dynamic>.from(x as Map)).firstWhere((x) => '${x['sinav_tarihi'] ?? ''}|${x['sinav_adi'] ?? x['sinavadi'] ?? ''}' == key);
            _detayYukle(secilen);
          },
        ),
    ]),
  );

  Widget _icerik() {
    if (_detayYukleniyor) return const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator(color: AppColors.purple)));
    if (_detayHata.isNotEmpty) return _mesajKart(_detayHata, Icons.menu_book_rounded);
    if (_subeler.isEmpty) return const SizedBox.shrink();

    int toplam = 0;
    int tekrar = 0;
    double basariToplam = 0;
    int basariAdet = 0;
    for (final subeValue in _subeler.values) {
      if (subeValue is Map) {
        for (final dersValue in subeValue.values) {
          if (dersValue is List) {
            toplam += dersValue.length;
            for (final item in dersValue) {
              if (item is Map && item['basari'] != null) {
                final p = double.tryParse(item['basari'].toString());
                if (p != null) { basariToplam += p; basariAdet++; if (p < 60) tekrar++; }
              }
            }
          }
        }
      }
    }
    final genelOrtalama = basariAdet == 0 ? null : basariToplam / basariAdet;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _ozetKarti('Kazanım kaydı', '$toplam', AppColors.purple)),
        const SizedBox(width: 8),
        Expanded(child: _ozetKarti('Tekrar önerilen', '$tekrar', const Color(0xFFDC2626))),
        const SizedBox(width: 8),
        Expanded(child: _ozetKarti('Ortalama başarı', genelOrtalama == null ? '—' : '%${genelOrtalama.toStringAsFixed(1)}', const Color(0xFF16A34A))),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.07), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.fact_check_rounded, color: AppColors.purple)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_sinavAdi ?? 'Seçilen sınav', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dark)),
            const SizedBox(height: 3),
            Text('${_subeler.length} sınıf/şube · $toplam kazanım kaydı', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          ])),
        ]),
      ),
      const SizedBox(height: 14),
      ..._subeler.entries.map((e) => _subeKarti(e.key, e.value)),
      const SizedBox(height: 4),
      const Text('Başarı yüzdesi doğru / (doğru + yanlış) üzerinden hesaplanır; boşlar ayrıca gösterilir.', style: TextStyle(fontSize: 10, color: AppColors.gray, height: 1.4)),
    ]);
  }

  Widget _ozetKarti(String baslik, String deger, Color renk) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), boxShadow: [BoxShadow(color: renk.withOpacity(.08), blurRadius: 8)]),
    child: Column(children: [
      Text(baslik, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 9, color: AppColors.gray, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      FittedBox(fit: BoxFit.scaleDown, child: Text(deger, style: TextStyle(fontSize: 16, color: renk, fontWeight: FontWeight.w900))),
    ]),
  );

  Widget _subeKarti(String sube, dynamic rawDersler) {
    final dersler = rawDersler is Map ? Map<String, dynamic>.from(rawDersler) : <String, dynamic>{};
    final sayi = dersler.values.fold<int>(0, (toplam, v) => toplam + (v is List ? v.length : 0));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.05), blurRadius: 10)]),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _subeler.length == 1,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.school_rounded, color: AppColors.purple)),
          title: Text(sube, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.dark)),
          subtitle: Text('${dersler.length} ders · $sayi kazanım', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          children: dersler.entries.map((e) => _dersKarti(e.key, e.value)).toList(),
        ),
      ),
    );
  }

  Widget _dersKarti(String ders, dynamic rawKazanimlar) {
    final liste = rawKazanimlar is List ? rawKazanimlar : <dynamic>[];
    double basariToplam = 0;
    int basariAdet = 0;
    for (final item in liste) {
      if (item is Map && item['basari'] != null) {
        final v = double.tryParse(item['basari'].toString());
        if (v != null) { basariToplam += v; basariAdet++; }
      }
    }
    final ort = basariAdet == 0 ? null : basariToplam / basariAdet;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(13)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.menu_book_rounded, size: 17, color: AppColors.purple),
          const SizedBox(width: 7),
          Expanded(child: Text(ders, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.dark))),
          if (ort != null) Text('Ort. %${ort.toStringAsFixed(1)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _renk(ort))),
          const SizedBox(width: 7),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('${liste.length}', style: const TextStyle(fontSize: 10, color: AppColors.purple, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 8),
        ...liste.map((item) {
          final row = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{'kazanim': item.toString()};
          final d = _sayi(row['dogru']);
          final y = _sayi(row['yanlis']);
          final b = _sayi(row['bos']);
          final p = row['basari'] == null ? null : double.tryParse(row['basari'].toString());
          final durum = p == null ? 'Veri yok' : p < 60 ? 'Tekrar et' : p < 80 ? 'Pekiştir' : 'İyi';
          return Container(
            margin: const EdgeInsets.only(top: 7),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.lightGray)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((row['kazanim'] ?? 'Kazanım belirtilmemiş').toString(), style: const TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.dark, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 5, children: [
                _miniSonuc('Doğru', d.toString()), _miniSonuc('Yanlış', y.toString()), _miniSonuc('Boş', b.toString()),
                _miniSonuc('Öğrenci', (row['ogrenci_sayisi'] ?? '—').toString()),
              ]),
              const SizedBox(height: 7),
              Row(children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: p == null ? 0 : (p / 100).clamp(0, 1).toDouble(), minHeight: 7, backgroundColor: AppColors.lightGray, valueColor: AlwaysStoppedAnimation<Color>(_renk(p ?? 0))))),
                const SizedBox(width: 8),
                Text(p == null ? '—' : '${p.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _renk(p ?? 0))),
                const SizedBox(width: 7),
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: _renk(p ?? 0).withOpacity(.12), borderRadius: BorderRadius.circular(6)), child: Text(durum, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _renk(p ?? 0)))),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  double _sayi(dynamic value) => double.tryParse((value ?? 0).toString()) ?? 0;

  Color _renk(double p) => p < 60 ? const Color(0xFFDC2626) : p < 80 ? const Color(0xFFD97706) : const Color(0xFF16A34A);

  Widget _miniSonuc(String baslik, String deger) => RichText(text: TextSpan(style: const TextStyle(fontSize: 10, color: AppColors.gray), children: [TextSpan(text: '$baslik '), TextSpan(text: deger, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.dark))]));

  String _tarihGoster(String tarih) {
    final p = tarih.length >= 10 ? tarih.substring(0, 10).split('-') : <String>[];
    return p.length == 3 ? '${p[2]}.${p[1]}.${p[0]}' : tarih;
  }

  Widget _mesajKart(String mesaj, IconData ikon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Column(children: [
      Icon(ikon, size: 38, color: AppColors.gray),
      const SizedBox(height: 10),
      Text(mesaj, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.gray, height: 1.4)),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _seciliSinav == null ? _sinavlariYukle : () => _detayYukle(_seciliSinav!), icon: const Icon(Icons.refresh), label: const Text('Yenile')),
    ]),
  );
}
