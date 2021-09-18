import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes_app/util/HexColor.dart';
import 'package:painter/painter.dart';
import 'package:path/path.dart';
import 'package:popup_menu/popup_menu.dart';
import 'package:sqflite/sqflite.dart';

import 'landing_page.dart';
import 'models/NotesModel.dart';
import 'util/constants.dart' as Constants;

class NewNotePage extends StatefulWidget {
  NotesModel notesModel;
  String heroTagValue;

  NewNotePage(this.notesModel, this.heroTagValue);

  @override
  _NewNotePageState createState() =>
      _NewNotePageState(notesModel, heroTagValue);
}

class _NewNotePageState extends State<NewNotePage> {
  NotesModel notesModel;
  String noteTitleVal = "",
      noteContentVal = "",
      heroTagValue = "",
      base64DrawingStr = "";

  _NewNotePageState(this.notesModel, this.heroTagValue);

  FlutterSound flutterSound;
  TextEditingController noteTitleController;
  TextEditingController noteContentController;
  static int scaffoldBackgroundColorPos = 0;
  static int scaffoldNoteTypePos = 0;
  GlobalKey key = new GlobalKey();
  var notesDB;
  static HexColor scaffoldBgHex;
  static HexColor bgHexMain;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    noteTitleVal = (notesModel != null) ? (notesModel.noteTitle) : ("");
    noteContentVal = (notesModel != null) ? (notesModel.noteContent) : ("");
    noteTitleController = new TextEditingController(text: noteTitleVal);
    noteContentController = new TextEditingController(text: noteContentVal);

    flutterSound = new FlutterSound();
    if (notesModel != null) {
      print("notesModel.noteBgColorHex ${notesModel.noteBgColorHex}");
      scaffoldBgHex = HexColor(notesModel.noteBgColorHex);
      if (notesModel.noteType == "3") {
        base64DrawingStr = notesModel.noteImgBase64;
        scaffoldNoteTypePos = 3;
      }
    }
    bgHexMain = (this.notesModel == null)
        ? (Constants.bgArray[scaffoldBackgroundColorPos])
        : (scaffoldBgHex);

