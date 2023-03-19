import 'package:contact/model/command.dart';
import 'package:contact/screen/screen_main.dart';
import 'package:flutter/material.dart';

class DroneScreen extends StatefulWidget{
  @override
  _DroneScreenState createState() =>  _DroneScreenState();
}
class _DroneScreenState extends State<DroneScreen> {
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title:  Text('7DRONE'),
          backgroundColor: Colors.black54,
          automaticallyImplyLeading: true,
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios), onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MainScreen()
              ),
            );
          }),
        ),
        backgroundColor: Colors.black45,
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top : height * 0.05),
              width: width * 0.6,
              height: height * 0.8,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(width * 0.005)),
            Container(
              margin: EdgeInsets.only(top : height * 0.08),
              width: width * 0.35,
              height: height * 0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(width * 0.005),
                    margin: EdgeInsets.all(width * 0.01),
                    width: width * 0.35,
                    height: height * 0.25,
                    child: ButtonTheme(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)
                        ),
                        child: MaterialButton(
                          child: Text(
                            'Drone Shoot!',
                            style: TextStyle(color: Colors.white),
                          ),
                          color: Colors.black45,
                          onPressed: () async {
                            // Drone Shoot API CALL
                            var response = await Command_APP2ROBOT("drone_shoot");
                          },
                        )
                    ),
                  ),
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
                            'Emergency Back',
                            style: TextStyle(color: Colors.white),
                          ),
                          color: Colors.black45,
                          onPressed: () async {
                            // Emergency Back API CALL
                            var response = await Command_APP2ROBOT("drone_back");
                          },
                        )
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      )
    );
  }
}