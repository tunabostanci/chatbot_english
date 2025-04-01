import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

// Başlangıç olayını tanımla
class AuthEventInitialize extends AuthEvent {
  const AuthEventInitialize();
}

// Kullanıcı çıkış yapınca tetiklenecek olay
class AuthEventLogout extends AuthEvent {
  const AuthEventLogout();
}
class AuthEventRegister extends AuthEvent {
  final String email;
  final String password;

  const AuthEventRegister({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
class AuthEventSendEmailVerification extends AuthEvent {
  const AuthEventSendEmailVerification();
}
class AuthEventLogin extends AuthEvent {
  final String email;
  final String password;

  const AuthEventLogin({required this.email, required this.password});
}
class AuthEventForgotPassword extends AuthEvent {
  final String email;

  const AuthEventForgotPassword({required this.email});
}


