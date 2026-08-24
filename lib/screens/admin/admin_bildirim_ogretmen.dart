import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

class AdminBildirimOgretmen extends StatefulWidget {
  const AdminBildirimOgretmen({super.key});

  @override
  State<AdminBildirimOgretmen> createState() => _AdminBildirimOgretmenState();
}

class _AdminBildirimOgretmenState extends State<AdminBildirimOgretmen> {
  bool _yukleniyor = true;
  List<dynamic> _ogretmenler = [];
  final Set<String> _seciliOgretmenler = {};
  final _baslikCtrl = TextEditingController();
  final _mesajCtrl = TextEditingController();
  bool _gonderiliyor = false;
  String _sonucMesaji = '';
  bool? _sonucBasari;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _baslikCtrl.dispose();
    _mesajCtrl.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    final r = await ApiService.adminBildirimMeta();
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _ogretmenler = r['ogretmenler'] ?? [];
      }
      _yukleniyor = false;
    });
  }

  Future<void> _gonder() async {
    if (_seciliOgretmenler.isEmpty) {
      setState(() { _sonucBasari = false; _sonucMesaji = 'Lütfen en az bir öğretmen seç'; });
      return;
    }
    if (_baslikCtrl.text.trim().isEmpty || _mesajCtrl.text.trim().isEmpty) {
      setState(() { _sonucBasari = false; _sonucMesaji = 'Başlık ve mesaj boş olamaz'; });
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duyuru Gönder'),
        content: Text('${_seciliOgretmenler.length} öğretmene bildirim gönderilecek. Emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gönder')),
        ],
      ),
    );
    if (onay != true) return;

    setState(() { _gonderiliyor = true; _sonucMesaji = ''; });
    final r = await ApiService.adminBildirimOgretmenGonder(
      ogretmenler: _seciliOgretmenler.toList(),
      baslik: _baslikCtrl.text.trim(),
      mesaj: _mesajCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _gonderiliyor = false;
      _sonucBasari = r['basari'] == true;
      _sonucMesaji = r['basari'] == true
          ? 'Başarılı: ${r['gonderilen']} öğretmene bildirim gönderildi.'
          : (r['mesaj'] ?? 'Gönderilemedi');
    });
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
              sliver: SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.orange))),
            )
          else
            SliverToBoxAdapter(child: _icerik()),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFA726), AppColors.orange, Color(0xFFE65100)]),
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
          const Text('📢 ÖĞRETMENLERE DUYURU', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text('Serbest Metinli Bildirim', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _icerik() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ÖĞRETMEN(LER) SEÇ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 10),
          if (_ogretmenler.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Henüz uygulamaya giriş yapıp bildirim izni vermiş öğretmen yok', style: TextStyle(color: AppColors.gray)),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: ListView(
                shrinkWrap: true,
                children: _ogretmenler.map((o) {
                  final tcno = o['tcno'] as String;
                  final secili = _seciliOgretmenler.contains(tcno);
                  return CheckboxListTile(
                    value: secili,
                    onChanged: (v) => setState(() { if (v == true) _seciliOgretmenler.add(tcno); else _seciliOgretmenler.remove(tcno); }),
                    title: Text(o['adisoyadi'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    activeColor: AppColors.orange,
                    dense: true,
                  );
                }).toList(),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                final tumTcnolar = _ogretmenler.map((o) => o['tcno'] as String).toList();
                if (_seciliOgretmenler.length == tumTcnolar.length) { _seciliOgretmenler.clear(); }
                else { _seciliOgretmenler..clear()..addAll(tumTcnolar); }
              }),
              child: const Text('Tümünü Seç / Kaldır', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),

          const SizedBox(height: 10),
          const Text('BAŞLIK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 8),
          TextField(
            controller: _baslikCtrl,
            decoration: InputDecoration(
              hintText: 'Örn: Toplantı Hatırlatması',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 14),
          const Text('MESAJ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 8),
          TextField(
            controller: _mesajCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Örn: Yarın saat 14:00\'te öğretmenler odasında toplantımız var.',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          if (_sonucMesaji.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_sonucBasari == true ? AppColors.green : AppColors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_sonucMesaji, style: TextStyle(color: _sonucBasari == true ? AppColors.green : AppColors.red, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)),
            ),
          ],

          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _gonderiliyor ? null : _gonder,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _gonderiliyor
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Duyuruyu Gönder', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
