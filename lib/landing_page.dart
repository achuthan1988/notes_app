import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/models/LabelModel.dart';
import 'package:notes_app/models/NotesModel.dart';
import 'package:notes_app/util/HexColor.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'new_note_page.dart';
import 'util/constants.dart' as Constants;

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Future<Database> database;
  var notesDB;
  bool isToggleAppBar = false;
  bool isListPopulated = false;
  List<bool> longPressList = [];
  List<NotesModel> notesModelList = new List<NotesModel>();
  List<LabelModel> labelModelList = new List<LabelModel>();
  var sliderTitleArray = ["Home", "Edit Labels", "Settings"];
  var sliderIconsArray = [Icons.home_rounded, Icons.edit, Icons.settings];
  static int numOfNotesSelected = 0;
  var _defaultAppBar = AppBar(
    title: Text("Landing Page"),
  );
  var _selectedAppBar = AppBar(
    backgroundColor: Colors.white,
    leading: Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // set your alignment
        children: [
          Flexible(
            child: Icon(
              Icons.close,
              color: Colors.blue,
              size: 30.0,
            ),
          ),
          Spacer(),
          Flexible(
            child: Text(
              numOfNotesSelected.toString(),
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
    actions: [
      Flexible(
        child: Icon(
          Icons.label_outline,
          color: Colors.blue,
          size: 30.0,
        ),
      ),
      Flexible(
        child: Icon(
          Icons.color_lens_outlined,
          color: Colors.blue,
          size: 30.0,
        ),
      ),
      Flexible(
        child: Icon(
          Icons.more_vert,
          color: Colors.blue,
          size: 30.0,
        ),
      )
    ],
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    numOfNotesSelected = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: (!isToggleAppBar
            ? AppBar(
                title: Text("Landing Page"),
              )
            : AppBar(
                backgroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    // set your alignment
                    children: [
                      Flexible(
                        child: GestureDetector(
                          child: Icon(
                            Icons.close,
                            color: Colors.blue,
                            size: 30.0,
                          ),
                          onTap: () {
                            print("onTap of X button!");
                            setState(() {
                              isToggleAppBar = false;
                              numOfNotesSelected = 0;
                              longPressList = List<bool>.generate(
                                  notesModelList.length, (int index) => false);
                            });
                          },
                        ),
                      ),
                      Spacer(),
                      Flexible(
                        child: Text(
                          numOfNotesSelected.toString(),
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Flexible(
                    child: Icon(
                      Icons.label_outline,
                      color: Colors.blue,
                      size: 30.0,
                    ),
                  ),
                  Flexible(
                    child: GestureDetector(
                      child: Icon(
                        Icons.color_lens_outlined,
                        color: Colors.blue,
                        size: 30.0,
                      ),
                      onTap: () {
                        print("pallette icon clicked!!");
                      },
                    ),
                  ),
                  Flexible(
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.blue,
                      size: 30.0,
                    ),
                  )
                ],
              )),
        drawer: Drawer(
            child: Container(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: sliderTitleArray.length,
            itemBuilder: (ctx, index) {
              return GestureDetector(
                child: Container(
                  padding: EdgeInsets.all(3.0),
                  height: 25.0,
                  child: Row(
                      children: [
                        Icon(sliderIconsArray[index]),
                        Text('${sliderTitleArray[index]}'),
                      ],
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center),
                ),
                onTap: () {
                  if (index == 1) {
                    Navigator.pop(context);
                    showAddLabelDialog(context);
                  }
                },
              );
            },
            separatorBuilder: (context, index) {
              return Divider();
            },
          ),
        )),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
              return NewNotePage(null, null);
            }));
          },
          child: Icon(Icons.add),
          backgroundColor: Constants.bgMainColor,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: FutureBuilder<List>(
            future: initDB(),
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? GridView.builder(
                      padding: EdgeInsets.all(2.0),
                      itemBuilder: (context, position) {
                        return GestureDetector(
                          onTap: () {
                            NotesModel notesModel = notesModelList[position];
                            Navigator.push(
                                context,
                                ScaleRoute(
                                    page: NewNotePage(
                                        notesModel, 'heroTag $position')));
                          },
                          onLongPress: () {
                            print("inside onLongPress");
                            /*(1) set indicator to denote selection on note
                      (2) Update counter in new app bar , based on number of notes selected
                      (3) Click of close ('X') button , deselects all notes ,restores default app bar
                      (4) functionality for label icon , palette icon , options menu features , (multiple notes cases to be kept in mind)
                      (5)
                    * */
                            if (!longPressList[position]) {
                              setState(() {
                                longPressList[position] = true;
                                isToggleAppBar = true;
                                numOfNotesSelected += 1;
                              });
                            }
                          },
                          child: Hero(
                            tag: 'heroTag $position',
                            child: Stack(
                              children: [
                                Container(
                                  margin: EdgeInsets.all(3.0),
                                  padding: EdgeInsets.all(1.0),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                      color: HexColor(notesModelList[position]
                                          .noteBgColorHex)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Flexible(
                                              child: Container(
                                                padding: EdgeInsets.all(2.0),
                                                child: Text(
                                                  notesModelList[position]
                                                      .noteTitle,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 14.0,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(2.0),
                                              child: Text(
                                                notesModelList[position]
                                                    .noteContent,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 10,
                                                style: TextStyle(
                                                    fontSize: 12.0,
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.w300),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 2.0,
                                  child: Visibility(
                                    visible: longPressList[position],
                                    maintainState: true,
                                    maintainSize: true,
                                    maintainAnimation: true,
                                    child: Container(
                                        width: 15.0,
                                        height: 15.0,
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.black87,
                                        )),
                                  ), //CircularAvatar
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      shrinkWrap: true,
                      itemCount: notesModelList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 0.0,
                        mainAxisSpacing: 0.0,
                      ),
                    )
                  : Center(
                      child: Text(
                        "No Notes Added",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey),
                      ),
                    );
            }));
  }

/*  void _showPopupMenu(BuildContext context, Offset offset) async {
    double left = offset.dx;
    double top = offset.dy;
    await showMenu(
      position: RelativeRect.fromLTRB(left, top, 0, 0),
      context: context,
      items: [
        PopupMenuItem<String>(
            child: GestureDetector(
              child: const Text('Add Label'),
              onTapDown: (TapDownDetails details) {
                Navigator.pop(context);
                _showPopupLabels(context,offset);
              },
            ),
            value: 'dd Label'),
        PopupMenuItem<String>(
            child: const Text('Second dummy'), value: 'Second dummy'),
      ],
      elevation: 8.0,
    );
  }


  void _showPopupLabels(BuildContext context, Offset offset) async {
    double left = offset.dx;
    double top = offset.dy;
    await showMenu(
      position: RelativeRect.fromLTRB(left, top, 0, 0),
      context: context,
      items: [
        PopupMenuItem<String>(
            child: GestureDetector(
              child: const Text('child 1'),
              onTapDown: (TapDownDetails details) {
              },
            ),
            value: 'dd Label'),
        PopupMenuItem<String>(
            child: const Text('child 2'), value: 'Second dummy'),
      ],
      elevation: 8.0,
    );

  }*/

  void showAddLabelDialog(BuildContext context) {
    bool isNewNoteAdded = false;
    TextEditingController labelTitleController = new TextEditingController();
    List<bool> labelListCheckStateList =
        List<bool>.generate(labelModelList.length, (index) => false);

    List<TextEditingController> controllerList =
        List<TextEditingController>.generate(
            labelModelList.length, (index) => TextEditingController());

    ScrollController _controller = new ScrollController();

    LabelModel createNewLabelObject() {
      final labelObject = LabelModel(labelTitleController.text.toString());
      return labelObject;
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, _setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.0)),
              //this right here
              child: Container(
                height: 350,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Edit Labels",
                        style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                            fontWeight: FontWeight.w800),
                      ),
                      if (!isNewNoteAdded)
                        Container(
                          margin: EdgeInsets.only(top: 10.0),
                          child: Row(
                            children: [
                              GestureDetector(
                                child: Icon(Icons.add, color: Colors.black26),
                                onTap: () {
                                  print("Add new note clicked!");
                                  _setState(() {
                                    isNewNoteAdded = true;
                                  });
                                },
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "Add Label",
                                    style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.black26,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          margin: EdgeInsets.only(top: 10.0),
                          child: Row(
                            children: [
                              GestureDetector(
                                child: Icon(Icons.close, color: Colors.black26),
                                onTap: () {
                                  print("close note clicked!");
                                  _setState(() {
                                    isNewNoteAdded = false;
                                  });
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  onChanged: ((String txt) {
                                    print("Textfield onChanged String $txt");
                                  }),
                                  onTap: () {
                                    print("onTap()");
                                  },
                                  autofocus: true,
                                  maxLines: 1,
                                  controller: labelTitleController,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12.0,
                                      decorationColor: Colors.red,
                                      decorationStyle:
                                          TextDecorationStyle.solid,
                                      decoration: TextDecoration.none),
                                  decoration: InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                      border: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black),
                                      ),
                                      hintText: "Enter Label",
                                      hintStyle: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black26,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                              GestureDetector(
                                child: Icon(Icons.add, color: Colors.black26),
                                onTap: () {
                                  if (labelTitleController.text
                                      .toString()
                                      .trim()
                                      .isNotEmpty) {
                                    insertNewLabel(createNewLabelObject());
                                    labelListCheckStateList.add(false);
                                    controllerList.add(TextEditingController());
                                    labelTitleController.text = "";
                                    _setState(() {});
                                  } else
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text("Enter a label title"),
                                    ));
                                },
                              ),
                            ],
                            mainAxisAlignment: MainAxisAlignment.start,
                          ),
                        ),
                      Container(
                          height: 250.0,
                          margin: EdgeInsets.only(top: 10.0),
                          child: FutureBuilder(
                              future: getAllLabels(),
                              builder: (context, AsyncSnapshot snapshot) {
                                if (!snapshot.hasData) {
                                  return Center(child: Text(""));
                                } else {
                                  return Container(
                                    key: UniqueKey(),
                                    child: ListView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        itemCount: snapshot.data.length,
                                        scrollDirection: Axis.vertical,
                                        controller: _controller,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          print(
                                              "inside itemBuilder of Labels LIST");
                                          if (!labelListCheckStateList[index]) {
                                            return Container(
                                                key: UniqueKey(),
                                                child: Row(
                                                    key: UniqueKey(),
                                                    children: [
                                                      Icon(Icons.label,
                                                          color:
                                                              Colors.black26),
                                                      Expanded(
                                                        child: Center(
                                                          child: Text(
                                                            snapshot.data[index]
                                                                .labelTitle,
                                                            style: TextStyle(
                                                                fontSize: 12.0,
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800),
                                                          ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        child: Icon(Icons.edit,
                                                            color:
                                                                Colors.black26),
                                                        onTap: () {
                                                          print(
                                                              "edit clicked!");
                                                          labelListCheckStateList[
                                                              index] = true;
                                                          _setState(() {});
                                                        },
                                                      ),
                                                    ]));
                                          } else {
                                            return Container(
                                                key: UniqueKey(),
                                                child: Row(
                                                    key: UniqueKey(),
                                                    children: [
                                                      GestureDetector(
                                                        child: Icon(
                                                            Icons.delete,
                                                            color:
                                                                Colors.black26),
                                                        onTap: () {
                                                          deleteLabel(snapshot
                                                                  .data[index])
                                                              .then((val) {
                                                            if (val > 0) {
                                                              _setState(() {});
                                                            }
                                                          });
                                                        },
                                                      ),
                                                      Expanded(
                                                        child: TextField(
                                                          onChanged:
                                                              ((String txt) {}),
                                                          autofocus: true,
                                                          maxLines: 1,
                                                          controller:
                                                              controllerList[
                                                                  index]
                                                                ..text = snapshot
                                                                    .data[index]
                                                                    .labelTitle,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              fontSize: 12.0,
                                                              decorationColor:
                                                                  Colors.red,
                                                              decorationStyle:
                                                                  TextDecorationStyle
                                                                      .solid,
                                                              decoration:
                                                                  TextDecoration
                                                                      .none),
                                                          decoration:
                                                              InputDecoration(
                                                                  contentPadding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  isDense: true,
                                                                  border:
                                                                      UnderlineInputBorder(
                                                                    borderSide:
                                                                        BorderSide(
                                                                            color:
                                                                                Colors.black),
                                                                  ),
                                                                  hintText:
                                                                      "Enter Label",
                                                                  hintStyle: TextStyle(
                                                                      fontSize:
                                                                          12.0,
                                                                      color: Colors
                                                                          .black26,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600)),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                          child: Icon(
                                                              Icons.check,
                                                              color: Colors
                                                                  .black26),
                                                          onTap: () {
                                                            print(
                                                                "check clicked!");
                                                            /*
                                                          * (1) Update row in DB
                                                          * (2) refresh UI back to first type
                                                          * */

                                                            if (controllerList[
                                                                    index]
                                                                .text
                                                                .toString()
                                                                .trim()
                                                                .isNotEmpty) {
                                                              updateLabel(
                                                                      controllerList[
                                                                              index]
                                                                          .text,
                                                                      snapshot.data[
                                                                          index])
                                                                  .then((val) {
                                                                print(
                                                                    "row updation status value : $val");

                                                                if (val > 0) {
                                                                  labelListCheckStateList[
                                                                          index] =
                                                                      false;
                                                                  _setState(
                                                                      () {});
                                                                } else {
                                                                  //updation of row failed !
                                                                }
                                                              });
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      SnackBar(
                                                                content: Text(
                                                                    "Enter a label title"),
                                                              ));
                                                            }
                                                          }),
                                                    ]));
                                          }
                                        }),
                                  );
                                }
                              }))
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  Future<void> insertNewLabel(LabelModel model) async {
    print("inside insertNewLabel()");

    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));
    await notesDB.insert(
      'TblLabels',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateLabel(String updatedLabel, LabelModel model) async {
    print("inside updateLabel() modelID: ${model.id}");

    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    Map<String, dynamic> row = {'labelTitle': updatedLabel};

    int updateCount = await notesDB
        .update('TblLabels', row, where: 'id = ?', whereArgs: [model.id]);

    print("inside updateLabel updateCount: $updateCount");

    return updateCount;
  }

  Future<int> deleteLabel(LabelModel model) async {
    print("inside deleteLabel() modelID: ${model.id}");

    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));
    int count = await notesDB
        .rawDelete('DELETE FROM TblLabels WHERE id = ?', [model.id]);

    return count;
  }

  Future<List> initDB() async {
    WidgetsFlutterBinding.ensureInitialized();
// Open the database and store the reference.
    final Future<Database> database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), Constants.DB_NAME),

      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        print("inside onCreate()");
        notesDB = db;
        // Run the CREATE TABLE statement on the database.
        db.execute(
          "CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, noteTitle TEXT, noteContent TEXT, noteType TEXT, noteBgColorHex TEXT, noteMediaPath TEXT,  noteImgBase64 TEXT,noteLabelIdsStr TEXT)",
        );
        db.execute(
            "CREATE TABLE TblLabels(id INTEGER PRIMARY KEY AUTOINCREMENT, labelTitle TEXT)");
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    notesDB = database;

    notesModelList = await getAllNotes();
    labelModelList = await getAllLabels();

    if (!isListPopulated) {
      longPressList =
          List<bool>.generate(notesModelList.length, (int index) => false);
      isListPopulated = true;
    }
    return notesModelList;
  }

  Future<List<NotesModel>> getAllNotes() async {
    // Get a reference to the database.
    final Database db = await notesDB;

    // Query the table for all The Notes.
    final List<Map<String, dynamic>> maps = await db.query('notes');
    // Convert the List<Map<String, dynamic> into a List<NotesModel>.
    return List.generate(maps.length, (i) {
      return NotesModel(
          maps[i]['noteTitle'],
          maps[i]['noteContent'],
          maps[i]['noteType'],
          maps[i]['noteBgColorHex'],
          maps[i]['noteMediaPath'],
          maps[i]['noteImgBase64'],
          maps[i]['noteLabelIdsStr']);
    });
  }

  Future<List<LabelModel>> getAllLabels() async {
    print("inside getAllLabels()");
    // Get a reference to the database.
    final Database db = await notesDB;

    // Query the table for all The Labels.
    final List<Map<String, dynamic>> maps = await db.query('TblLabels');
    // Convert the List<Map<String, dynamic> into a List<Label>.
    print("getAllLabels size ${maps.length}");
    return List.generate(maps.length, (i) {
      return LabelModel.param(maps[i]['id'], maps[i]['labelTitle']);
    });
  }
}

class SizeRoute extends PageRouteBuilder {
  final Widget page;

  SizeRoute({this.page})
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
              Align(
            child: SizeTransition(
              sizeFactor: animation,
              child: child,
            ),
          ),
        );
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
                curve: Curves.fastOutSlowIn,
              ),
            ),
            child: child,
          ),
        );
}
