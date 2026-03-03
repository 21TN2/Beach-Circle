// dashboard home page
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// dashboard screens
import 'map_screen.dart';
import 'misc_screen.dart';
import 'screens/resources_page.dart';
import 'settings_screen.dart';

import 'events_screen.dart';
import 'dormlife_screen.dart';
import 'hourscap_screen.dart';
import 'feedbackanalytics_screen.dart';

// Weather packages
import 'package:lottie/lottie.dart';
import 'package:beach_circle_flutter/weather/models/weather_model.dart';
import 'package:beach_circle_flutter/weather/services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Forum request page (the “add forum request” screen)
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

  // Tab 2: forum
  String _forumPage = "forum"; // forum | createForumRequest

  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

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
            _tileOpen(Icons.event, 'Events', () {
              setState(() {
                _currentIndex = 0;
                _homePage = "events";
              });
            }),
            _tileOpen(Icons.forum, 'Misc Forums', () {
              setState(() {
                _currentIndex = 2;
                _forumPage = "forum";
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

    // TAB 2 student misc forum
    if (_currentIndex == 2) {
      if (_forumPage == "createForumRequest") {
        return CreateForumPage(
          onClose: () => setState(() => _forumPage = "forum"),
          onSubmitted: () => setState(() => _forumPage = "forum"),
        );
      }
      return const MiscScreen();
    }

    // TAB 3 resource page
    if (_currentIndex == 3) return const ResourcesPage();

    // TAB 4 settings
    return const SettingsScreen();
  }

  // ---------- AppBar  ------------
  PreferredSizeWidget? _buildAppBar() {
    if (_currentIndex == 0 && _homePage == "home") {
      return AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: _logOut,
          ),
        ],
      );
    }

    // show a back button for dashboard pages
    if (_currentIndex == 0 && _homePage != "home") {
      String title = "Back";
      if (_homePage == "events") title = "Events";
      if (_homePage == "dormlife") title = "Dorm Life";
      if (_homePage == "hourscap") title = "Hours & Capacity";
      if (_homePage == "feedback") title = "Feedback & Analytics";

      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _homePage = "home"),
        ),
        title: Text(title),
        centerTitle: true,
      );
    }

    // no appbar for other tabs yet
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(context),

      //(request a forum/category)
      floatingActionButton:
          (_currentIndex == 2 && _forumPage == "forum")
              ? FloatingActionButton(
                backgroundColor: const Color(0xFFFFD500),
                foregroundColor: Colors.black,
                elevation: 3,
                onPressed: () {
                  setState(() {
                    _forumPage = "createForumRequest";
                  });
                },
                child: const Icon(Icons.edit),
              )
              : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap:
            (index) => setState(() {
              _currentIndex = index;

              // reset sub-pages when switching tabs
              if (index != 0) _homePage = "home";
              if (index != 2) _forumPage = "forum";
            }),
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

  Weather? _csulbWeather;
  Weather? _weather;

  bool _isLoading = true;
  bool _locationDenied = false;

  String? _currentLocationName;

  double convertToFahrenheit(double celsius) =>
      (celsius * 9 / 5) + 32; //Celcuis to Fahrenheit

  //Displays city name and weather condition
  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1️⃣ CSULB
      final csulb = await _weatherService.getWeatherByCoords(
        33.7838,
        -118.1141,
      );
      // 2️⃣ Permission check
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

      // 2️⃣ Current location position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3️⃣ Reverse geocode for city + state
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String city = placemarks[0].locality ?? "";
      String state = placemarks[0].administrativeArea ?? "";

      String stateAbbreviation = _getStateAbbreviation(state);

      final current = await _weatherService.getWeatherByCoords(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

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

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  //Displays weather background
  List<Color> _getBackgroundColorsFor(Weather weather) {
    final condition = weather.mainCondition.toLowerCase();
    final isNight = weather.icon.contains("n");

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

  //Displays weather icons to match weather conditions
  String _getWeatherAnimationFor(Weather weather) {
    final condition = weather.mainCondition.toLowerCase();
    final isNight = weather.icon.contains("n");

    if (condition == "clear") {
      return isNight
          ? "assets/weather/night.json"
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
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildWeatherCard(
                  weather: _csulbWeather,
                  title: "CSULB Campus",
                  name: name,
                ),
              ),
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

        const SizedBox(height: 8),

        // 👇 DOT INDICATOR
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

  Widget _buildWeatherCard({
    required Weather? weather,
    required String title,
    required String name,
  }) {
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
                      Text(
                        title == "CSULB Campus"
                            ? "Long Beach, CA"
                            : _currentLocationName ?? weather.cityName,
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 10),
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
                  Lottie.asset(
                    _getWeatherAnimationFor(weather),
                    width: 95,
                    height: 95,
                  ),
                ],
              ),
    );
  }

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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

  Widget _buildLocationRetry() {
    return GestureDetector(
      onTap: () async {
        LocationPermission permission = await Geolocator.requestPermission();

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
          Text(
            "Location Access Needed",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            "Tap to allow location",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
