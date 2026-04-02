import 'package:beach_circle_flutter/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_test_screen.dart';
import 'dormlife_screen.dart';
import 'eventboard_screen.dart';
import 'feedbackanalytics_screen.dart';
import 'hourscap_screen.dart';
import 'misc_screen.dart';
import 'addres_screen.dart';
import 'settings_screen.dart';

//import 'bathroom_finder.dart';
//import 'map/map_screen.dart';

// Weather packages
import 'package:lottie/lottie.dart';
import 'package:beach_circle_flutter/weather/models/weather_model.dart';
import 'package:beach_circle_flutter/weather/services/weather_service.dart';

// Forum imports
import 'package:beach_circle_flutter/screens/moderation_view_screen.dart';
import 'package:beach_circle_flutter/community_goods/smf/model/forum_category.dart';
import 'package:beach_circle_flutter/community_goods/smf/screens/forum_category_pg.dart';
import 'package:beach_circle_flutter/community_goods/smf/service/forum_service.dart';
import 'package:beach_circle_flutter/community_goods/smf/screens/create_forum_page_pg.dart';

import 'screens/resources_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _homePage = "home";

  final ForumService _forumService = ForumService();
  final GlobalKey<NavigatorState> _forumNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _dormNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _ebNavKey = GlobalKey<NavigatorState>();

  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // --- HELPER METHODS ---

  Widget _tileOpen(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          // Fixed deprecation warning
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
          _weatherHeader(name),
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
            // Bathroom Tile
            _tileOpen(Icons.family_restroom, 'Bathrooms', () {
              setState(() => _currentIndex = 1);
            }),
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (_) => const BathroomFinder()),
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
                _dormNavKey.currentState?.popUntil((r) => r.isFirst);
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

  Widget _buildDormTab() {
    return Navigator(
      key: _dormNavKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const DormlifeScreen());
      },
    );
  }

  Widget _buildEventBoardTab() {
  return Navigator(
    key: _ebNavKey,
    onGenerateRoute: (settings) {
      return MaterialPageRoute(builder: (_) => const EventBoardScreen());
    },
  );
}

  Widget _buildBody(BuildContext context) {
    if (_currentIndex == 0) {
      switch (_homePage) {
        case "events":
        return _buildEventBoardTab();
        case "dormlife":
          return _buildDormTab();
        case "hourscap":
          return const HourscapScreen();
        case "feedback":
          return const FeedbackanalyticsScreen();
        case "home":
        default:
          return _dashboardBody(context);
      }
    }
    if (_currentIndex == 1) return const MapScreen();
    if (_currentIndex == 2) return _buildForumTab();
    if (_currentIndex == 3) return const ResourcesPage();
    return const SettingsScreen();
  }

  PreferredSizeWidget? _buildAppBar() {
    final user = FirebaseAuth.instance.currentUser;

    // --- ADMIN LIST ---
    // Add emails here to give them access to the debug button
    final List<String> adminEmails = [
      'teef@gmail.com',
      'reytest@gmail.com',
      'giselle1@gmail.com',
      'josuealfaro8441@gmail.com',
    ];

    if (_currentIndex == 0 && _homePage == "home") {
      return AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          // Check if current user is in the admin list
          if (user?.email != null && adminEmails.contains(user!.email))
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.red),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationTestScreen(),
                  ),
                );
              },
            ),
          if (user?.email !=
                  null && // NEW FROM GISELLE ---> ADDED MODS VIEW SCREEN
              adminEmails.contains(
                user!.email,
              )) // Checks current user is a moderator
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ModerationViewScreen(
                          forumService: _forumService,
                        ), // to view Moderator only screen
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

  // ---------- Weather Bar  ------------
  final _weatherService = WeatherServices(
    'd947beb08a254433a6949b94bf6dccc1',
  ); //API key
  Weather? _weather;

  double convertToFahrenheit(double celsius) =>
      (celsius * 9 / 5) + 32; //Celcuis to Fahrenheit

  //Displays city name and weather condition
  Future<void> _fetchWeather() async {
    try {
      final cityName = await _weatherService.getCurrentCity();
      final weather = await _weatherService.getWeather(cityName);
      if (!mounted) return;
      setState(() => _weather = weather);
    }
    //raise error condition if issues occur
    catch (e) {
      print("Weather error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  //Displays weather background
  List<Color> _getBackgroundColors() {
    if (_weather == null) {
      return [Colors.lightBlue.shade400, Colors.orange.shade300];
    }

    final condition = _weather!.mainCondition.toLowerCase();
    final isNight = _weather!.icon.contains("n");

    if (condition == "clear") {
      return isNight
          ? [Colors.indigo.shade900, Colors.black]
          : [Colors.orange.shade300, Colors.lightBlue.shade400];
    }

    if (condition == "clouds") {
      return isNight
          ? [Colors.blueGrey.shade900, Colors.black54]
          : [Colors.blueGrey.shade400, Colors.grey.shade300];
    }

    if (condition == "rain" || condition == "drizzle") {
      return [Colors.indigo.shade700, Colors.blueGrey.shade500];
    }

    if (condition == "thunderstorm") {
      return [Colors.deepPurple.shade800, Colors.black];
    }

    if (condition == "snow") {
      return [Colors.lightBlueAccent.shade100, Colors.white];
    }

    if (condition == "mist" || condition == "fog" || condition == "haze") {
      return [Colors.grey.shade600, Colors.grey.shade400];
    }

    return [Colors.lightBlue, Colors.orange];
  }

  //Displays weather icons to match weather conditions
  String _getWeatherAnimation() {
    if (_weather == null) return "assets/weather/sunny.json";

    final condition = _weather!.mainCondition.toLowerCase();
    final isNight = _weather!.icon.contains("n");

    //Clear day or clear night
    if (condition == "clear") {
      return isNight
          ? "assets/weather/night.json"
          : "assets/weather/sunny.json";
    }

    //Cloudy
    if (condition == "clouds") {
      return isNight
          ? "assets/weather/night.json"
          : "assets/weather/cloudy.json";
    }

    //Rainy or drizzling
    if (condition == "rain" || condition == "drizzle") {
      return "assets/weather/rain.json";
    }

    //Thunderstorm
    if (condition == "thunderstorm") {
      return "assets/weather/storm.json";
    }

    //Snow
    if (condition == "snow") {
      return "assets/weather/snowy.json";
    }

    //Misty/foggy
    if (condition == "mist" ||
        condition == "smoke" ||
        condition == "haze" ||
        condition == "dust" ||
        condition == "fog") {
      return "assets/weather/mist.json";
    }

    return "assets/weather/sunny.json";
  }

  //Display weather information onto the dashboard
  Widget _weatherHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getBackgroundColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child:
          _weather == null
              ? const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT TEXT
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $name",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _weather!.cityName,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${_weather!.temperature.round()}°C  •  ${convertToFahrenheit(_weather!.temperature).round()}°F",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weather!.mainCondition,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),

                  // RIGHT ANIMATION
                  Lottie.asset(
                    _getWeatherAnimation(),
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
    );
  }
}
