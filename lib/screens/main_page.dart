import 'package:flutter/material.dart';
import 'package:memorycare/screens/home_page.dart';
import 'package:memorycare/screens/map_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const List<Tab> myTabs = <Tab>[
    Tab(text: 'Notes'),
    Tab(text: 'Map'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: myTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("MemoryCare"),
          centerTitle: true,
          backgroundColor: const Color(0xff553555),
          bottom: const TabBar(
            tabs: myTabs,
          ),
          actions: [
            IconButton(
              onPressed: () {
                _openEmailDialog();
              },
              icon: const Icon(Icons.email),
            )
          ],
        ),
        body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              HomePage(),
              MapPage(),
            ]),
      ),
    );
  }

  _setGuardianEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('guardian_email', email);
  }

  _openEmailDialog() {
    String updatedEmail = ''; // Variable to store the updated email

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Guardian Email'),
          content: TextField(
            onChanged: (value) {
              updatedEmail = value; // Update the email variable as user types
            },
            decoration: const InputDecoration(
              hintText: 'Enter the new email',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close the dialog without saving changes
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Email updated: $updatedEmail'),
                  ),
                );
                _setGuardianEmail(updatedEmail);

                Navigator.of(context).pop(); // Close the dialog after saving
              },
            ),
          ],
        );
      },
    );
  }
}