    initDB();
  }

  void initDB() async {
    print("enter  init()");
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
        // Run the CREATE TABLE statement on the database.
        db.execute(
          "CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, noteTitle"
          " TEXT, noteContent TEXT, noteType TEXT, noteBgColorHex TEXT, "
          "noteMediaPath TEXT,  noteImgBase64 TEXT,noteLabelIdsStr TEXT,"
          "isNotePinned INTEGER, isNoteArchived INTEGER)",
        );
        db.execute(
            "CREATE TABLE TblLabels(id INTEGER PRIMARY KEY AUTOINCREMENT, labelTitle TEXT)");
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );

    //notesDB = database;
    print("exit init()");
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

  Future<void> updateNote(String originalTitle, NotesModel model) async {
    print("inside updateNote()");

    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    // do the update and get the number of affected rows
    int updateCount = await notesDB.update('notes', model.toMap(),
        where: '${'noteTitle'} = ?', whereArgs: [originalTitle]);
    print("updateCount: $updateCount");
    // show the results: print all rows in the db
    print(await notesDB.query('notes'));
  }

  @override
  Widget build(BuildContext context) {
    print("inside build(): scaffoldNoteTypePos:$scaffoldNoteTypePos");
    if (scaffoldNoteTypePos == 0)
      return Scaffold(
        key: key,
        backgroundColor: bgHexMain,
        body: Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 30),
                    child: TextFormField(
                      controller: noteTitleController,
                      style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                          fontWeight: FontWeight.normal),
                      decoration: InputDecoration(
                          hintText: 'Title',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                              fontSize: 18.0,
                              color: Colors.black,
                              fontWeight: FontWeight.normal)),
                    ),
                  ),
                  (scaffoldNoteTypePos != 0
                      ? toggleWidget(scaffoldNoteTypePos)
                      : Container(
                          child: TextFormField(
                            controller: noteContentController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.black,
                                fontWeight: FontWeight.normal),
                            decoration: InputDecoration(
                              hintText: 'Note',
                              hintStyle: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal),
                              border: InputBorder.none,
                            ),
                          ),
                        ))
                ],
              ),
            ),
            GestureDetector(
              child: Hero(
                tag: 'heroTag',
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () async {
                        print("inside onPressed()");
                        if (this.notesModel != null) {
                          //update based on current Note title, Note content & bgColor
                          String originalTitle = notesModel.noteTitle;
                          notesModel.noteTitle =
                              noteTitleController.text.trim();
                          notesModel.noteContent =
                              noteContentController.text.trim();
                          Color color = bgHexMain;
                          notesModel.noteBgColorHex =
                              '#${color.value.toRadixString(16)}';

                          updateNote(originalTitle, notesModel);
                        } else {
                          print("inside else of  onTap()");
                          NotesModel model = createNoteObject();
                          await insertNote(model);
                        }

                        Navigator.push(
                            context, ScaleRoute(page: LandingPage()));
                      }),
                ),
              ),
              onTap: () async {
                print("inside onTap()");
                /*if (this.notesModel != null) {
                  //update based on current Note title, Note content & bgColor
                  String originalTitle = notesModel.noteTitle;
                  notesModel.noteTitle = noteTitleController.text.trim();
                  notesModel.noteContent = noteContentController.text.trim();
                  Color color = Constants.bgArray[scaffoldBackgroundColorPos];
                  notesModel.noteBgColorHex =
                      '#${color.value.toRadixString(16)}';

                  updateNote(originalTitle, notesModel);
                } else {
                  print("inside else of  onTap()");
                  NotesModel model = createNoteObject();
                  await insertNote(model);
                }

                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) {
                  return LandingPage();
                }));
                Navigator.pop(context);*/
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomMenuBar(this, this.notesModel),
      );
    else if (scaffoldNoteTypePos == 3)
      return DrawingWidget(this.notesModel, this);
    else if (scaffoldNoteTypePos == 5)
      return SizedBox();
  }

  NotesModel createNoteObject() {
    final noteObject = NotesModel(
        noteTitleController.text.trim(),
        noteContentController.text.trim(),
        "0",
        '#${bgHexMain.value.toRadixString(16)}',
        "",
        "",
        "",
        0,
        0);

    return noteObject;
  }

  /*NotesModel createDrawingNoteObject(){
    final noteObject = NotesModel(
        "",
        "",
        "0",
        '#${bgHexMain.value.toRadixString(16)}',
        "",
        "",
        "",
        0,
        0);

    return noteObject;
  }*/

  Widget toggleWidget(int position) {
    print("toggleWidget position: $position");
    if (position == 2) {
      return CustomCheckItemsWidget();
    } else if (position == 3) {
      return DrawingWidget(this.notesModel, this);
    }
  }
}

class BottomMenuBar extends StatefulWidget {
  State parentState;
  NotesModel notesModel;

  BottomMenuBar(State state, NotesModel notesModel) {
    parentState = state;
    this.notesModel = notesModel;
  }

  @override
  _BottomMenuBarState createState() =>
      _BottomMenuBarState(notesModel, parentState);
}

class _BottomMenuBarState extends State<BottomMenuBar> {
  GlobalKey btnKey = GlobalKey();
  GlobalKey btnKey1 = GlobalKey();

  State parent;
  int iconSelectedPosition = 0;
  int noteTypePosition = 0;
  NotesModel notesModel;

