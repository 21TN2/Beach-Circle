import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_test_screen.dart';
import 'dormlife_screen.dart';
import 'events_screen.dart';
import 'feedbackanalytics_screen.dart';
import 'hourscap_screen.dart';
import 'misc_screen.dart';
import 'addres_screen.dart';
import 'settings_screen.dart';
import 'bathroom_finder.dart';
import 'map/map_screen.dart';

import 'package:beach_circle_flutter/community_goods/smf/model/forum_category.dart';
import 'package:beach_circle_flutter/community_goods/smf/screens/forum_category_pg.dart';
import 'package:beach_circle_flutter/community_goods/smf/service/forum_service.dart';
import 'package:beach_circle_flutter/community_goods/smf/screens/create_forum_page_pg.dart';
import 'package:beach_circle_flutter/moderation/moderation_view_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _homePage = "home";
  String? _mapFilter;

  final ForumService _forumService = ForumService();
  final GlobalKey<NavigatorState> _forumNavKey = GlobalKey<NavigatorState>();

  // NEW FROM GISELLE 4: ADDING MODERATION VIEW
  static const List<String> adminEmails = [
    'teef@gmail.com',
    'reytest@gmail.com',
    'giselle1@gmail.com',
    'nguyentheresa204@gmail.com',
    'josuealfaro8441@gmail.com',
  ];

  bool get _isModerator {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    return email != null &&
        adminEmails.map((e) => e.toLowerCase()).contains(email);
  }

  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Widget _tileOpen(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: Colors.blue.withValues(alpha: 0.25),
          splashColor: Colors.blue.withValues(alpha: 0.25),
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

          const Text(
            'Map Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          _scrollingRow([
            _tileOpen(Icons.local_pizza, 'Food Alert', () {
              setState(() {
                _currentIndex = 1;
                _mapFilter = "food";
              });
            }),
            _tileOpen(Icons.directions_car, 'Parking', () {
              setState(() {
                _currentIndex = 1;
                _mapFilter = "parking";
              });
            }),
            _tileOpen(Icons.power, 'Outlets', () {
              setState(() {
                _currentIndex = 1;
                _mapFilter = "charging";
              });
            }),
            _tileOpen(Icons.family_restroom, 'Bathrooms', () {
              setState(() {
                _currentIndex = 1;
                _mapFilter = "restroom";
              });
            }),
            _tileOpen(Icons.auto_stories, 'Study Halls', () {
              setState(() {
                _currentIndex = 1;
                _mapFilter = "study";
              });
            }),
          ]),

          const SizedBox(height: 24),

          const Text(
            'Community Goods',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _scrollingRow([
            _tileOpen(Icons.event, 'Events', () {
              setState(() {
                _currentIndex = 0;
                _homePage = "events";
              });
            }),
            _tileOpen(Icons.forum, 'Misc Forums', () {
              setState(() {
                _currentIndex = 2;
                _forumNavKey.currentState?.popUntil((r) => r.isFirst);
              });
            }),
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
            _tileOpen(Icons.access_time, 'Hours & Capacity', () {
              setState(() {
                _currentIndex = 0;
                _homePage = "hourscap";
              });
            }),
            _tileOpen(Icons.menu_book, 'Additional Resources', () {
              setState(() => _currentIndex = 3);
            }),
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

  Widget _buildForumTab() {
    return Navigator(
      key: _forumNavKey,
      onGenerateRoute: (settings) {
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
        if (settings.name == '/createForum') {
          return MaterialPageRoute(
            builder:
                (_) => CreateForumPage(
                  onClose: () => _forumNavKey.currentState?.pop(),
                  onSubmitted: () => _forumNavKey.currentState?.pop(),
                ),
          );
        }
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

  Widget _buildBody(BuildContext context) {
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

    if (_currentIndex == 1 && (_mapFilter != null)) {
      return MapScreen(initialFilter: _mapFilter);
    } else if (_currentIndex == 1) {
      return MapScreen();
    }

    if (_currentIndex == 2) return _buildForumTab();
    if (_currentIndex == 3) return const AddresScreen();
    return const SettingsScreen();
  }

  PreferredSizeWidget? _buildAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    if (_currentIndex == 0 && _homePage == "home") {
      return AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          if (_isModerator)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.red),
              tooltip: 'Notification Test',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationTestScreen(),
                  ),
                );
              },
            ),
          if (_isModerator) // NEW FROM GISELLE 4: To view moderation
            IconButton(
              icon: const Icon(
                Icons.admin_panel_settings,
                color: Colors.black87,
              ),
              tooltip: 'Moderation',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ModerationViewScreen(forumService: _forumService),
                  ),
                );
              },
            ),

          IconButton(icon: const Icon(Icons.logout), onPressed: _logOut),
        ],
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 0) _homePage = "home";
            if (index != 1) _mapFilter = null;
          });
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
