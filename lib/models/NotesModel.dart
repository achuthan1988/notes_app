class NotesModel {
  int id;
  String noteTitle;
  String noteContent;
  String noteType;
  String noteBgColorHex;
  String noteMediaPath;
  String noteImgBase64;
  String noteLabelIdsStr;

  NotesModel(
      this.noteTitle,
      this.noteContent,
      this.noteType,
      this.noteBgColorHex,
      this.noteMediaPath,
      this.noteImgBase64,
      this.noteLabelIdsStr);

  NotesModel.param(
      this.id,
      this.noteTitle,
      this.noteContent,
      this.noteType,
      this.noteBgColorHex,
      this.noteMediaPath,
      this.noteImgBase64,
      this.noteLabelIdsStr);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteTitle': noteTitle,
      'noteContent': noteContent,
      'noteType': noteType,
      'noteBgColorHex': noteBgColorHex,
      'noteMediaPath': noteMediaPath,
      'noteImgBase64': noteImgBase64,
      'noteLabelIdsStr': noteLabelIdsStr
    };
  }
}
