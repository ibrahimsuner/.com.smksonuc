import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

class AdminBildirimDevamsizlik extends StatefulWidget {
  const AdminBildirimDevamsizlik({super.key});

  @override
  State<AdminBildirimDevamsizlik> createState() => _AdminBildirimDevamsizlikState();
}

class _AdminBildirimDevamsizlikState extends State<AdminBildirimDevamsizlik> {
  bool _yukleniyor = true;
  List<dynamic> _liste = [];
  final Set<int> _seciliIdler = {};
  bool _gonderiliyor = false;
  String _sonucMesaji = '';
  bool? _sonucBasari;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _seciliIdler.clear(); });
    final r = await ApiService.adminDevamsizlikListe();
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _liste = r['liste'] ?? [];
      }
      _yukleniyor = false;
    });
  }

  Future<void> _gonder() async {
    if (_seciliIdler.isEmpty) {
      setState(() { _sonucBasari = false; _sonucMesaji = 'Lütfen en az bir öğrenci seç'; });
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Devamsızlık Bildirimi'),
        content: Text('${_seciliIdler.length} veliye bildirim gönderilecek. Emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gönder')),
        ],
      ),
    );
    if (onay != true) return;

    setState(() { _gonderiliyor = true; _sonucMesaji = ''; });
    final r = await ApiService.adminDevamsizlikGonder(_seciliIdler.toList());
    if (!mounted) return;

    final basari = r['basari'] == true;
    setState(() {
      _gonderiliyor = false;
      _sonucBasari = basari;
      if (basari) {
        final tokenYok = r['tokenBulunamayan'] ?? 0;
        _sonucMesaji = 'Başarılı: ${r['gonderilen']} bildirim gönderildi.'
            + (tokenYok > 0 ? ' $tokenYok öğrencinin kayıtlı bildirim tokenı yok.' : '');
      } else {
        _sonucMesaji = r['mesaj'] ?? 'Gönderilemedi';
      }
    });
    if (basari) _yukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          if (_yukleniyor)
            const SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 60),
              sliver: SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.teal))),
            )
          else if (_liste.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Column(children: [
                  Text('🎉', style: TextStyle(fontSize: 44)),
                  SizedBox(height: 12),
                  Text('Şu an bildirim bekleyen devamsız öğrenci yok', textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray)),
                ])),
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _bilgiVeSecTumu()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _ogrenciSatiri(_liste[i]),
                  childCount: _liste.length,
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _liste.isEmpty ? null : _gonderBar(),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF26A69A), AppColors.teal, Color(0xFF00695C)]),
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
          const Text('📋 ÇOCUK KULÜBÜ DEVAMSIZLIK', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text('${_liste.length} öğrenci bildirim bekliyor', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _bilgiVeSecTumu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text('Aşağıdaki öğrencilerin velisine devamsızlık bildirimi gönderilmemiş.', style: TextStyle(fontSize: 12, color: AppColors.gray, height: 1.4)),
          ),
          TextButton(
            onPressed: () => setState(() {
              final tumIdler = _liste.map((l) => l['yoklama_id'] as int).toList();
              if (_seciliIdler.length == tumIdler.length) { _seciliIdler.clear(); }
              else { _seciliIdler..clear()..addAll(tumIdler); }
            }),
            child: const Text('Tümünü Seç', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _ogrenciSatiri(dynamic d) {
    final id = d['yoklama_id'] as int;
    final secili = _seciliIdler.contains(id);
    final tarih = d['yoklama_tarihi']?.toString() ?? '';
    String tarihGosterim = tarih;
    try {
      final dt = DateTime.parse(tarih);
      tarihGosterim = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {}

    return GestureDetector(
      onTap: () => setState(() { if (secili) _seciliIdler.remove(id); else _seciliIdler.add(id); }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: secili ? AppColors.teal.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: secili ? AppColors.teal.withOpacity(0.35) : AppColors.lightGray),
        ),
        child: Row(children: [
          Icon(secili ? Icons.check_circle : Icons.circle_outlined, color: secili ? AppColors.teal : AppColors.lightGray, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['adisoyadi'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                const SizedBox(height: 2),
                Text('${d['sinifi']} • No: ${d['numarasi']} • ${d['sube']} şubesi', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tarihGosterim, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal)),
              if (d['kaydeden_admin'] != null && (d['kaydeden_admin'] as String).isNotEmpty)
                Text(d['kaydeden_admin'], style: const TextStyle(fontSize: 9, color: AppColors.gray)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _gonderBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_sonucMesaji.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _sonucMesaji,
                    style: TextStyle(color: _sonucBasari == true ? AppColors.green : AppColors.red, fontSize: 11, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _gonderiliyor ? null : _gonder,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _gonderiliyor
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Seçilenlere Bildirim Gönder (${_seciliIdler.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
