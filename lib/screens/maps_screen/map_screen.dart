import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MonumentMapScreen extends StatefulWidget {
  final String? recognizedLandmark;

  const MonumentMapScreen({Key? key, this.recognizedLandmark}) : super(key: key);

  @override
  State<MonumentMapScreen> createState() => _MonumentMapScreenState();
  
}

class _MonumentMapScreenState extends State<MonumentMapScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _monumentMarkers = [];
  Position? _currentPosition;
  bool _locationServiceEnabled = false;
  bool _locationLoaded = false;
  bool _monumentCentered = false;

  @override
  void initState() {
    super.initState();
    _checkLocationServiceEnabled();
    _getCurrentLocation();
    if (widget.recognizedLandmark?.isNotEmpty ?? false) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _getMonumentDetails(widget.recognizedLandmark!);
      });
    }
  }

  Future<void> _checkLocationServiceEnabled() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_locationServiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usługi lokalizacyjne są wyłączone.')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      print('Uprawnienia lokalizacji są permanentnie zablokowane.');
      return;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        print('Brak uprawnień do lokalizacji.');
        return;
      }
    }
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (position.latitude.isFinite && position.longitude.isFinite) {
        setState(() {
          _currentPosition = position;
          _locationLoaded = true;
        });
        if (!_monumentCentered) {
  _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
}

      }
    } catch (e) {
      print("Błąd podczas pobierania lokalizacji: $e");
    }
  }

  Future<void> _getMonumentDetails(String monumentName) async {
    final String url =
        'https://nominatim.openstreetmap.org/search?q=$monumentName&format=json&limit=1';
    try {
      final response = await http.get(
        Uri.parse(Uri.encodeFull(url)),
        headers: {'User-Agent': 'zabytki_app/1.0 (flutter)'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0]['lat'] != null && data[0]['lon'] != null) {
          final latitude = double.tryParse(data[0]['lat']?.toString() ?? '');
          final longitude = double.tryParse(data[0]['lon']?.toString() ?? '');

          if (latitude != null &&
              longitude != null &&
              latitude.isFinite &&
              longitude.isFinite) {
            final LatLng monumentLatLng = LatLng(latitude, longitude);
            setState(() {
              _monumentMarkers.add(
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: monumentLatLng,
                  child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
                ),
              );
            });
            _mapController.move(monumentLatLng, 16.0);
            _monumentCentered = true;
          } else {
            print('Nieprawidłowe współrzędne (NaN/Infinity) dla: $monumentName');
          }
        } else {
          print('Nie znaleziono zabytku: $monumentName');
        }
      } else {
        print('Błąd zapytania do OpenStreetMap: ${response.statusCode}');
      }
    } catch (e) {
      print('Wystąpił błąd: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> allMarkers = [..._monumentMarkers];
    if (_currentPosition != null &&
        _currentPosition!.latitude.isFinite &&
        _currentPosition!.longitude.isFinite) {
      allMarkers.add(
        Marker(
          width: 40.0,
          height: 40.0,
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: const Icon(Icons.my_location, color: Colors.red),
        ),
      );
    }

    final initialLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(0.0, 0.0); // domyślne, neutralne miejsce

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialLatLng,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'zabytki_app',
          ),
          MarkerLayer(markers: allMarkers),
        ],
      ),
    );
  }
}
