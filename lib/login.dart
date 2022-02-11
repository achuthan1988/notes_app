import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:notes_app/landing_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: null,
        body: Padding(
            padding: EdgeInsets.all(10),
            child: ListView(
                padding: EdgeInsets.all(0),
                children: <Widget>[
              Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(5),
                  child: Text(
                    Constants.appName,
                    style: TextStyle(
                        color: Constants.bgMainColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 30),
                  )),
              Container(
                alignment: Alignment.topLeft,
                padding: EdgeInsets.all(5),
                child: Text("Email Address",
                    style: TextStyle(
                        color: Constants.darkGreyColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              Container(
                padding: EdgeInsets.all(5),
                alignment: Alignment.center,
                child: TextField(
                  controller: nameController,
                ),
              ),
              Container(
                padding: EdgeInsets.all(5),
                child: TextField(
                  controller: passwordController,
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
                    onPressed: () async {
                      validateFormBlankFields(
                          nameController.text + " " + passwordController.text);

                      if (!isUserNameBlank && !isPassWordBlank) {
                        isLoginCredsValid().then((value) {
                          if (!value) {
                            var snackBar =
                                SnackBar(content: Text('User does not exist.'));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          } else {
                            //from valid,redirect to landing page using routing
                            navigateToLandingPage(context);
                          }
                        });
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

  Future<bool> isLoginCredsValid() async {
    String userName = nameController.text;
    String passWord = passwordController.text;
    var prefs = await SharedPreferences.getInstance();
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: userName, password: passWord);

      if (userCredential.user != null) {
        print("Valid user!, UID: ${userCredential.user.uid}");
        prefs.setString("USER_ID", userCredential.user.uid);
        return true;
      } else
        return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
        return false;
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
        return false;
      }
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
