import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/sinav_model.dart';

class SinavDetay extends StatefulWidget {
  final SinavModel sinav;
  const SinavDetay({super.key, required this.sinav});

  @override
  State<SinavDetay> createState() => _SinavDetayState();
}

class _SiraItem {
  final String label;
  final String deger;
  final String icon;
  final String sub;
  final Color color;
  const _SiraItem(this.label, this.deger, this.icon, this.sub, this.color);
}

class _SinavDetayState extends State<SinavDetay> {
  int _aktifTab = 0;

  final List<Map<String, dynamic>> _dersler = [
    {'ad': 'Türkçe', 'icon': '📖', 'color': AppColors.purple, 'max': 20},
    {'ad': 'Sosyal Bilgiler', 'icon': '🌍', 'color': AppColors.magenta, 'max': 20},
    {'ad': 'Din Kültürü', 'icon': '☪️', 'color': AppColors.teal, 'max': 10},
    {'ad': 'İngilizce', 'icon': '🌐', 'color': AppColors.blue, 'max': 10},
    {'ad': 'Matematik', 'icon': '🔢', 'color': AppColors.orange, 'max': 20},
    {'ad': 'Fen Bilimleri', 'icon': '🔬', 'color': AppColors.green, 'max': 20},
  ];

  List<int> get _dogru => [
    widget.sinav.turkced, widget.sinav.sosd, widget.sinav.dind,
    widget.sinav.ingd, widget.sinav.matd, widget.sinav.fend,
  ];
  List<int> get _yanlis => [
    widget.sinav.turkcey, widget.sinav.sosy, widget.sinav.diny,
    widget.sinav.ingy, widget.sinav.maty, widget.sinav.feny,
  ];
  List<double> get _net => [
    widget.sinav.turkcen, widget.sinav.sosn, widget.sinav.dinn,
    widget.sinav.ingn, widget.sinav.matn, widget.sinav.fenn,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context)),
          SliverToBoxAdapter(child: _tabBar()),
          if (_aktifTab == 0)
            SliverToBoxAdapter(child: _dersAnalizi())
          else
            SliverToBoxAdapter(child: _siralamalar()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Text('← Geri', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 14),
          Text(widget.sinav.sinavtarihi, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11)),
          const SizedBox(height: 3),
          Text(widget.sinav.sinavadi, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LGS PUANI', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(colors: [Colors.white, Color(0xFFD8CCFF)]).createShader(b),
                    child: Text(widget.sinav.lgs.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOPLAM NET', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                  Text(widget.sinav.ton.toStringAsFixed(2), style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 30, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            _tabButon(0, '📚 Ders Analizi'),
            _tabButon(1, '🏆 Sıralamalar'),
          ],
        ),
      ),
    );
  }

  Widget _tabButon(int index, String label) {
    final aktif = _aktifTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _aktifTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: aktif ? AppColors.purple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: aktif ? [BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: aktif ? Colors.white : AppColors.gray)),
        ),
      ),
    );
  }

  Widget _dersAnalizi() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          // Toplam D/Y/Net
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 14)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOPLAM SONUÇ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _toplamKutu('Doğru', '${widget.sinav.tod}', AppColors.green),
                    const SizedBox(width: 8),
                    _toplamKutu('Yanlış', '${widget.sinav.toy}', AppColors.red),
                    const SizedBox(width: 8),
                    _toplamKutu('Net', widget.sinav.ton.toStringAsFixed(2), AppColors.purple),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        Flexible(flex: widget.sinav.tod, child: Container(color: AppColors.green)),
                        Flexible(flex: widget.sinav.toy, child: Container(color: AppColors.red)),
                        Flexible(flex: 120 - widget.sinav.tod - widget.sinav.toy, child: Container(color: AppColors.lightGray)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0', style: TextStyle(fontSize: 10, color: AppColors.gray)),
                    Text('Toplam 120 Soru', style: TextStyle(fontSize: 10, color: AppColors.gray)),
                    Text('120', style: TextStyle(fontSize: 10, color: AppColors.gray)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Ders bazlı tablo
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.07), blurRadius: 14)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DERS BAZLI SONUÇLAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
                const SizedBox(height: 14),
                // Başlık satırı
                Row(
                  children: [
                    const Expanded(flex: 3, child: Text('DERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gray))),
                    ...[' D ', ' Y ', 'NET', ' % '].map((h) => SizedBox(width: 44, child: Text(h, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gray)))),
                  ],
                ),
                const Divider(color: AppColors.lightGray),
                ..._dersler.asMap().entries.map((e) {
                  final i = e.key;
                  final d = e.value;
                  final nv = _net[i];
                  final yuzde = (nv / (d['max'] as int) * 100).round();
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(children: [
                              Text(d['icon'], style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Flexible(child: Text(d['ad'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.dark), overflow: TextOverflow.ellipsis)),
                            ]),
                          ),
                          SizedBox(width: 44, child: Text('${_dogru[i]}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green))),
                          SizedBox(width: 44, child: Text('${_yanlis[i]}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.red))),
                          SizedBox(width: 44, child: Text(nv.toStringAsFixed(2), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: d['color'] as Color))),
                          SizedBox(width: 44, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: (d['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text('%$yuzde', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: d['color'] as Color)),
                          )),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: nv / (d['max'] as int),
                          backgroundColor: AppColors.lightGray,
                          valueColor: AlwaysStoppedAnimation<Color>(d['color'] as Color),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toplamKutu(String label, String deger, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: renk.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(deger, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: renk)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: renk)),
          ],
        ),
      ),
    );
  }

  Widget _siralamalar() {
    final siralar = [
      _SiraItem('Sınıf Sıralaması', '${widget.sinav.dereces}', '🏫', 'Sınıftaki öğrenciler arasında', AppColors.purple),
      _SiraItem('Okul Sıralaması', '${widget.sinav.dereceo}', '🏢', 'Okuldaki tüm öğrenciler arasında', AppColors.blue),
      _SiraItem('İlçe Sıralaması', '${widget.sinav.dereceilce}', '🏘️', 'İlçedeki tüm öğrenciler arasında', AppColors.teal),
      _SiraItem('İl Sıralaması', '${widget.sinav.dereceil}', '🌆', 'İldeki tüm öğrenciler arasında', AppColors.orange),
      _SiraItem('Türkiye Sıralaması', '${widget.sinav.dereceg}', '🇹🇷', 'Türkiye geneli tüm öğrenciler', AppColors.red),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          ...siralar.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [s.color.withOpacity(0.2), s.color.withOpacity(0.08)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: s.color.withOpacity(0.25)),
                  ),
                  child: Center(child: Text(s.icon, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
                    Text(s.sub, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                  ],
                )),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Sıra', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                    Text(s.deger, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: s.color)),
                  ],
                ),
              ],
            ),
          )),
          // LGS Puan kutusu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.purpleL, AppColors.purpleD]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Bu Sınavın LGS Puanı', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Text(widget.sinav.lgs.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, height: 1)),
                const Text('500 tam puan üzerinden', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}