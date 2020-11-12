import 'package:flutter/material.dart';
import 'package:search_map_place/search_map_place.dart';

class LocationPicker extends StatefulWidget {
  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0a0a0a),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              SearchMapPlaceWidget(
                apiKey: "AIzaSyBwPACLNRvfWCz5yUvOFJD3mMroUX1p80A",
                placeholder: "Search for places",
                darkMode: true,
                onSelected: (Place place) {
                  Navigator.pop(context, place.description);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
