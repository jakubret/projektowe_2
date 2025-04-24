import 'package:zabytki_app/blocs/auth/auth_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_event.dart';
import 'package:zabytki_app/blocs/auth/auth_state.dart';
import 'package:zabytki_app/persistent_scaffold.dart'; // Zakładam, że to jest Twoja strona główna
import 'package:zabytki_app/repositories/auth_repository.dart';
import 'package:zabytki_app/screens/auth_screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  final AuthRepository _authRepository = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(authRepository: _authRepository)..add(AuthStarted()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            // Nawiguj do strony głównej
            return const PersistentScaffold(); // Zmień na Twój widget strony głównej
          } else if (state is AuthUnauthenticated) {
            return  LoginScreen();
          } else if (state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            return const Scaffold(
              body: Center(child: Text('Sprawdzanie autentykacji...')),
            );
          }
        },
      ),
    );
  }
}