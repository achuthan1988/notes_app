import 'dart:convert';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:notes_app/util/HexColor.dart';
import 'package:notes_app/util/PositionSeekWidget.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'models/LabelModel.dart';
import 'models/NotesModel.dart';
import 'util/constants.dart' as Constants;

class TrashPage extends StatefulWidget {
  const TrashPage({Key key, @required this.notifyLanding}) : super(key: key);
  final Function() notifyLanding;

  @override
  TrashPageState createState() => TrashPageState();
}

class TrashPageState extends State<TrashPage> {
  Future<Database> database;
  var notesDB;
  bool isToggleAppBar = false;
  bool isListPopulated = false;
  bool isArchiveSection = false;
  Widget pageWidget;
  TextEditingController _controller = new TextEditingController();

  List<bool> labelsCheckedList = [];
  List<Widget> sliderLabelWidgetList = [];
  List<NotesModel> notesModelList = [];
  List<LabelModel> labelModelList = [];
  int numOfNotesSelected = 0;
  Map longPressedNotesMap = new Map();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initDB();
    numOfNotesSelected = 0;
  }

  refresh() {
    setState(() {
      notesModelList.forEach((notesModel) {
        longPressedNotesMap[notesModel.id] = false;
      });
      isToggleAppBar = false;
      numOfNotesSelected = 0;
    });
  }

  setup(BuildContext context, int flag) {
    List<String> idList = [];
    longPressedNotesMap.keys.forEach((keyVal) {
      if (longPressedNotesMap[keyVal]) idList.add(keyVal.toString());
    });
    print("inside restoreNotesToLanding() id list size: ${idList.length}");
    if (flag == 0)
      restoreNotesToLanding(context, 0, idList);
    else {
      deleteRowsForever(idList);
      setState(() {
        isToggleAppBar = false;
        numOfNotesSelected = 0;
        notesModelList.forEach((notesModel) {
          longPressedNotesMap[notesModel.id] = false;
        });
      });
    }
  }

  Future<void> deleteRowsForever(List<String> idList) async {
    print("inside deleteRowsForever() size:${idList.length}");
    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));
    await notesDB.delete('notes',
        where: 'id IN (${List.filled(idList.length, '?').join(',')})',
        whereArgs: idList);
  }

  Future<void> restoreNotesToLanding(
      BuildContext context, int newState, List<String> idList) async {
    int counter = 0;
    notesDB =
        await openDatabase(join(await getDatabasesPath(), Constants.DB_NAME));

    while (counter < idList.length) {
      notesDB.update('notes', {'isNoteTrashed': newState},
          where: 'id = ?', whereArgs: [idList[counter]]);
      counter++;
    }

    if (counter == idList.length) {
      print("inside snackbar if clause!");
      setState(() {
        String msgTxt = "";
        if (idList.length == 1) {
          msgTxt = "Note restored.";
        } else if (idList.length > 1) {
          msgTxt = "${idList.length} notes restored.";
        }
        if (newState == 0) {
          var snackBar = SnackBar(
            content: Text(msgTxt),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                print("Snackbar Undo onPressed!");
                restoreNotesToLanding(context, 1, idList);
              },
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else if (newState == 1) {
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
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    notesDB = await database;

    notesModelList = await getAllNotes();

    if (!isListPopulated) {
      // longPressList =
      //     List<bool>.generate(notesModelList.length, (int index) => false);
      longPressedNotesMap = new Map();
      notesModelList.forEach((notesModel) {
        longPressedNotesMap[notesModel.id] = false;
      });

      isListPopulated = true;
    }

    return notesModelList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: FutureBuilder<List>(
          future: initDB(),
          builder: (context, snapshot) {
            print("inside builder of FutureBuilder ${snapshot.hasData}");
            return snapshot.hasData
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Flexible(
                        child: GridView.builder(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 2.0,
                                  mainAxisSpacing: 2.0),
                          itemBuilder: (_, position) => GestureDetector(
                            onTap: () {},
                            onLongPress: () {
                              print(
                                  "inside onLongPress longPressList[position]");

                              widget.notifyLanding();
                              if (!longPressedNotesMap[
                                  notesModelList[position].id]) {
                                setState(() {
                                  longPressedNotesMap[
                                      notesModelList[position].id] = true;
                                  isToggleAppBar = true;
                                  numOfNotesSelected += 1;
                                });
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.all(3.0),
                                  padding: EdgeInsets.all(1.0),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0)),
                                      color: HexColor(notesModelList[position]
                                          .noteBgColorHex)),
                                  child: (notesModelList[position].noteType ==
                                          "0"
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              // decoration: BoxDecoration(
                                              //   color: Colors.black,
                                              //   border: Border.all(
                                              //       width: 0),
                                              // ),
                                              padding: EdgeInsets.all(2.0),
                                              child: Text(
                                                notesModelList[position]
                                                    .noteTitle,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                            Container(
                                              // decoration: BoxDecoration(
                                              //   color: Colors.black,
                                              //   border: Border.all(
                                              //       width: 0),
                                              // ),
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
                                        )
                                      : changeNoteCell(
                                          notesModelList[position])),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 2.0,
                                  child: Visibility(
                                    visible: longPressedNotesMap[
                                        notesModelList[position].id],
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
                          itemCount: notesModelList.length,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      "No Notes in trash",
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey),
                    ),
                  );
          }),
    );
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

  Future<List<NotesModel>> getAllNotes() async {
    print(" trash_page inside getAllNotes()");
    // Get a reference to the database.
    List<NotesModel> filteredList = [];
    final Database db = await notesDB;
    final prefs = await SharedPreferences.getInstance();
    // Query the table for all The Notes.
    final List<Map<String, dynamic>> maps = await db.query('notes',
        where: 'is'
            'NoteTrashed '
            '= ?',
        whereArgs: ["1"]);
    print("length of notes map: ${maps.length}");
    List<NotesModel> mainList = List.generate(maps.length, (i) {
      return NotesModel.param(
          maps[i]['id'],
          prefs.getString("USER_ID"),
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
          maps[i]['reminderID']);
    });
    print(" trash_page notes size :${mainList.length}");
    return mainList;
  }
}
