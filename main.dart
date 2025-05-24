import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class SilentSpot {
  final String name;
  final String type;
  final int noiseLevel;
  final String wifiSpeed;
  final String seating;
  final LatLng location;

  SilentSpot({
    required this.name,
    required this.type,
    required this.noiseLevel,
    required this.wifiSpeed,
    required this.seating,
    required this.location,
  });
}


void main() => runApp(SilentSpaceApp());

class SilentSpaceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Silent Spaces',
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _currentPosition;
  LatLng? _selectedPoint;
  final List<Marker> _markers = [];
  final List<SilentSpot> _spots = [];

  Future<void> _saveSpots() async {
  final prefs = await SharedPreferences.getInstance();
  final spotsJson = _spots.map((spot) => jsonEncode({
    'name': spot.name,
    'type': spot.type,
    'noiseLevel': spot.noiseLevel,
    'wifiSpeed': spot.wifiSpeed,
    'seating': spot.seating,
    'lat': spot.location.latitude,
    'lng': spot.location.longitude,
  })).toList();
  await prefs.setStringList('saved_spots', spotsJson);
  }

  Future<void> _loadSpots() async {
  final prefs = await SharedPreferences.getInstance();
  final spotsJson = prefs.getStringList('saved_spots') ?? [];

  final loadedSpots = spotsJson.map((jsonStr) {
    final data = jsonDecode(jsonStr);
    return SilentSpot(
      name: data['name'],
      type: data['type'],
      noiseLevel: data['noiseLevel'],
      wifiSpeed: data['wifiSpeed'],
      seating: data['seating'],
      location: LatLng(data['lat'], data['lng']),
    );
  }).toList();

  setState(() {
    _spots.clear();
    _spots.addAll(loadedSpots);
  });
  }

  Future<void> _deleteSpot(SilentSpot spot) async {
  setState(() {
    _spots.remove(spot);
  });
  _saveSpots();
  }

  Future<void> _clearAllSpots() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _spots.clear();
  });
  await prefs.remove('saved_spots');
  }

  void _showSpotDetails(SilentSpot spot) {
  final distance = Geolocator.distanceBetween(
    _currentPosition!.latitude,
    _currentPosition!.longitude,
    spot.location.latitude,
    spot.location.longitude,
  ) / 1000;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(spot.name),
      content: Text(
          'Type: ${spot.type}\nNoise Level: ${spot.noiseLevel}\nWi-Fi: ${spot.wifiSpeed}\nSeating: ${spot.seating}\nDistance: ${distance.toStringAsFixed(2)} km'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close"),
        )
      ],
    ),
  );
}

void _showAllSpots() {
  showModalBottomSheet(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          String? filterType;

          return Column(
            children: [
              DropdownButton<String>(
                hint: Text("Filter by Type"),
                value: filterType,
                onChanged: (val) => setModalState(() => filterType = val),
                items: ["Café", "Library", "Park"].map((val) {
                  return DropdownMenuItem(
                      value: val, child: Text(val));
                }).toList(),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("Confirm Delete"),
                      content: Text("Are you sure you want to delete all saved spots?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Yes")),
                      ],
                    ),
                  );
                  if (confirmed ?? false) {
                    _clearAllSpots();
                    setModalState(() {}); // Refresh after deletion
                  }
                },
                icon: Icon(Icons.delete_sweep, color: Colors.red),
                label: Text("Clear All"),
              ),
              Expanded(
                child: Builder(
                  builder: (_) {
                    final filteredSpots = filterType == null
                        ? _spots
                        : _spots.where((s) => s.type == filterType).toList();

                    return ListView.builder(
                      itemCount: filteredSpots.length,
                      itemBuilder: (ctx, i) {
                        final s = filteredSpots[i];
                        final distance = Geolocator.distanceBetween(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                              s.location.latitude,
                              s.location.longitude,
                            ) / 1000;
                        return ListTile(
                          title: Text(s.name),
                          subtitle: Text('${s.type} • ${distance.toStringAsFixed(2)} km away'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteSpot(s);
                              setModalState(() {}); // Refresh list
                            },
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showSpotDetails(s);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}


  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadSpots(); // Load saved spots
}

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _showAddSpotDialog() {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String type = 'Café';
  int noiseLevel = 3;
  String wifiSpeed = 'Medium';
  String seating = 'Available';

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text("Add Silent Spot"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: "Place Name"),
                    validator: (val) => val!.isEmpty ? "Enter name" : null,
                    onSaved: (val) => name = val!,
                  ),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(labelText: "Type"),
                    items: ["Café", "Library", "Park"].map((label) {
                      return DropdownMenuItem(child: Text(label), value: label);
                    }).toList(),
                    onChanged: (val) => setDialogState(() => type = val!),
                  ),
                  DropdownButtonFormField<int>(
                    value: noiseLevel,
                    decoration: InputDecoration(labelText: "Noise Level"),
                    items: List.generate(5, (i) => i + 1).map((val) {
                      return DropdownMenuItem(
                        child: Text("Noise Level: $val"),
                        value: val,
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => noiseLevel = val!),
                  ),
                  DropdownButtonFormField<String>(
                    value: wifiSpeed,
                    decoration: InputDecoration(labelText: "Wi-Fi Speed"),
                    items: ["Slow", "Medium", "Fast"].map((val) {
                      return DropdownMenuItem(child: Text(val), value: val);
                    }).toList(),
                    onChanged: (val) => setDialogState(() => wifiSpeed = val!),
                  ),
                  DropdownButtonFormField<String>(
                    value: seating,
                    decoration: InputDecoration(labelText: "Seating"),
                    items: ["Low", "Medium", "Available"].map((val) {
                      return DropdownMenuItem(child: Text(val), value: val);
                    }).toList(),
                    onChanged: (val) => setDialogState(() => seating = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  if (_selectedPoint != null) {
                    final newSpot = SilentSpot(
                      name: name,
                      type: type,
                      noiseLevel: noiseLevel,
                      wifiSpeed: wifiSpeed,
                      seating: seating,
                      location: _selectedPoint!,
                    );

                    setState(() {
                      _spots.add(newSpot);
                      _selectedPoint = null;
                      _saveSpots();
                    });

                    Navigator.pop(context);
                  }
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Silent Spaces")),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                center: _currentPosition,
                zoom: 14.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedPoint = point;
                  });
                  _showAddSpotDialog();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
  markers: [
    ..._spots.map((spot) => Marker(
      point: spot.location,
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () => _showSpotDetails(spot),
        child: Icon(Icons.place, size: 40, color: Colors.deepPurple),
      ),
    )),
    Marker(
      point: _currentPosition!,
      width: 60,
      height: 60,
      child: const Icon(Icons.my_location,
          color: Colors.blue, size: 40),
    )
  ],
),

              ],
            ),
      floatingActionButton: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    FloatingActionButton.extended(
      onPressed: () {
        if (_currentPosition != null) {
          _selectedPoint = _currentPosition;
          _showAddSpotDialog();
        }
      },
      label: Text("Add Current Location"),
      icon: Icon(Icons.my_location),
    ),
    const SizedBox(height: 10),
    FloatingActionButton.extended(
      onPressed: _showAllSpots,
      label: Text("View Spots"),
      icon: Icon(Icons.list),
    ),
  ],
),

    );
  }
}
