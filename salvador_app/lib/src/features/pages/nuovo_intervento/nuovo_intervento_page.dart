import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart' as audioplayer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart'; // Import just_audio
import 'package:salvador_task_management/src/features/main_view/main_view.dart';
import 'package:watcher/watcher.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MusichePage extends ConsumerStatefulWidget {
  const MusichePage({super.key});

  @override
  _MusichePageState createState() => _MusichePageState();
}

class _MusichePageState extends ConsumerState<MusichePage> {
  TextEditingController _searchController = TextEditingController();
  List<FileSystemEntity> _filteredFiles = [];

  @override
  void initState() {
    super.initState();
    // Carica i file MP3 quando la pagina viene caricata
    _loadMp3Files();
  }

  // Funzione per caricare i file MP3 tramite il provider
  void _loadMp3Files() async {
    // Carica i file MP3 tramite il provider
    await ref.read(mp3FilesProvider.notifier).loadMp3Files();
    // Recupera i file caricati e aggiorna la lista dei file filtrati
    final mp3FilesState = ref.read(mp3FilesProvider);
    setState(() {
      _filteredFiles = mp3FilesState.mp3Files; // Aggiungi i file a _filteredFiles
    });
  }

  @override
  Widget build(BuildContext context) {
    // Se i file sono ancora in fase di caricamento (vuoto), mostra un indicatore di caricamento
    if (_filteredFiles.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Funzione per filtrare i file in base alla query di ricerca
    void _filterFiles(String query) {
      setState(() {
        if (query.isEmpty) {
          // Se la query è vuota, mostra tutti i file MP3
          _filteredFiles = ref.read(mp3FilesProvider).mp3Files;
        } else {
          // Filtra i file MP3 in base al testo della ricerca
          _filteredFiles = ref.read(mp3FilesProvider).mp3Files
              .where((file) => file.path
                  .split(Platform.pathSeparator)
                  .last
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();
        }
      });
    }

    // Ascolta ogni cambiamento nel campo di ricerca
    _searchController.addListener(() {
      _filterFiles(_searchController.text);
    });

    // Se non ci sono file, mostra un messaggio
    final displayFiles = _filteredFiles.isEmpty
        ? const Center(child: Text('Nessun file MP3 trovato'))
        : ListView.builder(
            itemCount: _filteredFiles.length,
            itemBuilder: (context, index) {
              final file = _filteredFiles[index];
              final baseFileName = file.path
                  .split(Platform.pathSeparator)
                  .last
                  .replaceAll('.mp3', '');

              String? coverPath;

              // Cerca una copertina associata al file
              for (final ext in ['.png', '.jpg', '.jpeg']) {
                final path = 'assets/copertine/$baseFileName$ext';
                if (File(path).existsSync()) {
                  coverPath = path;
                  break;
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 16.0 : 8.0,
                  bottom: 8.0,
                ),
                child: ListTile(
                  leading: Container(
                    width: 90, // Impostiamo la larghezza e l'altezza per ottenere un quadrato
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      image: coverPath != null
                          ? DecorationImage(
                              image: AssetImage(coverPath),
                              fit: BoxFit.cover, // Adatta l'immagine all'interno del quadrato
                            )
                          : null,
                    ),
                    child: coverPath == null
                        ? const Icon(Icons.music_note,
                            size: 50, color: Colors.blue)
                        : null,
                  ),
                  title: Text(file.path
                      .split(Platform.pathSeparator)
                      .last
                      .replaceAll('.mp3', '')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmed =
                          await _showDeleteDialog(context, file, baseFileName);
                      if (confirmed) {
                        await ref
                            .read(mp3FilesProvider.notifier)
                            .deleteFile(file, baseFileName);

                        // Rimuovi il file dalla lista locale
                        setState(() {
                          _filteredFiles.remove(file);
                        });
                      }
                    },
                  ),
                  onTap: () {
                    final audioPlayer = ref.read(audioPlayerProvider.notifier);
                    final isPlaying = ref.read(audioPlayerProvider).isPlaying;
                    audioPlayer.playPause(file.path); // Riproduce o mette in pausa il file selezionato

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerPage(
                          songTitle:
                              file.path.split(Platform.pathSeparator).last,
                          songPath: file.path,
                          currentIndex: index,
                          isPlaying: true,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );

    return Scaffold(
      body: Column(
        children: [
          // Posizioniamo la barra di ricerca in alto a destra con uno stile moderno
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 300, // Puoi regolare la larghezza della barra di ricerca
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30), // Bordi arrotondati
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2), // Ombra leggera
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 3), // Spostamento dell'ombra
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cerca...',
                    prefixIcon: Icon(Icons.search, color: Colors.blue),
                    border: InputBorder.none, // Rimuovi il bordo predefinito
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20), // Padding interno
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: displayFiles), // Rende il ListView scrollabile
        ],
      ),
    );
  }

  Future<bool> _showDeleteDialog(
      BuildContext context, FileSystemEntity file, String baseFileName) async {
    final actualFile = file is File ? file : File(file.path);

    return await showDialog<bool>(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
            'Sei sicuro di voler eliminare "${file.path.split(Platform.pathSeparator).last.replaceAll('.mp3', '')}"?'),
        content: const Text('Questa azione non può essere annullata.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    }) ?? false;
  }
}


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
            nextFile.path); // Passa `true` per avviare la riproduzione
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerPage(
              songTitle: nextFile.path.split(Platform.pathSeparator).last,
              songPath: nextFile.path,
              currentIndex: currentIndex + 1,
              isPlaying:
                  true, // Passa `true` per indicare che la canzone è in riproduzione
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
            previousFile.path); // Passa `true` per avviare la riproduzione
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerPage(
              songTitle: previousFile.path.split(Platform.pathSeparator).last,
              songPath: previousFile.path,
              currentIndex: currentIndex - 1,
              isPlaying:
                  true, // Passa `true` per indicare che la canzone è in riproduzione
            ),
          ),
        );
      }
    }

    Future<void> _modifyPitch() async {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5000/modify-pitch'),
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

class Mp3FilesState {
  final List<File> mp3Files;

  Mp3FilesState(this.mp3Files);
}

class Mp3FilesProvider extends StateNotifier<Mp3FilesState> {
  Mp3FilesProvider() : super(Mp3FilesState([]));

  Future<void> loadMp3Files() async {
    final directory = Directory('assets/musiche');
    final mp3Files = await directory
        .list()
        .where((entity) =>
            entity is File &&
            entity.path.endsWith('.mp3')) // Filtra solo i File
        .map((entity) =>
            entity as File) // Cast esplicito da FileSystemEntity a File
        .toList();

    // Notifica che i file sono stati caricati
    state = Mp3FilesState(mp3Files);
  }

  Future<void> deleteFile(FileSystemEntity file, String baseFileName) async {
    try {
      // Verifica se il file è di tipo File
      if (file is File) {
        // Elimina il file
        await file.delete();
        print("File eliminato: ${file.path}");
      } else {
        print("Il file non è un'istanza di File.");
      }
      // Ricarica la lista dei file dopo la cancellazione
      loadMp3Files();
    } catch (e) {
      print("Errore nella cancellazione del file: $e");
    }
  }
}

final mp3FilesProvider =
    StateNotifierProvider<Mp3FilesProvider, Mp3FilesState>((ref) {
  return Mp3FilesProvider();
});
