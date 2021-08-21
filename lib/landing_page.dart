import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/models/LabelModel.dart';
import 'package:notes_app/models/NotesModel.dart';
import 'package:notes_app/util/HexColor.dart';
import 'package:path/path.dart';
import 'package:popover/popover.dart';
import 'package:sqflite/sqflite.dart';

import 'new_note_page.dart';
import 'util/constants.dart' as Constants;

class PalletteWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scrollbar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              InkWell(
                onTap: () {},
                child: Container(
                  height: 50,
                  color: Colors.amber[100],
                  child: const Center(child: Text('Entry A')),
                ),
              ),
              const Divider(),
              Container(
                height: 50,
                color: Colors.amber[200],
                child: const Center(child: Text('Entry B')),
              ),
              const Divider(),
              Container(
                height: 50,
                color: Colors.amber[300],
                child: const Center(child: Text('Entry C')),
              ),
              const Divider(),
              Container(
                height: 50,
                color: Colors.amber[400],
                child: const Center(child: Text('Entry D')),
              ),
              const Divider(),
              Container(
                height: 50,
                color: Colors.amber[500],
                child: const Center(child: Text('Entry E')),
              ),
              const Divider(),
              Container(
                height: 50,
                color: Colors.amber[600],
                child: const Center(child: Text('Entry F')),
              ),
            ],
          ),
        ),
      ),
    );

    // TODO: implement build
    // return GridView.builder(
    //   padding: EdgeInsets.all(2.0),
    //   itemBuilder: (context, position) {
    //     return GestureDetector(
    //       onTap: () {
    //         print("on Tap of pallette pop up");
    //
    //       },
    //       child: Container(
    //         width: 20,
    //         height: 20,
    //         decoration: BoxDecoration(
    //             shape: BoxShape.circle, color: Constants.bgArray[0]),
    //       ),
    //     );
    //   },
    //   shrinkWrap: true,
    //   itemCount: Constants.bgArray.length,
    //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    //     crossAxisCount: 2,
    //     crossAxisSpacing: 0.0,
    //     mainAxisSpacing: 0.0,
    //   ),
    // );
  }
}

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
  List<bool> labelsCheckedList = [];
  List<NotesModel> notesModelList = new List<NotesModel>();
  List<LabelModel> labelModelList = new List<LabelModel>();
  List<NotesModel> longPressedNotesList = [];
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
    initDB();
    numOfNotesSelected = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
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
                    child: GestureDetector(
                      child: Icon(
                        Icons.label_outline,
                        color: Colors.blue,
                        size: 30.0,
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
                      child: Icon(
                        Icons.color_lens_outlined,
                        color: Colors.blue,
                        size: 30.0,
                      ),
                      onTap: () {
                        print("pallette icon clicked!!");

                        showPopover(
                          context: context,
                          transitionDuration: const Duration(milliseconds: 150),
                          bodyBuilder: (context) => PalletteWidget(),
                          onPop: () => print('Popover was popped!'),
                          direction: PopoverDirection.bottom,
                          width: 200,
                          height: 400,
                          arrowHeight: 15,
                          arrowWidth: 30,
                        );
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
              print("inside builder of FutureBuilder ${snapshot.hasData}");

              return snapshot.hasData
                  ? GridView.builder(
                      padding: EdgeInsets.all(2.0),
                      itemBuilder: (context, position) {
                        print("inside itemBuilder of GridView");
                        List<Widget> widgetList = getLabelTagWidgets(
                            notesModelList[position],
                            notesModelList[position].noteBgColorHex);
                        print("inside itemBuilder widgetList.length "
                            "${widgetList.length}");

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
                            print("inside onLongPress longPressList[position]"
                                " ${longPressList[position]}");
                            /*(1) set indicator to denote selection on note
                            (done)
                      (2) Update counter in new app bar , based on number of notes selected(done)
                      (3) Click of close ('X') button , deselects all notes ,restores default app bar(done)
                      (4) functionality for label icon , palette icon , options menu features , (multiple notes cases to be kept in mind)
                      (5)
                    * */

                            if (!longPressList[position]) {
                              setState(() {
                                longPressList[position] = true;
                                longPressedNotesList
                                    .add(notesModelList[position]);
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: EdgeInsets.all(2.0),
                                          child: Text(
                                            notesModelList[position].noteTitle,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Container(
                                          padding: EdgeInsets.all(2.0),
                                          child: Text(
                                            notesModelList[position]
                                                .noteContent,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 10,
                                            style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w300),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.bottomLeft,
                                          child: Wrap(
                                            children: widgetList,
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
          updateNotesIdList(idString, longPressedNotesList);
        }
        Navigator.pop(context);

        /*
        * (1) Update noteLabelIdsStr column of corresponding note in first
        * table with the above string.
        * (2) UI of note to be updated with string labels of ids selected ,
        * with first two notes shown wrap and more than 2 labels to be shown
        * as +1 etc as third note.Detailed labels to be shown in detailed on
        * click of note.
        * (3)
        *
        *
        * */
      },
    );
    print("longPressedNotesList.length ${longPressedNotesList.length}");

    if (longPressedNotesList.length == 1) {
      selectedLabelsStr = longPressedNotesList[0].noteLabelIdsStr;
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
                                    longPressedNotesList = [];
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

  Future<void> updateNotesIdList(
      String labelIdsStr, List<NotesModel> longPressedNotesList) async {
    print("inside updateNotesIdList() longPressedNotesList.length: "
        "${longPressedNotesList.length} labelIdsStr :$labelIdsStr");
    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    for (int i = 0; i < longPressedNotesList.length; i++) {
      Map<String, dynamic> row = {'noteLabelIdsStr': labelIdsStr};
      int updateCount = await notesDB.update('notes', row,
          where: 'id = ?', whereArgs: [longPressedNotesList[i].id]);
      print("inside updateNotesIdList updateCount: $updateCount");
    }
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
          "CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, noteTitle TEXT, noteContent TEXT, noteType TEXT, noteBgColorHex TEXT, noteMediaPath TEXT,  noteImgBase64 TEXT,noteLabelIdsStr TEXT)",
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
      longPressList =
          List<bool>.generate(notesModelList.length, (int index) => false);

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
          maps[i]['noteLabelIdsStr']);
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
