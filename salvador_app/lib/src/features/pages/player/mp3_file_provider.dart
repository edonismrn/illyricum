import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
