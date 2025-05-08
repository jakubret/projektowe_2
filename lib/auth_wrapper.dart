import 'package:zabytki_app/blocs/auth/auth_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_event.dart';
import 'package:zabytki_app/blocs/auth/auth_state.dart';
import 'package:zabytki_app/persistent_scaffold.dart';
import 'package:zabytki_app/repositories/auth_repository.dart';
import 'package:zabytki_app/screens/auth_screens/login_screen.dart';
import 'package:zabytki_app/screens/auth_screens/registration_screen.dart'; // Zaimportuj RegistrationScreen
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const PersistentScaffold();
        } else if (state is AuthUnauthenticated) {
          return const LoginScreen();
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
    );
  }
}