  _BottomMenuBarState(NotesModel notesModel, State parentState) {
    parent = parentState;
    this.notesModel = notesModel;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    PopupMenu.context = context;
    return BottomAppBar(
      color: Constants.bgMainColor,
      shape: CircularNotchedRectangle(),
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        child: Row(
          children: <Widget>[
            IconButton(
              iconSize: 36.0,
              tooltip: 'Open Note Type Menu',
              key: btnKey,
              icon: const Icon(Icons.add_box_outlined),
              onPressed: () {
                showPopUpMenu(context);
              },
            ),
            new Spacer(),
            IconButton(
              iconSize: 36.0,
              tooltip: 'Open Options Menu',
              key: btnKey1,
              icon: const Icon(Icons.menu),
              onPressed: () {
                showCustomMenu(context, parent);
              },
            ),
          ],
        ),
      ),
    );
  }

  void stateChanged(bool isShow) {
    print('menu is ${isShow ? 'showing' : 'closed'}');
  }

  Future<void> onClickMenu(MenuItemProvider item) async {
    print('Click menu -> ${item.menuTitle}');

    if (item.menuTitle.contains("Tick boxes")) {
      //(1) replace note TextField in main scaffold , to the checkbox box widget tree
      noteTypePosition = 2;
    } else if (item.menuTitle.contains("Drawing")) {
      noteTypePosition = 3;
    } else if (item.menuTitle.contains("Recording")) {
      noteTypePosition = 1;
      /*
      * (1) show alert dialog for recording audio
      * (2) If cancelled , dismiss alert
      * (3) If ticked, save to be initiated and redirect to landing page
      *
      * */
      showRecorderDialog(PopupMenu.context);
    } else if (item.menuTitle.contains("Take Photo")) {
      noteTypePosition = 5;
      final cameras = await availableCameras();
      final firstCamera = cameras.first;
      _pickedImage(PopupMenu.context);
    }

    parent.setState(() {
      print("onClickMenu setState() ");
      _NewNotePageState.scaffoldNoteTypePos = noteTypePosition;
      print(
          "onClickMenu setState() _NewNotePageState.scaffoldNoteTypePos: ${_NewNotePageState.scaffoldNoteTypePos}");
    });
  }

  void _pickedImage(BuildContext context) {
    File _pickedImage;
    final picker = ImagePicker();
    showDialog<ImageSource>(
      context: context,
      builder: (context) =>
          AlertDialog(content: Text("Choose image source"), actions: [
        FlatButton(
          child: Text("Camera"),
          onPressed: () => Navigator.pop(context, ImageSource.camera),
        ),
        FlatButton(
          child: Text("Gallery"),
          onPressed: () => Navigator.pop(context, ImageSource.gallery),
        ),
      ]),
    ).then((ImageSource source) async {
      if (source != null) {
        final pickedFile = await ImagePicker().getImage(source: source);
        print("image file path: ${pickedFile.path}");
        parent.setState(() => _pickedImage = File(pickedFile.path));
      }
    });

  }

  void showRecorderDialog(BuildContext context) {
    Dialog dialog = Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
      //this right here
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          height: 120.0,
          width: 100.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                "00:00:00",
                style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.w600,
                    color: Constants.bgMainColor),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () {},
                child: Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 36.0,
                ),
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(15),
                  primary: Constants.bgMainColor,
                  onPrimary: Constants.bgMainColor,
                ),
              )
            ],
          ),
        ),
      ),
    );
    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  void onDismiss() {
    print('Menu is dismiss');
  }

  void showPopUpMenu(BuildContext context) {
    print('inside showPopUpMenu()');
    TextStyle menuTextStyle = TextStyle(
        color: Colors.white, fontWeight: FontWeight.w400, fontSize: 10.0);
    Color menuColor = Colors.white;

    PopupMenu menu = PopupMenu(
        lineColor: Colors.white,
        backgroundColor: Constants.appGreenColor,
        items: [
          MenuItem(
              title: 'Take Photo',
              textStyle: menuTextStyle,
              image: Icon(
                Icons.camera_alt,
                color: menuColor,
              )),
          MenuItem(
              title: 'Add Image',
              textStyle: menuTextStyle,
              image: Icon(
                Icons.image,
                color: menuColor,
              )),
          MenuItem(
              title: 'Tick boxes',
              textStyle: menuTextStyle,
              image: Icon(
                Icons.check_box_outlined,
                color: menuColor,
              )),
          MenuItem(
              title: 'Drawing',
              textStyle: menuTextStyle,
              image: Icon(
                Icons.brush_outlined,
                color: Colors.white,
              )),
          MenuItem(
              title: 'Recording',
              textStyle: menuTextStyle,
              image: Icon(
                Icons.audiotrack,
                color: menuColor,
              )),
        ],
        onClickMenu: onClickMenu,
        onDismiss: onDismiss,
        maxColumn: 1);
    menu.show(widgetKey: btnKey);
  }

  void showCustomMenu(ctx, State parentState) {
    TextStyle menuTextStyle = TextStyle(
        color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18.0);
    Color menuColor = Colors.black87;
    showModalBottomSheet(
        context: ctx,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState
                  /*You can rename this!*/) {
            return Padding(
              padding: EdgeInsets.all(0.0),
              child: Container(
                alignment: Alignment.topLeft,
                color: (Constants.bgArray[iconSelectedPosition]),
                height: 200,
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: menuColor,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 5.0),
                          child: Text(
                            'Delete Note',
                            style: menuTextStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Row(children: [
                      Icon(
                        Icons.label,
                        color: menuColor,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 5.0),
                        child: Text(
                          'Label',
                          style: menuTextStyle,
                        ),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Row(children: [
                      Icon(
                        Icons.share,
                        color: menuColor,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 5.0),
                        child: Text(
                          'Share',
                          style: menuTextStyle,
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                print("inside setState() 0");
                                iconSelectedPosition = 0;
                                parent.setState(() {
                                  print("inside parent.setState() 0");
                                  _NewNotePageState.scaffoldBackgroundColorPos =
                                      iconSelectedPosition;
                                  _NewNotePageState.scaffoldBgHex =
                                      Constants.bgArray[iconSelectedPosition];
                                  _NewNotePageState.bgHexMain =
                                      Constants.bgArray[iconSelectedPosition];
                                });
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              child: Visibility(
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                visible:
                                    (iconSelectedPosition == 0 ? true : false),
                                child: Icon(
                                  Icons.check_outlined,
                                  color: Colors.black,
                                ),
                              ),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Constants.bgArray[0]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              setState(() {
                                print("inside setState() 1");
                                iconSelectedPosition = 1;
                                parent.setState(() {
                                  print("inside parent.setState() 1");
                                  _NewNotePageState.scaffoldBackgroundColorPos =
                                      iconSelectedPosition;
                                  _NewNotePageState.scaffoldBgHex =
                                      Constants.bgArray[iconSelectedPosition];
                                  _NewNotePageState.bgHexMain =
                                      Constants.bgArray[iconSelectedPosition];
                                });
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              child: Visibility(
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                visible:
                                    (iconSelectedPosition == 1 ? true : false),
                                child: Icon(
                                  Icons.check_outlined,
                                  color: Colors.black,
                                ),
                              ),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Constants.bgArray[1]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              setState(() {
                                print("inside setState() 2");
                                iconSelectedPosition = 2;
                                parent.setState(() {
                                  print("inside parent.setState() 2");
                                  _NewNotePageState.scaffoldBackgroundColorPos =
                                      iconSelectedPosition;
                                  _NewNotePageState.scaffoldBgHex =
                                      Constants.bgArray[iconSelectedPosition];
                                  _NewNotePageState.bgHexMain =
                                      Constants.bgArray[iconSelectedPosition];
                                });
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              child: Visibility(
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                visible:
                                    (iconSelectedPosition == 2 ? true : false),
                                child: Icon(
                                  Icons.check_outlined,
                                  color: Colors.black,
                                ),
                              ),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Constants.bgArray[2]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                parent.setState(() {
                                  print("inside setState() 3");
                                  iconSelectedPosition = 3;
                                  print("inside parent.setState() 3");
                                  _NewNotePageState.scaffoldBackgroundColorPos =
                                      iconSelectedPosition;
                                  _NewNotePageState.scaffoldBgHex =
                                      Constants.bgArray[iconSelectedPosition];
                                  _NewNotePageState.bgHexMain =
                                      Constants.bgArray[iconSelectedPosition];
                                });
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              child: Visibility(
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                visible:
                                    (iconSelectedPosition == 3 ? true : false),
                                child: Icon(
                                  Icons.check_outlined,
                                  color: Colors.black,
                                ),
                              ),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Constants.bgArray[3]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                parent.setState(() {
                                  iconSelectedPosition = 4;
                                  _NewNotePageState.scaffoldBackgroundColorPos =
                                      iconSelectedPosition;
                                  _NewNotePageState.scaffoldBgHex =
                                      Constants.bgArray[iconSelectedPosition];
                                  _NewNotePageState.bgHexMain =
                                      Constants.bgArray[iconSelectedPosition];
                                });
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              child: Visibility(
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                visible:
                                    (iconSelectedPosition == 4 ? true : false),
                                child: Icon(
                                  Icons.check_outlined,
                                  color: Colors.black,
                                ),
                              ),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Constants.bgArray[4]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                parent.setState(() {
                                  iconSelectedPosition = 5;
                                  _NewNotePageState.scaffoldBackgroundColorPos =
                                      iconSelectedPosition;
                                  _NewNotePageState.scaffoldBgHex =
                                      Constants.bgArray[iconSelectedPosition];
                                  _NewNotePageState.bgHexMain =
                                      Constants.bgArray[iconSelectedPosition];
                                });
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              child: Visibility(
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                visible:
                                    (iconSelectedPosition == 5 ? true : false),
                                child: Icon(
                                  Icons.check_outlined,
                                  color: Colors.black,
                                ),
                              ),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Constants.bgArray[5]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                parent.setState(() {
                                  iconSelectedPosition = 6;

                                  _NewNotePageState.scaffoldBackgroundColorPos =
                                      iconSelectedPosition;
                                  _NewNotePageState.scaffoldBgHex =
                                      Constants.bgArray[iconSelectedPosition];
                                  _NewNotePageState.bgHexMain =
                                      Constants.bgArray[iconSelectedPosition];
                                });
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              child: Visibility(
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                visible:
                                    (iconSelectedPosition == 6 ? true : false),
                                child: Icon(
                                  Icons.check_outlined,
                                  color: Colors.black,
                                ),
                              ),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Constants.bgArray[6]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                parent.setState(() {
                                  iconSelectedPosition = 7;

                                  _NewNotePageState.scaffoldBackgroundColorPos =
                                      iconSelectedPosition;
                                  _NewNotePageState.scaffoldBgHex =
                                      Constants.bgArray[iconSelectedPosition];
                                  _NewNotePageState.bgHexMain =
                                      Constants.bgArray[iconSelectedPosition];
                                });
                              });
                            },
                            child: Container(
                              child: Visibility(
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                visible:
                                    (iconSelectedPosition == 7 ? true : false),
                                child: Icon(
                                  Icons.check_outlined,
                                  color: Colors.black,
                                ),
                              ),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Constants.bgArray[7]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ]),
              ),
            );
          });
        });
  }
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key key,
    this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fill this out in the next steps.
    return Container();
  }
}

