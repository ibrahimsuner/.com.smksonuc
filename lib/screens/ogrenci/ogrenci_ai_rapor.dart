import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

class OgrenciAiRapor extends StatefulWidget {
  final String tcno;
  const OgrenciAiRapor({super.key, required this.tcno});

  @override
  State<OgrenciAiRapor> createState() => _OgrenciAiRaporState();
}

class _OgrenciAiRaporState extends State<OgrenciAiRapor> {
  bool _yukleniyor = true;
  String _hata = '';
  Map<String, dynamic>? _ogrenci;
  List<dynamic> _dersler = [];
  List<dynamic> _acilDersler = [];
  String _aiParagraf = '';

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = ''; });
    final r = await ApiService.yapayZekaRaporu(widget.tcno);
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _ogrenci = Map<String, dynamic>.from(r['ogrenci'] ?? {});
        _dersler = r['dersler'] ?? [];
        _acilDersler = r['acilDersler'] ?? [];
        _aiParagraf = r['aiParagraf'] ?? '';
      } else {
        _hata = r['mesaj'] ?? 'Rapor oluşturulamadı';
      }
      _yukleniyor = false;
    });
  }

  Color _riskRengi(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.gray;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          if (_yukleniyor)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
            )
          else if (_hata.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🤖', style: TextStyle(fontSize: 40)),
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
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _acilBanner()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _dersKarti(_dersler[i]),
                  childCount: _dersler.length,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _aiOzetKarti()),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
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
          const Text('🤖 YAPAY ZEKA ANALİZİ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(
            _ogrenci != null ? 'Son 3 Sınav • ${_ogrenci!['sinifi'] ?? ''}' : 'Akademik Performans Raporu',
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _acilBanner() {
    if (_acilDersler.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.red.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Öncelikli Müdahale Gereken Dersler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.red)),
                  const SizedBox(height: 3),
                  Text(_acilDersler.join(', '), style: const TextStyle(fontSize: 12, color: AppColors.dark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dersKarti(dynamic d) {
    final renk = _riskRengi(d['riskRenk'] as String?);
    final netler = (d['netler'] as List?)?.map((e) => (e as num)) ?? [];
    final netText = netler.map((n) => n.toStringAsFixed(1)).join(' → ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: renk.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Text('${d['trend'] ?? '→'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${d['ad'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dark)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(8)),
                  child: Text('${d['riskAdi'] ?? ''}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _miniIstatistik('Öğrenci', '%${d['ogrOrt'] ?? 0}'),
                    _miniIstatistik('Sınıf', '%${d['sinifOrt'] ?? 0}'),
                    _miniIstatistik('Sıra', '${d['siralama'] ?? '-'}/${d['toplam'] ?? '-'}'),
                  ],
                ),
                if (netText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Son 3 Sınav Neti: $netText', style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 8),
                Text('${d['ozet'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.dark, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniIstatistik(String label, String deger) {
    return Expanded(
      child: Column(
        children: [
          Text(deger, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.purple)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
        ],
      ),
    );
  }

  Widget _aiOzetKarti() {
    if (_aiParagraf.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.purpleL, AppColors.purple]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🤖', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text('YAPAY ZEKA GENEL DEĞERLENDİRME', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 10),
            Text(_aiParagraf, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
