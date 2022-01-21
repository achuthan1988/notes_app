import 'package:flutter/material.dart';

class NotesModel {
  int id;
  String noteTitle;
  String noteContent;
  String noteType;
  String noteBgColorHex;
  String noteMediaPath;
  String noteImgBase64;
  String noteLabelIdsStr;
  String noteDateOfDeletion;
  int isNotePinned;
  int isNoteArchived;
  int isNoteTrashed;
  String reminderID;
  Widget reminderWidget;

  NotesModel(
      this.noteTitle,
      this.noteContent,
      this.noteType,
      this.noteBgColorHex,
      this.noteMediaPath,
      this.noteImgBase64,
      this.noteLabelIdsStr,
      this.noteDateOfDeletion,
      this.isNotePinned,
      this.isNoteArchived,
      this.isNoteTrashed,
      this.reminderID);

  NotesModel.param(
      this.id,
      this.noteTitle,
      this.noteContent,
      this.noteType,
      this.noteBgColorHex,
      this.noteMediaPath,
      this.noteImgBase64,
      this.noteLabelIdsStr,
      this.noteDateOfDeletion,
      this.isNotePinned,
      this.isNoteArchived,
      this.isNoteTrashed,
      this.reminderID);

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
      'noteDateOfDeletion': noteDateOfDeletion,
      'isNotePinned': isNotePinned,
      'isNoteArchived': isNoteArchived,
      'isNoteTrashed': isNoteTrashed,
      'reminderID': reminderID
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
        noteDateOfDeletion = json['noteDateOfDeletion'],
        isNotePinned = json['isNotePinned'],
        isNoteArchived = json['isNoteArchived'],
        isNoteTrashed = json['isNoteTrashed'],
        reminderID = json['reminderID'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'noteTitle': noteTitle,
        'noteContent': noteContent,
        'noteType': noteType,
        'noteBgColorHex': noteBgColorHex,
        'noteMediaPath': noteMediaPath,
        'noteImgBase64': noteImgBase64,
        'noteLabelIdsStr': noteLabelIdsStr,
        'noteDateOfDeletion': noteDateOfDeletion,
        'isNotePinned': isNotePinned,
        'isNoteArchived': isNoteArchived,
        'isNoteTrashed': isNoteTrashed,
        'reminderID': reminderID
      };
}
