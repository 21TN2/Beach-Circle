import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Log out button
  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Dashboard tile
  Widget _tile(IconData icon, String label) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name =
        user?.email ??
        "User"; // in the future change this to fetching a username from Firestore (need to change up signup requirements)

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          // log out button
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
          children: [
            // note: might replace image to match the prototype but im just testing with the image we alr have
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://raw.githubusercontent.com/21TN2/Beach-Circle/resourcepage/Bob%20Cole%20Conservatory%20of%20Music%20@%20CSULB.jpeg',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // welcome user
            Center(
              child: Column(
                children: [
                  Text(
                    "Hello $name",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Welcome to Beach Circle!",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ----- DASHBOARD TILES -----
            // to do: make navigation path
            // to do: also want to include interaction with the tiles, such as when you hover over them
            // to do: figure out the spacing of the tiles
            // to do: make it better lol
            const Text(
              'Map Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tile(Icons.local_pizza, 'Food Alert'),
                const SizedBox(width: 30),
                _tile(Icons.directions_car, 'Parking'),
                const SizedBox(width: 30),
                _tile(Icons.power, 'Outlets'),
                const SizedBox(width: 30),
                _tile(Icons.family_restroom, 'Restrooms'),
              ],
            ),

            const SizedBox(height: 24),

            // ----- Community Goods -----
            const Text(
              'Community Goods',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tile(Icons.event, 'Events'),
                const SizedBox(width: 30),
                _tile(Icons.forum, 'Misc Forums'),
                const SizedBox(width: 30),
                _tile(Icons.apartment, 'Dorm Life'),
              ],
            ),

            const SizedBox(height: 24),

            // ----- Student Resources -----
            const Text(
              'Student Resources',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tile(Icons.access_time, 'Hours & Capacity'),
                const SizedBox(width: 30),
                _tile(Icons.menu_book, 'Additional Resources'),
                const SizedBox(width: 30),
                _tile(Icons.edit_note, 'Feedback & Analytics'),
              ],
            ),
          ],
        ),
      ),

      // Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
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
