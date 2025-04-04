import 'package:chatbot3/views/verify_email_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';
import '../auth/auth_state.dart';
import 'package:chatbot3/services/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap'),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lütfen giriş bilgilerinizi girin:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthStateLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Başarıyla giriş yapıldı!')),
                  );
                }
                else if (state is AuthStateNeedsVerification) {
                  // Navigate to verification screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const VerifyEmailView()),
                  );
                }
                else if (state is AuthStateLoggedOut && state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage!)),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();
                        context.read<AuthBloc>().add(AuthEventLogin(
                          email: email,
                          password: password,
                        ));
                      },
                      child: const Text('Giriş Yap'),
                    ),
                    TextButton(
                      onPressed: () {
                        final String email = _emailController.text;
                        final String password = _passwordController.text;
                        context.read<AuthBloc>().add(AuthEventRegister(email: email, password: password));
                      },
                      child: const Text('Kayıt Ol'),
                    ),
                    TextButton(
                      onPressed: () {
                        final String email = _emailController.text;
                        context.read<AuthBloc>().add(AuthEventForgotPassword(email: email ));
                      },
                      child: const Text('Şifremi Unuttum'),
                    ),
                    TextButton(
                      onPressed: () async{
                       await AuthService().signInWithGoogle();
                      },
                      child: const Text('Google ile giriş yap.'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
