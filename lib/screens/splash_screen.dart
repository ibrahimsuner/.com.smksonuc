import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/session_service.dart';
import 'login_screen.dart';
import 'ogrenci/ogrenci_ana_sayfa.dart';
import 'ogretmen/ogretmen_ana_sayfa.dart';
import 'cocuk_kulubu/cocuk_kulubu_ana_sayfa.dart';
import 'admin/admin_ana_sayfa.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _startProgress();
    _checkSession();
  }

  void _startProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return false;
      setState(() => _progress = (_progress + 0.04).clamp(0.0, 1.0));
      return _progress < 1.0;
    });
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final oturum = await SessionService.oturumOku();

    if (oturum != null) {
      if (oturum['tip'] == 'ogretmen') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OgretmenAnaSayfa(oturum: oturum),
          ),
        );
      } else if (oturum['tip'] == 'cocukkulubu') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CocukKulubuAnaSayfa(oturum: oturum),
          ),
        );
      } else if (oturum['tip'] == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminAnaSayfa(oturum: oturum),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OgrenciAnaSayfa(oturum: oturum),
          ),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purpleL, AppColors.purple, AppColors.purpleD],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100, right: -80,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -60, left: -50,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset('assets/images/logo.png', width: 90, height: 90, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'HARBİYE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Semihe Mehmet Karaali',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ortaokulu',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppColors.green, AppColors.orange,
                        AppColors.magenta, AppColors.yellow, AppColors.red,
                      ].asMap().entries.map((e) {
                        return Container(
                          width: 7, height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: e.value,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}