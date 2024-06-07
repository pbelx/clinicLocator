import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Nearby Medical Services App'),
        ),
        body: Center(
          child: LocationWidget(),
        ),
      ),
    );
  }
}

class LocationWidget extends StatefulWidget {
  @override
  _LocationWidgetState createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  String _locationMessage = "";
  Position? _currentPosition;
  List<dynamic>? _places;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = "Location permissions are denied";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage =
            "Location permissions are permanently denied, we cannot request permissions.";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _locationMessage =
          "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
    });
  }

  Future<void> _fetchPlaces() async {
    if (_currentPosition == null) return;

    final response = await http.get(
      Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_currentPosition!.latitude},${_currentPosition!.longitude}&radius=5000&type=hospital&key=AIzaSyD3fMAJHBauwZA8vJG0p6g23zwN0X0'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        _places = data['results'];
      });
    } else {
      throw Exception('Failed to load places');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            _locationMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _getCurrentLocation,
            child: Text("Get Location"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchPlaces,
            child: Text("Fetch Nearby Places"),
          ),
          SizedBox(height: 20),
          _places == null
              ? CircularProgressIndicator()
              : Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _places!.length,
                    itemBuilder: (context, index) {
                      final place = _places![index];
                      return SizedBox(
                        height: 150,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          margin: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Card(
                            color: Colors.green.shade500,
                            child: Stack(
                              children: [
                                Image.network(
                                  'https://via.placeholder.com/150',
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place['name'],
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(place['vicinity']),
                                        ElevatedButton(
                                          onPressed: () {
                                            launch(
                                                'https://www.google.com/maps/search/?api=1&query=${place['geometry']['location']['lat']},${place['geometry']['location']['lng']}');
                                          },
                                          child: Text('Get Directions'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