class CustomCheckItemsWidget extends StatefulWidget {
  @override
  _CustomCheckItemsWidgetState createState() => _CustomCheckItemsWidgetState();
}

class _CustomCheckItemsWidgetState extends State<CustomCheckItemsWidget> {
  GlobalKey reorderListKey = new GlobalKey();
  final listSizeNotfier = new ValueNotifier(0);
  static int rowWidgetSize = 0;
  static List<bool> checkBoxStateList = [];
  static List<TextEditingController> controllersList = [];
  Future<dynamic> future;
  StreamController<int> _controller = StreamController<int>();

  _CustomCheckItemsWidgetState() {
    rowWidgetSize++;
    checkBoxStateList.add(false);
    controllersList.add(TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    print(
        "inside _CustomCheckItemsWidgetState build(),new size: $rowWidgetSize");
    return StreamBuilder(
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
      return Column(
        children: [
          Container(
            height: (rowWidgetSize * 25.0).toDouble(),
            child: CustomListViewWidget(this),
          ),
          BottomListAdderWidget(_controller, listSizeNotfier, this, this.future,
              _controller.stream),
        ],
      );
    });
  }
}

class CustomListViewWidget extends StatefulWidget {
  @override
  _CustomListViewWidgetState createState() =>
      _CustomListViewWidgetState(this.customCheckState);
  _CustomCheckItemsWidgetState customCheckState;

