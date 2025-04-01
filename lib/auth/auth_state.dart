import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  final bool isLoading;
  final String? loadingText;

  const AuthState({required this.isLoading, this.loadingText});

  @override
  List<Object?> get props => [isLoading, loadingText];
}

// Başlangıç durumu
class AuthStateInitial extends AuthState {
  const AuthStateInitial({required super.isLoading});
}

// Kullanıcı giriş yapmışsa
class AuthStateLoggedIn extends AuthState {
  final User user;
  const AuthStateLoggedIn({required this.user})
      : super(isLoading: false);

  @override
  List<Object?> get props => [user];
}

// Kullanıcı e-posta doğrulaması gerekiyorsa
class AuthStateNeedsVerification extends AuthState {
  const AuthStateNeedsVerification() : super(isLoading: false);
}

// Kullanıcı çıkış yapmışsa
class AuthStateLoggedOut extends AuthState {
  const AuthStateLoggedOut({required String errorMessage}) : super(isLoading: false);

  get errorMessage => null;
}

// Şifre sıfırlama ekranındaysa
class AuthStateForgotPassword extends AuthState {
  const AuthStateForgotPassword() : super(isLoading: false);
}

// Kullanıcı kayıt ekranındaysa
class AuthStateRegistering extends AuthState {
  const AuthStateRegistering() : super(isLoading: false);
}
