import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_bloc.dart';
import 'package:zabytki_app/repositories/auth_repository.dart';
import 'package:zabytki_app/auth_wrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zabytki App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: RepositoryProvider(
        create: (context) => AuthRepository(),
        child: BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authRepository: RepositoryProvider.of<AuthRepository>(context)),
          child: AuthWrapper(),
        ),
      ),
    );
  }
}