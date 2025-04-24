import 'package:zabytki_app/blocs/auth/auth_bloc.dart'; // Import AuthBloc
import 'package:zabytki_app/blocs/login/login_bloc.dart';
import 'package:zabytki_app/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zabytki_app/widgets/auth_screens/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logowanie"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocProvider(
          create: (context) => LoginBloc(
            authRepository: RepositoryProvider.of<AuthRepository>(context),
            authBloc: BlocProvider.of<AuthBloc>(context), // Get AuthBloc instance here
          ),
          child: const LoginForm(),
        ),
      ),
    );
  }
}