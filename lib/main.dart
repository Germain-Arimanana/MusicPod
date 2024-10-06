import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart'; // For basename
import 'package:path_provider/path_provider.dart';
import 'package:radio_tor_net/player.dart';
//import 'player_page.dart'; // Updated import

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: MusicListPage(),
    );
  }
}

class MusicListPage extends StatefulWidget {
  @override
  _MusicListPageState createState() => _MusicListPageState();
}

class _MusicListPageState extends State<MusicListPage> {
  List<FileSystemEntity> _audioFiles = [];

  @override
  void initState() {
    super.initState();
    _fetchAudioFiles();
  }

  Future<void> _fetchAudioFiles() async {
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      await Permission.storage.request();
    }

    if (await Permission.storage.isGranted) {
      Directory dir = Directory('/storage/emulated/0/Music'); 
      List<FileSystemEntity> files = dir.listSync(recursive: true);

     
      List<FileSystemEntity> audioFiles = files.where((file) {
        return file.path.endsWith(".mp3") || file.path.endsWith(".aac");
      }).toList();

      setState(() {
        _audioFiles = audioFiles;
      });

      
      print('Files found:');
      for (var file in _audioFiles) {
        print(file.path);
      }
    } else {
      print('Storage permission not granted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: const Color.fromARGB(255, 76, 120, 216),
        centerTitle: false,
        title: Text(
          'MusicPod',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
        ),
        
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 25),
        child: ListView.builder(
          itemCount: _audioFiles.length,
          itemBuilder: (context, index) {
            FileSystemEntity file = _audioFiles[index];
            String fileName = basename(file.path);

            return ListTile(
              leading: Icon(Icons.music_note),
              title: Text(fileName),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MusicPlayerPage(
                      filePaths: _audioFiles.map((file) => file.path).toList(),
                      initialIndex: index, 
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
