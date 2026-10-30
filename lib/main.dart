
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HavaMitraHome(),
    );
  }
}

class HavaMitraHome extends StatefulWidget {
  const HavaMitraHome({super.key});

  @override
  State<HavaMitraHome> createState() => _HavaMitraHomeState();
}

class _HavaMitraHomeState extends State<HavaMitraHome> {
  final LatLng villageLocation =
      const LatLng(19.130057, 76.469843);

  LatLng selectedLocation =
      const LatLng(19.130057, 76.469843);

  String villageName = 'वाघाळा, ता. पाथरी, जि. परभणी';
  String weatherText = 'हवामानाची माहिती मिळवत आहे...';
  String temperature = '--';
  String humidity = '--';
  String windSpeed = '--';
  String rainChance = '--';
  String errorMessage = '';
  bool loading = false;

  Map<String, dynamic>? weatherData;

  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      final lat = selectedLocation.latitude;
      final lon = selectedLocation.longitude;

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,'
        'precipitation,weather_code,wind_speed_10m'
        '&hourly=precipitation_probability,precipitation'
        '&forecast_days=3&timezone=Asia%2FKolkata',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final current =
            data['current'] as Map<String, dynamic>;

        if (!mounted) return;

        setState(() {
          weatherData = data;
          temperature =
              '${current['temperature_2m']}°C';
          humidity =
              '${current['relative_humidity_2m']}%';
          windSpeed =
              '${current['wind_speed_10m']} km/h';

          final rain =
              current['precipitation'] ?? 0;
          rainChance = '$rain mm';

          weatherText = getWeatherDescription(
            current['weather_code'] as int? ?? 0,
          );

          loading = false;
        });
      } else {
        throw Exception('हवामान माहिती उपलब्ध नाही.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage =
            'इंटरनेट तपासा आणि पुन्हा प्रयत्न करा.';
      });
    }
  }

  String getWeatherDescription(int code) {
    if (code == 0) return 'आकाश निरभ्र';
    if (code <= 3) return 'ढगाळ वातावरण';
    if (code <= 48) return 'धुके';
    if (code <= 67) return 'पाऊस';
    if (code <= 77) return 'बर्फवृष्टी';
    if (code <= 82) return 'पावसाच्या सरी';
    if (code <= 99) return 'वादळाची शक्यता';
    return 'हवामानाची माहिती';
  }

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        showMessage('मोबाइलचे Location सुरू करा.');
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showMessage('GPS वापरण्याची परवानगी द्या.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        selectedLocation = LatLng(
          position.latitude,
          position.longitude,
        );
        villageName = 'तुमचे सध्याचे GPS स्थान';
      });

      await loadWeather();
    } catch (e) {
      showMessage('GPS स्थान मिळाले नाही.');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget weatherCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget buildHome() {
    return RefreshIndicator(
      onRefresh: loadWeather,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: Colors.blue.shade700,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud,
                    size: 55,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    villageName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    temperature,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    weatherText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: loadWeather,
                        icon: const Icon(Icons.refresh),
                        label: const Text('हवामान अपडेट'),
                      ),
                      ElevatedButton.icon(
                        onPressed: getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('माझे GPS'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              weatherCard(
                'आर्द्रता',
                humidity,
                Icons.water_drop,
              ),
              weatherCard(
                'वाऱ्याचा वेग',
                windSpeed,
                Icons.air,
              ),
              weatherCard(
                'सध्याचा पाऊस',
                rainChance,
                Icons.umbrella,
              ),
              weatherCard(
                'पावसाची शक्यता',
                getNextRainChance(),
                Icons.cloudy_snowing,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'पुढील काही तासांचा अंदाज',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          buildHourlyForecast(),
          const SizedBox(height: 12),
          const Text(
            'शेतीसाठी सूचना',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.agriculture,
                color: Colors.green,
              ),
              title: const Text('शेतकऱ्यांसाठी'),
              subtitle: Text(getFarmAdvice()),
            ),
          ),
        ],
      ),
    );
  }

  String getNextRainChance() {
    if (weatherData == null) return '--';

    final hourly =
        weatherData!['hourly'] as Map<String, dynamic>?;
    final chances =
        hourly?['precipitation_probability'] as List?;

    if (chances == null || chances.isEmpty) return '--';

    return '${chances.first}%';
  }

  Widget buildHourlyForecast() {
    if (weatherData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('हवामानाची माहिती लोड होत आहे...'),
        ),
      );
    }

    final hourly =
        weatherData!['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List;
    final rain = hourly['precipitation'] as List;
    final chances =
        hourly['precipitation_probability'] as List;

    final now = DateTime.now();
    int start = times.indexWhere((time) {
      return !DateTime.parse(time.toString()).isBefore(now);
    });

    if (start < 0) start = 0;

    final end = math.min(start + 6, times.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: List.generate(end - start, (index) {
            final i = start + index;
            final time = DateTime.parse(times[i].toString());

            return ListTile(
              dense: true,
              leading: const Icon(Icons.access_time),
              title: Text(
                '${time.hour.toString().padLeft(2, '0')}:00',
              ),
              subtitle: Text(
                'पाऊस: ${rain[i]} mm',
              ),
              trailing: Text(
                '${chances[i]}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String getFarmAdvice() {
    if (weatherData == null) {
      return 'हवामान मिळाल्यानंतर सूचना दिसतील.';
    }

    final hourly =
        weatherData!['hourly'] as Map<String, dynamic>;
    final rain = hourly['precipitation'] as List;
    final total = rain
        .take(24)
        .fold<double>(
          0,
          (sum, value) => sum + (value as num).toDouble(),
        );

    if (total >= 10) {
      return 'पुढील 24 तासांत पावसाचा अंदाज आहे. '
          'फवारणी आणि खत देण्याची वेळ काळजीपूर्वक ठरवा.';
    }

    return 'पुढील 24 तासांचा अंदाज तपासा. '
        'मातीतील ओलावा पाहूनच सिंचन करा.';
  }
  
  
Widget buildTradition() {
  final nakshatras = [
    ['अश्विनी', 'केतू', 'घोड्याच्या वेगाशी संबंधित नक्षत्र.'],
    ['भरणी', 'शुक्र', 'उष्णता आणि बदल यांच्याशी संबंधित लोकसमज.'],
    ['कृत्तिका', 'सूर्य', 'उन्हाळ्याच्या तीव्रतेचे पारंपरिक संकेत.'],
    ['रोहिणी', 'चंद्र', 'पावसाच्या दृष्टीने महत्त्वाचे मानले जाते.'],
    ['मृगशीर्ष', 'मंगळ', 'पावसाळ्याच्या सुरुवातीशी जोडले जाते.'],
    ['आर्द्रा', 'राहू', 'पावसाच्या आगमनाशी संबंधित मान्यता.'],
    ['पुनर्वसू', 'गुरू', 'पावसातील बदलांचे पारंपरिक संकेत.'],
    ['पुष्य', 'शनी', 'शेतीसाठी पावसाचे निरीक्षण केले जाते.'],
    ['आश्लेषा', 'बुध', 'ढग आणि पावसाबद्दल लोकसमजुती आहेत.'],
    ['मघा', 'केतू', 'पावसाच्या बदलांचे पारंपरिक निरीक्षण.'],
    ['पूर्वा फाल्गुनी', 'शुक्र', 'पावसाच्या स्थितीचे निरीक्षण.'],
    ['उत्तरा फाल्गुनी', 'सूर्य', 'शेतीतील ओलाव्याशी संबंधित संकेत.'],
    ['हस्त', 'चंद्र', 'पावसाच्या अंदाजात महत्त्वाचे मानले जाते.'],
    ['चित्रा', 'मंगळ', 'ढग आणि वाऱ्याचे निरीक्षण.'],
    ['स्वाती', 'राहू', 'वारा आणि पावसाच्या लोकसमजुती.'],
    ['विशाखा', 'गुरू', 'पावसातील बदलांचे निरीक्षण.'],
    ['अनुराधा', 'शनी', 'पारंपरिक पर्जन्य निरीक्षण.'],
    ['ज्येष्ठा', 'बुध', 'उष्णता आणि पावसाचे निरीक्षण.'],
    ['मूळ', 'केतू', 'पावसाच्या स्थितीबद्दल लोकसमजुती.'],
    ['पूर्वाषाढा', 'शुक्र', 'पावसाळ्याच्या निरीक्षणाशी संबंधित.'],
    ['उत्तराषाढा', 'सूर्य', 'शेतीसाठी पावसाचे निरीक्षण.'],
    ['श्रवण', 'चंद्र', 'पावसाच्या सातत्याचे पारंपरिक संकेत.'],
    ['धनिष्ठा', 'मंगळ', 'ढग आणि वाऱ्याचे निरीक्षण.'],
    ['शततारका', 'राहू', 'पावसाच्या बदलांबद्दल लोकसमजुती.'],
    ['पूर्वाभाद्रपदा', 'गुरू', 'पारंपरिक पर्जन्य निरीक्षण.'],
    ['उत्तराभाद्रपदा', 'शनी', 'पावसाच्या स्थितीचे निरीक्षण.'],
    ['रेवती', 'बुध', 'हंगामातील बदलांचे निरीक्षण.'],
  ];

  final currentName = getApproxNakshatra()
      .replaceAll(' (अंदाजे गणना)', '');

  final index = nakshatras.indexWhere(
    (item) => item[0] == currentName,
  );

  final selected = index >= 0
      ? nakshatras[index]
      : nakshatras[0];

  return ListView(
    padding: const EdgeInsets.all(12),
    children: [
      Card(
        color: Colors.deepPurple.shade50,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(
                Icons.nights_stay,
                size: 48,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 10),
              const Text(
                'आजचे अंदाजे नक्षत्र',
                style: TextStyle(fontSize: 17),
              ),
              Text(
                selected[0],
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('नक्षत्र क्रमांक: ${index + 1} / 27'),
            ],
          ),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.stars),
          title: const Text('नक्षत्राचा स्वामी ग्रह'),
          subtitle: Text(selected[1]),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.cloud),
          title: const Text('पारंपरिक पर्जन्य संकेत'),
          subtitle: Text(selected[2]),
        ),
      ),
      const Card(
        child: ListTile(
          leading: Icon(Icons.agriculture, color: Colors.green),
          title: Text('शेतीसाठी सूचना'),
          subtitle: Text(
            'पेरणी, फवारणी आणि सिंचनाचे निर्णय '
            'प्रत्यक्ष हवामान अंदाज व शेतातील ओलावा '
            'पाहूनच घ्या.',
          ),
        ),
      ),
      const Card(
        child: ListTile(
          leading: Icon(Icons.menu_book, color: Colors.brown),
          title: Text('सहदेव भाडळी लोकपरंपरा'),
          subtitle: Text(
            'ढगांचा रंग, वाऱ्याची दिशा, विजांचा कडकडाट '
            'आणि निसर्गातील बदल यांचे निरीक्षण '
            'पारंपरिक पर्जन्य अंदाजात केले जाते.',
          ),
        ),
      ),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'सूचना: ही पारंपरिक माहिती आहे. '
            'नक्षत्रामुळे पाऊस पडतो याचा वैज्ञानिक '
            'पुरावा नाही. पावसासाठी हवामान विभागाचा '
            'अंदाज तपासा.',
          ),
        ),
      ),
    ],
  );
}
  
  String getApproxNakshatra() {
    final now = DateTime.now().toUtc();

    final jd = now.millisecondsSinceEpoch /
            86400000.0 +
        2440587.5;

    final t = (jd - 2451545.0) / 36525.0;

    var moonLongitude = 218.3164477 +
        481267.88123421 * t -
        0.0015786 * t * t;

    moonLongitude %= 360;

    if (moonLongitude < 0) {
      moonLongitude += 360;
    }

    final names = [
      'अश्विनी',
      'भरणी',
      'कृत्तिका',
      'रोहिणी',
      'मृगशीर्ष',
      'आर्द्रा',
      'पुनर्वसू',
      'पुष्य',
      'आश्लेषा',
      'मघा',
      'पूर्वा फाल्गुनी',
      'उत्तरा फाल्गुनी',
      'हस्त',
      'चित्रा',
      'स्वाती',
      'विशाखा',
      'अनुराधा',
      'ज्येष्ठा',
      'मूळ',
      'पूर्वाषाढा',
      'उत्तराषाढा',
      'श्रवण',
      'धनिष्ठा',
      'शततारका',
      'पूर्वाभाद्रपदा',
      'उत्तराभाद्रपदा',
      'रेवती',
    ];

    final index =
        (moonLongitude / (360 / 27)).floor();

    return '${names[index]} (अंदाजे गणना)';
  }

  Widget buildRadar() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(
          'https://mausam.imd.gov.in/responsive/radar.php',
        ),
      );

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'पावसाचा रडार',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'रडारचे चित्र दिसण्यासाठी इंटरनेट आवश्यक आहे. '
            'वेबसाइट उपलब्ध नसेल तर रडार दिसणार नाही.',
          ),
        ),
        Expanded(
          child: WebViewWidget(
            controller: controller,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildHome(),
      buildTradition(),
      buildRadar(),
      FlutterMap(
        options: MapOptions(
          initialCenter: selectedLocation,
          initialZoom: 12,
          onTap: (tapPosition, point) {
            setState(() {
              selectedLocation = point;
              villageName = 'नकाशावर निवडलेले स्थान';
            });
            loadWeather();
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.havamitra.marathi',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: selectedLocation,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 42,
                ),
              ),
            ],
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('हवामित्र मराठी 🌦️'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            onPressed: loadWeather,
            icon: const Icon(Icons.refresh),
            tooltip: 'हवामान अपडेट',
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedTab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.cloud),
            label: 'हवामान',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome),
            label: 'नक्षत्र',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar),
            label: 'रडार',
          ),
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'नकाशा',
          ),
        ],
      ),
    );
  }
}
