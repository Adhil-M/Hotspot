import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocation/geolocation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import './map.dart';
import 'dart:math';
import 'dart:async';

class Home extends StatefulWidget {
  final Function pusher;
  final Function clear;
  final List<Marker> marker;
  Home(this.pusher, this.clear, this.marker);
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final firebase = FirebaseDatabase.instance;
  FlutterLocalNotificationsPlugin notification;
  int j;
  List<Marker> markers = [];
  List<bool> markerdata = [];
  LocationResult currentLocation;
  StreamSubscription<LocationResult> streamSubscription;
  CameraPosition initpos;
  bool isFeeding = false;

  initState() {
    super.initState();
    markers = widget.marker;
    j = markers.length;
    notification = new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var ios = new IOSInitializationSettings();
    var initsett = new InitializationSettings(android, ios);
    notification.initialize(initsett,
        onSelectNotification: onselectnotification);

    check();
    locate();
    isFeeding = false;
    currentLocation = null;
    print("ss");
  }

  Future onselectnotification(String payload) {
    debugPrint("payload:$payload");
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Hotspot'),
              content: Text("You have entered a hotspot region"),
            ));
  }

  check() async {
    final GeolocationResult result = await Geolocation.isLocationOperational();
    if (result.isSuccessful) {
      print("success");
    } else {
      print("not granted");
    }
  }

  showNotification(String txt) async {
    var android = new AndroidNotificationDetails(
        'channel id', 'channel NAME', 'channel disc');
    var ios = new IOSNotificationDetails();
    var platform = new NotificationDetails(android, ios);
    await notification.show(0, "Hotspot", txt, platform);
  }

  locate() {
    if (isFeeding) {
      setState(() => isFeeding = false);
      streamSubscription.cancel();
      streamSubscription = null;
      currentLocation = null;
    } else {
      setState(() => isFeeding = true);

      streamSubscription = Geolocation.locationUpdates(
        accuracy: LocationAccuracy.best,
        displacementFilter: 0.0,
        inBackground: false,
      ).listen((result) {
        setState(() {
          currentLocation = result;
          print(result.location.latitude);
        });

        if (markers.length > 0) {
          print("checked");
          calculate();
        } else {
          print("not checked");
        }
      });

      streamSubscription.onDone(() => setState(() {
            isFeeding = false;
          }));
    }
  }

  calculate() {
    double dist;
    double lat1 = currentLocation.location.latitude * (180 / pi);
    double long1 = currentLocation.location.longitude * (180 / pi);
    for (int i = 0; i < markerdata.length; i++) {
      double lat2 = markers[i + 1].position.latitude * (180 / pi);
      double long2 = markers[i + 1].position.longitude * (180 / pi);
      dist = 6.3788 *
          acos((sin(lat1) * sin(lat2)) +
              (cos(lat1) * cos(lat2) * cos(long2 - long1)));
      print("dist : $dist");
      print(markers.length);
      if (dist <= 5.0) {
        if (markerdata[i] == false) {
          setState(() {
            markerdata[i] = true;
          });
          showNotification("You have entered a hotspot region");
          break;
        }
      } else {
        if (markerdata[i] == true) {
          showNotification("You have left the hotspot region");
          setState(() {
            markerdata[i] = false;
          });
        }
      }
    }
  }

  clearMarkers() {
    widget.clear();
    setState(() {
      markers = [];
      j = 0;
      markerdata = [];
    });
  }

  addMarker(LatLng cordinate) {
    setState(() {
      int id = Random().nextInt(100);
      widget.pusher(id, cordinate.latitude, cordinate.longitude, false);
      markerdata.add(false);
      markers.add(Marker(
        markerId: MarkerId(id.toString()),
        position: cordinate,
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
      ));
    });
    print("Added");
  }

  @override
  Widget build(BuildContext context) {
    final ref = firebase.reference();
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Column(
        children: <Widget>[
          Stack(
            alignment: AlignmentDirectional.topEnd,
            fit: StackFit.passthrough,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: Container(
                    height: 250,
                    width: 200,
                    alignment: Alignment.topRight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.blue, Colors.red], stops: [0.02, 1]),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(4000),
                      ),
                    )),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  height: 250,
                  width: 380,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue, Colors.red]),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(2000),
                    ),
                  ),
                ),
              ),
              Positioned(
                  top: 90,
                  right: 120,
                  child: Text(
                    "Hotspot",
                    style: TextStyle(
                        fontSize: 50,
                        color: Colors.white,
                        fontWeight: FontWeight.w200),
                  ))
            ],
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 50,
            margin: EdgeInsets.only(top: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: FlatButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Map(
                            CameraPosition(
                                target: LatLng(
                                    currentLocation.location.latitude,
                                    currentLocation.location.longitude)),
                            markers,
                            addMarker)));
              },
              child: Text(
                "Add Hotspot",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ),
          markers.length != 0
              ? Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 50,
                  margin: EdgeInsets.only(top: 80),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: FlatButton(
                    onPressed: () {
                      clearMarkers();
                    },
                    child: Text(
                      "Clear Hotspots",
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                )
              : Text(""),
        ],
      ),
    );
  }
}