  CustomListViewWidget(this.customCheckState);
}

class _CustomListViewWidgetState extends State<CustomListViewWidget> {
  GlobalKey reorderListKey = new GlobalKey();
  final listSizeNotfier = new ValueNotifier(0);
  _CustomCheckItemsWidgetState customCheckState;

  _CustomListViewWidgetState(this.customCheckState);

  @override
  Widget build(BuildContext context) {
    print("inside build() of ListViewWidget!");
    return ReorderableListView.builder(
      key: reorderListKey,
      scrollDirection: Axis.vertical,
      itemCount: _CustomCheckItemsWidgetState.rowWidgetSize,
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) {
        print("inside itemBuilder ListView index: $index state: "
            "${_CustomCheckItemsWidgetState.checkBoxStateList[index]}"
            "");

        return Container(
          key: Key('$index'),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      child: SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: Icon(
                          Icons.menu,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: Checkbox(
                          value: _CustomCheckItemsWidgetState
                              .checkBoxStateList[index],
                          onChanged: (newValue) {
                            print(
                                "inside listview checkedValue  $newValue at $index");
                            _CustomCheckItemsWidgetState
                                .checkBoxStateList[index] = newValue;
                            print(
                                "checkBoxStateList[index]: ${_CustomCheckItemsWidgetState.checkBoxStateList[index]}");

                            // _setState(() {});
                            /* setState(() {
                                    });*/
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _CustomCheckItemsWidgetState.checkBoxStateList[index]
                      ? TextField(
                          onChanged: ((String txt) {
                            print("Textfield onChanged String $txt");
                          }),
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: 12.0,
                              decorationColor: Colors.red,
                              decorationStyle: TextDecorationStyle.solid,
                              decoration: TextDecoration.lineThrough),
                          controller: _CustomCheckItemsWidgetState
                              .controllersList[index],
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        )
                      : TextField(
                          onChanged: ((String txt) {
                            print("Textfield onChanged String $txt");
                          }),
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: 12.0,
                              decorationColor: Colors.red,
                              decorationStyle: TextDecorationStyle.solid,
                              decoration: TextDecoration.none),
                          controller: _CustomCheckItemsWidgetState
                              .controllersList[index],
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        ),
                ),
                GestureDetector(
                  onTap: () {
/*                      setState(() {
                          Key key = Key('$index');
                          int indexVal = int.parse(key.toString());
                          print("indexVal: $indexVal");
                        });*/
                  },
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      child: SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: Icon(
                          Icons.close,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
        );
      },
      onReorder: (oldIdx, newIdx) {},
    );
  }
}

/*class IndividualRowWidget extends StatefulWidget {
  @override
  _IndividualRowWidgetState createState() => _IndividualRowWidgetState();
  String id;
}

class _IndividualRowWidgetState extends State<IndividualRowWidget> {
  var checkedValue = false;
  var isTextStriked = false;
  TextEditingController controller = new TextEditingController();

  void onChanged(bool newValue) {
    print("newValue: $newValue");
    setState(() {
      checkedValue = newValue;
      isTextStriked = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext _context, StateSetter _setState) {
      return Container(
          key: UniqueKey(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {},
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    child: SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: Icon(
                        Icons.menu,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Checkbox(
                      value: checkedValue,
                      onChanged: (bool newValue) {
                        print("inside CB newValue: $newValue");
                        _setState(() {
                          checkedValue = !checkedValue;
                          isTextStriked = checkedValue;
                        });
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: TextField(
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 12.0,
                          decoration: (isTextStriked
                              ? TextDecoration.lineThrough
                              : TextDecoration.none)),
                      controller: controller,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    child: SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: Icon(
                        Icons.close,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ));
    });
  }
}*/

class BottomListAdderWidget extends StatefulWidget {
  @override
  _BottomListAdderWidgetState createState() =>
      _BottomListAdderWidgetState(this._controller, customCheckState);

