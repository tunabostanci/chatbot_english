import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthBloc() : super(const AuthStateInitial(isLoading: true)) {
    on<AuthEventInitialize>((event, emit) async {
      final user = _auth.currentUser;
      if (user == null) {
        emit(const AuthStateLoggedOut(errorMessage: ''));
      } else if (!user.emailVerified) {
        emit(const AuthStateNeedsVerification());
      } else {
        emit(AuthStateLoggedIn(user: user));
      }
    });

    on<AuthEventLogout>((event, emit) async {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      emit(const AuthStateLoggedOut(errorMessage: ''));
    });

    on<AuthEventRegister>((event, emit) async {
      emit(const AuthStateInitial(isLoading: true));
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        emit(AuthStateLoggedIn(user: userCredential.user!));
      } catch (e) {
        emit(const AuthStateLoggedOut(errorMessage: ''));
      }
      emit(AuthStateNeedsVerification());
    });
    on<AuthEventSendEmailVerification>((event, emit) async {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    });
    on<AuthEventLogin>((event, emit) async {
      emit(const AuthStateInitial(isLoading: true)); // Yüklenme durumu
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        if (userCredential.user?.emailVerified ?? false) {
          emit(AuthStateLoggedIn(user: userCredential.user!));
        } else {
          emit(const AuthStateNeedsVerification());
        }
      } catch (e) {
        emit(const AuthStateLoggedOut(errorMessage: 'Giriş başarısız!'));
      }
    });
    on<AuthEventForgotPassword>((event, emit) async {
      emit(const AuthStateInitial(isLoading: true)); // Yüklenme durumu
      try {
        await _auth.sendPasswordResetEmail(email: event.email);
        emit(const AuthStateLoggedOut(
          errorMessage: 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.',
        ));
      } catch (e) {
        emit(const AuthStateLoggedOut(
          errorMessage: 'Şifre sıfırlama başarısız!',
        ));
      }
    });
    on<AuthEventGoogleLogin>((event, emit) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(AuthStateLoggedIn(user: user)); // emailVerified kontrolü yapılmadan
      } else {
        emit(const AuthStateLoggedOut(errorMessage: 'Google girişi başarısız.'));
      }
    });

  }
}
