import 'dart:async';

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
// create lists of the players, per sound.

  late List<AudioPlayer> softWindPlayers = [];
  late List<AudioPlayer> rainPlayers = [];
  late List<AudioPlayer> windChimePlayers = [];

  // get the data of each sound
  var numSoftWind = 4;
  var numRain = 5;
  var numWindChime = 2;

  late List<UrlSource> softWindUrls;
  late List<UrlSource> rainUrls;
  late List<UrlSource> windChimeUrls;

  String softWindUrl =
      'https://cdn.trynoice.com/library/segments/soft_wind/soft_wind/128k/0001.mp3';

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    AudioManager.disposePlayers(softWindPlayers);
  }

  void AudioManagerHelper() async {
    softWindUrls = AudioManager.getUrls(softWindUrl, numSoftWind);
    await AudioManager.initAudioPlayers(softWindUrls, softWindPlayers);
    print('player length ${softWindPlayers.length}');
    await AudioManager.playAudio(softWindPlayers);
  }

  @override
  void initState() {
    super.initState();
    AudioManagerHelper();
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
  This class is responsible for managing the audio player.
  It will contain lists of audio players, each tied to a sound file.
  As soon as player1 is 2 seconds of finishing, player2 will fade in and start.
  When player1 is finished, player1 stops, but stays in memory. This way, we can just call
  each player by callback functions rather than recursions. This eliminates the Future hell and race conditions.
  (supposedly)
*/
class AudioManager {
  // create lists of the players, per sound.

  late List<AudioPlayer> softWindPlayers;
  late List<AudioPlayer> rainPlayers;
  late List<AudioPlayer> windChimePlayers;

  // get the data of each sound
  var numSoftWind = 4;
  var numRain = 5;
  var numWindChime = 2;

  /*
      gets a "dirty" url, will have to be sanitized to get the clean url.
      all urls end with 000x.mp3, so split at x, add the index, use as url for UrlSource
  */
  static List<UrlSource> getUrls(String dirtyUrl, int length) {
    List<UrlSource> urls = [];
    for (int i = 0; i <= length; i++) {
      var urlPrefix = dirtyUrl.substring(0, dirtyUrl.length - 5) + i.toString();
      var urlSuffix = dirtyUrl.substring(dirtyUrl.length - 4, dirtyUrl.length);
      var cleanUrl = urlPrefix + urlSuffix;
      urls.add(UrlSource(cleanUrl));
    }
    return urls;
  }

  /*
    creates the audioplayers in accordance to the number of files
  */
  static Future<void> initAudioPlayers(
      List<UrlSource> audioUrls, List<AudioPlayer> players) async {
    players.clear();
    for (var i = 0; i < audioUrls.length; i++) {
      AudioPlayer player = AudioPlayer();
      await player.setSource(audioUrls[i]); // link the player to the file
      await player.setReleaseMode(
          ReleaseMode.stop); // set the mode after the file is completed
      await player
          .setVolume(0.0); // set the volume to 0 (will gradually fade it in)
      players.add(player);
    }
  }

  static Future<void> fadeIn(AudioPlayer player) async {
    for (double volume = 0.0; volume <= 1.0; volume += 0.1) {
      await player.setVolume(volume);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<void> fadeOut(AudioPlayer player) async {
    for (double volume = 1.0; volume >= 0.0; volume -= 0.1) {
      await player.setVolume(volume);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<void> playAudio(List<AudioPlayer> players) async {
    for (var i = 0; i < players.length; i++) {
      late Duration duration = Duration.zero;
      late Duration position = Duration.zero;

      final nextPlayer = players[(i + 1) % players.length - 1];

      players[i].onDurationChanged.listen((Duration d) {
        duration = d;
        print('file ${i + 1} duration: $d');
      });

      var player = players[i];
      print('Playing sound ${i + 1}');
      await player.resume();

      await fadeIn(player);
      bool isTransitioning = false;
      player.onPositionChanged.listen((Duration pos) {
        // while position is changing
        // get current duration
        position = pos;
        if (!isTransitioning && duration - pos <= Duration(seconds: 2)) {
          // start transitioning to play the next audio
          isTransitioning = true;
          print('Sound ${i + 1} is transitioning');

          nextPlayer.resume();
          fadeIn(nextPlayer);

          fadeOut(player);
        }
      });

      // Wait for the player to complete
      bool isCompleted = false;
      player.onPlayerComplete.listen((_) {
        if (!isCompleted) {
          isCompleted = true;
          print('Sound ${i + 1} complete');
        }
      });

      // // start playing next audio
      while (!isTransitioning) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      // while (isTransitioning && player.volume >= 0.01) {
      //   await fadeOut(player);
      // }

      // reset position to start again once audio is done
      if (isCompleted) {
        await player.seek(Duration.zero);
        await player.pause();
      }
    }
    playAudio(players);
  }

  static void disposePlayers(List<AudioPlayer> players) {
    for (var i = 0; i < players.length; i++) {
      players[i].dispose();
    }
  }
}
