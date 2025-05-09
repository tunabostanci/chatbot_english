import 'package:flutter/material.dart';

class LoadingScreen {
  static final LoadingScreen _instance = LoadingScreen._internal();
  factory LoadingScreen() => _instance;
  LoadingScreen._internal();

  BuildContext? _context;

  void show({required BuildContext context, required String text}) {
    if (_context != null) return; // Eğer zaten açık bir loading varsa, tekrar açma


    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı ekrana basarak kapatamaz
      builder: (context) {
        _context = context;
        return WillPopScope(
          onWillPop: () async => false, // Geri tuşu ile kapatılmasını engelle
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(text),
              ],
            ),
          ),
        );
      },
    );
  }

  void hide() {
    if (_context != null && Navigator.canPop(_context!)) {
      Navigator.of(_context!).pop(); // Açık olan loading ekranını kapat
    }
    _context = null;
  }
}
