import 'package:firebase_database/firebase_database.dart';
import 'package:notes_app/models/NotesModel.dart';

class NotesDao {
  static String url = "https://notesapp-d1403-default-rtdb.firebaseio.com";
  final DatabaseReference _dbRef =
      FirebaseDatabase(databaseURL: url).reference();

  void saveNote(NotesModel notesModel) {
    _dbRef.child("notes").set(notesModel.toJson());
  }

  Query getNotesQuery() {
    return _dbRef;
  }
}
