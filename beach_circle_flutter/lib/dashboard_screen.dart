// dashboard home page
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_test_screen.dart'; 
import 'dormlife_screen.dart';
import 'events_screen.dart';
import 'feedbackanalytics_screen.dart';
import 'hourscap_screen.dart';
import 'map/map_screen.dart';
// dashboard screens
import 'misc_screen.dart';
import 'screens/resources_page.dart';
import 'settings_screen.dart';
import 'bathroom_finder.dart'; 

import 'events_screen.dart';
import 'dormlife_screen.dart';
import 'hourscap_screen.dart';
import 'feedbackanalytics_screen.dart';

// Forum imports
import 'package:beach_circle_flutter/community_goods/smf/model/forum_category.dart';
import 'package:beach_circle_flutter/community_goods/smf/screens/forum_category_pg.dart';
import 'package:beach_circle_flutter/community_goods/smf/service/forum_service.dart';
import 'package:beach_circle_flutter/community_goods/smf/screens/create_forum_page_pg.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 0 = Dashboard, 1 = Map, 2 = Forum, 3 = Resources, 4 = Settings
  int _currentIndex = 0;

  // Tab 0: dashboard
  String _homePage = "home"; // home | events | dormlife | hourscap | feedback

  // ---------- Forum  ----------
  final ForumService _forumService = ForumService();
  final GlobalKey<NavigatorState> _forumNavKey = GlobalKey<NavigatorState>();

  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // ----------  dashboard tiles  ----------
  Widget _tileOpen(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.blue.withOpacity(0.25),
          splashColor: Colors.blue.withOpacity(0.25),
          onTap: onTap,
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

  // ---------- Dashboard layout --------------
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
            _tileOpen(Icons.local_pizza, 'Food Alert', () {
              setState(() => _currentIndex = 1);
            }),
            _tileOpen(Icons.directions_car, 'Parking', () {
              setState(() => _currentIndex = 1);
            }),
            _tileOpen(Icons.power, 'Outlets', () {
              setState(() => _currentIndex = 1);
            }),
            _tileOpen(Icons.family_restroom, 'Bathrooms', () {
              setState(() => _currentIndex = 1);
            }),
            _tileOpen(Icons.auto_stories, 'Study Halls', () {
              setState(() => _currentIndex = 1);
            }),
          ]),

          const SizedBox(height: 24),

          const Text(
            'Community Goods',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _scrollingRow([
            // Events = dashboard sub-page (bottom nav stays)
            _tileOpen(Icons.event, 'Events', () {
              setState(() {
                _currentIndex = 0;
                _homePage = "events";
              });
            }),

            // Misc Forums
            _tileOpen(Icons.forum, 'Misc Forums', () {
              setState(() {
                _currentIndex = 2;
                // Reset forum navigator to home whenever coming from dashboard tile
                _forumNavKey.currentState?.popUntil((r) => r.isFirst);
              });
            }),

            // Dorm Life
            _tileOpen(Icons.apartment, 'Dorm Life', () {
              setState(() {
                _currentIndex = 0;
                _homePage = "dormlife";
              });
            }),
          ]),

          const SizedBox(height: 24),

          const Text(
            'Student Resources',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _scrollingRow([
            // Hours & Capacity
            _tileOpen(Icons.access_time, 'Hours & Capacity', () {
              setState(() {
                _currentIndex = 0;
                _homePage = "hourscap";
              });
            }),

            // Additional Resources
            _tileOpen(Icons.menu_book, 'Additional Resources', () {
              setState(() => _currentIndex = 3);
            }),

            // Feedback & Analytics
            _tileOpen(Icons.edit_note, 'Feedback & Analytics', () {
              setState(() {
                _currentIndex = 0;
                _homePage = "feedback";
              });
            }),
          ]),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------- Forum Tab Navigator  ----------
  Widget _buildForumTab() {
    return Navigator(
      key: _forumNavKey,
      onGenerateRoute: (settings) {
        // Forum Home (category grid)
        if (settings.name == '/' || settings.name == null) {
          return MaterialPageRoute(
            builder:
                (_) => MiscScreen(
                  forumService: _forumService,
                  onOpenCategory: (ForumCategory c) {
                    _forumNavKey.currentState?.pushNamed(
                      '/category',
                      arguments: c,
                    );
                  },
                ),
          );
        }

        // Category page
        if (settings.name == '/category') {
          final category = settings.arguments as ForumCategory;
          return MaterialPageRoute(
            builder:
                (_) => ForumCategoryPg(
                  category: category,
                  forumService: _forumService,
                ),
          );
        }

        // Create Forum Request page
        if (settings.name == '/createForum') {
          return MaterialPageRoute(
            builder:
                (_) => CreateForumPage(
                  onClose: () => _forumNavKey.currentState?.pop(),
                  onSubmitted: () => _forumNavKey.currentState?.pop(),
                ),
          );
        }

        // fallback
        return MaterialPageRoute(
          builder:
              (_) => MiscScreen(
                forumService: _forumService,
                onOpenCategory: (ForumCategory c) {
                  _forumNavKey.currentState?.pushNamed(
                    '/category',
                    arguments: c,
                  );
                },
              ),
        );
      },
    );
  }

  // ---------- Body switcher ------------
  Widget _buildBody(BuildContext context) {
    // TAB 0 dashboard homepage
    if (_currentIndex == 0) {
      switch (_homePage) {
        case "events":
          return const EventsScreen();
        case "dormlife":
          return const DormlifeScreen();
        case "hourscap":
          return const HourscapScreen();
        case "feedback":
          return const FeedbackanalyticsScreen();
        case "home":
        default:
          return _dashboardBody(context);
      }
    }

    // TAB 1 campus map
    if (_currentIndex == 1) return const MapScreen();

    // TAB 2 student misc forum (NEW: nested navigator)
    if (_currentIndex == 2) return _buildForumTab();

    // TAB 3 resource page
    if (_currentIndex == 3) return const ResourcesPage();

    // TAB 4 settings
    return const SettingsScreen();
  }

  // ---------- AppBar ------------
  PreferredSizeWidget? _buildAppBar() {
    if (_currentIndex == 0 && _homePage == "home") {
      return AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          // --- SECRET ADMIN BUTTON START ---
          if (user?.email == 'teef@gmail.com') 
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
      );
    }

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

      if (isForumRoot) {
        return FloatingActionButton(
          backgroundColor: const Color(0xFFFFD500),
          foregroundColor: Colors.black,
          elevation: 3,
          onPressed: () {
            _forumNavKey.currentState?.pushNamed('/createForum');
          },
          child: const Icon(Icons.edit),
        );
      }
    }

    return null;
  }

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
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;

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
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.layers), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
    );
  }
}