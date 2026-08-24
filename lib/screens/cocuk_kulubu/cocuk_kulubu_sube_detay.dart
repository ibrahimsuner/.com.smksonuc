import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

class CocukKulubuSubeDetay extends StatefulWidget {
  final String sube;
  final Map<String, String> oturum;
  const CocukKulubuSubeDetay({super.key, required this.sube, required this.oturum});

  @override
  State<CocukKulubuSubeDetay> createState() => _CocukKulubuSubeDetayState();
}

class _CocukKulubuSubeDetayState extends State<CocukKulubuSubeDetay> {
  bool _yukleniyor = true;
  bool _kaydediliyor = false;
  String _hata = '';
  List<dynamic> _ogrenciler = [];
  final Set<int> _gelmeyenler = {};

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = '';
    });

    final r = await ApiService.cocukKulubuSubeOgrencileri(widget.sube);

    print("CEVAP = $r");
    print("ÖĞRENCİ SAYISI = ${r['ogrenciler']?.length}");

    if (!mounted) return;

    setState(() {
      if (r['basari'] == true) {
        _ogrenciler = List<dynamic>.from(r['ogrenciler']);

        _gelmeyenler.clear();

        for (final o in _ogrenciler) {
          if (o['durum'] == 'gelmedi') {
            final id = int.tryParse(o['kayit_id']?.toString() ?? '');
            if (id != null) {
              _gelmeyenler.add(id);
            } else {
              print('UYARI: kayit_id ayrıştırılamadı -> $o');
            }
          }
        }
      } else {
        _hata = r['mesaj'] ?? 'Öğrenciler yüklenemedi';
      }

      _yukleniyor = false;
    });
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediliyor = true);
    final tarih = DateTime.now().toIso8601String().split('T').first;
    final r = await ApiService.cocukKulubuYoklamaKaydet(
      sube: widget.sube,
      tarih: tarih,
      kaydeden: widget.oturum['adisoyadi'] ?? '',
      gelmeyenler: _gelmeyenler.toList(),
    );
    if (!mounted) return;
    setState(() => _kaydediliyor = false);

    if (r['basari'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yoklama kaydedildi (${_gelmeyenler.length} öğrenci gelmedi)')),
      );
      _yukle();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r['mesaj'] ?? 'Kaydedilemedi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        title: Text(widget.sube),
      ),
      body: _yukleniyor
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _hata.isNotEmpty
          ? Center(
        child: Text(_hata),
      )
          : _ogrenciler.isEmpty
          ? const Center(
        child: Text("Bu şubede öğrenci yok"),
      )
          : Column(
        children: [

          _bilgiKutusu(),

          Expanded(
            child: ListView.builder(
              itemCount: _ogrenciler.length,
              itemBuilder: (context, index) {
                return _ogrenciSatiri(_ogrenciler[index]);
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar:
      _ogrenciler.isEmpty ? null : _kaydetBar(),
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
          Text(widget.sube, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Bugünün Yoklaması • ${_bugunMetni()}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }

  String _bugunMetni() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}.${n.month.toString().padLeft(2, '0')}.${n.year}';
  }

  Widget _bilgiKutusu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Gelmeyen öğrencilere dokun, sonra "Kaydet" e bas. Dokunmadıkların otomatik "geldi" sayılır.',
            style: TextStyle(fontSize: 11.5, color: AppColors.purple.withOpacity(0.85), fontWeight: FontWeight.w600, height: 1.4),
          )),
        ]),
      ),
    );
  }

  Widget _ogrenciSatiri(dynamic o) {
    // Savunmacı ayrıştırma: kayit_id null/boş/sayısal-olmayan gelirse
    // artık int.parse çökmüyor, bunun yerine ekranda görünür bir uyarı
    // satırı gösteriyoruz — böylece hangi kaydın bozuk olduğu belli olur.
    final rawId = o['kayit_id'];
    final kayitId = int.tryParse(rawId?.toString() ?? '');
    if (kayitId == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.red.withOpacity(0.4)),
        ),
        child: Text(
          'Kayıt hatalı (kayit_id yok/geçersiz): ${o['adisoyadi'] ?? o.toString()}',
          style: const TextStyle(fontSize: 11, color: AppColors.red, fontWeight: FontWeight.w700),
        ),
      );
    }
    final gelmedi = _gelmeyenler.contains(kayitId);
    return GestureDetector(
      onTap: () => setState(() {
        if (gelmedi) { _gelmeyenler.remove(kayitId); } else { _gelmeyenler.add(kayitId); }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: gelmedi ? AppColors.red.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gelmedi ? AppColors.red.withOpacity(0.3) : AppColors.lightGray),
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gelmedi ? AppColors.red : AppColors.green.withOpacity(0.12),
            ),
            child: Center(child: Text(gelmedi ? '✕' : '✓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: gelmedi ? Colors.white : AppColors.green))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o['adisoyadi'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
            Text('${o['sinifi'] ?? ''} • No: ${o['numarasi'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          ])),
          Text(
            gelmedi ? 'Gelmedi' : 'Geldi',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: gelmedi ? AppColors.red : AppColors.green),
          ),
        ]),
      ),
    );
  }

  Widget _kaydetBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: AppColors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${_gelmeyenler.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.red)),
                        const Text('Gelmedi', style: TextStyle(fontSize: 10, color: AppColors.red, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _kaydediliyor ? null : _kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _kaydediliyor
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Yoklamayı Kaydet', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}