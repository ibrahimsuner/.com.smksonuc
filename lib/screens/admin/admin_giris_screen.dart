import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import 'admin_ana_sayfa.dart';

class AdminGirisScreen extends StatefulWidget {
  const AdminGirisScreen({super.key});

  @override
  State<AdminGirisScreen> createState() => _AdminGirisScreenState();
}

class _AdminGirisScreenState extends State<AdminGirisScreen> {
  final _kullaniciAdiController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _sifreGizli = true;
  bool _yukleniyor = false;
  String _hata = '';

  @override
  void dispose() {
    _kullaniciAdiController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (_kullaniciAdiController.text.trim().isEmpty || _sifreController.text.isEmpty) {
      setState(() => _hata = 'Kullanıcı adı ve şifre boş olamaz');
      return;
    }
    setState(() { _yukleniyor = true; _hata = ''; });

    final sonuc = await ApiService.adminGiris(
      kullaniciAdi: _kullaniciAdiController.text.trim(),
      sifre: _sifreController.text,
    );

    if (!mounted) return;
    setState(() => _yukleniyor = false);

    if (sonuc['basari'] == true) {
      final oturum = <String, String>{
        'tip': 'admin',
        'tcno': sonuc['kullaniciAdi'] ?? '', // admin için "tcno" alanı kullanıcı adını tutuyor
        'adisoyadi': sonuc['adisoyadi'] ?? 'Yönetici',
      };
      await SessionService.oturumKaydet(
        tip: 'admin',
        tcno: oturum['tcno']!,
        adisoyadi: oturum['adisoyadi']!,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => AdminAnaSayfa(oturum: oturum),
      ));
    } else {
      setState(() => _hata = sonuc['mesaj'] ?? 'Giriş başarısız');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('← Geri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray)),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.dark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(child: Text('🛡️', style: TextStyle(fontSize: 30))),
              ),
              const SizedBox(height: 18),
              const Text('Yönetici Girişi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const SizedBox(height: 6),
              const Text('Bu alan yalnızca okul yöneticileri içindir.', style: TextStyle(color: AppColors.gray, fontSize: 13)),
              const SizedBox(height: 28),

              const Text('KULLANICI ADI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray)),
              const SizedBox(height: 8),
              TextField(
                controller: _kullaniciAdiController,
                decoration: InputDecoration(
                  hintText: 'Kullanıcı adı',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              const Text('ŞİFRE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray)),
              const SizedBox(height: 8),
              TextField(
                controller: _sifreController,
                obscureText: _sifreGizli,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(_sifreGizli ? Icons.visibility_off : Icons.visibility, color: AppColors.gray),
                    onPressed: () => setState(() => _sifreGizli = !_sifreGizli),
                  ),
                ),
                onSubmitted: (_) => _girisYap(),
              ),

              if (_hata.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_hata, style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w600))),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _yukleniyor ? null : _girisYap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _yukleniyor
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Giriş Yap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
