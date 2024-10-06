import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart';
import 'dart:io';

class MusicPlayerPage extends StatefulWidget {
  final List<String> filePaths;
  final int initialIndex;

  MusicPlayerPage({required this.filePaths, required this.initialIndex});

  @override
  _MusicPlayerPageState createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with SingleTickerProviderStateMixin {
  AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late int _currentIndex;
  bool _isPlaying = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // _playMusic();
    // _setupNotifications();

    _audioPlayer.onDurationChanged.listen((d) {
      setState(() {
        _duration = d;
      });
    });

    _audioPlayer.onPositionChanged.listen((p) {
      setState(() {
        _position = p;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _nextTrack();
    });

    _animationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: false);

    _slideAnimation = Tween<Offset>(
      begin: Offset(-1, 0),
      end: Offset(1, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }


  Future<void> _setupNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'music_channel_id',
      'Music Player',
      description: 'Music control notifications',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'music_channel_id',
      'Music Player',
      channelDescription: 'Music control notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      visibility: NotificationVisibility.public,
      ongoing: true,
      styleInformation: MediaStyleInformation(),
      actions: [
        AndroidNotificationAction(
          'prev',
          'Previous',
        ),
        AndroidNotificationAction(
          'play_pause',
          'Play/Pause',
        ),
        AndroidNotificationAction(
          'next',
          'Next',
        ),
      ],
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Music Player',
      'Playing ${basename(widget.filePaths[_currentIndex])}',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer
          .play(DeviceFileSource(widget.filePaths[_currentIndex]));
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
    await _updateNotification();
  }

  Future<void> _updateNotification() async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'music_channel_id',
      'Music Player',
      channelDescription: 'Music control notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      visibility: NotificationVisibility.public,
      ongoing: true,
      styleInformation: const MediaStyleInformation(),
      actions: [
        const AndroidNotificationAction(
          'prev',
          'Previous',
        ),
        AndroidNotificationAction(
          'play_pause',
          _isPlaying ? 'Pause' : 'Play',
        ),
        const AndroidNotificationAction(
          'next',
          'Next',
        ),
      ],
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Music Player',
      'Playing ${basename(widget.filePaths[_currentIndex])}',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> _playMusic() async {
    await _audioPlayer.play(DeviceFileSource(widget.filePaths[_currentIndex]));
    setState(() {
      _isPlaying = true;
    });
    await _updateNotification();
  }

  void _prevTrack() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _playMusic();
      });
    }
  }

  void _nextTrack() {
    if (_currentIndex < widget.filePaths.length - 1) {
      setState(() {
        _currentIndex++;
        _playMusic();
      });
    } else {
      setState(() {
        _currentIndex = 0;
        _playMusic();
      });
    }
  }

  void _stopMusic() {
    _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
    _flutterLocalNotificationsPlugin.cancel(0); // Cancel notification
  }

  Widget _buildAlbumArt() {
    final filePath = widget.filePaths[_currentIndex];
    final thumbnailPath = filePath.replaceAll(RegExp(r'\.mp3$'), '.jpg');

    return File(thumbnailPath).existsSync()
        ? Image.file(File(thumbnailPath),
            width: 350, height: 350, fit: BoxFit.cover)
        : Icon(Icons.music_note, size: 350, color: Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    String fileName = basename(widget.filePaths[_currentIndex]);

    return Scaffold(
      appBar: AppBar(
       
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildAlbumArt(),
              ),
              SizedBox(height: 20),
              SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      fileName,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Slider(
                activeColor: Colors.black,
                min: 0.0,
                max: _duration.inSeconds.toDouble(),
                value: _position.inSeconds.toDouble(),
                onChanged: (value) async {
                  final position = Duration(seconds: value.toInt());
                  await _audioPlayer.seek(position);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_position.toString().split('.').first} ",
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    "${_duration.toString().split('.').first}",
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.skip_previous, size: 60),
                    onPressed: _prevTrack,
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 60,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, size: 60),
                    onPressed: _nextTrack,
                  ),
                  /*
                  IconButton(
                    icon: Icon(Icons.stop, size: 60),
                    onPressed: _stopMusic,
                  ),
                  */
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