  _CustomCheckItemsWidgetState customCheckState;
  final ValueListenable<int> valueListenable;
  Future<dynamic> future;
  final Stream<int> stream;
  StreamController<int> _controller;

  BottomListAdderWidget(this._controller, this.valueListenable,
      this.customCheckState, this.future, this.stream);
}

class _BottomListAdderWidgetState extends State<BottomListAdderWidget> {
  _CustomCheckItemsWidgetState customCheckState;
  StreamController<int> _controller;

  _BottomListAdderWidgetState(this._controller, this.customCheckState);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("inside initState()");
    _controller.stream.listen((newSize) {
      print("inside listen newSize:$newSize");
      _CustomCheckItemsWidgetState.rowWidgetSize = newSize;
      updateSizeOfList();
    });
  }

  void updateSizeOfList() {
    print("inside updateSizeOfList()");
    customCheckState.setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("inside onTap of bottom adder!");

        _controller.add(_CustomCheckItemsWidgetState.rowWidgetSize + 1);
        _CustomCheckItemsWidgetState.checkBoxStateList.add(false);
        _CustomCheckItemsWidgetState.controllersList
            .add(new TextEditingController());

        print(
            "rowWidgetArray.size:'${_CustomCheckItemsWidgetState.rowWidgetSize}'");
      },
      child: Container(
          margin: EdgeInsets.only(left: 35.0),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(
                Icons.add,
                color: Colors.grey,
              ),
              Text(
                "Add Item",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600),
              )
            ],
          )),
    );
  }
}

