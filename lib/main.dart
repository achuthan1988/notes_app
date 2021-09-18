import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stetho/flutter_stetho.dart';
import 'package:notes_app/landing_page.dart';
import 'package:notes_app/login.dart';
import 'package:notes_app/new_note_page.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'util/constants.dart' as Constants;

void main() {
  Stetho.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  MaterialColor bgColorMaterial = MaterialColor(0xFFFF5A5F, {
    50: Color.fromRGBO(250, 90, 95, .1),
    100: Color.fromRGBO(250, 90, 95, .2),
    200: Color.fromRGBO(250, 90, 95, .3),
    300: Color.fromRGBO(250, 90, 95, .4),
    400: Color.fromRGBO(250, 90, 95, .5),
    500: Color.fromRGBO(250, 90, 95, .6),
    600: Color.fromRGBO(250, 90, 95, .7),
    700: Color.fromRGBO(250, 90, 95, .8),
    800: Color.fromRGBO(250, 90, 95, .9),
    900: Color.fromRGBO(250, 90, 95, 1),
  });



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: bgColorMaterial,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double opacity = 0.0;
  bool isTitleShown = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIOverlays([]);
    print("inside initState()");
    Future.delayed(Duration(milliseconds: 150), () {
      opacity = 1;
      print("inside delayed()");
      //invoke progress dialog
      // redirect after an interval to Login Page
    });

  }

  @override
  Widget build(BuildContext context) {
    print("inside build()");
    return Scaffold(
      backgroundColor: Constants.bgMainColor,
      body: SafeArea(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedOpacity(
                opacity: opacity,
                duration: Duration(milliseconds: 2000),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    Constants.appName,
                    style: TextStyle(
                        fontSize: 36.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal),
                  ),
                ),
                onEnd: () {
                  setState(() {
                    isTitleShown = true;

                    Future.delayed(Duration(milliseconds: 3000), () {
                      navigateToLoginPage(context);
                    });
                  });
                },
              ),
              Visibility(
                child: ProgressDialogWidget(),
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                visible: isTitleShown,
              )
            ],
          ),
        ),
      ),
    );
  }

  Future navigateToLoginPage(context) async {
    Route route = MaterialPageRoute(builder: (context) => LoginPage());
    Navigator.pushReplacement(context, route);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}

class ProgressDialogWidget extends StatefulWidget {
  @override
  _ProgressDialogWidgetState createState() => _ProgressDialogWidgetState();
}

class _ProgressDialogWidgetState extends State<ProgressDialogWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
          child: Container(
        width: 100.0,
        height: 100.0,
        decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      )),
    );
  }
}
