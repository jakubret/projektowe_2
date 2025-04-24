import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_event.dart';
import 'package:zabytki_app/repositories/auth_repository.dart';
import 'package:zabytki_app/auth_wrapper.dart';
import 'package:zabytki_app/blocs/account/account_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthRepository _authRepository = AuthRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authRepository: _authRepository)..add(AuthStarted()),
        ),
        BlocProvider<AccountBloc>(
          create: (context) => AccountBloc(authRepository: _authRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Aplikacja Zabytki',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home:  AuthWrapper(), // Użyj AuthWrapper jako głównego widgetu
      ),
    );
  }
}