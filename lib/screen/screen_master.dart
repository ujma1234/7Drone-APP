import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:contact/model/command.dart';
import 'package:contact/model/map_catch.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MasterScreen extends StatefulWidget {
  @override
  _MasterScreenState createState() => _MasterScreenState();
}

bool carrier_go_ = false;
bool carrier_return_ = false;
bool carrier_stop_ = false;
bool intercepter_go_ = false;
bool intercepter_stop_ = false;
bool intercepter_return_ = false;

bool driving_1 = false;
bool driving_2 = false;
bool driving_3 = false;

List<String> robot_status = ["이동중", "정지", "복귀중"];
List<String> drone_status = ["대기", "도약준비", "순찰중", "복귀중", "착륙중", "충전준비", "충전중"];
List<int> order = [0, 1, 2];

List<LatLng> way_positions = [LatLng(37.297974, 126.836633), LatLng(37.297909, 126.836475), LatLng(37.297837, 126.836532), LatLng(37.297765, 126.836566), LatLng(37.297607, 126.836678), LatLng(37.297550, 126.836720), LatLng(37.297487, 126.836765), LatLng(37.297389, 126.836838), LatLng(37.297312, 126.836887), LatLng(37.297273, 126.836816), LatLng(37.297172, 126.836882), LatLng(37.297068, 126.836951), LatLng(37.296924, 126.836871), LatLng(37.296811, 126.836755)];
LatLng dest_position = LatLng(37.296680, 126.836814);
LatLng drone_position = LatLng(0, 0);
int cnt_way = 0;

double point_x = 39.81379942441619 * (370/33);
double point_y = 22.446168659620582 * (480/57);

String _url_robo = "https://planr.ngrok.app/realSense";
String _url_dron = "https://planr.ngrok.app/camera/realSense";

String _url_r = "ws://planr.ngrok.app";

// -------------
late WebSocketChannel channel;
late WebSocketChannel channel_drone;
late WebSocketChannel channel_position;
late StreamSubscription<dynamic> subscription;
late StreamSubscription<dynamic> subscription_drone;
late StreamSubscription<dynamic> subscription_position;
Uint8List? imgData;
bool getCamera = false;
bool getCamera_drone = false;
bool getPosition = false;

class _MasterScreenState extends State<MasterScreen> {
  List<Uint8List> imageData = [];
  List<Uint8List> imageData_drone = [];
  List<double> data_Position_x = [];
  List<double> data_Position_y = [];
  int currentIndex = 0;
  int currentIndex_drone = 0;
  int currentIndex_position = 0;

