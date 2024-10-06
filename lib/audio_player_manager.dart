
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  AudioPlayerManager._internal();

  AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  int _currentIndex = 0;
  List<String> _filePaths = [];

  AudioPlayer get player => _audioPlayer;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isPlaying => _isPlaying;
  int get currentIndex => _currentIndex;
  List<String> get filePaths => _filePaths;

  void setFilePaths(List<String> paths) {
    _filePaths = paths;
  }

  void play(int index) async {
    if (_filePaths.isNotEmpty && index < _filePaths.length) {
      _currentIndex = index;
      await _audioPlayer.play(DeviceFileSource(_filePaths[_currentIndex]));
      _isPlaying = true;
    }
  }

  void pause() {
    _audioPlayer.pause();
    _isPlaying = false;
  }

  void resume() {
    if (_filePaths.isNotEmpty && _currentIndex < _filePaths.length) {
      _audioPlayer.play(DeviceFileSource(_filePaths[_currentIndex]));
      _isPlaying = true;
    }
  }

  void stop() {
    _audioPlayer.stop();
    _isPlaying = false;
  }

  void setIndex(int index) {
    _currentIndex = index;
  }

  void setDuration(Duration duration) {
    _duration = duration;
  }

  void setPosition(Duration position) {
    _position = position;
  }
}
