import 'dart:convert';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:jiffy/jiffy.dart';
import 'package:notes_app/archive_page.dart';
import 'package:notes_app/models/LabelModel.dart';
import 'package:notes_app/models/NotesModel.dart';
import 'package:notes_app/trash_page.dart';
import 'package:notes_app/util/HexColor.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'new_note_page.dart';
import 'util/PositionSeekWidget.dart';
import 'util/constants.dart' as Constants;

class LandingPage extends StatefulWidget {
  setTrashState() => createState().setTrashState();

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Future<Database> database;
  var notesDB;
  bool isToggleAppBar = false;
  bool isListPopulated = false;
  bool isArchiveSection = false;
  bool isTrashActive = false;
  Widget pageWidget;
  TextEditingController _controller = new TextEditingController();

  List<bool> labelsCheckedList = [];
  List<Widget> sliderLabelWidgetList = [];
  List<NotesModel> notesModelList = new List<NotesModel>();
  List<LabelModel> labelModelList = new List<LabelModel>();
  Map longPressedNotesMap = new Map();
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initDB();
    numOfNotesSelected = 0;
    drawerPosition = 0;
  }

  void setTrashState() {
    print("inside setTrashState()");
    isTrashActive = true;
    setState(() {

    });
  }

  bool getTrashState() {
    print("inside getTrashState()");
    return isTrashActive;
  }

  @override
  Widget build(BuildContext context) {
    print("inside build! landing page");
    return Scaffold(
        resizeToAvoidBottomInset: false,
        onDrawerChanged: (isOpened) async {
          if (isOpened) {
            labelModelList = await getAllLabels();
            notesModelList = await getAllNotes();
            sliderLabelWidgetList = getLabelSliderWidgets();

            setState(() {});
          }
        },
        appBar: (!isToggleAppBar
            ? AppBar(
                title: (drawerLabelId == -1)
                    ? Text(sliderTitleArray[drawerPosition])
                    : Text(drawerLabelTitle),
              )
            : (!getTrashState()
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
                      Flexible(
                        child: GestureDetector(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
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
                              int currentTimeInMillis =
                                  DateTime.now().millisecondsSinceEpoch;
                              print(
                                  "currentTimeInMillis: $currentTimeInMillis");

                              Widget okButton = TextButton(
                                child: Text("OK"),
                                onPressed: () {},
                              );

                              // set up the AlertDialog
                              AlertDialog alert = AlertDialog(
                                content: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: StatefulBuilder(
                                      builder: (context, _mainSetState) {
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Set Reminder"),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        GestureDetector(
                                            child: AbsorbPointer(
                                                child: TextField(
                                              textAlign: TextAlign.center,
                                              enabled: false,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.all(0),
                                                prefixIcon: Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 24.0,
                                                ),
                                                prefixIconConstraints:
                                                    BoxConstraints(
                                                        minWidth: 0,
                                                        minHeight: 0),
                                                isDense: true,
                                              ),
                                              controller: _controller,
                                            )),
                                            onTap: () {
                                              _selectDate(context);
                                            }),
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
                            },
                          ),
                        ),
                        visible: (numOfNotesSelected <= 1),
                      ),
                      Flexible(
                        child: GestureDetector(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
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
                            padding: const EdgeInsets.all(10.0),
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
                            padding: const EdgeInsets.all(10.0),
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
                            padding: const EdgeInsets.all(10.0),
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

                              sendToTrash(context, 1, idList);

                              /* String msgTxt = "";
                          if (idList.length == 1) {
                            msgTxt = "Note trashed.";
                          } else if (idList.length > 1) {
                            msgTxt = "${idList.length} notes trashed.";
                          }

                          final snackBar = SnackBar(
                            content: Text(msgTxt),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                sendToTrash(0, idList);
                              },
                            ),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(snackBar);*/
                              /*
                          * (1) Show snack bar with number of notes from size
                          *  of idList above
                          *
                          * (2) before duration click reverts the state by
                          * calling sendToTrash with 0 flag
                          *
                          * (3)
                          *
                          *
                          * */
                            });
                          },
                        ),
                      )
                    ],
                  )
                : AppBar(
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
                            }),
                      ),
                    ],
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
                                              labelModelList[position]
                                                  .labelTitle;
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
          visible: !isArchiveSection,
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
                  return snapshot.hasData
                      ? SingleChildScrollView(
                          child: new Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Visibility(
                              visible: (notesModelList.every((notesModel) =>
                                      (notesModel.isNotePinned == 0))
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
                                              .where((i) =>
                                                  (i.isNotePinned == 1 &&
                                                      i.isNoteArchived == 0))
                                              .toList()
                                              .length, (position) {
                                        print("inside itemBuilder of GridView");
                                        List<NotesModel> filteredList =
                                            notesModelList
                                                .where((i) =>
                                                    (i.isNotePinned == 1 &&
                                                        i.isNoteArchived == 0))
                                                .toList();
                                        List<Widget> widgetList =
                                            getLabelTagWidgets(
                                                filteredList[position],
                                                filteredList[position]
                                                    .noteBgColorHex);
                                        print(
                                            "inside itemBuilder widgetList.length "
                                            "${widgetList.length}");

                                        return GestureDetector(
                                          onTap: () {
                                            NotesModel notesModel =
                                                filteredList[position];
                                            Navigator.push(
                                                context,
                                                ScaleRoute(
                                                    page: NewNotePage(
                                                        notesModel)));
                                          },
                                          onLongPress: () {
                                            print(
                                                "inside onLongPress longPressList[position]");

                                            if (!longPressedNotesMap[
                                                filteredList[position].id]) {
                                              setState(() {
                                                longPressedNotesMap[
                                                    filteredList[position]
                                                        .id] = true;
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
                                                              MainAxisSize.max,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .black,
                                                                border:
                                                                    Border.all(
                                                                        width:
                                                                            0),
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(2.0),
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
                                                                color: Colors
                                                                    .black,
                                                                border:
                                                                    Border.all(
                                                                        width:
                                                                            0),
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(2.0),
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
                                                          filteredList[
                                                              position])),
                                                ),
                                                Positioned(
                                                  top: 0,
                                                  right: 2.0,
                                                  child: Visibility(
                                                    visible:
                                                        longPressedNotesMap[
                                                            filteredList[
                                                                    position]
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
                                          ),
                                        );
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
                                    visible: (notesModelList.every(
                                            (notesModel) =>
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
                                        List<NotesModel> filteredList =
                                            notesModelList
                                                .where((i) =>
                                                    i.isNotePinned == 0 &&
                                                    i.isNoteArchived == 0)
                                                .toList();

                                        List<Widget> widgetList =
                                            getLabelTagWidgets(
                                                filteredList[position],
                                                filteredList[position]
                                                    .noteBgColorHex);
                                        // print(
                                        //     "inside itemBuilder widgetList.length "
                                        //     "${widgetList.length}");

                                        return GestureDetector(
                                          onTap: () {
                                            NotesModel notesModel =
                                                filteredList[position];
                                            Navigator.push(
                                                context,
                                                ScaleRoute(
                                                    page: NewNotePage(
                                                        notesModel)));
                                          },
                                          onLongPress: () {
                                            print(
                                                "inside onLongPress longPressList[position]");

                                            if (!longPressedNotesMap[
                                                filteredList[position].id]) {
                                              setState(() {
                                                longPressedNotesMap[
                                                    filteredList[position]
                                                        .id] = true;
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
                                                                      height:
                                                                          70.0,
                                                                      width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width,
                                                                      child: Padding(
                                                                          padding: const EdgeInsets.all(2),
                                                                          child: GridView.builder(
                                                                            itemCount:
                                                                                filteredList[position].noteMediaPath.split(",").length,
                                                                            gridDelegate:
                                                                                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                                                                            shrinkWrap:
                                                                                true,
                                                                            itemBuilder:
                                                                                (BuildContext context, int index) {
                                                                              return Padding(
                                                                                padding: const EdgeInsets.all(1.0),
                                                                                child: Stack(
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
                                                                  EdgeInsets
                                                                      .all(2.0),
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
                                                                color: Colors
                                                                    .transparent,
                                                                border: Border.all(
                                                                    width: 0,
                                                                    color: Colors
                                                                        .transparent),
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(2.0),
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
                                                          filteredList[
                                                              position])),
                                                ),
                                                Positioned(
                                                  top: 0,
                                                  right: 2.0,
                                                  child: Visibility(
                                                    visible:
                                                        longPressedNotesMap[
                                                            filteredList[
                                                                    position]
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
                                          ),
                                        );
                                      })),
                                ],
                              ),
                            )
                          ],
                        ))
                      : Center(
                          child: Text(
                            "No Notes Added",
                            style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey),
                          ),
                        );
                }))
            : pageWidget));
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
        _controller.value = TextEditingValue(text: Jiffy(picked).yMMMd);
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
        return LandingPage();
        break;
      case 2:
        return ArchivePage();
        break;
      case 3:
        return TrashPage();
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

    return widgetList;
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

  Future<void> sendToTrash(
      BuildContext context, int newState, List<String> idList) async {
    int counter = 0;
    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    idList.forEach((noteId) async {
      print("inside forEach id: $noteId");

      await notesDB.update('notes', {'isNoteTrashed': newState},
          where: 'id = '
              '?',
          whereArgs: [noteId]);
      counter++;

      if (counter == idList.length) {
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
                  sendToTrash(context, 0, idList);
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
    });
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

      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        print("inside onCreate()");
        notesDB = db;
        // Run the CREATE TABLE statement on the database.
        db.execute(
          "CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, noteTitle"
          " TEXT, noteContent TEXT, noteType TEXT, noteBgColorHex TEXT, "
          "noteMediaPath TEXT,  noteImgBase64 TEXT,noteLabelIdsStr TEXT,"
          "isNotePinned INTEGER, isNoteArchived INTEGER, isNoteTrashed "
          "INTEGER)",
        );
        db.execute(
            "CREATE TABLE TblLabels(id INTEGER PRIMARY KEY AUTOINCREMENT, labelTitle TEXT)");
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    notesDB = await database;

    notesModelList = await getAllNotes();
    labelModelList = await getAllLabels();

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
      return NotesModel.param(
          maps[i]['id'],
          maps[i]['noteTitle'],
          maps[i]['noteContent'],
          maps[i]['noteType'],
          maps[i]['noteBgColorHex'],
          maps[i]['noteMediaPath'],
          maps[i]['noteImgBase64'],
          maps[i]['noteLabelIdsStr'],
          maps[i]['isNotePinned'],
          maps[i]['isNoteArchived'],
          maps[i]['isNoteTrashed']);
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
