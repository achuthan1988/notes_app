import 'dart:convert';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:notes_app/archive_page.dart';
import 'package:notes_app/login.dart';
import 'package:notes_app/models/LabelModel.dart';
import 'package:notes_app/models/NotesModel.dart';
import 'package:notes_app/models/ReminderModel.dart';
import 'package:notes_app/trash_page.dart';
import 'package:notes_app/util/HexColor.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'new_note_page.dart';
import 'util/PositionSeekWidget.dart';
import 'util/constants.dart' as Constants;

class LandingPage extends StatefulWidget {
  // setTrashState() => createState().setTrashState();
  var base64Str;
  var userFirstName;
  String emailPattern =
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
      r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
      r"{0,253}[a-zA-Z0-9])?)*$";

  LandingPage(this.base64Str, this.userFirstName);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Future<Database> database;
  var notesDB;
  var profileBase64;
  bool isToggleAppBar = false;
  bool isListPopulated = false;
  bool isArchiveSection = false;
  bool isTrashActive = false;
  Widget pageWidget;
  TextEditingController _dateController = new TextEditingController();
  TextEditingController _timeController = new TextEditingController();
  TimeOfDay selectedTime = TimeOfDay.now();
  final GlobalKey<TrashPageState> _key = GlobalKey();
  List<bool> labelsCheckedList = [];
  List<Widget> sliderLabelWidgetList = [], reminderWidgetList = [];
  List<NotesModel> notesModelList = new List<NotesModel>();
  List<LabelModel> labelModelList = new List<LabelModel>();
  Map longPressedNotesMap = new Map();
  String dropDownValue = "Does not repeat";
  var sliderTitleArray = [
    "Home",
    "Edit Labels",
    "Archive",
    "Trash"
        "Sett"
        "ing"
        "s",
    ""
  ];
  var sliderIconsArray = [
    Icons.home_rounded,
    Icons.edit,
    Icons.archive_outlined,
    Icons.delete,
    Icons.settings
  ];
  static int numOfNotesSelected = 0;
  int drawerPosition = 0;
  int drawerLabelId = -1;
  String drawerLabelTitle = "";

  CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('UsersCollection');
  var sharedPref;
  File imageFile;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    new Future.delayed(Duration.zero, () async {
      initDB();
    });

    numOfNotesSelected = 0;
    drawerPosition = 0;