  void scrollToEnd3() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          currentIndex_position++;
        });
        scrollToEnd3();
      }
    });
  }

  void scrollToEnd2() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          currentIndex_drone++;
        });
        scrollToEnd2();
      }
    });
  }

  void scrollToEnd() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          currentIndex++;
        });
        scrollToEnd();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // ---
    channel = IOWebSocketChannel.connect(Uri.parse(_url_r));
    channel.sink.add("realSense");
    subscription = channel.stream.listen((dynamic data) {
      setState(() {
        getCamera = true;
        imageData.add(data);
      });
      if (currentIndex == imageData.length -1) {
        scrollToEnd();
      }
    });

    channel_drone = IOWebSocketChannel.connect(Uri.parse(_url_r));
    channel_drone.sink.add('drone');
    subscription_drone = channel_drone.stream.listen((dynamic data) {
      setState(() {
        getCamera_drone = true;
        imageData_drone.add(data);
      });
      if (currentIndex_drone == imageData_drone.length -1) {
        scrollToEnd2();
      }
    });

    channel_position = IOWebSocketChannel.connect(Uri.parse(_url_r));
    channel_position.sink.add('indoor_position');
    subscription_position = channel_position.stream.listen((dynamic data) {
      setState(() {
        getPosition = true;
        List<String> tmp = data.toString().split(',');
        print(tmp);
        point_x = double.parse(tmp[0]) * (370/33);
        point_y = double.parse(tmp[1]) * (480/57);
        // 39.81379942441619,22.446168659620582
        // data_Position_x.add(double.parse(tmp[0]));
        // data_Position_y.add(double.parse(tmp[1]));

      });
      if (currentIndex_position == data_Position_x.length -1) {
        scrollToEnd3();
      }
    });

    startTimer_info();
    startTimer_status();
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
  }


  @override
  void dispose() {
    subscription.cancel();
    channel.sink.close();
    subscription_drone.cancel();
    channel_drone.sink.close();
    subscription_position.cancel();
    channel_position.sink.close();
    stopTimer();
    super.dispose();
  }

  bool isDroneShoot = false;
  bool isShoot = false;
  bool _addmarkermode = false;
  bool _dronemarkermode = false;
  bool _waypointmode = false;
  int way_num = 0;

  bool isout = false;
  bool first = true;

  final controller = Completer<GoogleMapController>();
  late Set<Marker> markers = new Set();
  Uint8List? marketimages;
  Future<Uint8List> getImages(String path, int width) async{
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return(await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  BitmapDescriptor RobotIcon = BitmapDescriptor.defaultMarker;
  _init_robotMarker(LatLng position) async {
    if(isShoot) {
      position = await robot_postion();
    }
    if (first) {
      position = LatLng(37.2976261, 126.8373285);
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
  Future<LatLng>setting () async {
    if(isShoot && isout) {
      LatLng _initialCameraPosition = await init_position();
      // List<String> res = ["12", "12"];
      await _init_robotMarker(_initialCameraPosition);
      return _initialCameraPosition;
    }
    else {
      return LatLng(37.2976261, 126.8373285);
    }
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
    }
    if (_waypointmode) {
      final Uint8List markIcons = await getImages("assets/waypoint.png", 110);
      final marker = Marker(
        markerId: MarkerId("WAY"+way_num.toString()),
        position: way_positions[cnt_way],
        icon: BitmapDescriptor.fromBytes(markIcons),
      );
      setState(() {
        markers = markers.where((marker) => marker.markerId.value != "WAY"+way_num.toString()).toSet();
        markers.add(marker);
        cnt_way++;
      });
      print('Maker added ${position.latitude}, ${position.longitude}');
    }
    if (_dronemarkermode) {
      final Uint8List markIcons = await getImages("assets/drone_point.png", 110);
      final marker = Marker(
        markerId: MarkerId("DRONE"),
        position: position,
        icon: BitmapDescriptor.fromBytes(markIcons),
      );
      setState(() {
        markers = markers.where((marker) => marker.markerId.value != "DRONE").toSet();
        markers.add(marker);
      });
      print('Maker added ${position.latitude}, ${position.longitude}');
    }
  }
  String robot_battery = '0';
  String drone_battery = '0';
  String robot_state = '0';

  int robot_status_num = 0;
  int drone_status_num = 0;

  StreamController<bool> _timerController = StreamController<bool>();
  late StreamSubscription<bool> _timerSubscription;
  StreamController<bool> _timerController2 = StreamController<bool>();
  late StreamSubscription<bool> _timerSubscription2;

  void startTimer_info() {
    _timerSubscription = Stream.periodic(Duration(seconds: 20), (_) => true).listen((bool_) async {
      // _controller1.reload();
      // _controller2.reload();
      List<String> robot_info = await update_state();
      // print(robot_inf);
      setState(() {
        robot_battery = robot_info[0];
        drone_battery = robot_info[1];
        robot_state = robot_info[2];
      });
      _timerSubscription.resume();
    });
  }

  void startTimer_status() {
    _timerSubscription2 = Stream.periodic(Duration(seconds: 2), (_) => true).listen((bool_) async {
      List<String> robot_info = await update_status();
      String robot_inout = await update_inout();
      print(robot_info);
      setState(() {
        robot_status_num = int.parse(robot_info[0]);
        drone_status_num = int.parse(robot_info[1]);
           if(int.parse(robot_inout) == 0) {
             isout = false;
           } else {
             isout = true;
           }
      });
      _timerSubscription2.resume();
    });
  }

  void stopTimer() {
    _timerSubscription?.cancel();
    _timerController.close();
    _timerSubscription2?.cancel();
    _timerController2.close();
  }

  late final WebViewController _controller1;
  // late final WebViewController _controller2;

  @override
  Widget build(BuildContext context) {

    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;

    BoxDecoration carrier_go = BoxDecoration(
      image: DecorationImage(
        fit: BoxFit.cover,
        image: AssetImage('assets/img/carrier_go.png')
      )
    );
    BoxDecoration carrier_stop = BoxDecoration(
        image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/img/carrier_stop.png')
        )
    );
    BoxDecoration carrier_return = BoxDecoration(
        image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/img/carrier_return.png')
        )
    );
    BoxDecoration intercepter_go = BoxDecoration(
        image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/img/intercepter_go.png')
        )
    );
    BoxDecoration intercepter_return = BoxDecoration(
        image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/img/intercepter_return.png')
        )
    );
    BoxDecoration intercepter_stop = BoxDecoration(
        image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/img/intercepter_stop.png')
        )
    );
    BoxDecoration go_off = BoxDecoration(
        image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/img/go_off.png')
        )
    );
    BoxDecoration stop_off = BoxDecoration(
        image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/img/stop_off.png')
        )
    );
    BoxDecoration return_off = BoxDecoration(
        image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/img/return_off.png')
        )
    );
    Container off_cam = Container(
      decoration: BoxDecoration(
        color: Colors.grey
      ),
      child: Center(
        child: Text(
          'no camera',
          style: TextStyle(
            fontFamily: 'PRETENDARD-R',
            fontSize: height * 0.02,
            color: Colors.blueGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
    ListView drone_cam_view = ListView.builder(
      itemCount: currentIndex_drone + 1,
      itemBuilder: (context, index) {
        final frame_drone = imageData_drone[imageData_drone.length-1];
        return Image.memory(
          frame_drone,
          fit: BoxFit.fill,
          gaplessPlayback: true,
        );
      },
    );
    ListView robot_cam_view = ListView.builder(
      itemCount: currentIndex + 1,
      itemBuilder: (context, index) {
        final frame = imageData[imageData.length-1];
        return Image.memory(
          frame,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );
      },
    );

    Container position_ws = Container(
      width: (order[0] == 0)? 12: 6,
      height: (order[0] == 0)? 12: 6,
      margin: EdgeInsets.only(
        // top: (1133) - real_y,
          top : (order[0] == 0)?(370 - point_y):((370 - point_y)/2),
          left: (order[0] == 0)?point_x : (point_x/2),
        // left: real_x,
      ),
      decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(50)
      ),
      child: RippleAnimation(
          color: Colors.red,
          delay: const Duration(milliseconds: 200),
          repeat: true,
          minRadius: 20,
          ripplesCount: 2,
          duration: const Duration(milliseconds: 6 * 300),
          child: SizedBox()
      ),
    );

    // SizedBox position_ws = SizedBox(
    //   width: (order[0] == 0)? 12: 6,
    //     child: ListView.builder(
    //       itemCount: currentIndex_position + 1,
    //       itemBuilder: (context, index) {
    //         // var x = data_Position_x[data_Position_x.length-1];
    //         // var y = data_Position_y[data_Position_y.length-1];
    //         var x = 10.0;
    //         var y = 10.0;
    //         bool isPoint = true;
    //         bool isBig = (order[0] == 0);
    //         final real_x = (order[0] == 0)? (1133 * x * 20 / 941) : 556 * x * 20/ 941;
    //         final real_y = (order[0] == 0)? 20 * y : 20 * 398 * y / 845;
    //         // print("real_x ="+ real_x.toString());
    //         if (real_x < 0 || real_y < 0 || real_x > 1133-12 || real_y > 845-12) {
    //           isPoint = false;
    //         } else if ((!isBig && real_x > 556) || (!isBig && real_y > 845)) {
    //           isPoint = false;
    //         }
    //
    //         return (isPoint)?
    //         Container(
    //
    //           width: (order[0] == 0)? 12: 6,
    //           height: (order[0] == 0)? 12: 6,
    //           decoration: BoxDecoration(
    //               color: Colors.red,
    //               borderRadius: BorderRadius.circular(50)
    //           ),
    //           child: RippleAnimation(
    //               color: Colors.red,
    //               delay: const Duration(milliseconds: 200),
    //               repeat: true,
    //               minRadius: 20,
    //               ripplesCount: 2,
    //               duration: const Duration(milliseconds: 6 * 300),
    //               child: SizedBox()
    //           ),
    //         ): SizedBox();
    //       },
    //     )
    // );


    Stack jido = Stack(
      children: <Widget>[
        GestureDetector(
          child: SizedBox(
            child: Stack(
              children : [
                FutureBuilder<LatLng?> (
                  future: setting(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return GoogleMap(
                        mapType: MapType.normal,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        initialCameraPosition: CameraPosition(
                          target: snapshot.data ?? LatLng(0, 0),
                          zoom: 18,
                        ),
                        myLocationButtonEnabled: false,
                        onTap: _onMapTap,
                        markers: markers,
                      );
                    } else {
                      if(first) {
                        _init_robotMarker(LatLng(0, 0));
                      }
                      return GoogleMap(
                        mapType: MapType.normal,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(37.2976261, 126.8373285),
                          zoom: 18,
                        ),
                        myLocationButtonEnabled: false,
                        onTap: _onMapTap,
                        markers: markers,
                      );
                    }
                  },
                ),
                if(order[0] == 0)
                Positioned(
                  top: height * 0.01,
                  right: - width * 0.007,
                  child: SizedBox(
                    width: width * 0.07,
                    height: height * 0.07,
                    child: FloatingActionButton(
                      heroTag: "robot",
                      child:_addmarkermode ? Icon(Icons.done) : Icon(Icons.king_bed_outlined),
                      onPressed: () {
                        setState(() {
                          _addmarkermode = !_addmarkermode;
                          _dronemarkermode = false;
                          _waypointmode = false;
                        });
                      },
                    ),
                  )
                ),
                if(order[0] == 0)
                Positioned(
                  top: height * 0.095,
                  right: -width * 0.007,
                  child: SizedBox(
                    width: width * 0.07,
                    height: height * 0.07,
                    child: FloatingActionButton(
                      heroTag: "way_point",
                      child:_waypointmode ? Icon(Icons.done) : Icon(Icons.flag),
                      onPressed: () {
                        setState(() {
                          _waypointmode = !_waypointmode;
                          _addmarkermode = false;
                          _dronemarkermode = false;
                          if(!_waypointmode) {
                            way_num += 1;
                          }
                        });
                        print(way_num);
                      },
                    ),
                  )
                ),
                if(order[0] == 0)
                Positioned(
                  top: height * 0.18,
                  right: -width * 0.007,
                  child: SizedBox(
                    width: width * 0.07,
                    height: height * 0.07,
                    child: FloatingActionButton(
                      heroTag: "drone",
                      child:_dronemarkermode ? Icon(Icons.done) : Icon(Icons.flight),
                      onPressed: () {
                        setState(() {
                          _dronemarkermode = !_dronemarkermode;
                          _waypointmode = false;
                          _addmarkermode = false;
                        });
                      },
                    ),
                  )
                ),
              ]
            )
          )
        ),
        Container(
          margin: EdgeInsets.only(
            left: width * 0.011,
            top: height * 0.0143
          ),
          width: width * 0.0679,
          height: height * 0.0325,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.black
          ),
          child: MaterialButton(
            onPressed: () {
              setState(() {
                order = [0, 1, 2];
              });
            },
            child: Center(
              child: Text(
                '지도',
                style: TextStyle(
                  fontFamily: 'PRETENDARD-R',
                  fontSize: height * 0.014,
                  color: Color.fromRGBO(0, 255, 209, 1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ),
        ),
      ],
    );

    Stack jido_indoor = Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage('assets/carrier_indoor_map.jpg')
            )
          ),
        ),
        (getPosition)? position_ws : SizedBox(),
        Container(
          margin: EdgeInsets.only(
              left: width * 0.011,
              top: height * 0.0143
          ),
          width: width * 0.0679,
          height: height * 0.0325,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.black
          ),
          child: MaterialButton(
              onPressed: () {
                setState(() {
                  order = [0, 1, 2];
                });
              },
              child: Center(
                child: Text(
                  '지도',
                  style: TextStyle(
                    fontFamily: 'PRETENDARD-R',
                    fontSize: height * 0.014,
                    color: Color.fromRGBO(0, 255, 209, 1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
          ),
        ),
      ]
    );

    Stack robot_cam = Stack(
      children: <Widget>[
        getCamera? robot_cam_view : off_cam,
        Container(
            margin: EdgeInsets.only(
                left: width * 0.011,
                top: height * 0.0143
            ),
            width: width * 0.0679,
            height: height * 0.0325,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.black
            ),
            child: MaterialButton(
                onPressed: () {
                  setState(() {
                    order = [1, 0, 2];
                  });
                },
                child: Center(
                  child: Text(
                    '로봇 카메라',
                    style: TextStyle(
                      fontFamily: 'PRETENDARD-R',
                      fontSize: height * 0.014,
                      color: Color.fromRGBO(0, 255, 209, 1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
            ),
        ),
      ],
    );
    Stack drone_cam = Stack(
      children: <Widget>[
        (imageData_drone.length != 0)?drone_cam_view : off_cam,
        Container(
            margin: EdgeInsets.only(
                left: width * 0.011,
                top: height * 0.0143
            ),
            width: width * 0.0679,
            height: height * 0.0325,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.black
            ),
            child: MaterialButton(
                onPressed: () {
                  setState(() {
                    order = [2, 1, 0];
                  });
                },
                child: Center(
                  child: Text(
                    '드론 카메라',
                    style: TextStyle(
                      fontFamily: 'PRETENDARD-R',
                      fontSize: height * 0.014,
                      color: Color.fromRGBO(0, 255, 209, 1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
            ),
        ),
      ],
    );
    var jido_sel;
    if(first) {
      jido_sel = jido;
    } else if (!isout) {
      jido_sel = jido_indoor;
    } else {
      jido_sel = jido;
    }
    List<Stack> view_list = [jido_sel, robot_cam, drone_cam];



    int mode = 1;

    return SafeArea(
      child: Scaffold(
        body: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage('assets/bg.jpg')
            )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 왼쪽 레이아웃
              Container(
                width: width * 0.666,
                height: height * 0.757,
                margin: EdgeInsets.only(
                  top: height * 0.11,
                  // left: width * 0.019
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[

                    // 화면 레이아웃
                    SizedBox(
                      width: width * 0.666,
                      height: height * 0.507,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          // Main view Box
                          SizedBox(
                            width: width * 0.442,
                            height: height * 0.507,
                            child: view_list[order[0]],
                          ),
                          //second view Box
                          SizedBox(
                            height: height * 0.507,
                            width: width * 0.217,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                SizedBox(
                                  width: width * 0.217,
                                  height: height * 0.248,
                                  child: view_list[order[1]],
                                ),
                                SizedBox(
                                  width: width * 0.217,
                                  height: height * 0.248,
                                  child: view_list[order[2]],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    // 버튼 레이아웃
                    SizedBox(
                      width: width * 0.666,
                      height: height * 0.152,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          // ㅋㅐ리어 버튼
                          SizedBox(
                            width: width * 0.301,
                            height: height * 0.152,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(top: height * 0.015),
                                  width: width * 0.051,
                                  height: height * 0.031,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        width: width * 0.013,
                                        height: height * 0.021,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage('assets/img/battery.png'),
                                            fit: BoxFit.contain
                                          )
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                          left: width * 0.0015
                                        ),
                                        child: Text(
                                          robot_battery +'%',
                                          style: TextStyle(
                                            fontFamily: 'PRETENDARD-R',
                                            fontSize: height * 0.014,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: width * 0.1356,
                                  height: height * 0.04,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Container(
                                        width: width * 0.078,
                                        height: height * 0.04,
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage('assets/img/carrier_box.png'),
                                                fit: BoxFit.cover
                                            )
                                        ),
                                      ),
                                      Container(
                                        width: width * 0.0468,
                                        height: height * 0.0287,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(30)
                                        ),
                                        child: Center(
                                          child: Text(
                                            robot_status[robot_status_num],
                                            style: TextStyle(
                                              fontFamily: 'PRETENDARD-R',
                                              fontSize: height * 0.014,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),

                                // 로봇 버튼 레이아웃
                                SizedBox(
                                  width: width * 0.666,
                                  height: height * 0.05,

                                  // 로봇 출발 버튼
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      Container(
                                        width: width * 0.085,
                                        height: height * 0.05,
                                        decoration: carrier_go_? carrier_go : go_off,
                                        child: MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              if(isout) {
                                                Timer.periodic(Duration(milliseconds: 1500), (timer) {
                                                  if(!isShoot) timer.cancel();
                                                  else {
                                                    setState(() {
                                                      isShoot = true;
                                                    });
                                                  }
                                                });
                                              }
                                              carrier_go_ = true;
                                              carrier_stop_ = false;
                                              carrier_return_ = false;
                                              isShoot = true;
                                              first = false;
                                              Command_GO_APP2ROBOT(markers);
                                            });
                                          },
                                        ),
                                      ),
                                      Container(
                                        width: width * 0.085,
                                        height: height * 0.05,
                                        decoration: carrier_stop_? carrier_stop : stop_off,
                                        child: MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              carrier_stop_ = true;
                                              carrier_go_ = false;
                                              carrier_return_ = false;
                                              isShoot = false;
                                            });
                                            Command_APP2ROBOT("robot_stop");
                                          },
                                        ),
                                      ),
                                      Container(
                                        width: width * 0.085,
                                        height: height * 0.05,
                                        decoration: carrier_return_? carrier_return : return_off,
                                        child: MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              carrier_return_ = true;
                                              carrier_stop_ = false;
                                              carrier_go_ = false;
                                            });
                                            Command_APP2ROBOT("robot_return");
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),

                          // 드론 버튼
                          SizedBox(
                            width: width * 0.301,
                            height: height * 0.152,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(top: height * 0.015),
                                  width: width * 0.051,
                                  height: height * 0.031,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        width: width * 0.013,
                                        height: height * 0.021,
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage('assets/img/battery.png'),
                                                fit: BoxFit.contain
                                            )
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            left: width * 0.0015
                                        ),
                                        child: Text(
                                          drone_battery+'%',
                                          style: TextStyle(
                                            fontFamily: 'PRETENDARD-R',
                                            fontSize: height * 0.014,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: width * 0.1356,
                                  height: height * 0.04,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Container(
                                        width: width * 0.078,
                                        height: height * 0.04,
                                        decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage('assets/img/intercepter_box.png'),
                                                fit: BoxFit.cover
                                            )
                                        ),
                                      ),
                                      Container(
                                        width: width * 0.0468,
                                        height: height * 0.0287,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(30)
                                        ),
                                        child: Center(
                                          child: Text(
                                            drone_status[drone_status_num],
                                            style: TextStyle(
                                              fontFamily: 'PRETENDARD-R',
                                              fontSize: height * 0.014,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),

                                // 드론 버튼 레이아웃
                                SizedBox(
                                  width: width * 0.666,
                                  height: height * 0.05,

                                  // 드론 출발 버튼
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: <Widget>[
                                      Container(
                                        width: width * 0.085,
                                        height: height * 0.05,
                                        decoration: intercepter_go_? intercepter_go : go_off,
                                        child: MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              intercepter_go_ = true;
                                              intercepter_stop_ = false;
                                              intercepter_return_ = false;
                                            });

                                            // 모드 처리 해야됨
                                            Command_GO_APP2DRONE(markers, mode);
                                          },
                                        ),
                                      ),
                                      Container(
                                        width: width * 0.085,
                                        height: height * 0.05,
                                        decoration: intercepter_stop_? intercepter_stop : stop_off,
                                        child: MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              intercepter_stop_ = true;
                                              intercepter_go_ = false;
                                              intercepter_return_ = false;
                                            });
                                            Command_APP2ROBOT("drone_stop");
                                          },
                                        ),
                                      ),
                                      Container(
                                        width: width * 0.085,
                                        height: height * 0.05,
                                        decoration: intercepter_return_? intercepter_return : return_off,
                                        child: MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              intercepter_return_ = true;
                                              intercepter_stop_ = false;
                                              intercepter_go_ = false;
                                            });
                                            Command_APP2ROBOT("drone_return");
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),

                    ),
                  ],
                ),
              ),
              // 오른쪽 레이아웃
              Container(
                width: width * 0.267,
                height: height * 0.748,
                margin: EdgeInsets.only(
                  top: height * 0.11,
                  // left: width * 0.009921875
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: width * 0.267,
                      height: height * 0.521,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[

                          // 캐리어 표시
                          Container(
                            width: width * 0.152,
                            height: height * 0.043,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/img/carrier_moving.png'),
                                fit: BoxFit.cover
                              )
                            ),
                          ),

                          // 캐리어 이동 위젯
                          SizedBox(
                            width: width * 0.267,
                            height: height * 0.096,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Container(
                                  width: width * 0.267,
                                  height: height * 0.07,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage('assets/img/road.png'),
                                      fit: BoxFit.cover
                                    )
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(padding: EdgeInsets.only(left: (width * 0.267) * (0.05 + (int.parse(robot_state) * 0.0085) ))),
                                      Container(
                                        width: height * 0.0175,
                                        height: height * 0.0175,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage('assets/img/point.png'),
                                            fit: BoxFit.cover
                                          )
                                        ),
                                      )
                                    ],
                                  )
                                ),
                                Container(
                                  width: width * 0.055,
                                  height: height * 0.016,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage('assets/img/road_name.png'),
                                      fit: BoxFit.cover
                                    )
                                  ),
                                )
                              ],
                            ),
                          ),

                          // 드라이빙 모드 표시
                          Container(
                            width: width * 0.152,
                            height: height * 0.043,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/img/driving_mode.png'),
                                fit: BoxFit.cover
                              )
                            ),
                          ),

                          // 드라이빙 버튼 레이아웃
                          SizedBox(
                            width: width * 0.267,
                            height: height * 0.251,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                // 버튼 1
                                SizedBox(
                                  width: width * 0.267,
                                  height: height * 0.048,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      SizedBox(
                                        width: width * 0.026,
                                        height: height * 0.023,
                                        child: Center(
                                          child: Text(
                                            '모드1',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard-R',
                                              fontSize: height * 0.015,
                                              fontWeight: FontWeight.w500,
                                              color: driving_1? Color.fromRGBO(255, 255, 255, 1) : Color.fromRGBO(255, 255, 255, 0.3)
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: width * 0.225,
                                        height: height * 0.048,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage('assets/img/driving_btn.png'),
                                            fit: BoxFit.cover,
                                            opacity: driving_1? 1: 0.3
                                          )
                                        ),
                                        child: MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              driving_1 = true;
                                              driving_2 = false;
                                              driving_3 = false;
                                              mode = 1;
                                            });
                                          },
                                          child: Center(
                                            child: Text(
                                              'PATROL MODE 1',
                                              style: TextStyle(
                                                fontFamily: 'Pretendard-R',
                                                fontSize: height * 0.015,
                                                fontWeight: FontWeight.w500,
                                                color: driving_1? Color.fromRGBO(255, 255, 255, 1) : Color.fromRGBO(255, 255, 255, 0.3)
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),

                                // 버튼 2
                                SizedBox(
                                  width: width * 0.267,
                                  height: height * 0.048,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      SizedBox(
                                        width: width * 0.026,
                                        height: height * 0.023,
                                        child: Center(
                                          child: Text(
                                            '모드2',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard-R',
                                              fontSize: height * 0.015,
                                              fontWeight: FontWeight.w500,
                                              color: driving_2? Color.fromRGBO(255, 255, 255, 1) : Color.fromRGBO(255, 255, 255, 0.3)
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: width * 0.225,
                                        height: height * 0.048,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage('assets/img/driving_btn.png'),
                                            fit: BoxFit.cover,
                                            opacity: driving_2? 1: 0.3
                                          )
                                        ),
                                        child: MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              driving_2 = true;
                                              driving_1 = false;
                                              driving_3 = false;
                                              mode = 2;
                                            });
                                          },
                                          child: Center(
                                            child: Text(
                                              'PATROL MODE 2',
                                              style: TextStyle(
                                                fontFamily: 'Pretendard-R',
                                                fontSize: height * 0.015,
                                                fontWeight: FontWeight.w500,
                                                color: driving_2? Color.fromRGBO(255, 255, 255, 1) : Color.fromRGBO(255, 255, 255, 0.3)
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),

                                // 버튼 3
                                SizedBox(
                                  width: width * 0.267,
                                  height: height * 0.048,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      SizedBox(
                                        width: width * 0.026,
                                        height: height * 0.023,
                                        child: Center(
                                          child: Text(
                                            '모드3',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard-R',
                                              fontSize: height * 0.015,
                                              fontWeight: FontWeight.w500,
                                              color: driving_3? Color.fromRGBO(255, 255, 255, 1) : Color.fromRGBO(255, 255, 255, 0.3)
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: width * 0.225,
                                        height: height * 0.048,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage('assets/img/driving_btn.png'),
                                            fit: BoxFit.cover,
                                            opacity: driving_3? 1: 0.3
                                          )
                                        ),
                                        child: MaterialButton(
                                          onPressed: () {
                                            setState(() {
                                              driving_3 = true;
                                              driving_2 = false;
                                              driving_1 = false;
                                              mode = 3;
                                            });
                                          },
                                          child: Center(
                                            child: Text(
                                              'PATROL MODE 3',
                                              style: TextStyle(
                                                fontFamily: 'Pretendard-R',
                                                fontSize: height * 0.015,
                                                fontWeight: FontWeight.w500,
                                                color: driving_3? Color.fromRGBO(255, 255, 255, 1) : Color.fromRGBO(255, 255, 255, 0.3)
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    // emergency 버튼
                    Container(
                      width: width * 0.124,
                      height: height * 0.097,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/img/emergency.png'),
                            fit: BoxFit.cover
                        )
                      ),
                      child: MaterialButton(
                        onPressed: () {
                          Command_APP2ROBOT("emergency");
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        )
      ),
    );
  }
}