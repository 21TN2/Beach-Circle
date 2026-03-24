import 'package:beach_circle_flutter/map_screen.dart';
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


// Weather packages
import 'package:lottie/lottie.dart';
import 'package:beach_circle_flutter/weather/models/weather_model.dart';
import 'package:beach_circle_flutter/weather/services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

//State Abbreviation for Weather Location 
  String _getStateAbbreviation(String stateName) {
    const stateMap = {
      "Alabama": "AL",
      "Alaska": "AK",
      "Arizona": "AZ",
      "Arkansas": "AR",
      "California": "CA",
      "Colorado": "CO",
      "Connecticut": "CT",
      "Delaware": "DE",
      "Florida": "FL",
      "Georgia": "GA",
      "Hawaii": "HI",
      "Idaho": "ID",
      "Illinois": "IL",
      "Indiana": "IN",
      "Iowa": "IA",
      "Kansas": "KS",
      "Kentucky": "KY",
      "Louisiana": "LA",
      "Maine": "ME",
      "Maryland": "MD",
      "Massachusetts": "MA",
      "Michigan": "MI",
      "Minnesota": "MN",
      "Mississippi": "MS",
      "Missouri": "MO",
      "Montana": "MT",
      "Nebraska": "NE",
      "Nevada": "NV",
      "New Hampshire": "NH",
      "New Jersey": "NJ",
      "New Mexico": "NM",
      "New York": "NY",
      "North Carolina": "NC",
      "North Dakota": "ND",
      "Ohio": "OH",
      "Oklahoma": "OK",
      "Oregon": "OR",
      "Pennsylvania": "PA",
      "Rhode Island": "RI",
      "South Carolina": "SC",
      "South Dakota": "SD",
      "Tennessee": "TN",
      "Texas": "TX",
      "Utah": "UT",
      "Vermont": "VT",
      "Virginia": "VA",
      "Washington": "WA",
      "West Virginia": "WV",
      "Wisconsin": "WI",
      "Wyoming": "WY",
    };

    return stateMap[stateName] ?? stateName;
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

  Weather? _csulbWeather; //Weather at CSULb
  Weather? _weather; //User current location weather

  bool _isLoading = true; //Whether user accepts permission or denies
  bool _locationDenied = false; //Location permission denied 

  String? _currentLocationName;

  double convertToFahrenheit(double celsius) =>
      (celsius * 9 / 5) + 32; //Celcuis to Fahrenheit

  //Displays city name and weather condition
  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // CSULB Weather
      final csulb = await _weatherService.getWeatherByCoords(
        33.7838,
        -118.1141,
      );
      //Permission check
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _csulbWeather = csulb;
          _locationDenied = true;
          _isLoading = false;
        });

        return;
      }

      // Current location of the User
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      //Find City & State of the User
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String city = placemarks[0].locality ?? "";
      String state = placemarks[0].administrativeArea ?? "";

      String stateAbbreviation = _getStateAbbreviation(state); //Ex. California -> CA

      final current = await _weatherService.getWeatherByCoords(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

    //Weather Widget Display 
      setState(() {
        _csulbWeather = csulb;
        _weather = current;
        _currentLocationName = "$city, $stateAbbreviation"; // 👈 SAVE IT
        _locationDenied = false;
        _isLoading = false;
      });
    } catch (e) {
      print("Weather error: $e");
    }
  }

  //State of the Weather
  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  //Weather Widget Background
  List<Color> _getBackgroundColorsFor(Weather weather) {
    final condition = weather.mainCondition.toLowerCase();
    final isNight = weather.icon.contains("n");

    //Weather Conditions(Cloudy, Sunny, Rainy, etc.)
    if (condition == "clear") {
      return isNight
          ? [Colors.indigo.shade900, Colors.black]
          : [Colors.orange, Colors.lightBlue];
    }

    if (condition == "clouds") {
      return isNight
          ? [Colors.blueGrey.shade900, Colors.black54]
          : [Colors.blueGrey, Colors.grey];
    }

    if (condition == "rain") {
      return [Colors.indigo, Colors.blueGrey];
    }

    if (condition == "thunderstorm") {
      return [Colors.deepPurple, Colors.black];
    }

    if (condition == "snow") {
      return [Colors.lightBlueAccent, Colors.white];
    }

    if (condition == "mist" || condition == "fog") {
      return [Colors.grey.shade600, Colors.grey.shade400];
    }

    return [Colors.blue, Colors.lightBlue];
  }

  //Weather icons match current weather conditions(Ex. If rainy weather show rainy icon)
  String _getWeatherAnimationFor(Weather weather) {
    final condition = weather.mainCondition.toLowerCase();
    final isNight = weather.icon.contains("n");

    if (condition == "clear") {
      return isNight
          ? "assets/weather/night.json" //Json file is the weather icons 
          : "assets/weather/sunny.json";
    }

    if (condition == "clouds") {
      return isNight
          ? "assets/weather/night.json"
          : "assets/weather/cloudy.json";
    }

    if (condition == "rain" || condition == "drizzle") {
      return "assets/weather/rain.json";
    }

    if (condition == "thunderstorm") {
      return "assets/weather/storm.json";
    }

    if (condition == "snow") {
      return "assets/weather/snowy.json";
    }

    if (condition == "mist" || condition == "fog") {
      return "assets/weather/mist.json";
    }

    return "assets/weather/sunny.json";
  }

  //Weather Widget Title
  Widget _weatherHeader(String name) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },

            //CSULB Campus title text
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildWeatherCard(
                  weather: _csulbWeather,
                  title: "CSULB Campus",
                  name: name,
                ),
              ),

              //Current location text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildWeatherCard(
                  weather: _weather,
                  title: "Current Location",
                  name: name,
                ),
              ),
            ],
          ),
        ),

        //Title Card Size
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 16 : 8,
              decoration: BoxDecoration(
                color:
                    _currentPage == index
                        ? Colors.blueAccent
                        : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  //Weather Card Widget Implementations
  Widget _buildWeatherCard({
    required Weather? weather,
    required String title,
    required String name,
  }) {

    //Implementing Background onto Widget
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              weather == null
                  ? [Colors.blue, Colors.lightBlue]
                  : _getBackgroundColorsFor(weather),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),

      //If location permission is allowed
      child:
          weather == null
              ? _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : (title == "Current Location" && _locationDenied)
                  ? _buildLocationRetry() 
                  : const SizedBox()
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    //Welcoming User Texts
                    children: [
                      Text(
                        "Hello, $name",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),

                      //Title Card Implemented on Widget
                      Text(
                        title == "CSULB Campus"
                            ? "Long Beach, CA"
                            : _currentLocationName ?? weather.cityName,
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 10),

                      //Current Temperature
                      Text(
                        "${weather.temperature.round()}°C • "
                        "${convertToFahrenheit(weather.temperature).round()}°F",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weather.mainCondition,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),

                  //Weather icon 
                  Lottie.asset(
                    _getWeatherAnimationFor(weather),
                    width: 95,
                    height: 95,
                  ),
                ],
              ),
    );
  }

  //Location permission Denied
  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(

          //Display message requiring location permissions
          title: const Text("Location Access Required"),
          content: const Text(
            "Please enable location access to view current weather.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  //If location permission is not accepted or denied(Allow Retry)
  Widget _buildLocationRetry() {
    return GestureDetector(
      onTap: () async {
        LocationPermission permission = await Geolocator.requestPermission(); //Permission Request

        if (permission == LocationPermission.always || 
            permission == LocationPermission.whileInUse) {
          _fetchWeather();
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.location_off, size: 50, color: Colors.white),
          SizedBox(height: 12),

          //If location is not accepted, prompted message
          Text(
            "Location Access Needed",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),

          //Allow users to tap to load permission acceess
          Text(
            "Tap to allow location",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
