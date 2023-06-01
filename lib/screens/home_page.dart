import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:memorycare/models/note.dart';
import 'package:memorycare/screens/note_page.dart';
import 'package:memorycare/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textFieldController = TextEditingController();
  List<Note> _notes = [];
  final TextEditingController _titleController = TextEditingController();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  initState() {
    super.initState();
    _loadNotes();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO: add search bar
      body: Center(
        child: _buildNotes(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _displayDialog(context);
        },
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  _buildNotes() {
    return _notes.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("You currently have 0 notes!"),
            ),
          )
        : ListView.builder(
            itemBuilder: (context, index) => _buildSingleNote(index),
            itemCount: _notes.length,
          );
  }

  _buildSingleNote(index) {
    String formattedDate =
        DateFormat('yyyy-MM-dd – kk:mm').format(_notes[index].date!);

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          setState(() {
            _notes[index].finished = !_notes[index].finished!;
          });
        },
        child: CircleAvatar(
          backgroundColor:
              _notes[index].finished == false ? Colors.red : Colors.green,
        ),
      ),
      title: Text(_notes[index].title ?? ""),
      subtitle: Row(children: [
        Spacer(),
        Text(
          formattedDate,
        ),
      ]),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotePage(
              note: _notes[index],
            ),
          ),
        );
      },
      onLongPress: () {
        _displayDeleteNote(index);
      },
    );
  }

  void _displayDeleteNote(index) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove note'),
          content: Text(
            "Are you sure you want to remove \"${_notes[index].title}\" from your notes?",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                _deleteNoteAtIndex(index);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _displayDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a new note'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: "Note title"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                _addNote(_textFieldController.text);
                _textFieldController.text = "";
                Navigator.pop(context, _textFieldController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> noteStrings = prefs.getStringList('notes') ?? [];
    setState(() {
      _notes = noteStrings.map((noteString) {
        final Map<String, dynamic> json = jsonDecode(noteString);
        return Note.fromJson(json);
      }).toList();
    });
  }

  Future<void> _saveNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> noteStrings =
        _notes.map((note) => jsonEncode(note.toJson())).toList();
    prefs.setStringList('notes', noteStrings);
  }

  Future<void> _addNote(String title) async {
    if (title.isEmpty) return;

    setState(() {
      _notes.add(Note(title));
    });
    _titleController.clear();
    await _saveNotes();
  }

  Future<void> _deleteNoteAtIndex(int index) async {
    setState(() {
      _notes.removeAt(index);
    });
    await _saveNotes();
  }

  Future<void> _clearNotes() async {
    setState(() {
      _notes.clear();
    });
    await _saveNotes();
  }

  _requestPermissions() async {
    await NotificationService().requestNotificationPermission(context);
  }
}
