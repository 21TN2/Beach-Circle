import 'package:beach_circle_flutter/addres_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_test_screen.dart'; 
import 'dormlife_screen.dart';
import 'events_screen.dart';
import 'feedbackanalytics_screen.dart';
import 'hourscap_screen.dart';
import 'map_screen.dart';
import 'misc_screen.dart';
import 'settings_screen.dart';
import 'bathroom_finder.dart'; 

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Log out button
  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Dashboard Widgets for the different features
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

  // Helper widget to create a scrolling row
  Widget _scrollingRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Add padding so the first item isn't glued to the edge
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: children,
      ),
    );
  }

  // Header info
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email?.split('@').first ?? "User";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          // --- SECRET ADMIN BUTTON START ---
          if (user?.email == 'reytest@gmail.com') 
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.red), 
              tooltip: 'Secret Admin Test',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationTestScreen()),
                );
              },
            ),
          // --- SECRET ADMIN BUTTON END ---

          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: _logOut,
          ),
        ],
      ),

      // Body
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Welcoming the user with their name
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
            // Map Features
            const Text(
              'Map Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _scrollingRow([
              _tile(
                context,
                Icons.local_pizza,
                'Food Alert',
                const MapScreen(),
              ),
              _tile(
                context,
                Icons.directions_car,
                'Parking',
                const MapScreen(),
              ),
              _tile(context, Icons.power, 'Outlets', const MapScreen()),
              
              // 2. BATHROOM TILE UPDATED HERE
              _tile(
                context,
                Icons.family_restroom,
                'Bathrooms',
                const BathroomFinder(), // Changed from MapScreen()
              ),
              
              _tile(
                context,
                Icons.auto_stories,
                'Study Halls',
                const MapScreen(),
              ),
            ]),

            const SizedBox(height: 24),

            // ----- Community Goods -----
            const Text(
              'Community Goods',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _scrollingRow([
              _tile(context, Icons.event, 'Events', const EventsScreen()),
              _tile(context, Icons.forum, 'Misc Forums', const MiscScreen()),
              _tile(
                context,
                Icons.apartment,
                'Dorm Life',
                const DormlifeScreen(),
              ),
            ]),

            const SizedBox(height: 24),

            // ----- Student Resources -----
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
                const AddresScreen(),
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
      ),

      //------ Navigation Bar ------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) return; // to dashboard

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddresScreen()),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.layers), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
    );
  }
}