import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:zabytki_app/blocs/auth/auth_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_state.dart';
import 'package:zabytki_app/config.dart';
import 'dart:convert';
import 'package:zabytki_app/model/history.dart';
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _historyItems = [];
  Set<int> _expandedItems = <int>{}; // Przechowuje ID rozwiniętych elementów
  bool _isLoading = false;
  String _errorMessage = '';
final String serverAddress = Config.serverAddress;

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _fetchHistory(context); // Przekaż context
  });
}

// W HistoryScreen (zmodyfikuj _fetchHistory)
Future<void> _fetchHistory(BuildContext context) async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  final authBloc = BlocProvider.of<AuthBloc>(context); // Pobierz AuthBloc

  if (authBloc.state is AuthAuthenticated) {
    final userId = (authBloc.state as AuthAuthenticated).user!.id;
    final Uri uri = Uri.parse('$serverAddress/history?user_id=$userId'); // Dodaj user_id jako parametr

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _historyItems = data.map((item) => HistoryItem.fromJson(item as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Wystąpił błąd podczas pobierania historii: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Wystąpił błąd połączenia: $e';
        _isLoading = false;
      });
    }
  } else {
    // Obsłuż sytuację, gdy użytkownik nie jest zalogowany
    setState(() {
      _errorMessage = 'Użytkownik nie jest zalogowany, nie można pobrać historii.';
      _isLoading = false;
    });
  }
}

// Zmień wywołanie _fetchHistory w initState:


  void _toggleExpansion(int itemId) {
    setState(() {
      if (_expandedItems.contains(itemId)) {
        _expandedItems.remove(itemId);
      } else {
        _expandedItems.add(itemId);
      }
    });
  }

  Widget _buildHistoryItem(HistoryItem item) {
    final isExpanded = _expandedItems.contains(item.id);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(item.question, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Zabytek: ${item.zabytek}'),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => _toggleExpansion(item.id),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Odpowiedź:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Text(item.answer),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia Zapytań'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _historyItems.isEmpty
                  ? const Center(child: Text('Brak historii zapytań.'))
                  : ListView.builder(
                      itemCount: _historyItems.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryItem(_historyItems[index]);
                      },
                    ),
    );
  }
}