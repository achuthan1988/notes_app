import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:notes_app/landing_page.dart';
import 'package:notes_app/models/NotesModel.dart';
import 'package:notes_app/register_page.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

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
  bool _isPassWordShown = false;
  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('UsersCollection');
  CollectionReference notesCollection =
      FirebaseFirestore.instance.collection('NotesCollection');
  var profileBase64;
  UserCredential userCredential;
  String errorText;
  String emailPattern =
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
      r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
      r"{0,253}[a-zA-Z0-9])?)*$";
  var notesDB;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initDB();
  }

  void initDB() async {
    print("enter  init()");

    if (!kIsWeb) {
      var status = await Permission.storage.request();
      var statusM = await Permission.microphone.request();
    }
    WidgetsFlutterBinding.ensureInitialized();
// Open the database and store the reference.
    final Future<Database> database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), Constants.DB_NAME),

      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        print("inside onCreate DB!!");
        notesDB = db;
        // Run the   statement on the database.
        db.execute(
          "CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT,userId "
          "TEXT, "
          "noteTitle"
          " TEXT, noteContent TEXT, noteType TEXT, noteBgColorHex TEXT, "
          "noteMediaPath TEXT,  noteImgBase64 TEXT,noteLabelIdsStr TEXT, "
          "noteDateOfDeletion TEXT,"
          "isNotePinned INTEGER, isNoteArchived INTEGER, isNoteTrashed "
          "INTEGER, reminderID INTEGER)",
        );
        db.execute(
            "CREATE TABLE TblLabels(id INTEGER PRIMARY KEY AUTOINCREMENT, labelTitle TEXT)");

        db.execute("CREATE TABLE TblReminders(id INTEGER PRIMARY KEY "
            "AUTOINCREMENT, reminderDate TEXT, reminderTime TEXT, "
            "reminderInterval TEXT)");
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );

    //notesDB = database;
    print("exit init()");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: null,
        resizeToAvoidBottomInset: false,
        body: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
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
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.separated(
                        physics: BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: 1,
                        itemBuilder: (context, index) => Container(
                          height: MediaQuery.of(context).size.height * 0.8,
                          padding: EdgeInsets.all(10.0),
                          child:
                              ListView(padding: EdgeInsets.all(0), children: <
                                  Widget>[
                            SizedBox(height: 10.0),
                            Container(
                              padding: EdgeInsets.all(5),
                              height: 30.0,
                              alignment: Alignment.center,
                              child: TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  hintStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[400]),
                                  hintText: 'Email',
                                ),
                              ),
                            ),
                            SizedBox(height: 10.0),
                            Container(
                              padding: EdgeInsets.all(5),
                              height: 30.0,
                              child: TextField(
                                textAlignVertical: TextAlignVertical.center,
                                obscureText: !_isPassWordShown,
                                controller: passwordController,
                                decoration: InputDecoration(
                                  suffixIcon: InkWell(
                                    child: Icon(
                                      _isPassWordShown
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _isPassWordShown = !_isPassWordShown;
                                      });
                                    },
                                  ),
                                  isDense: true,
                                  suffixIconConstraints: BoxConstraints(
                                    minWidth: 7,
                                    minHeight: 7,
                                  ),
                                  hintStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[400]),
                                  hintText: 'Password',
                                ),
                              ),
                            ),
                            SizedBox(height: 5.0),
                            GestureDetector(
                              child: Container(
                                padding: EdgeInsets.all(5.0),
                                height: 30.0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                          color: Constants.bgMainColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                print("Forgot password clicked!");
                                /*
                                * 1. Display alert with heading , subtitle
                                * and textfield , button
                                *
                                * 2. Click initiates firebase Auth reset mail
                                *  sending(Validate email blank and proper
                                * format)
                                *
                                * 3. Check if email exists in list of
                                * registered auths , if not present show a
                                * snackbar saying user not found.
                                *
                                * 4. Dismiss dialog and show snackbar saying
                                * " Reset password link sent to your mail"
                                *
                                * 5. Change password and test failure for
                                * older paswword & success for new one.(on
                                * @ login UI)
                                *
                                * */
                                TextEditingController emailController =
                                    TextEditingController();

                                final _formKey = GlobalKey<FormState>();
                                Dialog dialog = Dialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          12.0)), //this right here
                                  child: Container(
                                    height: 250.0,
                                    width: 300.0,
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.all(5.0),
                                            child: Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18.0),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(5.0),
                                            child: Text(
                                              'Enter the mail id '
                                              'associated with your account.',
                                              style: TextStyle(
                                                  color: Colors.black26,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14.0),
                                            ),
                                          ),
                                          Padding(
                                              padding:
                                                  EdgeInsets.only(top: 10.0)),
                                          Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: TextField(
                                              controller: emailController,
                                              decoration: InputDecoration(
                                                hintStyle: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey[400]),
                                                hintText: 'Email',
                                                errorText: errorText,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 20.0),
                                          ElevatedButton(
                                            style: ButtonStyle(
                                                foregroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(Colors.white),
                                                backgroundColor:
                                                    MaterialStateProperty.all<Color>(
                                                        Constants.bgMainColor),
                                                shape: MaterialStateProperty.all<
                                                        RoundedRectangleBorder>(
                                                    RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(2.0),
                                                        side: BorderSide(color: Constants.bgMainColor)))),
                                            child: Text('Send Mail',
                                                style: TextStyle(
                                                    color:
                                                        Constants.bgWhiteColor,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            onPressed: () async {
                                              if (!RegExp(emailPattern)
                                                      .hasMatch(emailController
                                                          .value.text
                                                          .toString()) ||
                                                  emailController
                                                      .value.text.isEmpty) {
                                                errorText = 'Email id is '
                                                    'invalid';

                                                // return errorText;
                                              } else {
                                                checkIfEmailInUse(
                                                        emailController
                                                            .value.text)
                                                    .then((isEmailExists) {
                                                  if (!isEmailExists) {
                                                    errorText = 'This user '
                                                        'does not exist';

                                                    // return errorText;
                                                  }
                                                });

                                                // errorText = "";
                                                // return errorText;
                                              }
                                              setState(() {});

                                              print("errorText: $errorText");
                                              if (errorText.length == 0) {
                                                auth.sendPasswordResetEmail(
                                                    email: emailController
                                                        .value.text);

                                                var snackBar = SnackBar(
                                                    content: Text(
                                                        'Reset  password link '
                                                        'has '
                                                        'been sent.'));
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(snackBar);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) => dialog);
                              },
                            ),
                            SizedBox(height: 30.0),
                            Container(
                                margin: const EdgeInsets.only(top: 30.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton(
                                      style: ButtonStyle(
                                          foregroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.white),
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Constants.bgMainColor),
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          2.0),
                                                  side: BorderSide(color: Constants.bgMainColor)))),
                                      child: Text('LOGIN',
                                          style: TextStyle(
                                              color: Constants.bgWhiteColor,
                                              fontWeight: FontWeight.bold)),
                                      onPressed: () async {
                                        validateFormBlankFields(
                                            nameController.text +
                                                " " +
                                                passwordController.text);

                                        if (!isUserNameBlank &&
                                            !isPassWordBlank) {
                                          isLoginCredsValid(context)
                                              .then((value) {
                                            if (!value) {
                                              var snackBar = SnackBar(
                                                  content: Text(
                                                      'User does not exist.'));
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(snackBar);
                                            } else {
                                              navigateToLandingPage(context);

                                              //from valid,redirect to landing page using routing

                                            }
                                          });
                                        }
                                      },
                                    ),
                                    SignInButton(
                                      Buttons.Google,
                                      onPressed: () {
                                        /* signInWithGoogle()
                                                 .then((value) => print("google sign in email id:"
                                                     " ${value.user.email} URL : ${value.user.photoUrl}"));*/
                                      },
                                    ),
                                    SizedBox(height: 2.0),
                                    SignInButton(
                                      Buttons.Facebook,
                                      onPressed: () {},
                                    ),
                                  ],
                                )),
                            SizedBox(height: 30.0),
                            GestureDetector(
                              child: Container(
                                  padding: EdgeInsets.all(5),
                                  height: 30.0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Dont have an account?",
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        "Create Account",
                                        style: TextStyle(
                                            color: Constants.bgMainColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14),
                                      )
                                    ],
                                  )),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => RegisterPage()));
                              },
                            ),
                          ]),
                        ),
                        separatorBuilder: (context, index) =>
                            Divider(height: 10.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Future<bool> checkIfEmailInUse(String emailAddress) async {
    try {
      // Fetch sign-in methods for the email address
      final list =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(emailAddress);

      // In case list is not empty
      if (list.isNotEmpty) {
        // Return true because there is an existing
        // user using the email address
        return true;
      } else {
        // Return false because email adress is not in use
        return false;
      }
    } catch (error) {
      return true;
    }
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

  Future<bool> isLoginCredsValid(BuildContext context) async {
    String userName = nameController.text;
    String passWord = passwordController.text;
    var prefs = await SharedPreferences.getInstance();
    try {
      userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: userName, password: passWord);

      if (userCredential.user != null) {
        print("Valid user!, UID: ${userCredential.user.uid}");

        if (FirebaseAuth.instance.currentUser.emailVerified) {
          print("email verified!");
          prefs.setString("USER_ID", userCredential.user.uid);

          /* usersCollection.where('userId',isEqualTo:userCredential.user.uid.toString())
            .get().then((QuerySnapshot querySnapshot) {
              querySnapshot.docs.forEach((doc) {
                print("base64---- " + doc.get("noteContent"));
                profileBase64 = doc.get("noteContent");
                prefs.setString("PROFILE_BASE", profileBase64);
              });
            });*/

          return true;
        } else {
          var snackBar =
              SnackBar(content: Text('Email not verified.Check your inbox.'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          FirebaseAuth.instance.currentUser.sendEmailVerification();
          return false;
        }
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

    return true;
  }

  Future navigateToLandingPage(context) async {
    var prefs = await SharedPreferences.getInstance();
    usersCollection
        .where('userId', isEqualTo: userCredential.user.uid)
        .get()
        .then((QuerySnapshot querySnapshot) {
      try {
        try {
          try {
            querySnapshot.docs.forEach((doc) {
              print("base64---- " + doc.get("noteContent"));
              profileBase64 = doc.get("noteContent");
              prefs.setString("PROFILE_BASE", profileBase64);
              prefs.setString("FIRST_NAME", doc.get("userFullName"));
              loadFireStoreToDb(context);
              /*
              * data populate local db by querying UsersCollection based on uid
              * The uid comma string if it starts with the login uid he is a
              * owner else a collaborator
              *
              *
              * */
              /*   Route route = MaterialPageRoute(
                  builder: (context) => LandingPage(
                      prefs.getString("PROFILE_BASE"),
                      prefs.get("FIRST_NAME")));
              Navigator.pushReplacement(context, route);*/
            });
          } catch (e, s) {
            print(s);
          }
        } catch (e, s) {
          print(s);
        }
      } catch (e, s) {
        print(s);
      }
    });
  }

  Future<void> loadFireStoreToDb(BuildContext context) async {
    var prefs = await SharedPreferences.getInstance();
    notesCollection
        .where("userIDObj", arrayContains: userCredential.user.uid)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        //transfer data to local here!!TODO
        String userIdStr = "";
        List<dynamic> userIdList = doc['userIDObj'];
        userIdList.forEach((element) {
          userIdStr = userIdStr  + element.toString()+"||";
        });

        print("userIdStr:$userIdStr");
        NotesModel modelObj = NotesModel(
            userIdStr,
            doc['noteTitle'],
            doc['noteContent'],
            doc['noteType'],
            doc['noteBgColorHex'],
            doc['noteMediaPath'],
            doc['noteImgBase64'],
            doc['noteLabelIdsStr'],
            doc['noteDateOfDeletion'],
            doc['isNotePinned'],
            doc['isNoteArchived'],
            doc['isNoteTrashed'],
            doc['reminderID']);
        await insertNote(modelObj);
      });

      Route route = MaterialPageRoute(
          builder: (context) => LandingPage(
              prefs.getString("PROFILE_BASE"), prefs.get("FIRST_NAME")));
      Navigator.pushReplacement(context, route);
    });
  }

  Future<void> insertNote(NotesModel model) async {
    print("inside insertNote()");

    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    await notesDB.insert(
      'notes',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
