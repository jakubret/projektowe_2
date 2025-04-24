import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_event.dart';
import 'package:zabytki_app/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;
  final AuthBloc authBloc;

  LoginBloc({required this.authRepository, required this.authBloc}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      if (user != null) {
        emit(LoginSuccess());
        authBloc.add(AuthLoggedIn(user: user)); // Przekazuj cały obiekt User
      } else {
        emit(const LoginFailure('Nieprawidłowe dane logowania')); // Corrected: Use const constructor with argument
      }
    } catch (error) {
      emit(LoginFailure(error.toString()));
    }
  }
}