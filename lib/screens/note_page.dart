import 'package:flutter/material.dart';
import 'package:memorycare/models/note.dart';

class NotePage extends StatefulWidget {
  final Note note;
  const NotePage({super.key, required this.note});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  late TextEditingController _controller;

  late Note currentNote;

  @override
  void initState() {
    super.initState();
    setState(() {
      currentNote = widget.note;
    });
    _controller = TextEditingController(text: currentNote.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentNote.title ?? ""),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 100,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Note Content',
                ),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentNote.setText(_controller.text);
                });
                Navigator.pop(context, _controller.text);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
