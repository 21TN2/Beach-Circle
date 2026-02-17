//Dependencies and packages
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:beach_circle_flutter/weather/models/weather_model.dart';
import 'package:beach_circle_flutter/weather/services/weather_service.dart';

//Creates the Weather page template
class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

//Weather page displays
class _WeatherPageState extends State<WeatherPage> {

  //The api key
  final _weatherService =
      WeatherServices('d947beb08a254433a6949b94bf6dccc1');

  Weather? _weather;

  //If any error occurs while trying to receive the data
  _fetchWeather() async {
    String cityName = await _weatherService.getCurrentCity();

    try {
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      print(e);
    }
  }

  //Converts celsius to Fahrenheit
  double convertToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  //Weather animation displays(Icons)
  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return "assets/weather/sunny.json";

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return "assets/weather/sunny.json";
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return "assets/weather/sunny.json";
      case 'thunderstorm':
        return "assets/weather/sunny.json";
      case 'clear':
        return "assets/weather/sunny.json";
      default:
        return "assets/weather/sunny.json";
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  //Function to match the weather icon to the current weather condition
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _weather == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_weather!.cityName),
                  Lottie.asset(
                      getWeatherAnimation(_weather?.mainCondition)),
                  Text(
                    '${_weather!.temperature.round()}°C / '
                    '${convertToFahrenheit(_weather!.temperature).round()}°F',
                    style: const TextStyle(fontSize: 28),
                  ),
                  Text(_weather?.mainCondition ?? ""),
                ],
              ),
      ),
    );
  }
}
