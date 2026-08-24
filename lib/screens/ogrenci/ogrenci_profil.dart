import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'ogrenci_ai_rapor.dart';

class OgrenciProfil extends StatefulWidget {
  final Map<String, String> oturum;
  final VoidCallback onCikis;

  const OgrenciProfil({super.key, required this.oturum, required this.onCikis});

  @override
  State<OgrenciProfil> createState() => _OgrenciProfilState();
}

class _OgrenciProfilState extends State<OgrenciProfil> {
  bool _bildirim = true;

  String get _tcMasked {
    final tc = widget.oturum['tcno'] ?? '';
    if (tc.length < 5) return tc;
    return '${tc.substring(0, 3)}•••••${tc.substring(tc.length - 2)}';
  }

  // oturum['sube'] zaten "8/A" gibi hem sınıf hem şube harfini birlikte
  // içeriyor. Eskiden burada "7. Sınıf" sabit (hardcoded) yazılıyordu ve
  // ardından yine oturum['sube'] eklenince "7. Sınıf - 8/A Şubesi" gibi
  // hem yanlış hem tekrarlı bir metin çıkıyordu. Artık gerçek veriden
  // ayrıştırılıyor: "8/A" -> sınıf "8", şube "A".
  String get _sinifSubeMetni {
    final sube = widget.oturum['sube'] ?? '';
    final parcalar = sube.split('/');
    if (parcalar.length == 2) {
      return '${parcalar[0]}. Sınıf - ${parcalar[1]} Şubesi';
    }
    // Beklenmedik bir formatta gelirse (örn. sadece "A" ya da boş),
    // hatalı bir sınıf numarası uydurmak yerine olduğu gibi gösterilir.
    return sube.isNotEmpty ? sube : 'Bilgi yok';
  }

  void _cikisOnayla() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              const Text('Çıkış Yapmak Üzeresin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const SizedBox(height: 8),
              const Text('Tekrar girmek için TC kimlik numaranı kullanman gerekecek.', style: TextStyle(fontSize: 12, color: AppColors.gray), textAlign: TextAlign.center),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightGray, foregroundColor: AppColors.gray,
                        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Vazgeç', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () { Navigator.pop(ctx); widget.onCikis(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red, foregroundColor: Colors.white,
                        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 70),
            child: const Center(
              child: Text('PROFİL', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ),
          ),

          // Avatar kartı (header'dan taşan)
          Transform.translate(
            offset: const Offset(0, -56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 84, height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [AppColors.purpleL, AppColors.purple]),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 16)],
                      ),
                      child: const Center(child: Text('🎒', style: TextStyle(fontSize: 38))),
                    ),
                    const SizedBox(height: 14),
                    Text(widget.oturum['adisoyadi'] ?? '', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.dark)),
                    const SizedBox(height: 3),
                    const Text('Öğrenci', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _bilgiKutu('Şube', widget.oturum['sube'] ?? ''),
                        const SizedBox(width: 8),
                        _bilgiKutu('Okul No', widget.oturum['no'] ?? ''),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kişisel bilgiler
                  const Text('KİŞİSEL BİLGİLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  _kart([
                    _satirRow('🪪', 'TC Kimlik No', _tcMasked),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _satirRow('🏫', 'Okul', 'Harbiye Semihe Mehmet Karaali Ortaokulu'),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _satirRow('📚', 'Sınıf / Şube', _sinifSubeMetni),
                  ]),
                  const SizedBox(height: 16),

                  // Akademik Analiz
                  const Text('AKADEMİK ANALİZ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      final tc = widget.oturum['tcno'] ?? '';
                      if (tc.isEmpty) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OgrenciAiRapor(tcno: tc)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.purpleL, AppColors.purple]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Yapay Zeka Destekli Rapor', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                                SizedBox(height: 2),
                                Text('Son 3 sınava göre kişisel analiz', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ayarlar
                  const Text('UYGULAMA AYARLARI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  _kart([
                    _toggleSatir('🔔', 'Bildirimler', 'Yeni sınav sonucu bildirimleri', _bildirim, (v) => setState(() => _bildirim = v)),
                  ]),
                  const SizedBox(height: 16),

                  // Çıkış
                  _kart([
                    _satirRow('🚪', 'Çıkış Yap', '', tiklama: _cikisOnayla, tehlike: true),
                  ]),
                  const SizedBox(height: 16),

                  const Center(
                    child: Text('SMK Sonuç v1.0.0', style: TextStyle(color: AppColors.gray, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bilgiKutu(String label, String deger) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(deger, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.purple)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
          ],
        ),
      ),
    );
  }

  Widget _kart(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.06), blurRadius: 12)],
      ),
      child: Column(children: children),
    );
  }

  Widget _satirRow(String icon, String label, String alt, {VoidCallback? tiklama, bool tehlike = false}) {
    return GestureDetector(
      onTap: tiklama,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: tehlike ? AppColors.red.withOpacity(0.1) : AppColors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 17))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tehlike ? AppColors.red : AppColors.dark)),
                if (alt.isNotEmpty) Text(alt, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
              ]),
            ),
            if (tiklama != null) const Icon(Icons.chevron_right, color: AppColors.gray),
          ],
        ),
      ),
    );
  }

  Widget _toggleSatir(String icon, String label, String alt, bool deger, Function(bool) onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
            Text(alt, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          ])),
          Switch(value: deger, onChanged: onChange, activeColor: AppColors.purple),
        ],
      ),
    );
  }
}