    // final cron = Cron()
    //   ..schedule(Schedule.parse('*/1 * * * * *'), () {
    //     print("inside cron job scheduler!");
    //     removeNotesFromDB();
    //   });
  }

  void removeNotesFromDB() {
    print("inside deleteOlderNotesFromDB()");

    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String currentDateTime = dateFormat.format(DateTime.now());
    print("currentDate: $currentDateTime");

    List<NotesModel> filteredList = notesModelList.where((notesModel) {
      return notesModel.isNoteTrashed == 1;
    });

    filteredList.forEach((notesModel) {
      String dateOfDeletion = notesModel.noteDateOfDeletion;
      DateTime dtOfDeletion = dateFormat.parse(dateOfDeletion);
      DateTime currentDT = dateFormat.parse(currentDateTime);
      if (currentDT.difference(dtOfDeletion).inDays >= 7) {
        notesDB.delete('notes', where: "id = ?", whereArgs: [notesModel.id]);
      }
    });
  }

  refresh() {
    print("inside refersh landing!");
    isTrashActive = true;
    isToggleAppBar = true;
    numOfNotesSelected++;
    setState(() {});
  }

  /* void setTrashState() {
    print("inside setTrashState()");
    isTrashActive = true;
    setState(() {
      getTrashState();
    });
  }

  bool getTrashState() {
    print("inside getTrashState()");
    return isTrashActive;
  }*/

  @override
  Widget build(BuildContext context) {
    print("inside build! landing page");

    return Scaffold(
      resizeToAvoidBottomInset: false,
      onDrawerChanged: (isOpened) async {
        if (isOpened) {
          labelModelList = await getAllLabels();
          notesModelList = await getAllNotes();
          reminderWidgetList = await getReminderWidgets();
          sliderLabelWidgetList = getLabelSliderWidgets();

          setState(() {});
        }
      },
      appBar: ((!isToggleAppBar && !isTrashActive)
          ? AppBar(
              title: (drawerLabelId == -1)
                  ? Text(sliderTitleArray[drawerPosition])
                  : Text(drawerLabelTitle),
              actions: [
                Flexible(
                  child: GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: (widget.base64Str.toString().isNotEmpty
                          ? Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                image: DecorationImage(
                                    image: Image.memory(
                                      base64.decode(widget.base64Str),
                                      fit: BoxFit.cover,
                                    ).image,
                                    fit: BoxFit.fill),
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ))
                          : Container(
                              width: 50,
                              height: 50,
                              child: CircleAvatar(
                                backgroundColor: Colors.blueGrey,
                                child: Text(
                                  widget.userFirstName
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 26.0, color: Colors.white60),
                                ),
                                maxRadius: 30,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ))),
                    ),
                    onTap: () {
                      print("profile icon onTap!!");
                    },
                    onTapDown: (TapDownDetails details) {
                      print("profile icon onTapDown!!");
                      _showProfileMenu(details.globalPosition, context);
                    },
                  ),
                ),
              ],
            )
          : ((isToggleAppBar && !isTrashActive)
              ? AppBar(
                  backgroundColor: Colors.white,
                  leading: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      // set your alignment
                      children: [
                        GestureDetector(
                          child: Flexible(
                            child: GestureDetector(
                              child: Icon(
                                Icons.close,
                                color: Colors.blue,
                                size: 25.0,
                              ),
                            ),
                          ),
                          onTap: () {
                            print("onTap of X button!");
                            setState(() {
                              isToggleAppBar = false;
                              numOfNotesSelected = 0;
                              notesModelList.forEach((notesModel) {
                                longPressedNotesMap[notesModel.id] = false;
                              });
                            });
                          },
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
                    Visibility(
                      child: Flexible(
                        child: GestureDetector(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.group_add,
                              color: Colors.blue,
                              size: 30.0,
                            ),
                          ),
                          onTap: () {
                            print("colab icon clicked!!");

                            longPressedNotesMap.keys.forEach((keyVal) {
                              if (longPressedNotesMap[keyVal]) {
                                notesModelList.forEach((element) {
                                  if (keyVal == element.id) {
                                    showCollabDialog(context, element);
                                  }
                                });
                              }
                            });
                            /*
                            * (1) Show alert with owner image ,name & email
                            * id (Full screen page , slide up from bottom)
                            * (2) Adding a new collaborator , based on
                            * whether its valid email
                            * (3) On saving the alert the ids get comma
                            * separated in the note user Ids
                            * (4) UI Shows avatar tags of owner for other
                            * collaborators, owner sees all collaborators as
                            * tags
                            * (5) +N as used for tags to be used here for
                            * overflow of avatar tags.
                            * (6)
                            *
                            *
                            * */
                          },
                        ),
                      ),
                      visible: (numOfNotesSelected <= 1),
                    ),
                    Flexible(
                      child: GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            (isNotesUnpinned()
                                ? Icons.push_pin
                                : Icons.push_pin_outlined),
                            color: Colors.blue,
                            size: 30.0,
                          ),
                        ),
                        onTap: () {
                          print("pin icon clicked!!");

                          List<String> idList = [];
                          longPressedNotesMap.keys.forEach((keyVal) {
                            if (longPressedNotesMap[keyVal])
                              idList.add(keyVal.toString());
                          });

                          if (isNotesUnpinned()) {
                            updatePinnedStateRows(1, idList);
                          } else {
                            updatePinnedStateRows(0, idList);
                          }
                        },
                      ),
                    ),
                    Visibility(
                      child: Flexible(
                        child: GestureDetector(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.notification_add,
                              color: Colors.blue,
                              size: 25.0,
                            ),
                          ),
                          onTap: () {
                            /* => Alert for reminders display
                          *   (1) get current time
                          *   (2) grey out duration values in dropdown based
                          * on above value.
                          *   (3)
                          *
                          * */
                            showReminderDialog(context, null);
                          },
                        ),
                      ),
                      visible: (numOfNotesSelected <= 1),
                    ),
                    Flexible(
                      child: GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.archive_outlined,
                            color: Colors.blue,
                            size: 25.0,
                          ),
                        ),
                        onTap: () {
                          /*
                      * (1) Get all note objects long pressed and change flag
                      *  state to 1 in DB.
                      * (2) refresh ui state
                      * (3) show snackbar for a fixed duration with UNDO option
                      * (4) If UNDO pressed restoration of those notes
                      * archived in step (1) by change of state in DB and UI.
                      * */
                          List<String> idList = [];
                          longPressedNotesMap.keys.forEach((keyVal) {
                            if (longPressedNotesMap[keyVal])
                              idList.add(keyVal.toString());
                          });
                          updateArchivedStateRows(1, idList, context);
                        },
                      ),
                    ),
                    Flexible(
                      child: GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.label_outline,
                            color: Colors.blue,
                            size: 25.0,
                          ),
                        ),
                        onTap: () {
                          print("label onTap pressed");
                          /*
                        * (1) show a dialog with UI as per set requirement
                        * (done)
                        * (2) Populate based on entries in Labels table (done)
                        * (3) attaching a note(s) with labels and updating in
                        *  DB (done)
                        * (4) displaying button tags(needs to be seen whether
                        *  to display button tags in landing/detailed because
                        *  of spacing constraints).(done)
                        * (5) Sidebar also has the list of labels, click
                        * displays notes for each label.(dynamic sidebar).
                        * (6)
                        *
                        * */

                          showLabelsDialog(context);
                        },
                      ),
                    ),
                    Flexible(
                      child: GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.color_lens_outlined,
                            color: Colors.blue,
                            size: 25.0,
                          ),
                        ),
                        onTap: () {
                          print("pallette icon clicked!!");

                          /*
                        * (1) Show all constant 8 colors as circles , inside
                        * an alert dialog, with no button
                        * (2) All long pressed notes to be updated with the
                        * selected hex color in Table.
                        * (3) UI to reflect the new BG color for all relevant
                        *  notes.
                        *
                        * */

                          showColorPaletteDialog(context);
                        },
                      ),
                    ),
                    Flexible(
                      child: GestureDetector(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.delete,
                            color: Colors.blue,
                            size: 25.0,
                          ),
                        ),
                        onTap: () {
                          print("delete icon clicked!!");
                          List<String> idList = [];
                          longPressedNotesMap.keys.forEach((keyVal) {
                            if (longPressedNotesMap[keyVal])
                              idList.add(keyVal.toString());
                          });

                          DateFormat dateFormat =
                              DateFormat("yyyy-MM-dd HH:mm:ss");
                          String currentDateTime =
                              dateFormat.format(DateTime.now());
                          sendToTrash(context, 1, idList, currentDateTime);
                        },
                      ),
                    )
                  ],
                )
              : ((isToggleAppBar && isTrashActive))
                  ? AppBar(
                      backgroundColor: Colors.white,
                      leading: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          // set your alignment
                          children: [
                            GestureDetector(
                              child: Flexible(
                                child: GestureDetector(
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.blue,
                                    size: 25.0,
                                  ),
                                ),
                              ),
                              onTap: () {
                                print("onTap of X button!");
                                setState(() {
                                  _key.currentState.refresh();
                                  isTrashActive = false;
                                  isToggleAppBar = false;
                                  numOfNotesSelected = 0;
                                  notesModelList.forEach((notesModel) {
                                    longPressedNotesMap[notesModel.id] = false;
                                  });
                                });
                              },
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
                          child: GestureDetector(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Icon(
                                Icons.restore_from_trash,
                                color: Colors.blue,
                                size: 25.0,
                              ),
                            ),
                            onTap: () {
                              print("restore icon clicked!!");
                              _key.currentState.setup(context, 0);
                              setState(() {
                                isToggleAppBar = false;
                                isTrashActive = false;
                                numOfNotesSelected = 0;
                                notesModelList.forEach((notesModel) {
                                  longPressedNotesMap[notesModel.id] = false;
                                });
                              });
                            },
                          ),
                        ),
                        Flexible(
                          child: GestureDetector(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Icon(
                                  Icons.delete_forever,
                                  color: Colors.blue,
                                  size: 25.0,
                                ),
                              ),
                              onTap: () {
                                print("delete forever icon clicked!!");
                                showDeleteForever(context);
                              }),
                        ),
                      ],
                    )
                  : AppBar(
                      title: (drawerLabelId == -1)
                          ? Text(sliderTitleArray[drawerPosition])
                          : Text(drawerLabelTitle),
                    ))),
      drawer: Drawer(
          child: Container(
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: sliderTitleArray.length,
          itemBuilder: (ctx, index) {
            return InkWell(
              child: Container(
                padding: EdgeInsets.all(3.0),
                height: (index != 4
                    ? 25.0
                    : (sliderLabelWidgetList.length > 0
                        ? sliderLabelWidgetList.length * 30.0
                        : 0.0)),
                child: (index != 4
                    ? Row(
                        children: [
                            Icon(sliderIconsArray[index]),
                            SizedBox(
                                child: Text('${sliderTitleArray[index]}',
                                    overflow: TextOverflow.ellipsis),
                                width: 150),
                          ],
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center)
                    : Visibility(
                        child: Container(
                          height: (sliderLabelWidgetList.length > 0
                              ? sliderLabelWidgetList.length * 40.0
                              : 0.0),
                          child: Wrap(
                            children: [
                              Divider(
                                color: Colors.grey[600],
                              ),
                              ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: sliderLabelWidgetList.length,
                                  itemBuilder: (context, position) {
                                    return GestureDetector(
                                      child: sliderLabelWidgetList[position],
                                      onTap: () {
                                        print("inside onTap() of ListView!!"
                                            " $position");
                                        drawerLabelId =
                                            labelModelList[position].id;
                                        drawerLabelTitle =
                                            labelModelList[position].labelTitle;
                                        print("inside label click "
                                            "drawerLabelId: $drawerLabelId");
                                        Navigator.pop(context);

                                        setState(() {});
                                      },
                                    );
                                  }),
                            ],
                          ),
                        ),
                        visible: sliderLabelWidgetList.length > 0,
                      )),
              ),
              onTap: () {
                drawerPosition = index;
                Navigator.pop(context);
                if (drawerPosition == 1) {
                  showAddLabelDialog(context, this);
                } else {
                  if (drawerPosition == 0) drawerLabelId = -1;
                  setState(() {
                    pageWidget = switchDrawerWidget();
                  });
                }
              },
            );
          },
          separatorBuilder: (context, index) {
            return Divider(
              color: Colors.transparent,
            );
          },
        ),
      )),
      floatingActionButton: Visibility(
        visible: !isArchiveSection && (drawerPosition != 3),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (BuildContext context) {
              return NewNotePage(null);
            }));
          },
          child: Icon(Icons.add),
          backgroundColor: Constants.bgMainColor,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ((drawerPosition == 0 || drawerPosition == 1)
          ? (FutureBuilder<List>(
              future: initDB(),
              builder: (context, snapshot) {
                print("inside builder of FutureBuilder ${snapshot.hasData}");
                if (snapshot.data != null && snapshot.data.isNotEmpty)
                  return SingleChildScrollView(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: (notesModelList.every(
                                (notesModel) => (notesModel.isNotePinned == 0))
                            ? false
                            : true),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  "Pinned",
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            GridView(
                                padding: EdgeInsets.all(2.0),
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 2.0,
                                  mainAxisSpacing: 2.0,
                                ),
                                children: List.generate(
                                    notesModelList
                                        .where((i) => (i.isNotePinned == 1 &&
                                            i.isNoteArchived == 0))
                                        .toList()
                                        .length, (position) {
                                  print("inside itemBuilder of GridView");
                                  List<NotesModel> filteredList = notesModelList
                                      .where((i) => (i.isNotePinned == 1 &&
                                          i.isNoteArchived == 0))
                                      .toList();
                                  List<Widget> widgetList = [];

                                  widgetList = getLabelTagWidgets(
                                      filteredList[position],
                                      filteredList[position].noteBgColorHex);

                                  print("inside itemBuilder widgetList.length "
                                      "${widgetList.length}");

                                  return GestureDetector(
                                      onTap: () => Navigator.push(
                                          context,
                                          ScaleRoute(
                                              page: NewNotePage(
                                                  filteredList[position]))),
                                      onLongPress: () {
                                        print(
                                            "inside onLongPress longPressList[position]");

                                        if (!longPressedNotesMap[
                                            filteredList[position].id]) {
                                          setState(() {
                                            longPressedNotesMap[
                                                    filteredList[position].id] =
                                                true;
                                            isToggleAppBar = true;
                                            numOfNotesSelected += 1;
                                          });
                                        }
                                        Hero(
                                          tag: 'heroTag $position',
                                          child: Stack(
                                            children: [
                                              Container(
                                                margin: EdgeInsets.all(3.0),
                                                padding: EdgeInsets.all(1.0),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                7.0)),
                                                    color: HexColor(
                                                        filteredList[position]
                                                            .noteBgColorHex)),
                                                child: (filteredList[position]
                                                            .noteType ==
                                                        "0"
                                                    ? Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.black,
                                                              border:
                                                                  Border.all(
                                                                      width: 0),
                                                            ),
                                                            padding:
                                                                EdgeInsets.all(
                                                                    2.0),
                                                            child: Text(
                                                              filteredList[
                                                                      position]
                                                                  .noteTitle,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      14.0,
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                          ),
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.black,
                                                              border:
                                                                  Border.all(
                                                                      width: 0),
                                                            ),
                                                            padding:
                                                                EdgeInsets.all(
                                                                    2.0),
                                                            child: Text(
                                                              filteredList[
                                                                      position]
                                                                  .noteContent,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 10,
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      12.0,
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300),
                                                            ),
                                                          ),
                                                          Container(
                                                            child: Align(
                                                              alignment: Alignment
                                                                  .bottomLeft,
                                                              child: Wrap(
                                                                children:
                                                                    widgetList,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : changeNoteCell(
                                                        filteredList[
                                                            position])),
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: 2.0,
                                                child: Visibility(
                                                  visible: longPressedNotesMap[
                                                      filteredList[position]
                                                          .id],
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
                                        );
                                      });
                                })),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: (notesModelList.every((notesModel) =>
                                (notesModel.isNotePinned == 1 &&
                                    notesModel.isNoteArchived == 0))
                            ? false
                            : true),
                        child: Column(
                          children: [
                            Visibility(
                              visible: (notesModelList.every((notesModel) =>
                                      notesModel.isNotePinned == 0 &&
                                      notesModel.isNoteArchived == 0)
                                  ? false
                                  : true),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Text(
                                    "Others",
                                    style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                            GridView(
                                padding: EdgeInsets.all(2.0),
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 2.0,
                                  mainAxisSpacing: 2.0,
                                ),
                                children: List.generate(
                                    notesModelList
                                        .where((i) =>
                                            i.isNotePinned == 0 &&
                                            i.isNoteArchived == 0)
                                        .toList()
                                        .length, (position) {
                                  print("inside itemBuilder of GridView");
                                  List<NotesModel> filteredList = notesModelList
                                      .where((i) =>
                                          i.isNotePinned == 0 &&
                                          i.isNoteArchived == 0)
                                      .toList();

                                  List<Widget> widgetList = [];
                                  widgetList = getLabelTagWidgets(
                                      filteredList[position],
                                      filteredList[position].noteBgColorHex);

                                  print("inside itembuilder widgetList "
                                      "size: ${widgetList.length}");

                                  return GestureDetector(
                                    onTap: () {
                                      NotesModel notesModel =
                                          filteredList[position];
                                      Navigator.push(
                                          context,
                                          ScaleRoute(
                                              page: NewNotePage(notesModel)));
                                    },
                                    onLongPress: () {
                                      print(
                                          "inside onLongPress longPressList[position]");

                                      if (!longPressedNotesMap[
                                          filteredList[position].id]) {
                                        setState(() {
                                          longPressedNotesMap[
                                              filteredList[position].id] = true;
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
                                                color: HexColor(
                                                    filteredList[position]
                                                        .noteBgColorHex)),
                                            child: (filteredList[position]
                                                        .noteType ==
                                                    "0"
                                                ? Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Visibility(
                                                        child: (filteredList[
                                                                    position]
                                                                .noteMediaPath
                                                                .isEmpty
                                                            ? Container()
                                                            : Container(
                                                                height: 70.0,
                                                                width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width,
                                                                child: Padding(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                            2),
                                                                    child: GridView
                                                                        .builder(
                                                                      itemCount: filteredList[
                                                                              position]
                                                                          .noteMediaPath
                                                                          .split(
                                                                              ",")
                                                                          .length,
                                                                      gridDelegate:
                                                                          SliverGridDelegateWithFixedCrossAxisCount(
                                                                              crossAxisCount: 3),
                                                                      shrinkWrap:
                                                                          true,
                                                                      itemBuilder:
                                                                          (BuildContext context,
                                                                              int index) {
                                                                        return Padding(
                                                                          padding:
                                                                              const EdgeInsets.all(1.0),
                                                                          child:
                                                                              Stack(
                                                                            children: <Widget>[
                                                                              GestureDetector(
                                                                                child: Container(
                                                                                  color: Constants.bgWhiteColor.withOpacity(0.3),
                                                                                  child: Center(
                                                                                    child: Image.file(
                                                                                      File(
                                                                                        filteredList[position].noteMediaPath.split(",")[index],
                                                                                      ),
                                                                                      fit: BoxFit.cover,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                onTap: () {
                                                                                  Navigator.push(
                                                                                      context,
                                                                                      MaterialPageRoute(
                                                                                        builder: (context) => NewNotePage(
                                                                                          filteredList[position],
                                                                                        ),
                                                                                      ));
                                                                                },
                                                                              ),
                                                                              /*Positioned(
                                                                                          right: 1.0,
                                                                                          top: 1.0,
                                                                                          child: GestureDetector(
                                                                                            child: Container(
                                                                                              child: Icon(
                                                                                                Icons.delete,
                                                                                                color: Colors.white,
                                                                                                size: 12.0,
                                                                                              ),
                                                                                              color: Colors.black87.withOpacity(0.6),
                                                                                            ),
                                                                                            onTap: () {
                                                                                              print("delete button "
                                                                                                  "clicked at $index");
                                                                                              filteredList[position].noteMediaPath.split(",").removeAt(index);
                                                                                              setState(() {});
                                                                                            },
                                                                                          ),
                                                                                        )*/
                                                                            ],
                                                                          ),
                                                                        );
                                                                      },
                                                                    )),
                                                              )),
                                                        visible: (filteredList[
                                                                position]
                                                            .noteMediaPath
                                                            .isNotEmpty),
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .transparent,
                                                          border: Border.all(
                                                              width: 0,
                                                              color: Colors
                                                                  .transparent),
                                                        ),
                                                        padding:
                                                            EdgeInsets.all(2.0),
                                                        child: Text(
                                                          filteredList[position]
                                                              .noteTitle,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              fontSize: 14.0,
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                      ),
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .transparent,
                                                          border: Border.all(
                                                              width: 0,
                                                              color: Colors
                                                                  .transparent),
                                                        ),
                                                        padding:
                                                            EdgeInsets.all(2.0),
                                                        child: Text(
                                                          filteredList[position]
                                                              .noteContent,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 10,
                                                          style: TextStyle(
                                                              fontSize: 12.0,
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Align(
                                                          alignment: Alignment
                                                              .bottomLeft,
                                                          child: Wrap(
                                                            children:
                                                                widgetList,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : changeNoteCell(
                                                    filteredList[position])),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 2.0,
                                            child: Visibility(
                                              visible: longPressedNotesMap[
                                                  filteredList[position].id],
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
                                })),
                          ],
                        ),
                      ),
                    ],
                  ));
                else
                  return Align(
                    alignment: Alignment.center,
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        return Container(
                          height: constraints.maxHeight,
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                            child: Column(
                              children: [
                                Icon(MdiIcons.note,
                                    size: 100.0, color: Colors.grey[400]),
                                Center(
                                  child: Text(
                                    "No Notes Added",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[400]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
              }))
          : pageWidget),
    );
  }

  Widget _getCollabCardWidget() {
    return Card(
      child: Column(
        children: [
          Text('name'),
          Text('standard'),
          Text('Roll No'),
        ],
      ),
    );
  }

  showCollabDialog(BuildContext context, NotesModel model) async {
    bool isEmailSearching = false, isEmailInUse = false;
    List<Widget> _collabCardList = [];
    String ownerID = (model.userId.contains("||")
        ? model.userId.split("||")[0]
        : model.userId);
    print("ownerId $ownerID");
    QuerySnapshot querySnap =
        await usersCollection.where('userId', isEqualTo: ownerID).get();
    QueryDocumentSnapshot doc = querySnap.docs[0];

    String userFullName = doc['userFullName'];
    String userEmailId = doc['userEmailId'];
    String base64Str = doc['noteContent'];

    print("name,email,base64: $userFullName $userEmailId $base64Str");

    final _formKey = GlobalKey<FormState>();
    TextEditingController emailController = TextEditingController();
    String errorMsg;
    showMaterialModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) => StatefulBuilder(builder: (ctx, _setStateOuter) {
        return Container(
          padding: EdgeInsets.all(10.0),
          height: 600.0,
          color: Colors.white30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Collaborators',
                style: TextStyle(
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    fontSize: 16.0),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Divider(
                  color: Colors.grey[400],
                  height: 3,
                ),
              ),
              SizedBox(
                height: 60.0,
                child: Container(
                  height: 60.0,
                  width: MediaQuery.of(context).size.width,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                image: DecorationImage(
                                    image: Image.memory(
                                      base64.decode(base64Str),
                                      fit: BoxFit.cover,
                                    ).image,
                                    fit: BoxFit.fill),
                                color: Colors.white,
                                shape: BoxShape.circle,
                              )),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 10.0, left: 10.0),
                            child: Container(
                              height: 30.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        userFullName,
                                        style: TextStyle(
                                            decoration: TextDecoration.none,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                            fontSize: 12.0),
                                      ),
                                      Text(
                                        ' (Owner)',
                                        style: TextStyle(
                                            decoration: TextDecoration.none,
                                            fontWeight: FontWeight.w300,
                                            color: Colors.black,
                                            fontStyle: FontStyle.italic,
                                            fontSize: 9.0),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    userEmailId,
                                    style: TextStyle(
                                        decoration: TextDecoration.none,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black38,
                                        fontSize: 10.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Visibility(
                child: LimitedBox(
                  maxHeight: 200.0,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _collabCardList.length,
                    itemBuilder: (context, index) {
                      return _collabCardList[index];
                    },
                  ),
                ),
                visible: (_collabCardList.length > 0),
              ),
              SizedBox(
                height: 60.0,
                child: Container(
                  height: 60.0,
                  width: MediaQuery.of(context).size.width,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.black26,
                              ),
                            ),
                            /*decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        image: DecorationImage(
                                            image: MaterialI
                                            fit: BoxFit.scaleDown),
                                        color: Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),*/
                          ),
                        ),
                        Expanded(
                          child: StatefulBuilder(builder: (ctx, _setState) {
                            return Container(
                              height: 75.0,
                              child: IntrinsicHeight(
                                child: Form(
                                  key: _formKey,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                          child: TextFormField(
                                        controller: emailController,
                                        validator: (txtVal) {
                                          String valmsg;
                                          if (!RegExp(widget.emailPattern)
                                              .hasMatch(txtVal)) {
                                            valmsg = "Invalid email id";
                                          } else if (!isEmailInUse) {
                                            valmsg = "Email id "
                                                "not found.";
                                          }
                                          return valmsg;
                                        },
                                        onChanged: (text) {
                                          print("in onChanged!");

                                          if (text.length > 0)
                                            isEmailSearching = true;
                                          else
                                            isEmailSearching = false;

                                          _setState(() {});
                                        },
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.normal,
                                        ),
                                        decoration: InputDecoration(
                                            hintText: 'Enter email address',
                                            alignLabelWithHint: true,
                                            errorStyle: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            hintStyle: TextStyle(
                                              color: Colors.black26,
                                              fontSize: 12.0,
                                              fontStyle: FontStyle.italic,
                                            )),
                                      )),
                                      Visibility(
                                        visible: isEmailSearching,
                                        child: IconButton(
                                            onPressed: () async {
                                              _collabCardList.forEach((widget) {
                                                String key =
                                                    (widget.key as ValueKey)
                                                        .value
                                                        .toString();

                                                print("widgetKey $key");
                                              });

                                              isEmailInUse =
                                                  await checkIfEmailInUse(
                                                      emailController
                                                          .value.text);
                                              print("iconbutton "
                                                  "onPressed!");
                                              final FormState form =
                                                  _formKey.currentState;
                                              if (form.validate()) {
                                                print('form valid!');

                                                // text in form is valid
                                                QuerySnapshot querySnap =
                                                    await usersCollection
                                                        .where('userEmailId',
                                                            isEqualTo:
                                                                emailController
                                                                    .value.text)
                                                        .get();
                                                QueryDocumentSnapshot doc =
                                                    querySnap.docs[0];

                                                _collabCardList.add(Card(
                                                  key: ValueKey(emailController
                                                      .value.text),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(5.0),
                                                        child: Container(
                                                            width: 50,
                                                            height: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey),
                                                              image:
                                                                  DecorationImage(
                                                                      image: Image
                                                                          .memory(
                                                                        base64.decode(
                                                                            doc['noteContent']),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ).image,
                                                                      fit: BoxFit
                                                                          .fill),
                                                              color:
                                                                  Colors.white,
                                                              shape: BoxShape
                                                                  .circle,
                                                            )),
                                                      ),
                                                      Flexible(
                                                        child: Text(
                                                          doc['userEmailId'],
                                                          style: TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .none,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 12.0),
                                                        ),
                                                      ),
                                                      Spacer(),
                                                      IconButton(
                                                          onPressed: () async {
                                                          // print("clickedIndex"
                                                          //     " $index")
                                                            /*_collabCardList.forEach((card) {

                                                              String
                                                              widgetKey = (card.key
                                                              as ValueKey)
                                                                  .value
                                                                  .toString();

                                                              print
                                                                ("widgetKey :"
                                                                  " "
                                                                  "$widgetKey");

                                                              if((card.key
                                                              as ValueKey)
                                                                  .value
                                                                  .toString() ==
                                                                  emailController
                                                                      .value
                                                                      .text){

                                                                _collabCardList.remove(card);
                                                              }

                                                            });

                                                            for(int i=0;
                                                            i<_collabCardList
                                                                .length;i++){

                                                              if(
                                                              (_collabCardList[i].key
                                                              as ValueKey)
                                                                  .value
                                                                  .toString() ==
                                                                  emailController
                                                                      .value
                                                                      .text){

                                                                _collabCardList.removeAt(i);
                                                              }

                                                            }

                                                            print(
                                                                "_collabCardList.length:${_collabCardList.length}");
                                                            _setStateOuter(
                                                                () {});*/

                                                          },
                                                          icon: Icon(
                                                            Icons.close,
                                                            size: 24.0,
                                                            color: Colors.black,
                                                          )),
                                                    ],
                                                  ),
                                                ));
                                                _setStateOuter(() {
                                                  emailController.clear();
                                                });
                                              } else {
                                                print('form invalid!');
                                              }
                                              //TODO check existence in
                                              // AUTH DB
                                            },
                                            icon: Icon(
                                              Icons.check,
                                              size: 24.0,
                                              color: Colors.black26,
                                            )),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      }),
    );
  }

  // Returns true if email address is in use.
  Future<bool> checkIfEmailInUse(String emailAddress) async {
    print("checkIfEmailInUse $emailAddress");
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
        print("checkIfEmailInUse email not found!");
        // Return false because email address is not in use
        return false;
      }
    } catch (error) {
      print("checkIfEmailInUse catch block");
      return true;
    }
  }

  /* Future<bool> isEmailExistsInDB(String email, String password) async {
    print("in isEmailExistsInDB");
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: email)
          .then((value) {});
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('Email already in use');
        return true;
      }
    }

    return false;
  }*/

/*  String getExceptionText(Exception e) {
    print("inside getExceptionText");
    if (e is PlatformException) {
      print("inside getExceptionText msg ${e.message}");
      switch (e.message) {
        case 'There is no user record corresponding to this identifier. The user may have been deleted.':
          return 'User with this e-mail not found.';
          break;
        case 'The password is invalid or the user does not have a password.':
          return 'Invalid password.';
          break;
        case 'A network error (such as timeout, interrupted connection or unreachable host) has occurred.':
          return 'No internet connection.';
          break;
        case 'The email address is already in use by another account.':
          return 'Email address is already taken.';
          break;
        default:
          return 'Unknown error occured.';
      }
    } else {
      return 'Unknown error occured.';
    }
  }*/

  showReminderDialog(BuildContext context, ReminderModel model) {
    int currentTimeInMillis = DateTime.now().millisecondsSinceEpoch;
    print("currentTimeInMillis: $currentTimeInMillis");

    if (model != null) {
      _dateController.value = TextEditingValue(text: model.reminderDate);
      _timeController.value = TextEditingValue(text: model.reminderTime);
    } else {
      _dateController.value =
          TextEditingValue(text: Jiffy(DateTime.now()).yMMMd);
      _timeController.value =
          TextEditingValue(text: TimeOfDay.now().format(context));
    }

    // set up the AlertDialog
    // show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ButtonBarTheme(
          data: ButtonBarThemeData(alignment: MainAxisAlignment.center),
          child: WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: StatefulBuilder(builder: (context, _mainSetState) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(((model != null
                          ? "Update Reminder"
                          : "Set Reminder"))),
                      SizedBox(
                        height: 10,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                              child: AbsorbPointer(
                                  child: TextField(
                                textAlign: TextAlign.center,
                                enabled: false,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.all(5.0),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Icon(
                                      Icons.calendar_today_rounded,
                                      size: 30.0,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  border: OutlineInputBorder(),
                                  prefixIconConstraints:
                                      BoxConstraints(minWidth: 0, minHeight: 0),
                                  isDense: true,
                                ),
                                controller: _dateController,
                              )),
                              onTap: () {
                                _selectDate(context);
                              }),
                          SizedBox(
                            height: 10,
                          ),
                          GestureDetector(
                              child: AbsorbPointer(
                                  child: TextField(
                                textAlign: TextAlign.center,
                                enabled: false,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.all(5.0),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Icon(
                                      Icons.alarm,
                                      size: 30.0,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  border: OutlineInputBorder(),
                                  prefixIconConstraints:
                                      BoxConstraints(minWidth: 0, minHeight: 0),
                                  isDense: true,
                                ),
                                controller: _timeController,
                              )),
                              onTap: () {
                                _selectTime(context);
                              }),
                          SizedBox(
                            height: 10,
                          ),
                          DropdownButtonFormField(
                            isExpanded: true,
                            value: dropDownValue,
                            onChanged: (newValue) {
                              print("inside onChanged!: "
                                  "$newValue");
                              dropDownValue = newValue;
                              _mainSetState(() {});
                            },
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(5.0),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Icon(
                                  Icons.repeat,
                                  size: 30.0,
                                  color: Colors.grey[400],
                                ),
                              ),
                              border: OutlineInputBorder(),
                              prefixIconConstraints:
                                  BoxConstraints(minWidth: 0, minHeight: 0),
                              isDense: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                child: Center(
                                  child: Text("Does not repeat"),
                                ),
                                value: "Does not repeat",
                              ),
                              DropdownMenuItem(
                                child: Center(child: Text("Daily")),
                                value: "Daily",
                              ),
                              DropdownMenuItem(
                                child: Center(child: Text("Weekly")),
                                value: "Weekly",
                              ),
                              DropdownMenuItem(
                                child: Center(child: Text("Monthly")),
                                value: "Monthly",
                              ),
                              DropdownMenuItem(
                                child: Center(child: Text("Yearly")),
                                value: "Yearly",
                              ),
                            ],
                            hint: Center(child: Text("Select item")),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
              actions: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.20,
                      child: RaisedButton(
                        child: new Text(
                          'Close',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Constants.bgMainColor,
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(30.0),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.01,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.20,
                      child: RaisedButton(
                        child: new Text(
                          'Set',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Constants.bgMainColor,
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(30.0),
                        ),
                        onPressed: () {
                          /*(1) Insert
                                                    reminderDate,
                                                    reminderTime,
                                                    reminderInterval to
                                                    TblReminder
                                                    (2) notes table to have
                                                    id of reminder inserted
                                                    into it.

                                                    * */
                          Navigator.of(context).pop();

                          if (model != null) {
                            updateReminder(ReminderModel.param(
                                model.id,
                                _dateController.value.text,
                                _timeController.value.text,
                                dropDownValue));
                          } else {
                            insertNewReminder(ReminderModel(
                                _dateController.value.text,
                                _timeController.value.text,
                                dropDownValue));
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.height * 0.01,
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.20,
                      child: RaisedButton(
                        child: new Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Constants.bgMainColor,
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(30.0),
                        ),
                        onPressed: () {
                          /*
                          * (1) Delete row based on ID from TblReminders
                          * (2) Update reminderID in notes table to empty string
                          * */

                          deleteReminder(model);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  showDeleteForever(BuildContext context) {
    // set up the buttons
    Widget noButton = TextButton(
      child: Text("No"),
      onPressed: () {},
    );
    Widget yesButton = TextButton(
      child: Text("Yes"),
      onPressed: () {
        _key.currentState.setup(context, 1);
        Navigator.pop(context);
        setState(() {
          isToggleAppBar = false;
          isTrashActive = false;
          numOfNotesSelected = 0;
          notesModelList.forEach((notesModel) {
            longPressedNotesMap[notesModel.id] = false;
          });
        });
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Delete?"),
      content: Text("Do you want to permenantly delete these note(s)?."),
      actions: [
        noButton,
        yesButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _showProfileMenu(Offset offset, BuildContext context) async {
    double left = offset.dx;
    double top = offset.dy;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, 0, 0),
      items: [
        PopupMenuItem(
          value: 1,
          height: 0,
          padding: EdgeInsets.all(5.0),
          child: (widget.base64Str.toString().isNotEmpty
              ? Stack(
                  children: [
                    Center(
                      child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            image: DecorationImage(
                                image: Image.memory(
                                  base64.decode(widget.base64Str),
                                  fit: BoxFit.cover,
                                ).image,
                                fit: BoxFit.fill),
                            color: Colors.white,
                            shape: BoxShape.circle,
                          )),
                    ),
                    Positioned(
                        bottom: -10,
                        right: 10,
                        child: RawMaterialButton(
                          onPressed: () {},
                          elevation: 0.0,
                          fillColor: Colors.transparent,
                          child: SizedBox(
                              height: 20.0,
                              width: 20.0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                  size: 25.0,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showUpdateProfileDialog(
                                      context, widget.base64Str.toString());
                                },
                              )),
                          padding: EdgeInsets.all(2.0),
                          shape: CircleBorder(),
                        )),
                  ],
                )
              : Stack(
                  children: [
                    Center(
                      child: Container(
                          width: 75,
                          height: 75,
                          child: CircleAvatar(
                            backgroundColor: Colors.blueGrey,
                            child: Text(
                              widget.userFirstName
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                  fontSize: 30.0, color: Colors.white60),
                            ),
                            maxRadius: 30,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            color: Colors.white,
                            shape: BoxShape.circle,
                          )),
                    ),
                    Positioned(
                        bottom: -10,
                        right: 10,
                        child: RawMaterialButton(
                          onPressed: () {},
                          elevation: 0.0,
                          fillColor: Colors.transparent,
                          child: SizedBox(
                              height: 20.0,
                              width: 20.0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                  size: 25.0,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showUpdateProfileDialog(
                                      context, widget.base64Str.toString());
                                },
                              )),
                          padding: EdgeInsets.all(2.0),
                          shape: CircleBorder(),
                        )),
                  ],
                )),
        ),
        PopupMenuItem(
          value: 2,
          height: 0,
          padding: EdgeInsets.all(3.0),
          child: Center(
            child: Text(
              widget.userFirstName.toString(),
              style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                  color: Colors.black),
            ),
          ),
        ),
        PopupMenuItem(
            value: 3,
            height: 0,
            padding: EdgeInsets.zero,
            child: Center(
              child: Text(
                FirebaseAuth.instance.currentUser.email,
                style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.black38),
              ),
            )),
        PopupMenuItem(
            value: 4,
            height: 0,
            padding: EdgeInsets.zero,
            child: Center(
              child: OutlinedButton(
                onPressed: () {
                  // set up the buttons
                  Widget cancelButton = TextButton(
                    child: Text("No"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  );
                  Widget continueButton = TextButton(
                    child: Text("Yes"),
                    onPressed: () async {
                      await clearAllData();
                      SharedPreferences _prefs =
                          await SharedPreferences.getInstance();
                      _prefs.clear();
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                  );
                  AlertDialog alert = AlertDialog(
                    title: Text("Logout?"),
                    content: Text("Do you want to logout?"),
                    actions: [
                      cancelButton,
                      continueButton,
                    ],
                  );
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) => alert);
                },
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0))),
                ),
                child: Text(
                  "Logout",
                  style: TextStyle(
                      color: Constants.bgMainColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
            )),
      ],
      elevation: 8.0,
    );
  }

  Future<void> clearAllData() async {
    await notesDB.rawQuery("DELETE FROM notes");
    await notesDB.rawQuery("DELETE FROM TblReminders");
    await notesDB.rawQuery("DELETE FROM TblLabels");
  }

  Future<Null> _selectDate(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1901, 1),
        lastDate: DateTime(2100));
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
        _dateController.value = TextEditingValue(text: Jiffy(picked).yMMMd);
      });
  }

  _showUpdateProfileDialog(BuildContext context, String base64Str) {
    TextEditingController nameController = TextEditingController();
    String errorText, imageB64 = "";
    nameController.text = widget.userFirstName.toString();
    final _formKey = GlobalKey<FormState>();
    CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('UsersCollection');
    String userId = FirebaseAuth.instance.currentUser.uid;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            StatefulBuilder(builder: (context, _setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                //this right here
                child: Container(
                  height: 350.0,
                  width: 300.0,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Center(
                          child: SizedBox(
                            height: 150,
                            width: 150,
                            child: (imageFile != null ||
                                    widget.base64Str.toString().isNotEmpty
                                ? Stack(
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
                                              : widget.base64Str
                                                      .toString()
                                                      .isNotEmpty
                                                  ? Image.memory(base64Decode(
                                                      widget.base64Str))
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
                                              _pickImage(_setState);
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
                                  )
                                : Stack(
                                    clipBehavior: Clip.none,
                                    fit: StackFit.loose,
                                    children: [
                                      Container(
                                          height: 150,
                                          width: 150,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.blueGrey,
                                            child: Text(
                                              widget.userFirstName
                                                  .toString()
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                  fontSize: 40.0,
                                                  color: Colors.white60),
                                            ),
                                            maxRadius: 30,
                                          ),
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.white),
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          )),
                                      Positioned(
                                          bottom: 0,
                                          right: -30,
                                          child: RawMaterialButton(
                                            onPressed: () {
                                              _pickImage(_setState);
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
                                  )),
                          ),
                        ),
                        Padding(padding: EdgeInsets.only(top: 10.0)),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[400]),
                              hintText: 'First Name',
                              errorText: errorText,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                              BorderRadius.circular(2.0),
                                          side: BorderSide(
                                              color: Constants.bgMainColor)))),
                              child: Text('Update',
                                  style: TextStyle(
                                      color: Constants.bgWhiteColor,
                                      fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                if (imageFile != null) {
                                  List<int> imageBytes =
                                      imageFile.readAsBytesSync();
                                  imageB64 = base64Encode(imageBytes);
                                  print("base64Str: $imageB64");
                                }

                                QuerySnapshot querySnap = await usersCollection
                                    .where('userId', isEqualTo: userId)
                                    .get();
                                QueryDocumentSnapshot doc = querySnap.docs[0];
                                DocumentReference docRef = doc.reference;
                                await docRef.update({
                                  'noteContent': imageB64,
                                  'userFullName':
                                      nameController.value.text.toString()
                                });
                                Navigator.pop(context);
                                setState(() {
                                  List<int> imageBytes =
                                      imageFile.readAsBytesSync();
                                  String imageB64 = base64Encode(imageBytes);
                                  print("new base64Str: $imageB64");
                                  widget.base64Str = imageB64;
                                  widget.userFirstName =
                                      nameController.text.toString();
                                });
                              },
                            ),
                            SizedBox(width: 10.0),
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
                                              BorderRadius.circular(2.0),
                                          side: BorderSide(
                                              color: Constants.bgMainColor)))),
                              child: Text('Cancel',
                                  style: TextStyle(
                                      color: Constants.bgWhiteColor,
                                      fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                Navigator.pop(context);
                                imageFile = null;
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }));
  }

  Future<Null> _pickImage(Function setState) async {
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

  Future<Null> _selectTime(BuildContext context) async {
    final TimeOfDay pickedS = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        builder: (BuildContext context, Widget child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child,
          );
        });

    if (pickedS != null && pickedS != selectedTime)
      setState(() {
        selectedTime = pickedS;
        _timeController.value =
            TextEditingValue(text: selectedTime.format(context));
      });
  }

  List<Widget> getLabelSliderWidgets() {
    print("inside getLabelSliderWidgets()");
    List<Widget> widgetList = [];
    for (var label in labelModelList) {
      print(" label.labelTitle ${label.labelTitle}");
      widgetList.add(IntrinsicHeight(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Row(
                  children: [
                    Icon(Icons.label_rounded),
                    SizedBox(
                      child: Text(
                        '${label.labelTitle}',
                        overflow: TextOverflow.fade,
                      ),
                      width: 250.0,
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center),
            ),
          ],
        ),
      ));
    }
    print(" getLabelSliderWidgets() size ${widgetList.length}");

    return widgetList;
  }

  Future<List<Widget>> getReminderWidgets() async {
    print("inside getReminderWidgets()");
    List<Widget> widgetList = [];

    for (var notesModel in notesModelList) {
      Widget reminderWidget;
      Color bgTagColor =
          darkerColorByPerc(HexColor(notesModel.noteBgColorHex), 0.15);
      if (notesModel.reminderID != 0) {
        print("reminderID:${notesModel.reminderID}");
        List<Map<String, dynamic>> resultMap = await notesDB.query(
            'TblReminders',
            where: 'id = ?',
            whereArgs: [notesModel.reminderID]);
        resultMap.forEach((row) => print("ROW!: $row"));

        if (resultMap.isNotEmpty) {
          reminderWidget = Builder(builder: (context) {
            return GestureDetector(
              child: Container(
                margin: EdgeInsets.all(3.0),
                child: SizedBox(
                  width: 65.0,
                  child: Center(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          resultMap[0]['reminderInterval'] == "Does not repeat"
                              ? Icons.alarm
                              : Icons.repeat,
                          size: 15.0,
                          color: Colors.black87,
                        ),
                        Text(
                          '${resultMap[0]['reminderTime']}',
                          style: TextStyle(
                              fontSize: 11.0,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: bgTagColor,
                  border: Border.all(
                    color: Colors.transparent,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              onTap: () {
                ReminderModel reminderModel =
                    ReminderModel.fromJson(resultMap[0]);
                showReminderDialog(context, reminderModel);
              },
            );
          });
        }
      }
      notesModel.reminderWidget = reminderWidget;
      if (reminderWidget != null) widgetList.add(reminderWidget);
    }
    print(" getReminderWidgets() size ${widgetList.length}");
    return widgetList;
  }

  Widget changeNoteCell(NotesModel notesModel) {
    if (notesModel.noteType == "3") {
      // print(
      //     "notesModel.noteImgBase64.intvalue: ${base64Decode(notesModel.noteImgBase64.toString())}");

      return SizedBox.expand(
        child: FittedBox(
          child: Image.memory(base64Decode(notesModel.noteImgBase64)),
          fit: BoxFit.fill,
        ),
      );
    } else if (notesModel.noteType == "5") {
      AssetsAudioPlayer _assetsAudioPlayer = new AssetsAudioPlayer();
      Duration totalDuration;
      print("audio file path: ${notesModel.noteMediaPath}");
      _assetsAudioPlayer.open(
        Audio.file(notesModel.noteMediaPath),
        autoStart: false,
      );

      _assetsAudioPlayer.current.listen((Playing current) {
        if (current != null) {
          totalDuration = current.audio.duration;
        }
      });

      void _playPause() {
        _assetsAudioPlayer.playOrPause();
      }

      @override
      void dispose() {
        _assetsAudioPlayer.stop();
        super.dispose();
      }

      /// Returns a formatted string for the given Duration [d] to be DD:HH:mm:ss
      /// and ignore if 0.
      String formatDuration(Duration duration) {
        if (duration != null) {
          String twoDigits(int n) => n.toString().padLeft(2, "0");
          String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
          String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

          if (duration.inHours != 0)
            return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
          else
            return "$twoDigitMinutes:$twoDigitSeconds";
        }
        return "";
      }

// /data/user/0/com.example.notes_app/cache/1637281071741.mp4
      Duration currentDuration = null;
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                StreamBuilder(
                    stream: _assetsAudioPlayer.isPlaying,
                    initialData: false,
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      return Container(
                        width: 36.0,
                        height: 36.0,
                        child: NeumorphicButton(
                            style: NeumorphicStyle(
                              boxShape: NeumorphicBoxShape.circle(),
                              color: Constants.bgMainColor,
                            ),
                            padding: EdgeInsets.all(3),
                            margin: EdgeInsets.all(3),
                            onPressed: _playPause,
                            child: (snapshot.data
                                ? Icon(
                                    Icons.pause,
                                    color: Colors.white,
                                  )
                                : Icon(Icons.play_arrow, color: Colors.white))),
                      );
                    })

                /* IconButton(
                  icon: Icon(AssetAudioPlayerIcons.to_end),
                  onPressed: _next,
                ),*/
              ],
            ),
            _assetsAudioPlayer.builderRealtimePlayingInfos(
                builder: (context, RealtimePlayingInfos infos) {
              Duration duration;
              if (infos == null) {
                return SizedBox();
              } else {
                duration = totalDuration;
                print("total duration : ${formatDuration(duration)}");
              }

              //print('infos: $infos');
              return Column(
                children: [
                  PositionSeekWidget(
                    currentPosition: infos.currentPosition,
                    duration: duration,
                    seekTo: (to) {
                      _assetsAudioPlayer.seek(to);
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      );
    }
    return SizedBox();
  }

  Widget switchDrawerWidget() {
    switch (drawerPosition) {
      case 0:
        return LandingPage("", "");
        break;
      case 2:
        return ArchivePage();
        break;
      case 3:
        return TrashPage(key: _key, notifyLanding: refresh);
        break;
    }

    return Scaffold();
  }

  Color darkerColorByPerc(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  List<Widget> getLabelTagWidgets(NotesModel notesModel, String bgHexStr) {
    print("inside getLabelTagWidgets()");
    List<Widget> widgetList = [];
    if (bgHexStr != "") {
      Color bgTagColor = darkerColorByPerc(HexColor(bgHexStr), 0.15);
      String labelIdsStr = notesModel.noteLabelIdsStr;
      print("in getLabelTagWidgets labelIdsStr: $labelIdsStr");
      List<String> labelIdArr = labelIdsStr.split(",");
      List<String> selectedLabelsStrArr = [];

      Widget reminderWidget = notesModel.reminderWidget;
      if (reminderWidget != null) {
        widgetList.add(reminderWidget);
      }

/*      getRemindersForNote(bgTagColor, notesModel.reminderID).then((value) {
        reminderWidget = value;
        print('value!=null:${value != null}');
        if (reminderWidget != null) {
          widgetList.add(reminderWidget);
        }
      });*/

      print('after if widgetList size: ${widgetList.length}');
      int totalLabelSize = labelIdArr.length;
      int noOfLabelCounters = totalLabelSize > 2 ? (totalLabelSize - 2) : 0;
      Widget trailingWidget = (noOfLabelCounters > 0
          ? Container(
              margin: EdgeInsets.all(3.0),
              child: Text(
                "+" + noOfLabelCounters.toString(),
                style: TextStyle(
                    fontSize: 11.0,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600),
              ),
              decoration: BoxDecoration(
                color: bgTagColor,
                border: Border.all(
                  color: Colors.transparent,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(5.0),
              ),
            )
          : null);

      print(
          "inside getLabelTagWidgets labelModelList.length ${labelModelList.length}");
      print("inside getLabelTagWidgets labelIdArr.length ${labelIdArr.length} "
          "labelIdArr ${labelIdArr[0]}");

      if (labelIdsStr != "") {
        for (int i = 0; i < labelModelList.length; i++) {
          for (int j = 0; j < labelIdArr.length; j++) {
            if (labelModelList[i].id == int.parse(labelIdArr[j])) {
              selectedLabelsStrArr.add(labelModelList[i].labelTitle);
            }
          }
        }
        int finalSize = (selectedLabelsStrArr.length > 2
            ? (2)
            : selectedLabelsStrArr.length);

        //ADD REMINDER CUSTOM WIDGET to widgetList HERE, IF IT EXISTS FOR THE NOTE!!
        // if (notesModel.reminderID != 0) {
        //
        //   List<Map> result = await notesDB.query(
        //       'TblReminders',
        //       columns: [
        //         "id"
        //       ],
        //       where: 'id = ?',
        //       whereArgs: notesModel.reminderID);
        //   // print the results
        //   result.forEach((row) => print(row));
        //
        //
        // }

        for (int i = 0; i < finalSize; i++) {
          print("labelTitle ${selectedLabelsStrArr[i]}");
          String labelTitle = selectedLabelsStrArr[i].trim();

          widgetList.add(Container(
            margin: EdgeInsets.all(3.0),
            child: SizedBox(
              width: 50.0,
              child: Center(
                child: Text(
                  labelTitle,
                  style: TextStyle(
                      fontSize: 11.0,
                      overflow: TextOverflow.ellipsis,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: bgTagColor,
              border: Border.all(
                color: Colors.transparent,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(5.0),
            ),
          ));
        }

        if (trailingWidget != null) {
          widgetList.add(trailingWidget);
        }
        print(
            "inside getLabelTagWidgets() widgetList.length: ${widgetList.length}");
      }
    }
    print("return widgetList size:${widgetList.length}");
    return (widgetList);
  }

// Future<List<Widget>> getLabelChips(int position) async {
//   print("inside getLabelChips()");
//   List<Widget> widgetList = [];
//   notesDB =
//       await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));
//
//   String labelIdsStr = notesModelList[position].noteLabelIdsStr;
//   List<String> labelIdArr = labelIdsStr.split(",");
//   int totalLabelSize = labelIdArr.length;
//   int noOfLabelCounters = totalLabelSize > 2 ? (totalLabelSize - 2) : 0;
//   Widget trailingWidget = (noOfLabelCounters > 0
//       ? Container(child: Text("+" + noOfLabelCounters.toString()))
//       : null);
//   int finalSize =
//       (totalLabelSize > 2 ? (totalLabelSize - 2) : totalLabelSize);
//
//   for (int i = 0; i < finalSize; i++) {
//     List<String> columnsToSelect = ["labelTitle"];
//     String whereString = 'id = ?';
//     List<dynamic> whereArguments = [labelIdArr[i]];
//     List<Map> result = await notesDB.query("TblLabels",
//         columns: columnsToSelect,
//         where: whereString,
//         whereArgs: whereArguments);
//
//     result.forEach((row) {
//       String labelTitle = row
//           .toString()
//           .substring(0, row.toString().length - 1)
//           .split(":")[1]
//           .trim();
//       widgetList.add(Container(
//         child: Text(
//           labelTitle,
//           style: TextStyle(
//               fontSize: 12.0,
//               color: Colors.black45,
//               fontWeight: FontWeight.w800),
//         ),
//         decoration: BoxDecoration(
//           color: Colors.transparent,
//           border: Border.all(
//             color: Colors.transparent,
//             width: 2.0,
//           ),
//           borderRadius: BorderRadius.circular(15),
//         ),
//       ));
//     });
//
//     if (trailingWidget != null) {
//       widgetList.add(trailingWidget);
//     }
//   }
//
//   return widgetList;
// }

  BoxDecoration myBoxDecoration() {
    return BoxDecoration(
      border: Border.all(width: 3.0),
      borderRadius: BorderRadius.all(
          Radius.circular(3.0) //                 <--- border radius here
          ),
    );
  }

  showColorPaletteDialog(BuildContext context) {
    AlertDialog alert;
    String selectedBgHex = "";
    alert = AlertDialog(
        content: Wrap(
      children: getPaletteWidgets(selectedBgHex, context),
      alignment: WrapAlignment.spaceAround,
    ));
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  List<Widget> getPaletteWidgets(String selectedBgHex, BuildContext context) {
    List<Widget> widgetList = [];
    for (int i = 0; i < Constants.bgArray.length; i++) {
      widgetList.add(GestureDetector(
        child: Container(
          width: 50,
          height: 50,
          margin: EdgeInsets.all(2.0),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black45, width: 0.5),
              color: Constants.bgArray[i]),
        ),
        onTap: () {
          selectedBgHex = '#${Constants.bgArray[i].value.toRadixString(16)}';
          updateNotesBgColor(selectedBgHex, longPressedNotesMap)
              .then((value) => Navigator.pop(context));
        },
      ));
    }

    return widgetList;
  }

  bool isNotesUnpinned() {
    int unpinnedCount = 0;
    int pinnedCount = 0;

    longPressedNotesMap.keys.forEach((keyVal) {
      if (longPressedNotesMap[keyVal]) {
        notesModelList.forEach((notesModel) {
          if (notesModel.id == keyVal) {
            if (notesModel.isNotePinned == 1)
              pinnedCount++;
            else
              unpinnedCount++;
          }
        });
      }
    });

    print("inside isNotesUnpinned() pinnedCount $pinnedCount unpinnedCount "
        "$unpinnedCount");

    if (unpinnedCount > 0 && pinnedCount > 0)
      return true;
    else if (pinnedCount == 0)
      return true;
    else if (unpinnedCount == 0) return false;

    return false;
  }

  showLabelsDialog(BuildContext context) {
    TextEditingController controller = new TextEditingController();
    List<String> labelIdsList = <String>[];
    String selectedLabelsStr = "";
    AlertDialog alert;
    int totalPressedCount = 0;
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        var idString = labelIdsList.join(",");
        print("idString: $idString");
        updateNotesIdList(idString, longPressedNotesMap);
        Navigator.pop(context);
      },
    );
    print("longPressedNotesMap.length ${longPressedNotesMap.length}");
    for (var keyVal in longPressedNotesMap.keys) {
      if (longPressedNotesMap[keyVal]) totalPressedCount++;
    }

    if (totalPressedCount == 1) {
      for (var keyVal in longPressedNotesMap.keys) {
        notesModelList.forEach((notesModel) {
          print("## notesModel.id ${notesModel.id} keyVal $keyVal");
          if (notesModel.id == keyVal && longPressedNotesMap[keyVal]) {
            if (selectedLabelsStr.length == 0)
              selectedLabelsStr = notesModel.noteLabelIdsStr;
          }
        });
      }
    }

    if (selectedLabelsStr.isNotEmpty) {
      labelIdsList = selectedLabelsStr.split(",").toList();
      print("labelIdsList ${labelIdsList.toString()}");
    }

    print("in showLabelsDialog selectedLabelsStr $selectedLabelsStr");
    // set up the AlertDialog
    alert = AlertDialog(
      content: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: StatefulBuilder(builder: (context, _mainSetState) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text("Label Note",
                    style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                        fontWeight: FontWeight.w800)),
              ),
              SizedBox(height: 2),
              Theme(
                data: new ThemeData(
                  primaryColor: Colors.black26,
                  primaryColorDark: Colors.black,
                ),
                child: SizedBox(
                  height: 40.0,
                  child: TextField(
                    onChanged: ((String txt) {
                      print("Textfield onChanged String $txt");
                    }),
                    onTap: () {
                      print("onTap()");
                    },
                    autofocus: true,
                    maxLines: 1,
                    controller: controller,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(7.0),
                      isDense: true,
                      border: new OutlineInputBorder(
                        borderSide: new BorderSide(color: Colors.black26),
                      ),
                      hintText: "Enter Label",
                      hintStyle: TextStyle(
                          fontSize: 14.0,
                          color: Colors.black26,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 5.0),
                child: FutureBuilder(
                    future: getAllLabels(),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: Text(""));
                      } else {
                        return Container(
                          height: 200.0,
                          key: UniqueKey(),
                          child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: snapshot.data.length,
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemBuilder: (BuildContext context, int index) {
                                return StatefulBuilder(
                                    builder: (_context, _setState) {
                                  return Container(
                                      height: 25.0,
                                      key: UniqueKey(),
                                      child: Row(key: UniqueKey(), children: [
                                        Icon(Icons.label,
                                            color: Colors.black54),
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              snapshot.data[index].labelTitle,
                                              style: TextStyle(
                                                  fontSize: 12.0,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                        ),
                                        Checkbox(
                                            checkColor: Colors.white,
                                            value: (selectedLabelsStr.contains(
                                                snapshot.data[index].id
                                                    .toString())),
                                            onChanged: (bool value) {
                                              print("check changed $value");

                                              String idVal = snapshot
                                                  .data[index].id
                                                  .toString();

                                              print("idVal $idVal");
                                              if (!value) {
                                                //uncheck action!
                                                print(
                                                    "inside uncheck action if");
                                                int indexPos =
                                                    labelIdsList.indexOf(idVal);
                                                labelIdsList.removeAt(indexPos);
                                              } else {
                                                //check action!
                                                print("inside check action "
                                                    "else");
                                                labelIdsList.add(idVal);
                                                print("labelIdsList length : "
                                                    "${labelIdsList.length}");
                                              }
                                              selectedLabelsStr =
                                                  labelIdsList.join(",");

                                              print(
                                                  "selectedLabelsStr: $selectedLabelsStr");

                                              _setState(() {
                                                print("labelIdsList: "
                                                    "${labelIdsList.toString()}");
                                              });
                                            }),
                                      ]));
                                });
                              }),
                        );
                      }
                    }),
              ),
              Divider(),
              GestureDetector(
                child: Container(
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.black54),
                      Text(
                        "Create Label",
                        style: TextStyle(color: Colors.black54, fontSize: 12.0),
                      )
                    ],
                  ),
                ),
                onTap: () {
                  if (controller.value.toString().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Enter a label title"),
                    ));
                  } else {
                    var labelObject = LabelModel(controller.text.toString());
                    insertNewLabel(labelObject);
                    controller.text = "";
                    _mainSetState(() {});
                  }
                },
              )
            ],
          );
        }),
      ),
      actions: [okButton],
    );
    // show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _showPopupMenu(BuildContext context, Offset offset) async {
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
                _showPopupLabels(context, offset);
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
              onTapDown: (TapDownDetails details) {},
            ),
            value: 'dd Label'),
        PopupMenuItem<String>(
            child: const Text('child 2'), value: 'Second dummy'),
      ],
      elevation: 8.0,
    );
  }

  Future<void> showAddLabelDialog(
      BuildContext context, _LandingPageState ctx) async {
    bool isNewNoteAdded = false;
    TextEditingController labelTitleController = new TextEditingController();
    labelModelList = await getAllLabels();
    List<bool> labelListCheckStateList =
        List<bool>.generate(labelModelList.length, (index) => false);

    List<TextEditingController> controllerList =
        List<TextEditingController>.generate(
            labelModelList.length, (index) => TextEditingController());

    FocusNode focusNode = new FocusNode();

    List<FocusNode> focusNodeList =
        List<FocusNode>.generate(labelModelList.length, (index) => FocusNode());

    ScrollController _controller = new ScrollController();

    LabelModel createNewLabelObject() {
      final labelObject = LabelModel(labelTitleController.text.toString());
      return labelObject;
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.0)),
              //this right here
              child: StatefulBuilder(builder: (thisLowerContext, _setState) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: IntrinsicHeight(
                      child: SingleChildScrollView(
                        physics: ClampingScrollPhysics(),
                        child: Column(
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
                                      child: Icon(Icons.add,
                                          color: Colors.black26),
                                      onTap: () {
                                        print("Add new note clicked!");
                                        _setState(() {
                                          labelTitleController.clear();
                                          focusNode.requestFocus();
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
                                      child: Icon(Icons.close,
                                          color: Colors.black26),
                                      onTap: () {
                                        print("close note clicked!");
                                        _setState(() {
                                          longPressedNotesMap = Map();
                                          isNewNoteAdded = false;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: TextField(
                                        onChanged: ((String txt) {
                                          print(
                                              "Textfield onChanged String $txt");
                                        }),
                                        onTap: () {
                                          print("onTap()");
                                        },
                                        autofocus: true,
                                        maxLines: 1,
                                        focusNode: focusNode,
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
                                              borderSide: BorderSide(
                                                  color: Colors.black),
                                            ),
                                            hintText: "Enter Label",
                                            hintStyle: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.black26,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    GestureDetector(
                                      child: Icon(Icons.add,
                                          color: Colors.black26),
                                      onTap: () {
                                        if (labelTitleController.text
                                            .toString()
                                            .trim()
                                            .isNotEmpty) {
                                          insertNewLabel(
                                              createNewLabelObject());
                                          labelListCheckStateList.add(false);
                                          controllerList
                                              .add(TextEditingController());
                                          labelTitleController.text = "";
                                          _setState(() {
                                            isNewNoteAdded = false;
                                          });
                                        } else
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content:
                                                Text("Enter a label title"),
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
                                                  (BuildContext context,
                                                      int index) {
                                                print(
                                                    "inside itemBuilder of Labels LIST");
                                                if (!labelListCheckStateList[
                                                    index]) {
                                                  return Container(
                                                      key: UniqueKey(),
                                                      child: Row(
                                                          key: UniqueKey(),
                                                          children: [
                                                            Icon(Icons.label,
                                                                color: Colors
                                                                    .black26),
                                                            Expanded(
                                                              child: Center(
                                                                child: Text(
                                                                  snapshot
                                                                      .data[
                                                                          index]
                                                                      .labelTitle,
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          12.0,
                                                                      color: Colors
                                                                          .black54,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w800),
                                                                ),
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              child: Icon(
                                                                  Icons.edit,
                                                                  color: Colors
                                                                      .black26),
                                                              onTap: () {
                                                                print(
                                                                    "edit clicked!");
                                                                labelListCheckStateList[
                                                                        index] =
                                                                    true;
                                                                _setState(
                                                                    () {});
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
                                                                  color: Colors
                                                                      .black26),
                                                              onTap: () {
                                                                deleteLabel(snapshot
                                                                            .data[
                                                                        index])
                                                                    .then(
                                                                        (val) {
                                                                  if (val > 0) {
                                                                    _setState(
                                                                        () {
                                                                      labelListCheckStateList = List<
                                                                              bool>.generate(
                                                                          labelModelList
                                                                              .length,
                                                                          (index) =>
                                                                              false);
                                                                    });
                                                                  }
                                                                });
                                                              },
                                                            ),
                                                            Expanded(
                                                              child: TextField(
                                                                onChanged:
                                                                    ((String
                                                                        txt) {}),
                                                                autofocus: true,
                                                                maxLines: 1,
                                                                controller: controllerList[
                                                                    index]
                                                                  ..text = snapshot
                                                                      .data[
                                                                          index]
                                                                      .labelTitle,
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12.0,
                                                                    decorationColor:
                                                                        Colors
                                                                            .red,
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
                                                                        isDense:
                                                                            true,
                                                                        border:
                                                                            UnderlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(color: Colors.black),
                                                                        ),
                                                                        hintText:
                                                                            "Enter Label",
                                                                        hintStyle: TextStyle(
                                                                            fontSize:
                                                                                12.0,
                                                                            color:
                                                                                Colors.black26,
                                                                            fontWeight: FontWeight.w600)),
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

                                                                  if (controllerList[
                                                                          index]
                                                                      .text
                                                                      .toString()
                                                                      .trim()
                                                                      .isNotEmpty) {
                                                                    updateLabel(
                                                                            controllerList[index]
                                                                                .text,
                                                                            snapshot.data[
                                                                                index])
                                                                        .then(
                                                                            (val) {
                                                                      print(
                                                                          "row updation status value : $val");

                                                                      if (val >
                                                                          0) {
                                                                        labelListCheckStateList[index] =
                                                                            false;
                                                                        _setState(
                                                                            () {});
                                                                      } else {
                                                                        //updation of row failed !
                                                                      }
                                                                    });
                                                                  } else {
                                                                    ScaffoldMessenger.of(
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
                  ),
                );
              }));
        }).then((value) {
      ctx.setState(() {});
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

  Future<void> updateReminder(ReminderModel model) async {
    print("inside updateReminder()");
    Map<String, dynamic> map = model.toMap();
    print("Reminder ID: $map");
    int updateCount = await notesDB.update('TblReminders', model.toMap(),
        where: 'id = ?', whereArgs: [map['id']]);
    print("inside updateReminder() updateCount: $updateCount");
    setState(() {});
  }

  Future<void> deleteReminder(ReminderModel model) async {
    print("inside deleteReminder()");
    int count = await notesDB
        .rawDelete('DELETE FROM TblReminders WHERE id = ?', [model.id]);
    if (count > 0) {
      Map<String, dynamic> row = {'reminderID': 0};
      int updateCount = await notesDB
          .update('notes', row, where: 'reminderID = ?', whereArgs: [model.id]);
      print("inside deleteReminder() updateCount: $updateCount");
      setState(() {});
    }
  }

  Future<void> insertNewReminder(ReminderModel model) async {
    print("inside insertNewReminder()");
    List<String> idList = [];
    longPressedNotesMap.keys.forEach((keyVal) {
      if (longPressedNotesMap[keyVal]) idList.add(keyVal.toString());
    });
    print("idList.length:${idList.length}");

    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));
    final insertedId = await notesDB.insert(
      'TblReminders',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("insertedId: $insertedId");

    if (insertedId != "0") {
      /*
      * (1) Update notes table id with insertedId
      * (2) UI TAG(clock or loop symbol)
      * (3) Appbar close
      * (4) Click of reminder tag opens dialog
      * */
      Map<String, dynamic> row = {'reminderID': insertedId};
      int updateCount = await notesDB
          .update('notes', row, where: 'id = ?', whereArgs: [idList[0]]);
      print("inside insertNewReminder updateCount: $updateCount");
    }
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

  Future<void> updateNotesIdList(
      String labelIdsStr, Map longPressedNotesMap) async {
    print("()inside updateNotesIdList longPressedNotesMap.length: "
        "${longPressedNotesMap.length} labelIdsStr :$labelIdsStr");
    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    longPressedNotesMap.forEach((key, value) async {
      Map<String, dynamic> row = {'noteLabelIdsStr': labelIdsStr};
      print("inside foreach noteID ${key.toString()}");
      print("inside foreach noteID value $value");
      if (value) {
        int updateCount = await notesDB
            .update('notes', row, where: 'id = ?', whereArgs: [key.toString()]);
        print("inside updateNotesIdList updateCount: $updateCount");
      }
    });
  }

  Future<int> updateNotesBgColor(String bgColorStr, Map longPressedMap) async {
    int updateCount = 0;
    print("inside updateNotesBgColor() longPressedMap.length: "
        "${longPressedMap.length} bgColorStr :$bgColorStr");
    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    longPressedMap.forEach((key, value) async {
      Map<String, dynamic> row = {'noteBgColorHex': bgColorStr};
      updateCount =
          await notesDB.update('notes', row, where: 'id = ?', whereArgs: [key]);
      print("inside updateNotesBgColor updateCount: $updateCount");
    });
    setState(() {});

    return updateCount;
  }

  Future<int> updateRowPinnedState(int newState, NotesModel notesModel) async {
    int updateCount = 0;
    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));
    await notesDB.update('notes', {'isNotePinned': newState},
        where: 'id = '
            '?',
        whereArgs: [notesModel.id]);

    setState(() {});

    return updateCount;
  }

  Future<void> updatePinnedStateRows(int newState, List<String> idList) async {
    int counter = 0;
    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    idList.forEach((noteId) async {
      print("inside forEach id: $noteId");

      await notesDB.update('notes', {'isNotePinned': newState},
          where: 'id = '
              '?',
          whereArgs: [noteId]);
      counter++;

      if (counter == idList.length) {
        setState(() {
          isToggleAppBar = false;
          numOfNotesSelected = 0;
          notesModelList.forEach((notesModel) {
            longPressedNotesMap[notesModel.id] = false;
          });
        });
      }
    });
  }

  Future<void> sendToTrash(BuildContext context, int newState,
      List<String> idList, String currentDateTime) async {
    print("inside sendToTrash() id list size: ${idList.length}");
    int counter = 0;

    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    while (counter < idList.length) {
      notesDB.update('notes',
          {'isNoteTrashed': newState, 'noteDateOfDeletion': currentDateTime},
          where: 'id = ?', whereArgs: [idList[counter]]);
      counter++;
    }

    if (counter == idList.length) {
      print("inside snackbar if clause!");
      setState(() {
        String msgTxt = "";
        if (idList.length == 1) {
          msgTxt = "Note trashed.";
        } else if (idList.length > 1) {
          msgTxt = "${idList.length} notes trashed.";
        }
        if (newState == 1) {
          var snackBar = SnackBar(
            content: Text(msgTxt),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                print("Snackbar Undo onPressed!");
                sendToTrash(context, 0, idList, "");
              },
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else if (newState == 0) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }

        isToggleAppBar = false;
        numOfNotesSelected = 0;
        notesModelList.forEach((notesModel) {
          longPressedNotesMap[notesModel.id] = false;
        });
      });
    }
  }

  Future<void> updateArchivedStateRows(
      int newState, List<String> idList, BuildContext context) async {
    int counter = 0;
    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    idList.forEach((noteId) async {
      print("inside forEach id: $noteId");

      await notesDB.update('notes', {'isNoteArchived': newState},
          where: 'id = '
              '?',
          whereArgs: [noteId]);
      counter++;

      if (counter == idList.length) {
        setState(() {
          if (newState != 0) {
            isToggleAppBar = false;
          }

          final snackBar = SnackBar(
            content: Text('Notes Archived.'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                isToggleAppBar = true;
                List<String> idList = [];
                longPressedNotesMap.keys.forEach((keyVal) {
                  if (longPressedNotesMap[keyVal])
                    idList.add(keyVal.toString());
                });
                updateArchivedStateRows(0, idList, context);
              },
            ),
          );

          if (newState != 0) {
            ScaffoldMessenger.of(context)
                .showSnackBar(snackBar)
                .closed
                .then((SnackBarClosedReason reason) {
              numOfNotesSelected = 0;
              notesModelList.forEach((notesModel) {
                longPressedNotesMap[notesModel.id] = false;
              });
            });
          }
        });
      }
    });
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
    print("inside initDB()");
    WidgetsFlutterBinding.ensureInitialized();
// Open the database and store the reference.
    final Future<Database> database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), Constants.DB_NAME),

      // When the database is first created, create a table to s  tore dogs.
      onCreate: (db, version) {
        print("inside onCreate()");
        notesDB = db;
        // Run the CREATE TABLE statement on the database.
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
    notesDB = await database;

    notesModelList = await getAllNotes();
    labelModelList = await getAllLabels();
    reminderWidgetList = await getReminderWidgets();

    if (!isListPopulated) {
      // longPressList =
      //     List<bool>.generate(notesModelList.length, (int index) => false);
      longPressedNotesMap = new Map();
      notesModelList.forEach((notesModel) {
        longPressedNotesMap[notesModel.id] = false;
      });

      isListPopulated = true;
    }

    sliderLabelWidgetList = getLabelSliderWidgets();

    if (sliderLabelWidgetList.length > 0) {
      sliderTitleArray = [
        "Home",
        "Edit Labels",
        "Archive",
        "Trash",
        "Settings",
        ""
      ];
      sliderIconsArray = [
        Icons.home_rounded,
        Icons.edit,
        Icons.archive_outlined,
        Icons.delete,
        Icons.settings,
        Icons.label_outline
      ];
    } else {
      sliderTitleArray = [
        "Home",
        "Edit Labels",
        "Archive",
        "Trash",
        "Settings"
      ];
      sliderIconsArray = [
        Icons.home_rounded,
        Icons.edit,
        Icons.archive_outlined,
        Icons.delete,
        Icons.settings
      ];
    }

    print("inside initDB() labelModelList.length ${labelModelList.length}");
    print("inside initDB() notesModelList.length ${notesModelList.length}");

    return notesModelList;
  }

  Future<List<NotesModel>> getAllNotes() async {
    print("inside getAllNotes()");
    // Get a reference to the database.
    List<NotesModel> filteredList = [];
    final Database db = await notesDB;

    // Query the table for all The Notes.
    final List<Map<String, dynamic>> maps = await db.query('notes',
        where: 'is'
            'NoteTrashed '
            '= ?',
        whereArgs: ["0"]);
    print("length of notes map: ${maps.length}");
    print("inside getAllNotes drawerLabelId: $drawerLabelId");
    // Convert the List<Map<String, dynamic> into a List<NotesModel>.
    List<NotesModel> mainList = List.generate(maps.length, (i) {
      print("ReminderID: ${maps[i]['reminderID']}");
      return NotesModel.param(
          maps[i]['id'],
          maps[i]['userId'],
          maps[i]['noteTitle'],
          maps[i]['noteContent'],
          maps[i]['noteType'],
          maps[i]['noteBgColorHex'],
          maps[i]['noteMediaPath'],
          maps[i]['noteImgBase64'],
          maps[i]['noteLabelIdsStr'],
          maps[i]['noteDateOfDeletion'],
          maps[i]['isNotePinned'],
          maps[i]['isNoteArchived'],
          maps[i]['isNoteTrashed'],
          maps[i]['reminderID'].toString());
    });

    if (drawerLabelId == -1)
      return mainList;
    else {
      filteredList = mainList
          .where((element) => element.noteLabelIdsStr
              .split(",")
              .contains(drawerLabelId.toString()))
          .toList();
      return filteredList;
    }
  }

  Future<List<LabelModel>> getAllLabels() async {
    print("inside getAllLabels()");
    // Query the table for all The Labels.
    final List<Map<String, dynamic>> maps = await notesDB.query('TblLabels');
    // Convert the List<Map<String, dynamic> into a List<Label>.
    print("getAllLabels size ${maps.length}");
    labelsCheckedList = List<bool>.generate(maps.length, (int index) => false);
    return List.generate(maps.length, (i) {
      return LabelModel.param(maps[i]['id'], maps[i]['labelTitle']);
    });
  }

  Future<List<LabelModel>> getSelectedLabels() async {
    print("inside getSelectedLabels()");
    // Query the table for all The Labels.
    final List<Map<String, dynamic>> maps = await notesDB.query('TblLabels');
    // Convert the List<Map<String, dynamic> into a List<Label>.
    print("getSelectedLabels size ${maps.length}");
    labelsCheckedList = List<bool>.generate(maps.length, (int index) => false);
    return List.generate(maps.length, (i) {
      return LabelModel.param(maps[i]['id'], maps[i]['labelTitle']);
    });
  }

  Future<Widget> getRemindersForNote(Color bgTagColor, int reminderID) async {
    print("inside getRemindersForNote");
    Widget reminderWidget;
    if (reminderID != 0) {
      print("reminderID:$reminderID");
      List<Map<String, dynamic>> resultMap = await notesDB
          .query('TblReminders', where: 'id = ?', whereArgs: [reminderID]);
      resultMap.forEach((row) => print(row));

      reminderWidget = Container(
        margin: EdgeInsets.all(3.0),
        child: SizedBox(
          width: 50.0,
          child: Row(
            children: [
              Icon(
                resultMap[0]['reminderInterval'] != "Does not repeat"
                    ? Icons.alarm
                    : Icons.repeat,
                size: 30.0,
                color: Colors.grey[400],
              ),
              Text(
                '${resultMap[0]['reminderDate']},'
                '${resultMap[0]['reminderTime']}',
                style: TextStyle(
                    fontSize: 11.0,
                    overflow: TextOverflow.ellipsis,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        decoration: BoxDecoration(
          color: bgTagColor,
          border: Border.all(
            color: Colors.transparent,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(5.0),
        ),
      );
    }
    print('reminderWidget!=null: ${reminderWidget != null}');
    return reminderWidget;
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
