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

  late AudioManager softWindManager = AudioManager();
  late AudioManager windChimeManager = AudioManager();
  late AudioManager rainManager = AudioManager();

  String softWindUrl =
      'https://cdn.trynoice.com/library/segments/soft_wind/soft_wind/128k/0001.mp3';
  String windChimeUrl =
      'https://cdn.trynoice.com/library/segments/wind_chimes/wind_chimes_0/128k/0002.mp3';

  String rainUrl =
      'https://cdn.trynoice.com/library/segments/rain/rain_moderate/128k/0001.mp3';

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    softWindManager.disposePlayers(softWindPlayers);
  }

  void softWindHelper() async {
    softWindUrls = AudioManager.getUrls(softWindUrl, numSoftWind);
    await softWindManager.initAudioPlayers(softWindUrls, softWindPlayers);
    print('player length ${softWindPlayers.length}');
    await softWindManager.playAudio(softWindPlayers);
  }

  void rainHelper() async {
    rainUrls = AudioManager.getUrls(rainUrl, numRain);
    await rainManager.initAudioPlayers(rainUrls, rainPlayers);
    print('player length ${rainPlayers.length}');
    await rainManager.playAudio(rainPlayers);
  }

  void windChimeHelper() async {
    windChimeUrls = AudioManager.getUrls(windChimeUrl, numWindChime);
    await windChimeManager.initAudioPlayers(windChimeUrls, windChimePlayers);
    print('player length ${windChimePlayers.length}');
    await windChimeManager.playAudio(windChimePlayers);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text('Soft Wind'),
                IconButton(
                  onPressed: () {
                    softWindHelper();
                  },
                  icon: Icon(Icons.play_arrow),
                ),
              ],
            ),
            Row(
              children: [
                Text('Rain'),
                IconButton(
                  onPressed: () {
                    rainHelper();
                  },
                  icon: Icon(Icons.play_arrow),
                ),
              ],
            ),
            Row(
              children: [
                Text('Wind Chime'),
                IconButton(
                  onPressed: () {
                    windChimeHelper();
                  },
                  icon: Icon(Icons.play_arrow),
                ),
              ],
            ),
          ],
        ),
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
  Future<void> initAudioPlayers(
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

  Future<void> fadeIn(AudioPlayer player) async {
    for (double volume = 0.0; volume <= 1.0; volume += 0.1) {
      await player.setVolume(volume);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> fadeOut(AudioPlayer player) async {
    for (double volume = 1.0; volume >= 0.0; volume -= 0.1) {
      await player.setVolume(volume);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> playAudio(List<AudioPlayer> players) async {
    for (var i = 0; i < players.length; i++) {
      late Duration duration = Duration.zero;
      // late Duration position = Duration.zero;

      final nextPlayer = players[(i + 1) % (players.length)];

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
        // position = pos;
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
        print('number of players: ${players.length}');
        await player.seek(Duration.zero);
        await player.pause();
      }
    }
    playAudio(players);
  }

  void disposePlayers(List<AudioPlayer> players) {
    for (var i = 0; i < players.length; i++) {
      players[i].dispose();
    }
  }
}
