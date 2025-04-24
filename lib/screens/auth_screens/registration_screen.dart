import 'package:zabytki_app/blocs/registration/registration_bloc.dart';
import 'package:zabytki_app/repositories/auth_repository.dart';
import 'package:zabytki_app/widgets/auth_screens/registration_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rejestracja"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocProvider(
          create: (context) => RegistrationBloc(authRepository: AuthRepository()),
          child: const RegistrationForm(),
        ),
      ),
    );
  }
}
