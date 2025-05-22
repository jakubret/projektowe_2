import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MonumentMapScreen extends StatefulWidget {
  final String? recognizedLandmark;
  final List<String>? nearbyMonuments; // New parameter for nearby monuments

  const MonumentMapScreen({
    Key? key,
    this.recognizedLandmark,
    this.nearbyMonuments, // Initialize the new parameter
  }) : super(key: key);

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

  // Track the index of the currently displayed nearby monument
  int _currentNearbyMonumentIndex = -1; // -1 means no nearby monument is currently centered

  @override
  void initState() {
    super.initState();
    _checkLocationServiceEnabled();
    _getCurrentLocation();

    // Fetch details for the recognized landmark
    if (widget.recognizedLandmark?.isNotEmpty ?? false) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _getMonumentDetails(widget.recognizedLandmark!, Colors.blue, true); // Main monument is blue, center on it initially
      });
    }

    // Fetch details for nearby monuments
    if (widget.nearbyMonuments != null && widget.nearbyMonuments!.isNotEmpty) {
      // Don't center on them immediately, let the navigation buttons handle it
      for (String monumentName in widget.nearbyMonuments!) {
        _getMonumentDetails(monumentName, Colors.purple, false); // Nearby monuments are purple, don't center initially
      }
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
        // If no monument is centered yet, center on current location
        if (!_monumentCentered) {
          _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
        }
      }
    } catch (e) {
      print("Błąd podczas pobierania lokalizacji: $e");
    }
  }

  // Modified _getMonumentDetails to accept a color for the marker and a boolean to center the map
  Future<void> _getMonumentDetails(String monumentName, Color markerColor, bool shouldCenter) async {
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
                  child: Icon(Icons.location_pin, color: markerColor, size: 40),
                ),
              );
            });
            // Center the map only if shouldCenter is true
            if (shouldCenter) {
              _mapController.move(monumentLatLng, 16.0);
              _monumentCentered = true;
            }
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

  // Function to navigate to the next nearby monument
  void _navigateToNextMonument() async {
    if (widget.nearbyMonuments == null || widget.nearbyMonuments!.isEmpty) {
      return; // No nearby monuments to navigate
    }

    setState(() {
      _currentNearbyMonumentIndex = (_currentNearbyMonumentIndex + 1) % widget.nearbyMonuments!.length;
    });

    final String monumentName = widget.nearbyMonuments![_currentNearbyMonumentIndex];
    await _centerMapOnMonument(monumentName);
  }

  // Function to navigate to the previous nearby monument
  void _navigateToPreviousMonument() async {
    if (widget.nearbyMonuments == null || widget.nearbyMonuments!.isEmpty) {
      return; // No nearby monuments to navigate
    }

    setState(() {
      _currentNearbyMonumentIndex = (_currentNearbyMonumentIndex - 1 + widget.nearbyMonuments!.length) % widget.nearbyMonuments!.length;
    });

    final String monumentName = widget.nearbyMonuments![_currentNearbyMonumentIndex];
    await _centerMapOnMonument(monumentName);
  }

  // Helper function to center the map on a given monument name
  Future<void> _centerMapOnMonument(String monumentName) async {
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

          if (latitude != null && longitude != null && latitude.isFinite && longitude.isFinite) {
            final LatLng monumentLatLng = LatLng(latitude, longitude);
            _mapController.move(monumentLatLng, 16.0); // Adjust zoom level as needed
          }
        } else {
          print('Could not find coordinates for $monumentName to center map.');
        }
      }
    } catch (e) {
      print('Error centering map on $monumentName: $e');
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

    // Determine if navigation buttons should be visible
    final bool showNavigationButtons = widget.nearbyMonuments != null && widget.nearbyMonuments!.isNotEmpty;

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
      floatingActionButton: showNavigationButtons
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "nextMonumentFab", // Unique tag for FAB
                  onPressed: _navigateToNextMonument,
                  child: const Icon(Icons.arrow_forward),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "prevMonumentFab", // Unique tag for FAB
                  onPressed: _navigateToPreviousMonument,
                  child: const Icon(Icons.arrow_back),
                ),
              ],
            )
          : null, // Don't show FABs if no nearby monuments
    );
  }
}