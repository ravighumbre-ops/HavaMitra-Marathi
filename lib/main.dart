
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HavaMitraApp());
}

class HavaMitraApp extends StatelessWidget {
  const HavaMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'हवामित्र मराठी',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String status = 'हवामान माहिती मिळवत आहे...';
  String temperature = '--';
  String description = 'वाघाळा, पाथरी, परभणी';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    setState(() {
      loading = true;
      status = 'हवामान माहिती मिळवत आहे...';
    });

    try {
      final uri = Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        {
          'latitude': '19.130057',
          'longitude': '76.469843',
          'current': 'temperature_2m,weather_code',
          'timezone': 'Asia/Kolkata',
        },
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('सर्व्हरने माहिती दिली नाही.');
      }

      final data = jsonDecode(response.body);
      final current = data['current'];

      if (current == null) {
        throw Exception('हवामान माहिती उपलब्ध नाही.');
      }

      if (!mounted) return;
      setState(() {
        temperature =
            '${(current['temperature_2m'] as num).round()}°C';
        description = weatherText(current['weather_code']);
        status = 'हवामान अपडेट झाले';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        status = 'हवामान मिळाले नाही. इंटरनेट तपासा.';
        loading = false;
      });
    }
  }

  String weatherText(dynamic code) {
    final c = (code as num?)?.toInt() ?? 0;
    if (c == 0) return 'निरभ्र आकाश';
    if (c <= 3) return 'ढगाळ हवामान';
    if (c == 45 || c == 48) return 'धुके';
    if (c >= 51 && c <= 67) return 'पावसाची शक्यता';
    if (c >= 80 && c <= 82) return 'पावसाच्या सरी';
    if (c >= 95) return 'वादळाची शक्यता';
    return 'हवामान बदलते आहे';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF8),
      appBar: AppBar(
        title: const Text('🌦️ हवामित्र मराठी'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud,
                size: 90,
                color: Colors.teal,
              ),
              const SizedBox(height: 20),
              const Text(
                'वाघाळा, पाथरी, परभणी',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                temperature,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              Text(
                status,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: loading ? null : fetchWeather,
                icon: const Icon(Icons.refresh),
                label: const Text('हवामान पुन्हा तपासा'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
