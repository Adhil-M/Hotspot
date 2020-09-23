import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import './Home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  MyApp({this.app});
  final FirebaseApp app;
  List<Marker> markers;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final firebase = FirebaseDatabase.instance;
  @override
  initState() {
    // TODO: implement initState
    super.initState();
    final ref = firebase.reference();
    List<Marker> initiate() {
      List<Marker> mark = [];
      ref.child("Markers").once().then((DataSnapshot snap) {
        if (snap != null) {
          var keys = snap.value.keys;
          var data = snap.value;
          for (var k in keys) {
            mark.add(Marker(
              markerId: MarkerId(k),
              position: LatLng(data[k]["lat"], data[k]["long"]),
            ));
          }
        }
      });
      return mark;
    }

    widget.markers = initiate();
    print(widget.markers.length);
  }

  @override
  Widget build(BuildContext context) {
    final ref = firebase.reference();
    push(int id, double lat, double long, bool bol) {
      ref.child("Markers").update({
        "$id": {"lat": lat, "long": long, "bool": bol}
      }).asStream();
      print("PUSHEEEEEEEe");
    }

    clear() {
      ref.child("Markers").set({});
    }

    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: Home(push, clear, widget.markers),
      ),
    );
  }
}
