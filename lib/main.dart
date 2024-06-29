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

  void playAudio(int index) async {
    if (index >= softWindUrls.length) index = 0; // Loop back to the first audio

    if (isPlaying[index]) return; // If already playing, return

    // Ensure the players list can hold the new player
    if (index >= players.length) {
      players.add(AudioPlayer()); // Add new player if needed
    }

    AudioPlayer player = players[index]; // Use existing or new player
    await player.setVolume(1.0);
    player.setPlayerMode(PlayerMode.mediaPlayer);
    player.setReleaseMode(ReleaseMode.loop);

    // Mark as playing
    isPlaying[index] = true;

    // Listen for duration update to schedule next audio
    player.onDurationChanged.listen((Duration d) async {
      var duration = d;
      // Schedule next audio 2 seconds before current ends
      Future.delayed(duration - Duration(seconds: 2), () {
        if (index + 1 < softWindUrls.length) {
          playAudio(index + 1); // Schedule next audio
        }
      });
    });

    // Listen for audio completion to update playing status
    player.onPlayerComplete.listen((event) {
      print('Audio ${index + 1} completed');
      isPlaying[index] = false; // Mark as not playing
    });

    await player.play(UrlSource(softWindUrls[index]));
    print('Playing audio ${index + 1}');
  }

  @override
  void initState() {
    super.initState();
    softWindUrls = getSoftWindUrls();
    playAudio(0); // Start playing from the first audio
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Hello, World!'),
      ),
    );
  }
}
