import 'dart:convert';
import 'package:http/http.dart' as http;

Command_APP2ROBOT(String command) async {
  Map data = {"command" : command};
  var body = json.encode(data);
  var url = Uri.parse('http://211.37.13.187/');
  var response = await http.post(
    url,
    headers: {"Content-Type" : "application/json"},
    body:body,
  );
  return response;
}