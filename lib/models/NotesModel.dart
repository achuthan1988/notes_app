class NotesModel {
  int id;
  String noteTitle;
  String noteContent;
  String noteType;
  String noteBgColorHex;
  String noteMediaPath;
  String noteImgBase64;
  String noteLabelIdsStr;
  int isNotePinned;
  int isNoteArchived;
  int isNoteTrashed;

  NotesModel(
      this.noteTitle,
      this.noteContent,
      this.noteType,
      this.noteBgColorHex,
      this.noteMediaPath,
      this.noteImgBase64,
      this.noteLabelIdsStr,
      this.isNotePinned,
      this.isNoteArchived,
      this.isNoteTrashed);

  NotesModel.param(
      this.id,
      this.noteTitle,
      this.noteContent,
      this.noteType,
      this.noteBgColorHex,
      this.noteMediaPath,
      this.noteImgBase64,
      this.noteLabelIdsStr,
      this.isNotePinned,
      this.isNoteArchived,
      this.isNoteTrashed);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteTitle': noteTitle,
      'noteContent': noteContent,
      'noteType': noteType,
      'noteBgColorHex': noteBgColorHex,
      'noteMediaPath': noteMediaPath,
      'noteImgBase64': noteImgBase64,
      'noteLabelIdsStr': noteLabelIdsStr,
      'isNotePinned': isNotePinned,
      'isNoteArchived': isNoteArchived,
      'isNoteTrashed': isNoteTrashed
    };
  }

  NotesModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        noteTitle = json['noteTitle'],
        noteContent = json['noteContent'],
        noteType = json['noteType'],
        noteBgColorHex = json['noteBgColorHex'],
        noteMediaPath = json['noteMediaPath'],
        noteImgBase64 = json['noteImgBase64'],
        noteLabelIdsStr = json['noteLabelIdsStr'],
        isNotePinned = json['isNotePinned'],
        isNoteArchived = json['isNoteArchived'],
        isNoteTrashed = json['isNoteTrashed'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'noteTitle': noteTitle,
        'noteContent': noteContent,
        'noteType': noteType,
        'noteBgColorHex': noteBgColorHex,
        'noteMediaPath': noteMediaPath,
        'noteImgBase64': noteImgBase64,
        'noteLabelIdsStr': noteLabelIdsStr,
        'isNotePinned': isNotePinned,
        'isNoteArchived': isNoteArchived,
        'isNoteTrashed': isNoteTrashed
      };
}
