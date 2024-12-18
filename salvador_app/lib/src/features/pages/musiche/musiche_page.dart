import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:illyricum_music/src/features/pages/player/audio_player_notifier.dart';
import 'package:illyricum_music/src/features/pages/player/mp3_file_provider.dart';
import 'package:illyricum_music/src/features/pages/player/player_page.dart';

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

  // Se non ci sono file MP3 o risultati della ricerca
  final displayFiles = _filteredFiles.isEmpty
      ? Center(
          child: Text(
            _searchController.text.isEmpty
                ? 'Nessun file MP3 trovato' // Nessun file iniziale
                : 'Nessun risultato per "${_searchController.text}"', // Nessun risultato di ricerca
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
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

  Future<bool> _showDeleteDialog(BuildContext context, FileSystemEntity file, String baseFileName) async {

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