import 'package:contact/screen/screen_drone.dart';
import 'package:contact/screen/screen_robot.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  // List<Main> home;
  // MainScreen({this.home})
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('7DRONE'),
          backgroundColor: Colors.black54,
          leading: Container(),
        ),
        backgroundColor: Colors.black45,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: width * 0.4725,
                  height: height * 0.7,
                  child: ButtonTheme(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                    ),
                      child: MaterialButton(
                        child: Text(
                          'Robot',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.black45,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RobotScreen()
                            )
                          );
                        },
                      )
                  ),
                ),
                Padding(padding: EdgeInsets.all(width * 0.005)),
                Container(
                  width: width * 0.4725,
                  height: height * 0.7,
                  child: ButtonTheme(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)
                      ),
                      child: MaterialButton(
                        child: Text(
                          'Drone',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.black45,
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DroneScreen(),
                              )
                          );
                        },
                      )
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(width * 0.005),
            ),
            Container(
              width: width * 0.96,
              height: height * 0.15,
              child: ButtonTheme(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: MaterialButton(
                    child: Text(
                      'EMERGENCY',
                      style: TextStyle(color: Colors.white),
                    ),
                    color: Colors.black45,
                    onPressed: () {},
                  )
              ),
              )
          ]
        )
      ),
    );
  }
}