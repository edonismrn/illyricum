import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:illyricum_music/src/features/main_view/main_view.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:illyricum_music/src/features/pages/player/audio_player_notifier.dart';
import 'package:illyricum_music/src/features/pages/player/mp3_file_provider.dart';

class PlayerPage extends ConsumerWidget {
  final String songTitle;
  final String songPath;
  final int currentIndex;
  final bool isPlaying;

  const PlayerPage({
    super.key,
    required this.songTitle,
    required this.songPath,
    required this.currentIndex,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioPlayer = ref.watch(audioPlayerProvider.notifier);
    final coverPath = _getCoverPath();
    final coverMusicLogo = "assets/copertine/logo-music.png";
    final mp3Files = ref.watch(mp3FilesProvider).mp3Files;

    void _playNext() {
      if (currentIndex + 1 < mp3Files.length) {
        final nextFile = mp3Files[currentIndex + 1];
        audioPlayer.stop();
        audioPlayer.playPause(
            nextFile.path); // Passa true per avviare la riproduzione
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerPage(
              songTitle: nextFile.path.split(Platform.pathSeparator).last,
              songPath: nextFile.path,
              currentIndex: currentIndex + 1,
              isPlaying:
                  true, // Passa true per indicare che la canzone è in riproduzione
            ),
          ),
        );
      }
    }

    void _playPrevious() {
      if (currentIndex - 1 >= 0) {
        final previousFile = mp3Files[currentIndex - 1];
        audioPlayer.stop();
        audioPlayer.playPause(
            previousFile.path); // Passa true per avviare la riproduzione
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerPage(
              songTitle: previousFile.path.split(Platform.pathSeparator).last,
              songPath: previousFile.path,
              currentIndex: currentIndex - 1,
              isPlaying:
                  true, // Passa true per indicare che la canzone è in riproduzione
            ),
          ),
        );
      }
    }

    Future<void> _modifyPitch() async {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8080/modify-pitch'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        songPath,
        contentType: MediaType('audio', 'mp3'),
      ));

      request.fields['pitch'] = '1.2';

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await http.Response.fromStream(response);
        final mp3Url =
            responseBody.body; // Assuming the URL is returned in the response
        _showDownloadButton(context, mp3Url);
      } else {
        print('Error modifying pitch');
      }
    }

    final position =
        ref.watch(audioPlayerProvider.select((state) => state.position));
    final duration =
        ref.watch(audioPlayerProvider.select((state) => state.duration));
    final nextSongTriggered = ref
        .watch(audioPlayerProvider.select((state) => state.nextSongTriggered));

    final double progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    // Controlla se la canzone è finita per avviare il prossimo brano
    if (progress == 1.0 && !nextSongTriggered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(audioPlayerProvider.notifier)
            .playNext(mp3Files, currentIndex, context, songPath);
      });
    }

    return WillPopScope(
      onWillPop: () async {
        // Ferma la musica prima di navigare indietro
        audioPlayer.stop();
        return true; // Permetti la navigazione indietro
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(songTitle.replaceAll('.mp3', '')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Ferma la musica prima di tornare indietro
              audioPlayer.stop();

              // Usa Navigator.pushReplacementNamed per sostituire la schermata corrente
              Navigator.pushReplacementNamed(context,
                  MainView.routeName); // Torna alla schermata principale
            },
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (coverPath != null)
              Image.file(File(coverPath),
                  width: 360, height: 300, fit: BoxFit.cover)
            else
              Image.file(File(coverMusicLogo),
                  width: 360, height: 300, fit: BoxFit.cover),
            const SizedBox(height: 20),
            Text(songTitle.replaceAll('.mp3', ''),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Consumer(
              builder: (context, ref, child) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 50),
                          onPressed: _playPrevious,
                        ),
                        IconButton(
                          icon: Icon(
                              ref.watch(audioPlayerProvider).isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 50),
                          onPressed: () {
                            final audioPlayer =
                                ref.read(audioPlayerProvider.notifier);
                            audioPlayer.playPause(
                                songPath); // Play/Pause based on the current state
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 50),
                          onPressed: _playNext,
                        ),
                      ],
                    ),
                    Slider(
                      value: progress,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        final newPosition = Duration(
                            milliseconds:
                                (value * duration.inMilliseconds).toInt());
                        ref
                            .read(audioPlayerProvider.notifier)
                            .seek(newPosition);
                      },
                    ),
                    Text(
                      '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')} / '
                      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    if (!songTitle.endsWith(' (Speed Up).mp3')) ...[
                      Text('Speed Up', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _modifyPitch,
                        child: const Text('Rendi Speed Up'),
                      ),
                    ] else ...[
                      const SizedBox(height: 80),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _getCoverPath() {
    final baseFileName = songTitle.replaceAll('.mp3', '');
    for (final ext in ['.png', '.jpg', '.jpeg']) {
      final coverPath = 'assets/copertine/$baseFileName$ext';
      if (File(coverPath).existsSync()) {
        return coverPath;
      }
    }
    return null;
  }
}

void _showDownloadButton(BuildContext context, String mp3Url) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Pitch Modified"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("The pitch has been modified. Download the file below:"),
            TextButton(
              onPressed: () async {
                final response = await http.get(Uri.parse(mp3Url));
                if (response.statusCode == 200) {
                  // Handle the download as needed (e.g., open the file)
                  print('Downloading MP3...');
                  // Add your file saving logic here if necessary
                } else {
                  print("Failed to download file");
                }
              },
              child: Text("Download MP3"),
            ),
          ],
        ),
      );
    },
  );
}