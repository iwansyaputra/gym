import 'package:flutter/material.dart';
import 'package:membership_gym/pages/akun.dart';
import 'package:membership_gym/pages/beranda.dart';
import 'package:membership_gym/pages/login.dart';
import 'package:membership_gym/pages/promo.dart';
import 'package:membership_gym/pages/card.dart';
import 'package:membership_gym/pages/riwayat.dart';
import 'package:membership_gym/pages/registrasi.dart';

/// Main entry point aplikasi GymKu
/// Aplikasi membership gym dengan fitur login, registrasi, check-in NFC, dan management membership
void main() {
  runApp(const MyWidget());
}

/// Root widget aplikasi - MaterialApp dengan routing
/// Mendefinisikan semua rute/halaman yang tersedia dalam aplikasi
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymKu - Membership Gym',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          primary: const Color(0xFF1976D2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      // Halaman pertama yang ditampilkan saat app buka
      initialRoute: '/',
      // Definisi semua rute navigasi dalam aplikasi
      routes: {
        '/': (context) => const LoginPage(),
        '/login': (context) => const LoginPage(),
        '/beranda': (context) => const BerandaPage(),
        '/promo': (context) => const PromoPage(),
        '/card': (context) => const CardMemberPage(),
        '/riwayat': (context) => const RiwayatPage(),
        '/akun': (context) => const AkunPage(),
        '/registrasi': (context) => const RegistrasiPage(),
      },
    );
  }
}
