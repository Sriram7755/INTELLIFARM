import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';

class RainPredictionScreen extends StatefulWidget {
  @override
  _RainPredictionScreenState createState() => _RainPredictionScreenState();
}

class _RainPredictionScreenState extends State<RainPredictionScreen> {
  final humidityController = TextEditingController();
  final temperatureController = TextEditingController();
  final windSpeedController = TextEditingController();

  String predictionResult = '';
  bool isLoading = false;
  bool isWeatherLoading = false;

  final String weatherApiKey = "c47ca008bbbc46bdb4c33918250905"; // replace this

  @override
  void initState() {
    super.initState();
    getLocationAndFetchWeather();
  }

  Future<void> getLocationAndFetchWeather() async {
    setState(() => isWeatherLoading = true);

    try {
      var permission = await Permission.location.request();
      if (!permission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Location permission denied'),
        ));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double lat = position.latitude;
      double lon = position.longitude;

      await fetchWeatherData(lat, lon);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to get location'),
      ));
    } finally {
      setState(() => isWeatherLoading = false);
    }
  }

  Future<void> fetchWeatherData(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.weatherapi.com/v1/current.json?key=$weatherApiKey&q=$lat,$lon');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data['current']['temp_c'];
        final humidity = data['current']['humidity'];
        final windKph = data['current']['wind_kph'];
        final windMps = (windKph / 3.6).toStringAsFixed(2);

        setState(() {
          temperatureController.text = temp.toString();
          humidityController.text = humidity.toString();
          windSpeedController.text = windMps;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Weather API error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch weather data')),
      );
    }
  }

  Future<void> predictRain() async {
    setState(() {
      isLoading = true;
      predictionResult = '';
    });

    final url = Uri.parse('http://172.22.69.171:5000/predict');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'humidity': humidityController.text,
          'temperature': temperatureController.text,
          'wind_speed': windSpeedController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          predictionResult = data['prediction'] ?? 'No response';
        });
      } else {
        setState(() {
          predictionResult = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        predictionResult = 'Connection Error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    humidityController.dispose();
    temperatureController.dispose();
    windSpeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0FAF0),
      appBar: AppBar(
        title: Text("Rain Prediction"),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: getLocationAndFetchWeather,
            tooltip: "Refresh Weather Data",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            isWeatherLoading
                ? SpinKitFadingCircle(color: Colors.green, size: 40)
                : Text("Weather data fetched using location",
                    style: TextStyle(color: Colors.green[700])),
            SizedBox(height: 20),
            TextField(
              controller: humidityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Humidity (%)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: temperatureController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Temperature (°C)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: windSpeedController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Wind Speed (m/s)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 25),
            isLoading
                ? SpinKitFadingCircle(
                    color: Colors.green,
                    size: 50.0,
                  )
                : ElevatedButton.icon(
                    onPressed: predictRain,
                    icon: Icon(Icons.cloud_outlined),
                    label: Text('Predict Rain'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
            SizedBox(height: 30),
            if (predictionResult.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  "Prediction: $predictionResult",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
