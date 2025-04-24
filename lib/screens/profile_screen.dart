import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zabytki_app/blocs/account/account_bloc.dart';
import 'package:zabytki_app/blocs/account/account_event.dart';
import 'package:zabytki_app/blocs/account/account_state.dart';
import 'package:zabytki_app/blocs/auth/auth_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_event.dart';
import 'package:zabytki_app/blocs/auth/auth_state.dart';
//import 'package:zabytki_app/repositories/auth_repository.dart'; // Zaimportuj AuthRepository
import 'package:zabytki_app/styles/color.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        } else if (state is AccountSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.read<AuthBloc>().add(AuthLoggedOut()); // Zmieniono na AuthLoggedOut
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Twoje konto',
          ),
        ),
        body: Container(
          color: background,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 70,
                child: Icon(Icons.person, size: 100, color: primary),
              ),
              const SizedBox(height: 15),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final String displayName = (authState is AuthAuthenticated && authState.user != null)
                      ? authState.user!.name
                      : 'Brak danych';
                  final String email = (authState is AuthAuthenticated && authState.user != null)
                      ? authState.user!.email
                      : 'Brak danych';
                  return Column(
                    children: [
                      Card(
                        color: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading: const Icon(Icons.person, color: primary),
                          title: Text(
                            displayName,
                            style: const TextStyle(fontSize: 18, color: text),
                          ),
                          subtitle: const Text(
                            'Twój nick',
                            style: TextStyle(fontSize: 14, color: text),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Card(
                        color: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading: const Icon(Icons.email, color: primary),
                          title: Text(
                            email,
                            style: const TextStyle(fontSize: 18, color: text),
                          ),
                          subtitle: const Text(
                            'Twój email',
                            style: TextStyle(fontSize: 14, color: text),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              BlocBuilder<AccountBloc, AccountState>(
                builder: (context, state) {
                  if (state is AccountLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Wyloguj'),
                            onPressed: () {
                              context.read<AccountBloc>().add(AccountLogoutRequested());
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text('Usuń konto'),
                            onPressed: () {
                              final accountBloc = context.read<AccountBloc>();
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Potwierdzenie'),
                                  content: const Text(
                                    'Czy na pewno chcesz usunąć konto? Ta operacja jest nieodwracalna.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(),
                                      child: const Text('Anuluj'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                        accountBloc.add(AccountDeleteRequested());
                                      },
                                      child: const Text('Usuń'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                       
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


}