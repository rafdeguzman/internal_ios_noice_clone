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
    if (index >= softWindUrls.length) index = 0;

    if (isPlaying[index]) return;

    if (index >= players.length) {
      players.add(AudioPlayer());
    }

    AudioPlayer player = players[index];

    // Set up listeners if not already set
    player.onDurationChanged.listen((Duration d) async {
      Future.delayed(d - Duration(seconds: 1), () async {
        if (!isPlaying[index]) return;

        for (double vol = 1.0; vol >= 0; vol -= 0.1) {
          await Future.delayed(Duration(milliseconds: 100));
          await player.setVolume(vol);
        }

        isPlaying[index] = false;
        playAudio((index + 1) % softWindUrls.length);
      });
    });

    player.onPlayerComplete.listen((event) {
      isPlaying[index] = false;
      print('Audio ${index + 1} completed');
    });

    await player.setVolume(0.0);
    player.setPlayerMode(PlayerMode.mediaPlayer);
    player.setReleaseMode(ReleaseMode.loop);
    isPlaying[index] = true;

    await player.play(UrlSource(softWindUrls[index]));
    print('Playing audio ${index + 1}');

    for (double vol = 0; vol <= 1; vol += 0.1) {
      await Future.delayed(Duration(milliseconds: 100));
      await player.setVolume(vol);
    }
  }

  @override
  void initState() {
    super.initState();
    softWindUrls = getSoftWindUrls();
    playAudioManager(softWindUrls);
  }

  void playAudioManager(audios) {
    AudioManager audioManager = AudioManager(audios);
    audioManager.startPlayback();
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

class AudioManager {
  final List<String> softWindUrls;
  final List<AudioPlayer> players;
  int currentIndex = 0;
  bool isTransitioning = false;
  Map<int, Duration> audioDurations = {};

  AudioManager(this.softWindUrls)
      : players = List.generate(softWindUrls.length, (_) => AudioPlayer());

  Future<void> startPlayback() async {
    await _setupAndPlayAudio(currentIndex);
  }

  Future<void> _setupAndPlayAudio(int index) async {
    final player = players[index];
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setSourceUrl(softWindUrls[index]);
    await player.setVolume(1.0);

    player.onDurationChanged.listen((Duration d) {
      print('Audio ${index + 1} duration: $d');
      audioDurations[index] = d;
      if (!isTransitioning) {
        _scheduleNextAudio(player, index);
      }
    });

    await player.resume();
    print('Playing audio ${index + 1}');
  }

  Future<void> _fadeIn(AudioPlayer player, int index) async {
    print('Fading in audio ${index + 1}');
    for (double vol = 0.0; vol <= 1.0; vol += 0.1) {
      await player.setVolume(vol);
      await Future.delayed(Duration(milliseconds: 50));
    }
  }

  Future<void> _fadeOut(AudioPlayer player, int index) async {
    print('Fading out audio ${index + 1}');
    for (double vol = 1.0; vol >= 0.0; vol -= 0.1) {
      await player.setVolume(vol);
      await Future.delayed(Duration(milliseconds: 50));
    }
  }

  void _scheduleNextAudio(AudioPlayer currentPlayer, int currentIndex) {
    if (!audioDurations.containsKey(currentIndex)) return;

    Duration totalDuration = audioDurations[currentIndex]!;
    Duration transitionPoint = totalDuration - Duration(milliseconds: 1500);

    currentPlayer.onPositionChanged.listen((position) async {
      if (isTransitioning || position < transitionPoint) return;

      isTransitioning = true;
      int nextIndex = (currentIndex + 1) % softWindUrls.length;

      // Start next audio and fade it in
      final nextPlayer = players[nextIndex];
      await _setupAndPlayAudio(nextIndex);
      _fadeIn(nextPlayer, nextIndex);

      // Wait a bit before starting to fade out the current audio
      await Future.delayed(Duration(milliseconds: 500));

      // Fade out current audio
      await _fadeOut(currentPlayer, currentIndex);

      // Stop the current player after fade out
      await currentPlayer.stop();

      currentIndex = nextIndex;
      isTransitioning = false;
    });
  }

  Future<void> stopAll() async {
    for (var player in players) {
      await player.stop();
    }
  }
}
