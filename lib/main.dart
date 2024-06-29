import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<AudioPlayer> players = [];
  int numSoftWind = 4;
  List<String> softWindUrls = [];

  List<bool> isPlaying =
      List.filled(4, false); // Global list to track playing status

  List<String> getSoftWindUrls() {
    List<String> urls = [];
    for (int i = 1; i <= numSoftWind; i++) {
      urls.add(
          'https://cdn.trynoice.com/library/segments/soft_wind/soft_wind/128k/000$i.mp3');
    }
    return urls;
  }

  List<String> getChimesUrls() {
    List<String> urls = [];
    for (int i = 1; i <= numSoftWind; i++) {
      urls.add(
          'https://cdn.trynoice.com/library/segments/chimes/chimes/128k/000$i.mp3');
    }
    return urls;
  }

  @override
  void initState() {
    super.initState();
    softWindUrls = getSoftWindUrls();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Hello, World!'),
      ),
    );
  }
}

/*

*/
class AudioManager {
  static AudioPlayer player = AudioPlayer();
}
