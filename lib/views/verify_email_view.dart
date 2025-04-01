import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';

class VerifyEmailView extends StatelessWidget {
  const VerifyEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E-posta Doğrulama')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'E-posta adresinizi doğrulamak için size bir bağlantı gönderdik.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Eğer e-posta almadıysanız, aşağıdaki butona basarak tekrar gönderebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthEventSendEmailVerification());
              },
              child: const Text('Doğrulama E-postasını Tekrar Gönder'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthEventLogout());
              },
              child: const Text('Çıkış Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
