import 'package:chatbot3/services/chat_service.dart';
import 'package:chatbot3/views/chat_screen.dart';
import 'package:chatbot3/views/forgot_password_view.dart';
import 'package:chatbot3/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth/auth_bloc.dart';
import 'auth/auth_event.dart';
import 'auth/auth_state.dart';
import 'cubit/chat_cubit.dart';
import 'loading_screen.dart';
import 'views/register_view.dart';
import 'views/verify_email_view.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  var _ChatService = ChatService();
  runApp(
    MultiBlocProvider(
      providers: [
        // Auth işlemleri için Bloc
        BlocProvider(
          create: (context) => AuthBloc()..add(const AuthEventInitialize()),
        ),
        // Chat işlemleri için Cubit
        BlocProvider(
          create: (context) => ChatCubit(_ChatService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required String title});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isLoading) {
          LoadingScreen().show(
            context: context,
            text: state.loadingText ?? 'Please wait a moment.',
          );
        } else {
          LoadingScreen().hide();
        }
      },
      builder: (context, state) {
        print('Mevcut state: $state');
        if (state is AuthStateLoggedIn) {
          return ChatScreen();
        } else if (state is AuthStateNeedsVerification) {
          return const VerifyEmailView();
        } else if (state is AuthStateLoggedOut) {
          return LoginView();
        } else if (state is AuthStateForgotPassword) {
          return const ForgotPasswordView();
        } else if (state is AuthStateRegistering) {
          return const RegisterView();
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
