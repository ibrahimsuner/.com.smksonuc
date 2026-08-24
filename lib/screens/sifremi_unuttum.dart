import 'package:flutter/material.dart';
import 'package:smksonuc/constants/colors.dart';
import 'package:smksonuc/services/api_service.dart';

class SifremiUnuttum extends StatefulWidget {
  const SifremiUnuttum({super.key});
  @override
  State<SifremiUnuttum> createState() => _SifremiUnuttumState();
}

class _SifremiUnuttumState extends State<SifremiUnuttum> {
  int _adim = 0;
  final _tcController = TextEditingController();
  final _cevapController = TextEditingController();
  final _yeniSifre = TextEditingController();
  final _yeniSifreTekrar = TextEditingController();
  String _soru = '';
  bool _yukleniyor = false;
  String _hata = '';
  bool _basarili = false;

  Future<void> _soruGetir() async {
    if (_tcController.text.length != 11) {
      setState(() => _hata = 'TC kimlik numarası 11 haneli olmalı'); return;
    }
    setState(() { _yukleniyor = true; _hata = ''; });
    final r = await ApiService.ogretmenGuvenlikSoruGetir(_tcController.text.trim());
    if (!mounted) return;
    setState(() => _yukleniyor = false);
    if (r['basari'] == true) {
      setState(() { _soru = r['soru']; _adim = 1; });
    } else {
      setState(() => _hata = r['mesaj'] ?? 'İşlem başarısız');
    }
  }

  Future<void> _sifreyiSifirla() async {
    if (_cevapController.text.trim().isEmpty) {
      setState(() => _hata = 'Cevabı gir'); return;
    }
    if (_yeniSifre.text.length < 6) {
      setState(() => _hata = 'Yeni şifre en az 6 karakter olmalı'); return;
    }
    if (_yeniSifre.text != _yeniSifreTekrar.text) {
      setState(() => _hata = 'Şifreler eşleşmiyor'); return;
    }
    setState(() { _yukleniyor = true; _hata = ''; });
    final r = await ApiService.ogretmenSifreSifirla(
      tcno: _tcController.text.trim(),
      guvenlikCevap: _cevapController.text.trim(),
      yeniSifre: _yeniSifre.text.trim(),
    );
    if (!mounted) return;
    setState(() => _yukleniyor = false);
    if (r['basari'] == true) {
      setState(() => _basarili = true);
    } else {
      setState(() => _hata = r['mesaj'] ?? 'İşlem başarısız');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Şifremi Unuttum'), backgroundColor: Colors.transparent, elevation: 0, foregroundColor: AppColors.dark),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _basarili ? _basariEkrani() : (_adim == 0 ? _adim0() : _adim1()),
        ),
      ),
    );
  }

  Widget _adim0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🔎', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 10),
        const Text('Hesabını Bul', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
        const SizedBox(height: 6),
        const Text('TC kimlik numaranı gir, sana ait güvenlik sorusunu göstereceğiz.', style: TextStyle(color: AppColors.gray, fontSize: 13)),
        const SizedBox(height: 20),
        TextField(
          controller: _tcController, keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'TC Kimlik No', filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (_hata.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(_hata, style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _yukleniyor ? null : _soruGetir,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _yukleniyor ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Devam Et', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _adim1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔑', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          const Text('Güvenlik Sorusu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(_soru, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
          ),
          const SizedBox(height: 14),
          TextField(controller: _cevapController, decoration: _dekor('Cevabını yaz')),
          const SizedBox(height: 16),
          const Text('YENİ ŞİFRE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray)),
          const SizedBox(height: 8),
          TextField(controller: _yeniSifre, obscureText: true, decoration: _dekor('En az 6 karakter')),
          const SizedBox(height: 14),
          const Text('YENİ ŞİFRE (TEKRAR)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray)),
          const SizedBox(height: 8),
          TextField(controller: _yeniSifreTekrar, obscureText: true, decoration: _dekor('Tekrar gir')),
          if (_hata.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_hata, style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _yukleniyor ? null : _sifreyiSifirla,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _yukleniyor ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Şifreyi Sıfırla', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _basariEkrani() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✅', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          const Text('Şifren Güncellendi', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.dark)),
          const SizedBox(height: 6),
          const Text('Yeni şifrenle giriş yapabilirsin.', style: TextStyle(color: AppColors.gray)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Girişe Dön', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  InputDecoration _dekor(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}