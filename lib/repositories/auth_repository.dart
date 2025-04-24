import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthRepository {
  final String _baseUrl = "http://172.16.30.148:8000"; // Zmień na adres URL swojego backendu

  Future<User?> register(String email, String password, String name) async {
    final Uri uri = Uri.parse('$_baseUrl/register');
    final Map<String, String> body = {
      'name': name,
      'email': email,
      'password': password,
    };

    print('AuthRepository: Wysyłam żądanie rejestracji do: $uri z body: $body');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('AuthRepository: Otrzymałem odpowiedź z kodem: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 201) {
        // Rejestracja udana, serwer powinien zwrócić dane użytkownika
        final Map<String, dynamic> data = jsonDecode(response.body);
        return User(id: data['user']['id'].toString(), name: data['user']['name'], email: data['user']['email']); // Parsuj ID jako String
      } else {
        // Rejestracja nieudana, spróbuj sparsować błąd z body
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Błąd rejestracji');
      }
    } catch (e) {
      print('AuthRepository: Wystąpił błąd podczas rejestracji: $e');
      throw Exception('Wystąpił błąd podczas rejestracji: $e');
    }
    return null;
  }

  Future<User?> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/login');
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String? userNameNullable = data['user']['name'];
      final String userName = userNameNullable ?? 'Brak imienia';
      return User(id: data['user']['id'].toString(), name: userName, email: data['user']['email']); // Parsuj ID jako String
    } else {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Błąd logowania');
    }
    return null;
  }

  User? _currentUser;
  User? get currentUser => _currentUser;

  void setCurrentUser(User? user) {
    _currentUser = user;
  }

  Future<void> signOut() async {
    _currentUser = null;
  }

  Future<void> deleteAccount() async {
    final uri = Uri.parse('$_baseUrl/users/me');
    final response = await http.delete(
      uri,
      // Dodaj tutaj logikę autoryzacji
    );

    if (response.statusCode == 200) {
      _currentUser = null;
    } else {
      throw Exception('Failed to delete account');
    }
  }
}

class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'],
      email: json['email'],
    );
  }
}