import 'package:bloc/bloc.dart';
import 'package:zabytki_app/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoggedOut>(_onLoggedOut);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLogoutRequestedFromProfile>(_onLogoutRequestedFromProfile);
    on<AuthDeleteAccountRequested>(_onDeleteAccountRequested);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final User? user = _authRepository.currentUser;
    if (user != null) {
      print('AuthStarted: User is authenticated');
      emit(AuthAuthenticated(user: user));
    } else {
      print('AuthStarted: User is unauthenticated');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) async {
    _authRepository.setCurrentUser(event.user);
    emit(AuthAuthenticated(user: event.user));
  }

  Future<void> _onLoggedOut(AuthLoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    print('AuthLoggedOut: Attempting to log out user');
    try {
      await _authRepository.signOut();
      print('AuthLoggedOut: User logged out');
      emit(AuthUnauthenticated());
    } catch (e) {
      print('AuthLoggedOut Error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequestedFromProfile(AuthLogoutRequestedFromProfile event, Emitter<AuthState> emit) async {
    add(AuthLoggedOut());
  }

  Future<void> _onDeleteAccountRequested(AuthDeleteAccountRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    print('AuthDeleteAccountRequested: Attempting to delete account');
    try {
      await _authRepository.deleteAccount();
      print('AuthDeleteAccountRequested: Account deleted');
      emit(AuthUnauthenticated());
      // Możesz dodać tutaj emitowanie innego stanu sukcesu usunięcia konta, jeśli potrzebujesz
    } catch (e) {
      print('AuthDeleteAccountRequested Error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  // Nie będziesz miał tych metod bez Firebase
  // Future<void> createUserDocument(String userId, {Map<String, dynamic>? additionalData}) async {
  //   // Implementacja komunikacji z Twoją bazą danych
  // }

  // Future<void> createEmptyBoard(String userId) async {
  //   // Implementacja komunikacji z Twoją bazą danych
  // }
}