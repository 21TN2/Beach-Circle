//Creates the weather model template for the rest of the files

class Weather {
  //Shows the city name, temperature, and the condition that the weather is currently at
  final String cityName;
  final double temperature;
  final String mainCondition;
  final String icon;

  //Makes it so the Weather class requires those three aspects
  Weather({
    required this.cityName,
    required this.temperature,
    required this.mainCondition,
    required this.icon,
  });

  //Displays the city name, temperature, and the condition
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      mainCondition: json['weather'][0]['main'],
      icon: json['weather'][0]['icon'],
    );
  }
}
