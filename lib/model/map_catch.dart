import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:contact/model/command.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
init_position() async {
  // var response = await Command_APP2ROBOT("GetPosition");
  Map response = {"command":"37.300122,126.83781979"};
  var res = await json.encode(response);
  var position = await jsonDecode(res);
  List<String> txt = await position["command"].toString().split(',');
  return txt;
}
var rng = Random();
double k = rng.nextDouble();
robot_postion() {
  // var response = await Command_APP2ROBOT("GetPosition");
  Map response = {"command":"37.300122,${127.83782+k}"};
  var res = json.encode(response);
  var position = jsonDecode(res);
  List<String> txt = position["command"].toString().split(',');
  var latitude = double.parse(txt[0]);
  var longitude = double.parse(txt[1]);
  k += 1;
  return LatLng(latitude, longitude);
}