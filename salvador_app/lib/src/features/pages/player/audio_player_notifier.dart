import 'dart:io';
import 'package:audioplayers/audioplayers.dart' as audioplayer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:illyricum_music/src/features/pages/player/player_page.dart';

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
  return AudioPlayerNotifier();
});

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  AudioPlayerNotifier() : super(AudioPlayerState()) {
    _audioPlayer.onPositionChanged.listen((position) {
      state = state.copyWith(position: position);
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      state = state.copyWith(duration: duration);
    });
  }

  final audioplayer.AudioPlayer _audioPlayer = audioplayer.AudioPlayer();

  // Play or Pause based on current state
  void playPause(String songPath) {
    if (state.isPlaying) {
      _audioPlayer.pause();
      state = state.copyWith(
          isPlaying: false); // Aggiorna lo stato a "non in riproduzione"
    } else {
      _audioPlayer.play(audioplayer.DeviceFileSource(songPath));
      state = state.copyWith(
          isPlaying: true); // Aggiorna lo stato a "in riproduzione"
    }
  }

  // Seek to a specific position in the track
  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  // Stop the audio player
  void stop() {
    _audioPlayer.stop();
    state = state.copyWith(
        isPlaying: false); // Azzera lo stato a "non in riproduzione"
  }

  void playNext(List<File> mp3Files, int currentIndex, BuildContext context,
      String songPath) {
    // Assicurati che playNext venga invocato solo una volta
    if (currentIndex + 1 < mp3Files.length && !state.nextSongTriggered) {
      final nextFile = mp3Files[currentIndex + 1];

      // Ferma la canzone corrente prima di passare alla successiva
      _audioPlayer.stop();

      // Riproduci il prossimo brano
      _audioPlayer.play(audioplayer.DeviceFileSource(nextFile.path));

      // Aggiorna lo stato per riflettere che la canzone successiva è in riproduzione
      state = state.copyWith(
        isPlaying: true,
        currentIndex: currentIndex + 1,
        nextSongTriggered:
            true, // Imposta il flag per evitare chiamate multiple
      );

      // Ora, dopo aver avviato la riproduzione, esegui il push verso la nuova pagina
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerPage(
            songTitle: nextFile.path.split(Platform.pathSeparator).last,
            songPath: nextFile.path,
            currentIndex: currentIndex + 1,
            isPlaying: true,
          ),
        ),
      );
    }
  }

  void playPrevious(List<File> mp3Files, int currentIndex) {
    if (currentIndex - 1 >= 0) {
      final previousFile = mp3Files[currentIndex - 1];
      _audioPlayer.stop();
      _audioPlayer.play(audioplayer.DeviceFileSource(previousFile.path));
      state = state.copyWith(isPlaying: true, currentIndex: currentIndex - 1);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class AudioPlayerState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final double pitch;
  final List<File> mp3Files;
  final int currentIndex;
  final bool nextSongTriggered; // Flag per evitare il doppio trigger

  AudioPlayerState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.pitch = 1.0,
    this.mp3Files = const [],
    this.currentIndex = 0,
    this.nextSongTriggered = false, // Inizializza a false
  });

  AudioPlayerState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    double? pitch,
    List<File>? mp3Files,
    int? currentIndex,
    bool? nextSongTriggered, // Aggiungi il flag
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      pitch: pitch ?? this.pitch,
      mp3Files: mp3Files ?? this.mp3Files,
      currentIndex: currentIndex ?? this.currentIndex,
      nextSongTriggered: nextSongTriggered ?? this.nextSongTriggered,
    );
  }
}

