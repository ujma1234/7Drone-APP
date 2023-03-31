import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:contact/model/command.dart';
import 'package:contact/model/map_catch.dart';
import 'package:contact/screen/screen_drone.dart';
import 'package:contact/screen/screen_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animarker/helpers/extensions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animarker/flutter_map_marker_animation.dart';

class RobotScreen extends StatefulWidget{
  @override
  _RobotScreenState createState() => _RobotScreenState();
}

class _RobotScreenState extends State<RobotScreen> {
  double boxsize_w = 0;
  double boxsize_h = 0;
  bool isExpanded = false;
  bool _addmarkermode = false;
  bool isShoot = false;
  bool DoStop = false;
  final controller = Completer<GoogleMapController>();
  late Set<Marker> markers = new Set();

  Uint8List? marketimages;
  Future<Uint8List> getImages(String path, int width) async{
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return(await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  // late GoogleMapController _mapController;
  BitmapDescriptor RobotIcon = BitmapDescriptor.defaultMarker;
  _init_robotMarker(LatLng position) async {
    if(isShoot) {
        position = await robot_postion();
    }
    final Uint8List markIcons = await getImages("assets/robot.png", 110);
    final marker = Marker(
      markerId: MarkerId("ROBOT"),
      position: position,
      icon: BitmapDescriptor.fromBytes(markIcons),
    );
    markers = markers.where((marker) => marker.markerId.value != "ROBOT").toSet();
    markers.add(marker);
  }

  // void marker_transform(LatLng position) async {
  //   final Uint8List markIcons = await getImages("assets/robot.png", 110);
  //   final marker = RippleMarker(
  //     markerId: MarkerId("ROBOT"),
  //     position: position,
  //     icon: BitmapDescriptor.fromBytes(markIcons),
  //   );
  //   markers = markers.where((marker) => marker.markerId.value != "ROBOT").toSet();
  //   markers.add(marker);
  // }

  Future<LatLng>setting () async {
    List<String> res = await init_position();
    final _initialCameraPosition = LatLng(
        double.parse(res[0]),
        double.parse(res[1])
    );
    await _init_robotMarker(_initialCameraPosition);
    return _initialCameraPosition;
  }
  
  void _onMapTap(LatLng position) async {
    if (_addmarkermode) {
      final Uint8List markIcons = await getImages("assets/dest.png", 110);
      final marker = Marker(
        markerId: MarkerId("DEST"),
        position: position,
        icon: BitmapDescriptor.fromBytes(markIcons),
      );
      setState(() {
        markers = markers.where((marker) => marker.markerId.value != "DEST").toSet();
        markers.add(marker);
      });
      print('Maker added ${position.latitude}, ${position.longitude}');
    } else {
      setState(() {
        isExpanded = true;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;
    boxsize_w = width * 0.6;
    boxsize_h = height * 0.8;
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text('7DRONE'),
            backgroundColor: Colors.black54,
            // automaticallyImplyLeading: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios), onPressed: () {
                Navigator.push(
                  context,
                    MaterialPageRoute(
                        builder: (context) => MainScreen(),
                    ),
                );
              }),
          ),

          backgroundColor: Colors.black45,
          body: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget> [
              GestureDetector(
                  child: Container(
                      margin: EdgeInsets.only(top : height * 0.05),
                      width: isExpanded ? width : boxsize_w,
                      height: isExpanded ? height : boxsize_h,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                        ),
                      ),
                      child: Stack(
                          children : [
                            FutureBuilder<LatLng?> (
                              future: setting(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                    return GoogleMap(
                                      mapType: MapType.normal,
                                      initialCameraPosition: CameraPosition(
                                        target: snapshot.data ?? LatLng(0, 0),
                                        zoom: 18,
                                      ),
                                      myLocationButtonEnabled: false,
                                      onTap: _onMapTap,
                                      markers: markers,
                                    );
                                } else {
                                  return CircularProgressIndicator();
                                }
                              },
                            ),
                            if (isExpanded)
                              Positioned(
                                top: 16.0,
                                right: 16.0,
                                child: FloatingActionButton(
                                  child: Icon(Icons.menu_open),
                                  onPressed: () {
                                    setState(() {
                                      if(!_addmarkermode)
                                      isExpanded = false;
                                    });
                                  },
                                ),
                              ),
                            if (isExpanded)
                              Positioned(
                                top: 96,
                                right: 16,
                                child: FloatingActionButton(
                                  child:_addmarkermode ? Icon(Icons.done) : Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      _addmarkermode = !_addmarkermode;
                                    });
                                  },
                                ),
                              ),
                          ]
                      )
                  )
              ),
              if(!isExpanded)
                Padding(padding: EdgeInsets.all(width * 0.005)),
              if(!isExpanded)
                Container(
                  margin: EdgeInsets.only(top : height * 0.08),
                  width: width * 0.35,
                  height: height * 0.8,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[

                    //btn Container
                        Container(
                          padding: EdgeInsets.all(width * 0.005),
                          margin: EdgeInsets.all(width * 0.01),
                          width: width * 0.35,
                          height: height * 0.3,

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[

                              //STOP btn
                              Container(
                                width: width * 0.14,
                                height: height * 0.2,
                                child: ButtonTheme(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: MaterialButton(
                                      child: Text(
                                        'STOP',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      color: Colors.black45,
                                      onPressed: () async {
                                        // STOP API CALL
                                        // var response = await Command_APP2ROBOT("emergency");
                                        setState(() {
                                          isShoot = false;
                                        });
                                      },
                                    ),
                                ),
                              ),

                              //Comeback btn
                              Container(
                                width: width * 0.14,
                                height: height * 0.2,
                                child: ButtonTheme(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: MaterialButton(
                                      child: Text(
                                        'Come Back',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      color: Colors.black45,
                                      onPressed: () async {
                                        //ComeBack API CALL
                                        var response = await Command_APP2ROBOT("robot_back");
                                      },
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ),

                    //Shoot btn
                    Container(
                      padding: EdgeInsets.all(width * 0.005),
                      margin: EdgeInsets.all(width * 0.01),
                      width:  width * 0.35,
                      height:  height * 0.25,
                      child: ButtonTheme(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)
                          ),
                          child: MaterialButton(
                            child: Text(
                              'Robot SHOOT !',
                              style: TextStyle(color: Colors.white),
                            ),
                            color: Colors.black45,
                            onPressed: () {
                              //Robot Shoot API CALL !
                                isShoot = true;
                                Timer.periodic(Duration(milliseconds: 1500), (timer) {
                                  if(isShoot == false) {
                                    timer.cancel();
                                  }
                                  else {
                                    setState(() {
                                      isShoot = true;
                                    });
                                  }
                                });
                              // var response = await Command_APP2ROBOT("robot_shoot");
                            },
                          )
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ),
    );
  }
}