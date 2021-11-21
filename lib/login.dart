import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:notes_app/landing_page.dart';

import 'util/constants.dart' as Constants;

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _State();
}

class _State extends State<LoginPage> {
  bool isUserNameBlank = false, isPassWordBlank = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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

  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Center(child: Text('Login')),
        ),
        body: Padding(
            padding: EdgeInsets.all(10),
            child: ListView(children: <Widget>[
              Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(10),
                  child: Text(
                    Constants.appName,
                    style: TextStyle(
                        color: Constants.bgMainColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 30),
                  )),
              Container(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email ID',
                    errorText: isUserNameBlank ? 'Please enter username' : null,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: TextField(
                  obscureText: true,
                  controller: passwordController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    errorText: isPassWordBlank ? 'Please enter password' : null,
                  ),
                ),
              ),
              Container(
                  margin: const EdgeInsets.only(top: 10.0),
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                    side: BorderSide(
                                        color: Constants.bgMainColor)))),
                    child: Text('LOGIN',
                        style: TextStyle(
                            color: Constants.bgWhiteColor,
                            fontWeight: FontWeight.bold)),
                    onPressed: () {
                      validateFormBlankFields(
                          nameController.text + " " + passwordController.text);

                      if (!isUserNameBlank && !isPassWordBlank) {
                        if (!isDummyLoginEntered()) {
                          var snackBar =
                              SnackBar(content: Text('User does not exist.'));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        } else {
                          //from valid,redirect to landing page using routing
                          navigateToLandingPage(context);
                        }
                      }
                    },
                  )),
              Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Column(
                    children: <Widget>[
                      SignInButton(
                        Buttons.Google,
                        onPressed: () {
                         /* signInWithGoogle()
                              .then((value) => print("google sign in email id:"
                                  " ${value.user.email} URL : ${value.user.photoUrl}"));*/
                        },
                      ),
                      SignInButton(
                        Buttons.Facebook,
                        onPressed: () {},
                      ),
                    ],
                  )),
/*              Container(
                  child: TextButton(
                    child: Text(
                      'New User?,Register',
                      style: TextStyle(
                          color: Constants.bgMainColor,
                          fontWeight: FontWeight.w500),
                    ),
                    onPressed: () {
                      //signup screen
                    },
                  )),*/
            ])));
  }

  bool validateFormBlankFields(String validationText) {
    String userName = validationText.split(" ")[0];
    String passWord = validationText.split(" ")[1];

    if (userName.isEmpty) {
      setState(() {
        isUserNameBlank = true;
      });
      return false;
    }
    if (passWord.isEmpty) {
      setState(() {
        isPassWordBlank = true;
      });
      return false;
    }

    setState(() {
      isUserNameBlank = false;
      isPassWordBlank = false;
    });
    return true;
  }

  bool isDummyLoginEntered() {
    String userName = nameController.text;
    String passWord = passwordController.text;

    if (userName == "test" && passWord == "test") {
      return true;
    }
    return false;
  }

  Future navigateToLandingPage(context) async {
    Route route = MaterialPageRoute(builder: (context) => LandingPage());
    Navigator.pushReplacement(context, route);
  }

 /* Future<AuthResult> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    // Create a new credential
    final credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }*/
}
