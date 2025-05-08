import 'package:flutter/material.dart';
import 'package:zabytki_app/screens/history_screen/history_screen.dart';
import 'package:zabytki_app/screens/home_screen/landmark_recognition_screen.dart'; // Zaimportuj ekran rozpoznawania
//import 'package:zabytki_app/screens/basket_screens/basket_screen.dart'; // Jeśli masz taki ekran
//import 'package:zabytki_app/screens/order_screens/order_history_screen.dart'; // Jeśli masz taki ekran
import 'package:zabytki_app/screens/profile_screen.dart'; // Jeśli masz taki ekran
//import '../widgets/basket_icon_with_badge.dart'; // Jeśli używasz tego widgetu

class PersistentScaffold extends StatefulWidget {
  const PersistentScaffold({Key? key}) : super(key: key);

  @override
  _PersistentScaffoldState createState() => _PersistentScaffoldState();
}

class _PersistentScaffoldState extends State<PersistentScaffold> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  List<Widget> get _tabs => [
        Navigator(
          key: _navigatorKeys[0],
          onGenerateRoute: (routeSettings) {
            return MaterialPageRoute(
              builder: (_) => const LandmarkRecognitionScreen(), // Użyj LandmarkRecognitionScreen
            );
          },
        ),
        // Dodaj nawigator dla ekranu historii, jeśli go masz
         Navigator(
           key: _navigatorKeys[1],
           onGenerateRoute: (routeSettings) {
             return MaterialPageRoute(
               builder: (_) => const HistoryScreen(), // Zastąp OrderHistoryScreen() Twoim ekranem historii
             );
           },
         ),
        Navigator(
          key: _navigatorKeys[2],
          onGenerateRoute: (routeSettings) {
            return MaterialPageRoute(
              builder: (_) => const ProfileScreen(), // Zostaw lub zmień, jeśli nie masz
            );
          },
        ),
      ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentIndex = index;
      });
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // Dodaj element BottomNavigationBarItem dla ekranu historii, jeśli go masz
           BottomNavigationBarItem(
             icon: Icon(Icons.history),
             label: 'Historia',
           ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}