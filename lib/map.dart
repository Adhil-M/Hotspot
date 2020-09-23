import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class Map extends StatefulWidget {
  CameraPosition initpos;
  List<Marker> markers = [];
  List<Marker> marker = [];
  final Function addMarker;
  Map(this.initpos, this.markers, this.addMarker);

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  initState() {
    super.initState();
    widget.marker = widget.markers;
  }

  GoogleMapController mycontroller;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Hotspots"),
          centerTitle: true,
        ),
        body: Container(
            child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              child: GoogleMap(
                markers: widget.marker.toSet(),
                initialCameraPosition: widget.initpos,
                mapType: MapType.normal,
                onMapCreated: (controller) {
                  setState(() {
                    mycontroller = controller;
                  });
                },
                onTap: (coordinate) {
                  //widget.addMarker(coordinate);
                  setState(() {
                    widget.addMarker(coordinate);
                    int id = Random().nextInt(100);
                    widget.marker.add(Marker(
                      markerId: MarkerId(id.toString()),
                      position: coordinate,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueMagenta),
                    ));
                  });
                },
              ),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.black12,
            ),
            Positioned(
              bottom: 20,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.add),
              ),
            )
          ],
        )),
      ),
    );
  }
}