class ScaleRoute extends PageRouteBuilder {
  final Widget page;

  ScaleRoute({this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              ScaleTransition(
            scale: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            ),
            child: child,
          ),
        );
}

class LandingPageRoute extends PageRouteBuilder {
  final Widget page;

  LandingPageRoute({this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              ScaleTransition(
            scale: Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInBack,
              ),
            ),
            child: child,
          ),
        );
}

class DrawingWidget extends StatefulWidget {
  NotesModel notesModel;
  State state;

  DrawingWidget(this.notesModel, this.state);

  @override
  _DrawingWidgetState createState() =>
      new _DrawingWidgetState(this.notesModel, this.state);
}

class _DrawingWidgetState extends State<DrawingWidget> {
  bool _finished = false;
  NotesModel notesModel;
  State state;
  var notesDB;
  PainterController _controller = _newController();
  Painter painter;

  _DrawingWidgetState(this.notesModel, this.state);

  @override
  void initState() {
    super.initState();

    if (notesModel != null) {
      if (notesModel?.noteImgBase64 != "") {
        _controller = new PainterController();
        _controller.thickness = 5.0;
        _controller.backgroundColor = new HexColor(notesModel.noteBgColorHex);
        painter = new Painter(_controller);
      }
    }
  }

  static PainterController _newController() {
    PainterController controller = new PainterController();
    controller.thickness = 5.0;
    controller.backgroundColor = _NewNotePageState.bgHexMain;

    return controller;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions;
    if (_finished) {
      actions = <Widget>[
        new IconButton(
          icon: new Icon(Icons.content_copy),
          tooltip: 'New Painting',
          color: Colors.black,
          onPressed: () => setState(() {
            _finished = false;
            _controller = _newController();
          }),
        ),
      ];
    } else {
      actions = <Widget>[
        new IconButton(
          icon: new Icon(Icons.save),
          color: Colors.black,
          onPressed: () => saveDrawingToDB(_controller.finish(), context,
              '#${_controller.backgroundColor.value.toRadixString(16)}'),
        ),
        new IconButton(
            icon: new Icon(
              Icons.undo,
            ),
            color: Colors.black,
            tooltip: 'Undo',
            onPressed: () {
              if (_controller.isEmpty) {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) =>
                        new Text('Nothing to undo'));
              } else {
                _controller.undo();
              }
            }),
        /*new IconButton(
            icon: new Icon(Icons.delete),
            tooltip: 'Clear',
            color: Colors.black,
            onPressed: _controller.clear),*/
        /* new IconButton(
            icon: new Icon(Icons.check),
            color: Colors.black,
            onPressed: () => _show(_controller.finish(), context)),*/
      ];
    }
    return new Scaffold(
      key: ValueKey('2'),
      appBar: new AppBar(
          backgroundColor: _NewNotePageState.bgHexMain,
          leading: IconButton(
            onPressed: () {
              // Navigator.pop(context);
              state.setState(() {
                _NewNotePageState.scaffoldNoteTypePos = 0;
              });
            },
            icon: Icon(Icons.arrow_back),
            color: Colors.black,
          ),
          actions: actions,
          bottom: new PreferredSize(
            child: new DrawBar(_controller),
            preferredSize: new Size(MediaQuery.of(context).size.width, 30.0),
          )),
      body: new Center(child: new Painter(_controller)),
    );
  }

  void saveDrawingToDB(
      PictureDetails pictureDetails, BuildContext context, String bgHexStr) {
    print("inside saveDrawingToDB()");

    pictureDetails.toPNG().then((value) async {
      String base64Str = base64.encode(value);
      print("base64: $base64Str");
      print("bgHexStr: $bgHexStr");
      final noteDrawing =
          NotesModel("", "", "3", bgHexStr, "", base64Str, "", 0, 0);
      await insertDrawing(noteDrawing);
      Navigator.push(context, ScaleRoute(page: LandingPage()));
    });
  }

  Future<void> insertDrawing(NotesModel model) async {
    print("inside insertDrawing()");

    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    await notesDB.insert(
      'notes',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void _show(PictureDetails picture, BuildContext context) {
    setState(() {
      _finished = true;
    });
    Navigator.of(context)
        .push(new MaterialPageRoute(builder: (BuildContext context) {
      return new Scaffold(
        appBar: new AppBar(
          leading: IconButton(
            onPressed: () {},
            icon: Icon(Icons.home),
            color: Colors.black,
          ),
          backgroundColor: _NewNotePageState.bgHexMain,
          title: const Text('View your image'),
        ),
        body: new Container(
            alignment: Alignment.center,
            child: new FutureBuilder<Uint8List>(
              future: picture.toPNG(),
              builder:
                  (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return new Text('Error: ${snapshot.error}');
                    } else {
                      return Image.memory(snapshot.data);
                    }
                    break;
                  default:
                    return new Container(
                        child: new FractionallySizedBox(
                      widthFactor: 0.1,
                      child: new AspectRatio(
                          aspectRatio: 1.0,
                          child: new CircularProgressIndicator()),
                      alignment: Alignment.center,
                    ));
                }
              },
            )),
      );
    }));
  }
}

