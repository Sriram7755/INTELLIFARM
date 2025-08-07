import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherForecastPage extends StatefulWidget {
  final double lat;
  final double lon;
  final String locationName;

  const WeatherForecastPage({
    super.key,
    required this.lat,
    required this.lon,
    required this.locationName,
  });

  @override
  State<WeatherForecastPage> createState() => _WeatherForecastPageState();
}

class _WeatherForecastPageState extends State<WeatherForecastPage> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;

  final String apiKey = 'bd58ea1265cb41f1b5e95015251707'; // Your WeatherAPI key

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      final url =
          'http://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=${widget.lat},${widget.lon}&days=7';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        debugPrint("WeatherAPI Error: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Exception: $e");
      setState(() => isLoading = false);
    }
  }

  Widget buildCurrentWeather() {
    final current = weatherData!['current'];
    final condition = current['condition']['text'];
    final temp = current['temp_c'];
    final wind = current['wind_kph'];
    final humidity = current['humidity'];
    final icon = 'https:${current['condition']['icon']}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          widget.locationName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Image.network(icon, width: 100),
        Text(
          '$temp°C',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        Text(
          condition,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            weatherIconText(Icons.air, "$wind km/h", "Wind"),
            const SizedBox(width: 20),
            weatherIconText(Icons.water_drop, "$humidity%", "Humidity"),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget weatherIconText(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget buildForecastList() {
    final forecast = weatherData!['forecast']['forecastday'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Next 3 Days",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          itemCount: forecast.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final day = forecast[index];
            final date = day['date'];
            final condition = day['day']['condition']['text'];
            final icon = 'https:${day['day']['condition']['icon']}';
            final maxTemp = day['day']['maxtemp_c'];
            final minTemp = day['day']['mintemp_c'];
            final wind = day['day']['maxwind_kph'];
            final humidity = day['day']['avghumidity'];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Image.network(icon, width: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(condition, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text("↑ $maxTemp°C"),
                      Text("↓ $minTemp°C", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Icon(Icons.air, size: 16, color: Colors.blueGrey),
                      Text("$wind km/h", style: const TextStyle(fontSize: 12)),
                      Icon(Icons.water_drop, size: 16, color: Colors.blue),
                      Text("$humidity%", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: Text("Weather - ${widget.locationName}"),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weatherData == null
              ? const Center(child: Text("Error fetching weather"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      buildCurrentWeather(),
                      buildForecastList(),
                    ],
                  ),
                ),
    );
  }
}


