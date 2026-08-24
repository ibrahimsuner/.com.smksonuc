import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

class CocukKulubuKayitDurum extends StatefulWidget {
  const CocukKulubuKayitDurum({super.key});
  @override
  State<CocukKulubuKayitDurum> createState() => _CocukKulubuKayitDurumState();
}

class _CocukKulubuKayitDurumState extends State<CocukKulubuKayitDurum> {
  final _tcCtrl = TextEditingController();
  bool _yukleniyor = false;
  String _hata = '';
  List<dynamic> _kayitlar = [];

  Future<void> _sorgula() async {
    if (_tcCtrl.text.length != 11) {
      setState(() => _hata = '11 haneli TC kimlik numarası giriniz');
      return;
    }
    setState(() { _yukleniyor = true; _hata = ''; _kayitlar = []; });
    final r = await ApiService.cocukKulubuDurumSorgula(_tcCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (r['basari'] == true) {
        _kayitlar = r['kayitlar'] ?? [];
      } else {
        _hata = r['mesaj'] ?? 'Kayıt bulunamadı';
      }
    });
  }

  Color _durumRenk(String durum) {
    if (durum == 'onaylandi') return AppColors.green;
    if (durum == 'reddedildi') return AppColors.red;
    return AppColors.orange;
  }

  String _durumMetin(String durum) {
    if (durum == 'onaylandi') return '✅ Onaylandı';
    if (durum == 'reddedildi') return '❌ Reddedildi';
    return '⏳ Beklemede';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context)),
          SliverToBoxAdapter(child: _form()),
          if (_yukleniyor)
            const SliverPadding(padding: EdgeInsets.symmetric(vertical: 40), sliver: SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.purple))))
          else if (_hata.isNotEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(_hata, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)))))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              sliver: SliverList(delegate: SliverChildBuilderDelegate((c, i) => _kayitKarti(_kayitlar[i]), childCount: _kayitlar.length)),
            ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
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
          const Text('🔍 Kayıt Durumu Sorgula', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Öğrencinin TC kimlik numarasını gir', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _form() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 10)]),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _tcCtrl,
              keyboardType: TextInputType.number,
              maxLength: 11,
              decoration: const InputDecoration(hintText: 'TC Kimlik No', counterText: '', border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _yukleniyor ? null : _sorgula,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18)),
            child: const Text('Sorgula'),
          ),
        ]),
      ),
    );
  }

  Widget _kayitKarti(dynamic k) {
    final ucret = double.tryParse(k['ucret'].toString()) ?? 0;
    final odenen = double.tryParse((k['odenen_tutar'] ?? 0).toString()) ?? 0;
    final durum = k['onay_durumu'] ?? 'beklemede';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _durumRenk(durum).withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(k['adisoyadi'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.dark)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _durumRenk(durum).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(_durumMetin(durum), style: TextStyle(color: _durumRenk(durum), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Sınıf: ${k['sinifi'] ?? '-'}  •  No: ${k['numarasi'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          if (durum == 'onaylandi' && (k['sube'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('🏫 Çocuk Kulübü Şubesi: ${k['sube']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purple)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text('Beklenen: ${ucret.toStringAsFixed(0)} ₺', style: const TextStyle(fontSize: 12, color: AppColors.gray))),
            Expanded(child: Text('Ödenen: ${odenen.toStringAsFixed(0)} ₺', style: TextStyle(fontSize: 12, color: odenen >= ucret ? AppColors.green : AppColors.red, fontWeight: FontWeight.w700))),
          ]),
        ],
      ),
    );
  }
}