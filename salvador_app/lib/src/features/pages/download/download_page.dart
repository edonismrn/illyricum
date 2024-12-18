import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DownloadPage extends StatefulWidget {
  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _searchController = TextEditingController();
  final _urlController = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  String _searchQuery = '';
  Map<int, double> _imageScale = {}; // Mappa per gestire la scala di ogni copertina

  // Function to show loading dialog with progress
  void _showLoadingDialog(String title, double progress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('${(progress * 100).toStringAsFixed(1)}% completato'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Function to close loading dialog
  void _closeLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Function to search for videos based on the query
  Future<void> _searchVideos() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searchQuery = query;
      _searchResults = [];
    });

    double progress = 0.0;
    _showLoadingDialog('Cercando video...', progress);

    final response = await http.get(Uri.parse('http://127.0.0.1:8080/search?query=$query'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          _searchResults = List<Map<String, String>>.from(
            (data['video_info'] as List).map((item) => {
              'title': item['title'] as String,
              'url': item['url'] as String,
              'thumbnail': item['thumbnail'] as String,
            }),
          );
        });
      }
    } else {
      print('Error during search');
    }

    _closeLoadingDialog();
  }

  // Function to download and convert the video from the provided URL
  Future<void> _downloadAndConvert(String videoUrl) async {
    double progress = 0.0;
    _showLoadingDialog('Scaricando e convertendo...', progress);

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8080/download-and-convert'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': videoUrl}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('File MP3 URL: ${data['mp3_url']}');
      // You can now download the MP3 or play it
    } else {
      print('Error during download and conversion');
    }

    _closeLoadingDialog();
  }

  // Function to handle URL-based download and conversion
  Future<void> _downloadFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    double progress = 0.0;
    _showLoadingDialog('Scaricando e convertendo...', progress);

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8080/download-and-convert'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('File MP3 URL: ${data['mp3_url']}');
      // You can now download the MP3 or play it
    } else {
      print('Error during download and conversion');
    }

    _closeLoadingDialog();
  }

  // Function to clear the search input
  void _clearSearchInput() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _searchQuery = '';
    });
  }

  // Function to clear the URL input
  void _clearUrlInput() {
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cerca e Scarica Musica')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search input for video title or artist
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Inserisci titolo o artista',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: _clearSearchInput, // Clear search input
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _searchVideos,
              child: Text('Cerca'),
            ),
            SizedBox(height: 20),
            // Input for direct URL-based download
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Inserisci URL del video',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: _clearUrlInput, // Clear URL input
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _downloadFromUrl,
              child: Text('Scarica da URL'),
            ),
            SizedBox(height: 20),
            // Display search results header
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Risultati per "${_searchQuery}":',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            // Container for search results
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final video = _searchResults[index];
                  final videoTitle = video['title']!;
                  final videoUrl = video['url']!;
                  final thumbnailUrl = video['thumbnail']!;

                  return GestureDetector(
                    onTap: () async {
                      await _downloadAndConvert(videoUrl);
                    },
                    child: MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _imageScale[index] = 1.1; // Enlarge image when hover starts
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _imageScale[index] = 1.0; // Restore image size when hover ends
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // Image with hover effect
                            Container(
                              width: 100.0, // Specify a fixed width
                              height: 100.0, // Specify a fixed height
                              child: Transform.scale(
                                scale: _imageScale[index] ?? 1.0, // Apply scaling transformation
                                child: Image.network(
                                  thumbnailUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            // Title
                            Expanded(
                              child: Text(
                                videoTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
