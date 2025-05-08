import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_state.dart';
import 'package:zabytki_app/config.dart';
import 'package:zabytki_app/model/history.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _historyItems = [];
  Set<int> _expandedItems = <int>{};
  bool _isLoading = false;
  String _errorMessage = '';
  final String serverAddress = Config.serverAddress;
  IO.Socket? _socket;
  bool _isConnecting = false; // Dodaj flagę dla stanu połączenia

  @override
  void initState() {
    super.initState();
    _connectWebSocket(context);
    _fetchInitialHistory(context);
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _connectWebSocket(BuildContext context) {
    final authBloc = BlocProvider.of<AuthBloc>(context);
    if (authBloc.state is AuthAuthenticated) {
      final userId = (authBloc.state as AuthAuthenticated).user!.id;
      setState(() {
        _isConnecting = true; // Ustaw flagę na true przed połączeniem
      });
      _socket = IO.io(
        serverAddress,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'user_id': userId.toString()})
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        print('Połączono z WebSocket');
        setState(() {
          _isConnecting =
              false; // Ustaw flagę na false po pomyślnym połączeniu
        });
      });

      _socket?.onDisconnect((_) {
        print('Rozłączono z WebSocket');
        setState(() {
          _isConnecting =
              false; // Ustaw flagę na false po rozłączeniu
        });
      });

      _socket?.on('new_query', (data) {
        print('Otrzymano nowe zapytanie: $data');
        try {
          final newItem = HistoryItem.fromJson(data as Map<String, dynamic>);
          setState(() {
            _historyItems.insert(0, newItem); // Dodaj na początek listy
          });
        } catch (e) {
          print('Błąd podczas parsowania nowego zapytania: $e');
        }
      });

      _socket?.onError((error) {
        print('Błąd WebSocket: $error');
        setState(() {
          _errorMessage = 'Wystąpił problem z połączeniem WebSocket.';
          _isConnecting = false; // Ustaw flagę na false w przypadku błędu
        });
      });
    }
  }

  Future<void> _fetchInitialHistory(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authBloc = BlocProvider.of<AuthBloc>(context);

    if (authBloc.state is AuthAuthenticated) {
      final userId = (authBloc.state as AuthAuthenticated).user!.id;
      final Uri uri = Uri.parse('$serverAddress/history?user_id=$userId');

      try {
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
          setState(() {
            _historyItems = data
                .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Wystąpił błąd podczas pobierania historii: ${response.statusCode}';
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
      setState(() {
        _errorMessage = 'Użytkownik nie jest zalogowany.';
        _isLoading = false;
      });
    }
  }

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
            title:
                Text(item.question, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('Odpowiedź:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : _historyItems.isEmpty
                      ? const Center(child: Text('Brak historii zapytań.'))
                      : RefreshIndicator(
                          onRefresh: () => _fetchInitialHistory(context),
                          child: ListView.builder(
                            itemCount: _historyItems.length,
                            itemBuilder: (context, index) {
                              return _buildHistoryItem(_historyItems[index]);
                            },
                          ),
                        ),
          if (_isConnecting) // Użyj _isConnecting
            const Center(
                child:
                    CircularProgressIndicator()), // Wskaźnik łączenia WebSocket
        ],
      ),
    );
  }
}