class DrawBar extends StatelessWidget {
  final PainterController _controller;

  DrawBar(this._controller);

  @override
  Widget build(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Flexible(child: new StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return new Container(
              child: new Slider(
            value: _controller.thickness,
            onChanged: (double value) => setState(() {
              _controller.thickness = value;
            }),
            min: 1.0,
            max: 20.0,
            inactiveColor: Colors.grey,
            activeColor: Colors.black,
          ));
        })),
        new StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return new RotatedBox(
              quarterTurns: _controller.eraseMode ? 2 : 0,
              child: IconButton(
                  icon: new Icon(Icons.create),
                  color: Colors.black,
                  tooltip: (_controller.eraseMode ? 'Disable' : 'Enable') +
                      ' eraser',
                  onPressed: () {
                    setState(() {
                      _controller.eraseMode = !_controller.eraseMode;
                    });
                  }));
        }),
        new ColorPickerButton(_controller, false),
        new ColorPickerButton(_controller, true),
      ],
    );
  }
}

class ColorPickerButton extends StatefulWidget {
  final PainterController _controller;
  final bool _background;

  ColorPickerButton(this._controller, this._background);

  @override
  _ColorPickerButtonState createState() => new _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton> {
  @override
  Widget build(BuildContext context) {
    return new IconButton(
        icon: new Icon(_iconData, color: Colors.black),
        tooltip: widget._background
            ? 'Change background color'
            : 'Change draw color',
        onPressed: _pickColor);
  }

  void _pickColor() {
    Color pickerColor = _NewNotePageState.bgHexMain;
    Navigator.of(this.context)
        .push(new MaterialPageRoute(
            fullscreenDialog: true,
            builder: (BuildContext context) {
              return new Scaffold(
                  appBar: new AppBar(
                    backgroundColor: _NewNotePageState.bgHexMain,
                    title: const Text('Pick color'),
                  ),
                  body: new Container(
                      alignment: Alignment.center,
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color c) => pickerColor = c,
                      )));
            }))
        .then((_) {
      setState(() {
        _color = pickerColor;
      });
    });
  }

  Color get _color => widget._background
      ? widget._controller.backgroundColor
      : widget._controller.drawColor;

  IconData get _iconData =>
      widget._background ? Icons.format_color_fill : Icons.brush;

  set _color(Color color) {
    if (widget._background) {
      widget._controller.backgroundColor = color;
    } else {
      widget._controller.drawColor = color;
    }
  }
}
