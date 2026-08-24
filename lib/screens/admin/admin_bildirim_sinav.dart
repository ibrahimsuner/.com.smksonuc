import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

class AdminBildirimSinav extends StatefulWidget {
  const AdminBildirimSinav({super.key});

  @override
  State<AdminBildirimSinav> createState() => _AdminBildirimSinavState();
}

class _AdminBildirimSinavState extends State<AdminBildirimSinav> {
  bool _yukleniyor = true;
  List<String> _siniflar = [];
  List<dynamic> _sinavlar = [];
  final Set<String> _seciliSiniflar = {};
  String? _seciliSinav;
  bool _gonderiliyor = false;
  String _sonucMesaji = '';
  bool? _sonucBasari;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    final r = await ApiService.adminBildirimMeta();
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _siniflar = List<String>.from(r['siniflar'] ?? []);
        _sinavlar = r['sinavlar'] ?? [];
        _seciliSinav = _sinavlar.isNotEmpty ? _sinavlar.first['sinavadi'] : null;
      }
      _yukleniyor = false;
    });
  }

  Future<void> _gonder() async {
    if (_seciliSiniflar.isEmpty) {
      setState(() { _sonucBasari = false; _sonucMesaji = 'Lütfen en az bir şube seç'; });
      return;
    }
    if (_seciliSinav == null) {
      setState(() { _sonucBasari = false; _sonucMesaji = 'Lütfen bir sınav seç'; });
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bildirim Gönder'),
        content: Text('${_seciliSiniflar.length} şubeye "$_seciliSinav" bildirimi gönderilecek. Emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gönder')),
        ],
      ),
    );
    if (onay != true) return;

    setState(() { _gonderiliyor = true; _sonucMesaji = ''; });
    final r = await ApiService.adminBildirimSinavGonder(
      siniflar: _seciliSiniflar.toList(),
      sinavadi: _seciliSinav!,
    );
    if (!mounted) return;
    setState(() {
      _gonderiliyor = false;
      _sonucBasari = r['basari'] == true;
      _sonucMesaji = r['basari'] == true
          ? 'Başarılı: ${r['gonderilen']} bildirim gönderildi. (Kayıtlı öğrenci: ${r['toplamOgrenci']}, token sahibi: ${r['tokenSahibi']})'
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
              sliver: SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.blue))),
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
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF42A5F5), Color(0xFF1565C0), Color(0xFF0D47A1)]),
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
          const Text('📊 SINAV SONUCU BİLDİRİMİ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          const Text('Öğrenci / Veliye Gönder', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
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
          const Text('ŞUBE(LER) SEÇ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 10),
          if (_siniflar.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Sistemde kayıtlı şube bulunamadı', style: TextStyle(color: AppColors.gray)))
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: ListView(
                shrinkWrap: true,
                children: _siniflar.map((s) {
                  final secili = _seciliSiniflar.contains(s);
                  return CheckboxListTile(
                    value: secili,
                    onChanged: (v) => setState(() { if (v == true) _seciliSiniflar.add(s); else _seciliSiniflar.remove(s); }),
                    title: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    activeColor: AppColors.blue,
                    dense: true,
                  );
                }).toList(),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                if (_seciliSiniflar.length == _siniflar.length) { _seciliSiniflar.clear(); }
                else { _seciliSiniflar..clear()..addAll(_siniflar); }
              }),
              child: Text(_seciliSiniflar.length == _siniflar.length && _siniflar.isNotEmpty ? 'Seçimi Kaldır' : 'Tümünü Seç', style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),

          const SizedBox(height: 10),
          const Text('SINAV ADI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
          const SizedBox(height: 10),
          if (_sinavlar.isEmpty)
            const Text('Sistemde henüz sınav verisi yok', style: TextStyle(color: AppColors.gray))
          else
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _seciliSinav,
                  isExpanded: true,
                  items: _sinavlar.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                    value: s['sinavadi'] as String,
                    child: Text('${s['sinavadi']} (${s['sontarih']})', style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() => _seciliSinav = v),
                ),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _gonderiliyor
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Bildirimi Gönder', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
