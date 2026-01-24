import 'package:beach_circle_flutter/addres_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// importing the screens
// note: not all dart pages have been created yet
// missing: outlet, restroom, food alert, parking, studyhall, resource
import 'dormlife_screen.dart';
import 'events_screen.dart';
import 'feedbackanalytics_screen.dart';
import 'hourscap_screen.dart';
import 'map_screen.dart';
import 'misc_screen.dart';
import 'settings_screen.dart';

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
          // Welcoming the user with their name, note: email name might not properly describe user?
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

                // Add error builder in case image fails to load
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

            // note: screens are just the dart pages available as of rn
            _scrollingRow([
              // Food Alert
              _tile(
                context,
                Icons.local_pizza,
                'Food Alert',
                const MapScreen(),
              ),

              // Parking Difficulty Indicator
              _tile(
                context,
                Icons.directions_car,
                'Parking',
                const MapScreen(),
              ),

              // Outlets
              _tile(context, Icons.power, 'Outlets', const MapScreen()),

              // Bathroom Finder
              _tile(
                context,
                Icons.family_restroom,
                'Bathrooms',
                const MapScreen(),
              ),

              // Study Hall
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
              // Event Board
              _tile(context, Icons.event, 'Events', const EventsScreen()),

              // Student Misc Forum
              _tile(context, Icons.forum, 'Misc Forums', const MiscScreen()),

              // Dorm Life
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
              // Hours & Capacity
              _tile(
                context,
                Icons.access_time,
                'Hours & Capacity',
                const HourscapScreen(),
              ),

              // Additional Resources
              _tile(
                context,
                Icons.menu_book,
                'Additional Resources',
                const AddresScreen(),
              ),

              // Feedback & Analytics
              _tile(
                context,
                Icons.edit_note,
                'Feedback & Analytics',
                const FeedbackanalyticsScreen(),
              ),
            ]),

            // Add some extra space at bottom so navigation bar doesn't cover content
            const SizedBox(height: 20),
          ],
        ),
      ),

      //------ Navigation Bar ------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,

        // navigating the different pages from the bar
        onTap: (index) {
          if (index == 0) return; // to dashboard

          if (index == 1) {
            // redirects to map page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            );
          }
          if (index == 2) {
            // redirects to resource page NOTE: REPLACE IT WITH THE RIGHT SCREEN SINCE WE DONT HAVE IT ATM
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddresScreen()),
            );
          }

          if (index == 3) {
            // redirects to settings page
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
