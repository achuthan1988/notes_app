import 'dart:io';

import 'package:flutter/material.dart';

class NoteDetailedPage extends StatefulWidget {
  final String imagePath;

  const NoteDetailedPage({Key key, @required this.imagePath}) : super(key: key);

  @override
  _NoteDetailedPageState createState() => _NoteDetailedPageState();
}

class _NoteDetailedPageState extends State<NoteDetailedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        child: Container(
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
