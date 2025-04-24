import 'package:equatable/equatable.dart';
import 'package:zabytki_app/repositories/auth_repository.dart'; // Upewnij się, że ścieżka jest poprawna

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  @override
  List<Object?> get props => [];
}

class AuthLoggedIn extends AuthEvent {
  final User user;

  const AuthLoggedIn({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthRegistered extends AuthEvent {
  final String email;
  final String password;

  const AuthRegistered({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLoggedOut extends AuthEvent {
  @override
  List<Object?> get props => [];
}