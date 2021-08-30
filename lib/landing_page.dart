import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/archive_page.dart';
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
  bool isArchiveSection = false;
  Widget pageWidget;

  List<bool> labelsCheckedList = [];
  List<NotesModel> notesModelList = new List<NotesModel>();
  List<LabelModel> labelModelList = new List<LabelModel>();
  Map longPressedNotesMap = new Map();
  var sliderTitleArray = ["Home", "Edit Labels", "Archive", "Settings"];
  var sliderIconsArray = [
    Icons.home_rounded,
    Icons.edit,
    Icons.archive_outlined,
    Icons.settings
  ];
  static int numOfNotesSelected = 0;
  int drawerPosition = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initDB();
    numOfNotesSelected = 0;
    drawerPosition = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: (!isToggleAppBar
            ? AppBar(
                title: Text(sliderTitleArray[drawerPosition]),
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
                              notesModelList.forEach((notesModel) {
                                longPressedNotesMap[notesModel.id] = false;
                              });
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
                  Flexible(
                    child: GestureDetector(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.archive_outlined,
                          color: Colors.blue,
                          size: 30.0,
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
                          size: 30.0,
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
                          size: 30.0,
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
                          size: 30.0,
                        ),
                      ),
                      onTap: () {
                        print("delete icon clicked!!");
                      },
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
              return InkWell(
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
                  drawerPosition = index;
                  Navigator.pop(context);
                  if (drawerPosition == 1) {
                    showAddLabelDialog(context);
                  } else {
                    setState(() {
                      pageWidget = switchDrawerWidget();
                    });
                  }
                },
              );
            },
            separatorBuilder: (context, index) {
              return Divider();
            },
          ),
        )),
        floatingActionButton: Visibility(
          visible: !isArchiveSection,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) {
                return NewNotePage(null, null);
              }));
            },
            child: Icon(Icons.add),
            backgroundColor: Constants.bgMainColor,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: ((drawerPosition == 0 || drawerPosition == 1)
            ? FutureBuilder<List>(
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
                                              .where((i) => i.isNotePinned == 1)
                                              .toList()
                                              .length, (position) {
                                        print("inside itemBuilder of GridView");
                                        List<NotesModel> filteredList =
                                            notesModelList
                                                .where(
                                                    (i) => i.isNotePinned == 1)
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
                                                        notesModel,
                                                        'heroTag $position')));
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
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Align(
                                                      //   alignment:
                                                      //       Alignment.topRight,
                                                      //   child: GestureDetector(
                                                      //     child: Padding(
                                                      //       padding:
                                                      //           const EdgeInsets
                                                      //               .all(3.0),
                                                      //       child: Icon(
                                                      //         Icons.push_pin_sharp,
                                                      //         color: Colors.black,
                                                      //         size: 24.0,
                                                      //       ),
                                                      //     ),
                                                      //     onTap: () {
                                                      //       updateRowPinnedState(
                                                      //           0,
                                                      //           filteredList[
                                                      //               position]);
                                                      //     },
                                                      //   ),
                                                      // ),
                                                      Flexible(
                                                        child: Container(
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
                                                                fontSize: 14.0,
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                          ),
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child: Container(
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
                                                                fontSize: 12.0,
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300),
                                                          ),
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
                                                  ),
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
                                      notesModel.isNotePinned == 1)
                                  ? false
                                  : true),
                              child: Column(
                                children: [
                                  Visibility(
                                    visible: (notesModelList.every(
                                            (notesModel) =>
                                                notesModel.isNotePinned == 0)
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
                                              .where((i) => i.isNotePinned == 0)
                                              .toList()
                                              .length, (position) {
                                        print("inside itemBuilder of GridView");
                                        List<NotesModel> filteredList =
                                            notesModelList
                                                .where(
                                                    (i) => i.isNotePinned == 0)
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
                                                        notesModel,
                                                        'heroTag $position')));
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
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Align(
                                                      //   alignment:
                                                      //       Alignment.topRight,
                                                      //   child: GestureDetector(
                                                      //     child: Padding(
                                                      //       padding:
                                                      //           const EdgeInsets
                                                      //               .all(3.0),
                                                      //       child: Icon(
                                                      //         Icons
                                                      //             .push_pin_outlined,
                                                      //         color: Colors.black,
                                                      //         size: 24.0,
                                                      //       ),
                                                      //     ),
                                                      //     onTap: () {
                                                      //       /*
                                                      //         * (1) update pinned
                                                      //         * state
                                                      //         * of corresponding
                                                      //         * row to 1.
                                                      //         * (2) Call set
                                                      //         * state to trigger
                                                      //         * reordering of lists.
                                                      //         * (3) Pinned
                                                      //         * section and
                                                      //         * others section
                                                      //         * with headers to
                                                      //         * be visible
                                                      //         * (4) Pinned note
                                                      //         * to have filled
                                                      //         * pin icon
                                                      //         *
                                                      //         *
                                                      //         *
                                                      //         * */
                                                      //
                                                      //       updateRowPinnedState(
                                                      //           1,
                                                      //           filteredList[
                                                      //               position]);
                                                      //     },
                                                      //   ),
                                                      // ),
                                                      Flexible(
                                                        child: Container(
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
                                                                fontSize: 14.0,
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                          ),
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child: Container(
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
                                                                fontSize: 12.0,
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300),
                                                          ),
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
                                                  ),
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
                })
            : pageWidget));
  }

  Widget switchDrawerWidget() {
    switch (drawerPosition) {
      case 0:
        return LandingPage();
        break;
      case 2:
        return ArchivePage();
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
    Color bgTagColor = darkerColorByPerc(HexColor(bgHexStr), 0.15);
    String labelIdsStr = notesModel.noteLabelIdsStr;
    print("in getLabelTagWidgets labelIdsStr: $labelIdsStr");
    List<String> labelIdArr = labelIdsStr.split(",");
    List<String> selectedLabelsStrArr = [];
    List<Widget> widgetList = [];
    int totalLabelSize = labelIdArr.length;
    int noOfLabelCounters = totalLabelSize > 2 ? (totalLabelSize - 2) : 0;
    Widget trailingWidget = (noOfLabelCounters > 0
        ? Container(
            margin: EdgeInsets.all(3.0),
            child: Text(
              "+" + noOfLabelCounters.toString(),
              style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.black45,
                  fontWeight: FontWeight.w800),
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
      int finalSize =
          (selectedLabelsStrArr.length > 2 ? (2) : selectedLabelsStrArr.length);

      for (int i = 0; i < finalSize; i++) {
        print("labelTitle ${selectedLabelsStrArr[i]}");
        String labelTitle = selectedLabelsStrArr[i].trim();

        widgetList.add(Container(
          margin: EdgeInsets.all(3.0),
          child: SizedBox(
            width: 50.0,
            child: Text(
              labelTitle,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.black45,
                  fontWeight: FontWeight.w800),
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
    List<String> labelIdsList = [];
    String selectedLabelsStr = "";
    AlertDialog alert;
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        var idString = labelIdsList.join(",");
        print("idString: $idString");
        if (idString != "") {
          updateNotesIdList(idString, longPressedNotesMap);
        }
        Navigator.pop(context);
      },
    );
    print("longPressedNotesMap.length ${longPressedNotesMap.length}");

    if (longPressedNotesMap.length == 1) {
      selectedLabelsStr = longPressedNotesMap[0].noteLabelIdsStr;
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
                                                        .toString())
                                                ? true
                                                : labelsCheckedList[index]),
                                            onChanged: (bool value) {
                                              _setState(() {
                                                labelsCheckedList[index] =
                                                    value;
                                                String idCurrent = snapshot
                                                    .data[index].id
                                                    .toString();
                                                if (labelIdsList
                                                    .contains(idCurrent)) {
                                                  labelIdsList
                                                      .remove(idCurrent);
                                                } else {
                                                  labelIdsList.add(idCurrent);
                                                }
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
    labelIdsList = [];
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
                                    longPressedNotesMap = Map();
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

  Future<void> updateNotesIdList(
      String labelIdsStr, Map longPressedNotesMap) async {
    print("inside updateNotesIdList() longPressedNotesMap.length: "
        "${longPressedNotesMap.length} labelIdsStr :$labelIdsStr");
    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    longPressedNotesMap.forEach((key, value) async {
      Map<String, dynamic> row = {'noteLabelIdsStr': labelIdsStr};
      int updateCount = await notesDB.update('notes', row,
          where: 'id = ?', whereArgs: [longPressedNotesMap[key].id]);
      print("inside updateNotesIdList updateCount: $updateCount");
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


  Future<void> updateArchivedStateRows(int newState, List<String> idList,
      BuildContext context)
  async {
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
          isToggleAppBar = false;
          numOfNotesSelected = 0;
          /*
          * (1) Display snackbar
          * (2) once duration finished do below false setting
          * (3) If undo clicked do restoration of state in DB.
          *
          *
          * */

          final snackBar = SnackBar(
            content: Text('Notes Archived.'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {

              },
            ),
          );


          ScaffoldMessenger.of(context).showSnackBar(snackBar);


          /*notesModelList.forEach((notesModel) {
            longPressedNotesMap[notesModel.id] = false;
          });*/
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
          "isNotePinned INTEGER, isNoteArchived INTEGER)",
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

    print("inside initDB() labelModelList.length ${labelModelList.length}");
    print("inside initDB() notesModelList.length ${notesModelList.length}");

    return notesModelList;
  }

  Future<List<NotesModel>> getAllNotes() async {
    print("inside getAllNotes()");
    // Get a reference to the database.
    final Database db = await notesDB;

    // Query the table for all The Notes.
    final List<Map<String, dynamic>> maps = await db.query('notes');
    print("length of notes map: ${maps.length}");
    // Convert the List<Map<String, dynamic> into a List<NotesModel>.
    return List.generate(maps.length, (i) {
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
      );
    });
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
