import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';

class AdminOgrenciYonetimi extends StatefulWidget {
  const AdminOgrenciYonetimi({super.key});

  @override
  State<AdminOgrenciYonetimi> createState() => _AdminOgrenciYonetimiState();
}

class _AdminOgrenciYonetimiState extends State<AdminOgrenciYonetimi> {
  bool _yukleniyor = true;
  List<dynamic> _ogrenciler = [];
  List<String> _siniflar = [];
  String? _seciliSinif; // null = tümü
  String _aramaMetni = '';
  String _hata = '';
  final _aramaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = ''; });
    final r = await ApiService.adminOgrenciListe(arama: _aramaMetni, sinif: _seciliSinif ?? '');
    if (!mounted) return;
    setState(() {
      if (r['basari'] == true) {
        _ogrenciler = r['ogrenciler'] ?? [];
        _siniflar = List<String>.from(r['siniflar'] ?? []);
      } else {
        _ogrenciler = [];
        _hata = r['mesaj'] ?? 'Öğrenciler yüklenemedi';
      }
      _yukleniyor = false;
    });
  }

  void _formGoster({Map<String, dynamic>? duzenlenecek}) {
    final tcCtrl = TextEditingController(text: duzenlenecek?['tcno'] ?? '');
    final adCtrl = TextEditingController(text: duzenlenecek?['adisoyadi'] ?? '');
    final sinifCtrl = TextEditingController(text: duzenlenecek?['sinifi'] ?? '');
    final noCtrl = TextEditingController(text: duzenlenecek?['numarasi'] ?? '');
    final veliTelCtrl = TextEditingController(text: duzenlenecek?['veli_telefon'] ?? '');
    final duzenlemeModu = duzenlenecek != null;
    String hata = '';
    bool yukleniyor = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 18),
                  Text(duzenlemeModu ? 'Öğrenciyi Güncelle' : 'Yeni Öğrenci Ekle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  const SizedBox(height: 18),

                  _etiket('TC KİMLİK NUMARASI'),
                  TextField(controller: tcCtrl, keyboardType: TextInputType.number, maxLength: 11, decoration: _dekor('11 haneli TC no')),

                  _etiket('AD SOYAD'),
                  TextField(controller: adCtrl, decoration: _dekor('Öğrencinin adı soyadı')),

                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _etiket('ŞUBE'),
                      TextField(controller: sinifCtrl, decoration: _dekor('Örn: 5/A')),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _etiket('OKUL NO'),
                      TextField(controller: noCtrl, keyboardType: TextInputType.number, decoration: _dekor('Örn: 24')),
                    ])),
                  ]),

                  _etiket('VELİ TELEFONU (İSTEĞE BAĞLI)'),
                  TextField(controller: veliTelCtrl, keyboardType: TextInputType.phone, decoration: _dekor('05XX XXX XX XX')),

                  if (hata.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(hata, style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],

                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: yukleniyor ? null : () async {
                        if (tcCtrl.text.trim().length != 11) { setSt(() => hata = 'TC kimlik no 11 haneli olmalı'); return; }
                        if (adCtrl.text.trim().isEmpty) { setSt(() => hata = 'Ad soyad boş olamaz'); return; }
                        if (sinifCtrl.text.trim().isEmpty) { setSt(() => hata = 'Şube boş olamaz'); return; }

                        setSt(() { yukleniyor = true; hata = ''; });

                        final Map<String, dynamic> sonuc;
                        if (duzenlemeModu) {
                          sonuc = await ApiService.adminOgrenciGuncelle(
                            eskiTcno: duzenlenecek['tcno'] as String,
                            tcno: tcCtrl.text.trim(),
                            adisoyadi: adCtrl.text.trim(),
                            sinifi: sinifCtrl.text.trim(),
                            numarasi: noCtrl.text.trim(),
                            veliTelefon: veliTelCtrl.text.trim(),
                          );
                        } else {
                          sonuc = await ApiService.adminOgrenciEkle(
                            tcno: tcCtrl.text.trim(),
                            adisoyadi: adCtrl.text.trim(),
                            sinifi: sinifCtrl.text.trim(),
                            numarasi: noCtrl.text.trim(),
                            veliTelefon: veliTelCtrl.text.trim(),
                          );
                        }

                        if (sonuc['basari'] == true) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          _yukle();
                        } else {
                          setSt(() { yukleniyor = false; hata = sonuc['mesaj'] ?? 'İşlem başarısız'; });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: yukleniyor
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(duzenlemeModu ? 'Güncelle' : 'Ekle', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _silOnayla(Map<String, dynamic> ogrenci) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗑️', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text('${ogrenci['adisoyadi']} silinsin mi?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const SizedBox(height: 6),
              const Text('Bu işlem geri alınamaz.', style: TextStyle(fontSize: 12, color: AppColors.gray)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightGray, foregroundColor: AppColors.gray, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
                  child: const Text('Vazgeç', style: TextStyle(fontWeight: FontWeight.w700)),
                )),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final r = await ApiService.adminOgrenciSil(ogrenci['tcno'] as String);
                    if (r['basari'] == true) { _yukle(); }
                    else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['mesaj'] ?? 'Silinemedi')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
                  child: const Text('Sil', style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _aramaVeFiltre()),
          if (_yukleniyor)
            const SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 60),
              sliver: SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.purple))),
            )
          else if (_hata.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(children: [
                    const Text('⚠️', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 10),
                    Text(_hata, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _yukle, child: const Text('Tekrar Dene')),
                  ]),
                ),
              ),
            )
          else if (_ogrenciler.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Öğrenci bulunamadı', style: TextStyle(color: AppColors.gray)))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) => _ogrenciKarti(_ogrenciler[i]),
                    childCount: _ogrenciler.length,
                  ),
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formGoster(),
        backgroundColor: AppColors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Öğrenci Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 20),
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
          const Text('👥 ÖĞRENCİ YÖNETİMİ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text('${_ogrenciler.length} öğrenci', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _aramaVeFiltre() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
            child: TextField(
              controller: _aramaCtrl,
              decoration: const InputDecoration(
                hintText: 'İsim, TC no veya okul numarası...',
                prefixIcon: Icon(Icons.search, color: AppColors.gray),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (v) { _aramaMetni = v; _yukle(); },
            ),
          ),
          if (_siniflar.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _sinifCip('Tümü', null),
                  ..._siniflar.map((s) => _sinifCip(s, s)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sinifCip(String label, String? deger) {
    final secili = _seciliSinif == deger;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () { setState(() => _seciliSinif = deger); _yukle(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: secili ? AppColors.purple : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: secili ? Colors.white : AppColors.gray))),
        ),
      ),
    );
  }

  Widget _ogrenciKarti(dynamic o) {
    final veliTel = (o['veli_telefon'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.purpleL, AppColors.purple]), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text((o['sinifi'] ?? '').toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800), textAlign: TextAlign.center)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o['adisoyadi'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
                const SizedBox(height: 2),
                Text('No: ${o['numarasi']} • TC: ${o['tcno']}', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                if (veliTel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('📞 $veliTel', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _formGoster(duzenlenecek: Map<String, dynamic>.from(o)),
            icon: const Icon(Icons.edit_outlined, color: AppColors.purple, size: 20),
          ),
          IconButton(
            onPressed: () => _silOnayla(Map<String, dynamic>.from(o)),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _etiket(String metin) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(metin, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray)),
  );

  InputDecoration _dekor(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
