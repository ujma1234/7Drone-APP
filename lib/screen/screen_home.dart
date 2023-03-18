import 'package:contact/screen/screen_main.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
              Center(
                child: Image.asset(
                  'assets/21853.jpg',
                  width: width*0.5,
                  height: height*0.5,
                ),
              ),
              Padding(padding: EdgeInsets.all(width*0.005)
              ),
              Container(
                padding: EdgeInsets.only(top: height * 0.086),
                child: Center(
                  child: ButtonTheme(
                    minWidth: width * 0.2,
                    height: height * 0.1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: MaterialButton(
                      child: Text(
                        '접속',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.grey,
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MainScreen(
                                ),
                            ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }
}