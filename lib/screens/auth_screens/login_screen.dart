import 'package:zabytki_app/blocs/auth/auth_bloc.dart';
import 'package:zabytki_app/blocs/login/login_bloc.dart';
import 'package:zabytki_app/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zabytki_app/widgets/auth_screens/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final authRepository = context.read<AuthRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Logowanie"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocProvider<LoginBloc>(
          create: (_) => LoginBloc(
            authRepository: authRepository,
            authBloc: authBloc,
          ),
          child: const LoginForm(),
        ),
      ),
    );
  }
}
