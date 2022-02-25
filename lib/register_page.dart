import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'models/UserModel.dart';
import 'util/constants.dart' as Constants;

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  File imageFile;
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPwController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  bool _isPassWordShown = false, _isConfirmPwShown = false;
  String emailPattern =
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
      r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
      r"{0,253}[a-zA-Z0-9])?)*$";
  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('UsersCollection');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          title: Text("Sign Up"),
          centerTitle: true,
        ),
        resizeToAvoidBottomInset: false,
        body: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
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
                          child: ListView(
                              padding: EdgeInsets.all(0),
                              children: <Widget>[
                                Center(
                                  child: SizedBox(
                                    height: 150,
                                    width: 150,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      fit: StackFit.loose,
                                      children: [
                                        ClipOval(
                                          child: Container(
                                            height: 150,
                                            width: 150,
                                            color: Colors.grey.shade200,
                                            child: (imageFile != null
                                                ? Image.file(imageFile)
                                                : Image.asset(
                                                    'assets/images/profile_pic.png',
                                                  )),
                                          ),
                                        ),
                                        Positioned(
                                            bottom: 0,
                                            right: -30,
                                            child: RawMaterialButton(
                                              onPressed: () {
                                                _pickImage();
                                              },
                                              elevation: 2.0,
                                              fillColor: Colors.grey.shade200,
                                              child: Icon(
                                                Icons.add_a_photo_outlined,
                                                color: Constants.bgMainColor,
                                              ),
                                              padding: EdgeInsets.all(5.0),
                                              shape: CircleBorder(),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 25.0),
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
                                      hintText: 'Full name',
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
                                            _isPassWordShown =
                                                !_isPassWordShown;
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
                                SizedBox(height: 10.0),
                                Container(
                                  padding: EdgeInsets.all(5),
                                  height: 30.0,
                                  child: TextField(
                                    textAlignVertical: TextAlignVertical.center,
                                    obscureText: !_isConfirmPwShown,
                                    controller: confirmPwController,
                                    decoration: InputDecoration(
                                      suffixIcon: InkWell(
                                        child: Icon(
                                          _isConfirmPwShown
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _isConfirmPwShown =
                                                !_isConfirmPwShown;
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
                                      hintText: 'Confirm password',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.0),
                                Container(
                                  padding: EdgeInsets.all(5),
                                  height: 30.0,
                                  alignment: Alignment.center,
                                  child: TextField(
                                    controller: emailController,
                                    decoration: InputDecoration(
                                      hintStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[400]),
                                      hintText: 'Email id',
                                    ),
                                  ),
                                ),
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
                                          child: Text('Register',
                                              style: TextStyle(
                                                  color: Constants.bgWhiteColor,
                                                  fontWeight: FontWeight.bold)),
                                          onPressed: () async {
                                            if (isFormValid()) {
                                              try {
                                                UserCredential userCredential =
                                                    await auth
                                                        .createUserWithEmailAndPassword(
                                                            email:
                                                                emailController
                                                                    .value.text,
                                                            password:
                                                                passwordController
                                                                    .value
                                                                    .text);
                                                print("register userId : "
                                                    "${userCredential.user.uid}");

                                                /*
                                                * (1) Insert UID,Full name &
                                                * profile pic into new
                                                * collection in firestore.
                                                * */

                                                List<int> imageBytes =
                                                    imageFile.readAsBytesSync();
                                                String imageB64 =
                                                    base64Encode(imageBytes);
                                                print("base64Str: $imageB64");

                                                addNoteToFireStore(UserModel(
                                                    userCredential.user.uid,
                                                    nameController.value.text
                                                        .toString(),
                                                    imageB64));

                                              } on FirebaseAuthException catch (e) {
                                                if (e.code == 'weak-password') {
                                                  print(
                                                      'The password provided is too weak.');
                                                } else if (e.code ==
                                                    'email-already-in-use') {
                                                  var snackBar = SnackBar(
                                                      content: Text('Email id '
                                                          'already exists.'));
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(snackBar);
                                                }
                                              } catch (e) {
                                                print(e);
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    )),
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

  Future<void> addNoteToFireStore(UserModel model) {
    print("in addNoteToFireStore()");
    usersCollection
        .add(model.toMap())
        .then((value) => print("User added to firestore"))
        .catchError((error) => print("Failed to add note: $error"));
  }

  Future<Null> _pickImage() async {
    print("inside _pickImage()");
    XFile pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    print("pickedFile null ${pickedFile == null}");
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      print("imagePth ${pickedFile.path}");
      File croppedFile = await ImageCropper().cropImage(
          sourcePath: imageFile.path,
          aspectRatioPresets: Platform.isAndroid
              ? [
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio16x9
                ]
              : [
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio3x2,
                  CropAspectRatioPreset.ratio4x3,
                  CropAspectRatioPreset.ratio5x3,
                  CropAspectRatioPreset.ratio5x4,
                  CropAspectRatioPreset.ratio7x5,
                  CropAspectRatioPreset.ratio16x9
                ],
          androidUiSettings: AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          iosUiSettings: IOSUiSettings(
            title: 'Cropper',
          ));
      if (croppedFile != null) {
        imageFile = croppedFile;
        setState(() {
          // state = AppState.cropped;
        });
      }
    }
  }

  bool isFormValid() {
    if (nameController.value.text.isEmpty) {
      var snackBar = SnackBar(content: Text('Full name mandatory'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return false;
    }
    if (passwordController.value.text.isEmpty ||
        confirmPwController.value.text.isEmpty) {
      var snackBar = SnackBar(content: Text('Passwords cannot be empty'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return false;
    } else if (passwordController.value.text.toString() !=
        confirmPwController.value.text.toString()) {
      var snackBar = SnackBar(content: Text('Passwords do not match'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return false;
    } else if (passwordController.value.text.toString().length < 6) {
      var snackBar = SnackBar(
          content: Text('Password should be of atleast 6 '
              'characters'
              ''));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return false;
    } else if (!RegExp(emailPattern)
            .hasMatch(emailController.value.text.toString()) ||
        emailController.value.text.isEmpty) {
      var snackBar = SnackBar(content: Text('Enter a valid email address'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return false;
    }
    return true;
  }
}
