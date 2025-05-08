import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:zabytki_app/blocs/auth/auth_bloc.dart';
import 'package:zabytki_app/blocs/auth/auth_state.dart';
import 'package:zabytki_app/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:zabytki_app/screens/maps_screen/map_screen.dart';

class LandmarkRecognitionScreen extends StatefulWidget {
  const LandmarkRecognitionScreen({Key? key}) : super(key: key);

  @override
  _LandmarkRecognitionScreenState createState() =>
      _LandmarkRecognitionScreenState();
}

class _LandmarkRecognitionScreenState extends State<LandmarkRecognitionScreen> {
  File? _image;
  final picker = ImagePicker();
  String _prediction = "";
  String _description = "";
  String _answer = "";
  final _questionController = TextEditingController();
  final String serverAddress = Config.serverAddress;
  List<Map<String, String>> conversation = [];
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _connectWebSocket(context);
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
      _socket = IO.io(
        serverAddress,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'user_id': userId.toString()}) // Przekaż user_id
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        print('Połączono z WebSocket na LandmarkScreen');
      });

      _socket?.onDisconnect((_) {
        print('Rozłączono z WebSocket na LandmarkScreen');
      });

      _socket?.onError((error) {
        print('Błąd WebSocket na LandmarkScreen: $error');
      });
    }
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      await _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(File image) async {
    final uri = Uri.parse("$serverAddress/predict/");
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    final data = json.decode(respStr);

    setState(() {
      _prediction = data['prediction'] ?? "";
      _description = data['description'] ?? "";
    });
  }

  Future<void> _askQuestion(BuildContext context) async {
    final uri = Uri.parse("$serverAddress/ask/");
    final authBloc = BlocProvider.of<AuthBloc>(context);

    if (authBloc.state is AuthAuthenticated) {
      final userId = (authBloc.state as AuthAuthenticated).user!.id;
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'zabytek': _prediction,
          'question': _questionController.text,
          'user_id': userId,
        }),
      );

      final data = json.decode(response.body);
      setState(() {
        _answer = data['answer'] ?? "Brak odpowiedzi.";
        conversation.add({
          'question': _questionController.text,
          'answer': _answer,
        });
        _questionController.clear();
      });

      // Emituj zdarzenie WebSocket po zadaniu pytania
      _socket?.emit('new_query', {
        'user_id': userId,
        'zabytek': _prediction,
        'question': _questionController.text,
        'answer': _answer,
      });
    } else {
      print("Użytkownik nie jest zalogowany.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rozpoznawanie zabytków")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _getImage(ImageSource.camera),
                    child: const Text("Zrób zdjęcie"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _getImage(ImageSource.gallery),
                    child: const Text("Wybierz z galerii"),
                  ),
                ),
              ],
            ),
            if (_image != null) ...[
              const SizedBox(height: 10),
              Image.file(_image!, height: 200),
            ],
            if (_prediction.isNotEmpty)
              Text("Zabytek: $_prediction", style: const TextStyle(fontSize: 18)),
            if (_description.isNotEmpty)
              Text("Opis: $_description", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            if (_prediction.isNotEmpty) ...[
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: "Zadaj pytanie o zabytek",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _askQuestion(context),
                child: const Text("Zapytaj"),
              ),
              const SizedBox(height: 20),
            ],
            if (_prediction.isNotEmpty && _description.isNotEmpty)
            ElevatedButton(
                onPressed: () { 
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MonumentMapScreen(recognizedLandmark: _prediction),
                    ),
                  );
                },
                child: const Text("Pokaż na mapie"),
              ),
            if (conversation.isNotEmpty)
              Column(
                children: conversation.map((msg) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pytanie: ${msg['question']}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Odpowiedź: ${msg['answer']}"),
                      const SizedBox(height: 15),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}