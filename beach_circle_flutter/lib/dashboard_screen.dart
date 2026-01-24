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
      // Add a margin to the right so buttons don't stick together when scrolling
      margin: const EdgeInsets.only(right: 16), 
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email ?? "User"; 

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
          children: [
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
                    child: const Center(child: Icon(Icons.broken_image, size: 50))
                  );
                },
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
            const Text(
              'Map Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            // Replaced standard Row with _scrollingRow helper
            _scrollingRow([
              _tile(Icons.local_pizza, 'Food Alert'),
              _tile(Icons.directions_car, 'Parking'),
              _tile(Icons.power, 'Outlets'),
              _tile(Icons.family_restroom, 'Restrooms'),
            ]),

            const SizedBox(height: 24),

            // ----- Community Goods -----
            const Text(
              'Community Goods',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            _scrollingRow([
               _tile(Icons.event, 'Events'),
               _tile(Icons.forum, 'Misc Forums'),
               _tile(Icons.apartment, 'Dorm Life'),
            ]),

            const SizedBox(height: 24),

            // ----- Student Resources -----
            const Text(
              'Student Resources',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            _scrollingRow([
              _tile(Icons.access_time, 'Hours & Capacity'),
              _tile(Icons.menu_book, 'Additional Resources'),
              _tile(Icons.edit_note, 'Feedback & Analytics'),
            ]),
            
            // Add some extra space at bottom so navigation bar doesn't cover content
            const SizedBox(height: 20),
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