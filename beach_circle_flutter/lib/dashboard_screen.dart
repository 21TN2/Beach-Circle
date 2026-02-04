import 'package:beach_circle_flutter/addres_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dormlife_screen.dart';
import 'events_screen.dart';
import 'feedbackanalytics_screen.dart';
import 'hourscap_screen.dart';
import 'map_screen.dart';
import 'misc_screen.dart';
import 'settings_screen.dart';
import 'screens/resources_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 0 = Dashboard, 1 = Map, 2 = Forum, 3 = Resources, 4 = Settings
  int _currentIndex = 0;

  // Log out button
  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // grid pushes to a page
  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    Widget destination,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.blue.withOpacity(0.25),
          splashColor: Colors.blue.withOpacity(0.25),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destination),
            );
          },
          child: Ink(
            width: 110,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFD7EBFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tile that SWITCHES tabs for bottom navigator
  Widget _tileTab(IconData icon, String label, int tabIndex) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.blue.withOpacity(0.25),
          splashColor: Colors.blue.withOpacity(0.25),
          onTap: () => setState(() => _currentIndex = tabIndex),
          child: Ink(
            width: 110,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFD7EBFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to create a scrolling row
  Widget _scrollingRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Dashboard Body
  Widget _dashboardBody(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email?.split('@').first ?? "User";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $name',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Welcome to Beach Circle !',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 12),

          // CSULB Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://raw.githubusercontent.com/21TN2/Beach-Circle/resourcepage/Bob%20Cole%20Conservatory%20of%20Music%20@%20CSULB.jpeg',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 220,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // -------- DASHBOARD TILES --------------
          const Text(
            'Map Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          _scrollingRow([
            _tile(context, Icons.local_pizza, 'Food Alert', const MapScreen()),
            _tile(context, Icons.directions_car, 'Parking', const MapScreen()),
            _tile(context, Icons.power, 'Outlets', const MapScreen()),
            _tile(
              context,
              Icons.family_restroom,
              'Bathrooms',
              const MapScreen(),
            ),
            _tile(
              context,
              Icons.auto_stories,
              'Study Halls',
              const MapScreen(),
            ),
          ]),

          const SizedBox(height: 24),

          const Text(
            'Community Goods',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _scrollingRow([
            _tile(context, Icons.event, 'Events', const EventsScreen()),

            // ✅ IMPORTANT: switch to Forum tab so nav bar stays visible
            _tileTab(Icons.forum, 'Misc Forums', 2),

            _tile(
              context,
              Icons.apartment,
              'Dorm Life',
              const DormlifeScreen(),
            ),
          ]),

          const SizedBox(height: 24),

          const Text(
            'Student Resources',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _scrollingRow([
            _tile(
              context,
              Icons.access_time,
              'Hours & Capacity',
              const HourscapScreen(),
            ),
            _tile(
              context,
              Icons.menu_book,
              'Additional Resources',
              const ResourcesPage(),
            ),
            _tile(
              context,
              Icons.edit_note,
              'Feedback & Analytics',
              const FeedbackanalyticsScreen(),
            ),
          ]),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tab pages
    final pages = <Widget>[
      // Tab 0: Dashboard
      Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Dashboard'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log Out',
              onPressed: _logOut,
            ),
          ],
        ),
        body: _dashboardBody(context),
      ),

      const MapScreen(),
      const MiscScreen(),
      const ResourcesPage(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],

      // Student Misc Forum: for pencil icon to appear
      floatingActionButton:
          _currentIndex == 2
              ? FloatingActionButton(
                backgroundColor: const Color(0xFFFFD500),
                foregroundColor: Colors.black,
                elevation: 3,
                onPressed: () {
                  // TODO: later navigate to "create post"
                },
                child: const Icon(Icons.edit),
              )
              : null,

      // location of the pencil icon
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.layers), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
    );
  }
}
