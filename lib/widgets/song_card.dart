import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/download_service.dart';
import '../services/library_store.dart';

class SongCard extends StatelessWidget {
  const SongCard({
    required this.song,
    required this.onTap,
    super.key,
  });

  final Song song;
  final VoidCallback onTap;

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                libraryStore.isFavorite(song.id)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              title: Text(
                libraryStore.isFavorite(song.id)
                    ? 'Remove favorite'
                    : 'Add to favorites',
              ),
              onTap: () => Navigator.pop(context, 'favorite'),
            ),
            ListTile(
              enabled: song.isDownloadable || libraryStore.isDownloaded(song.id),
              leading: Icon(
                libraryStore.isDownloaded(song.id)
                    ? Icons.delete_outline_rounded
                    : Icons.download_rounded,
              ),
              title: Text(
                libraryStore.isDownloaded(song.id)
                    ? 'Remove download'
                    : song.isDownloadable
                        ? 'Download for offline'
                        : 'Stream only (download unavailable)',
              ),
              onTap: song.isDownloadable || libraryStore.isDownloaded(song.id)
                  ? () => Navigator.pop(context, 'download')
                  : null,
            ),
            if (libraryStore.playlistNames.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Add to playlist'),
                onTap: () => Navigator.pop(context, 'playlist'),
              ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == 'favorite') {
      await libraryStore.toggleFavorite(song);
      return;
    }

    if (action == 'download') {
      if (libraryStore.isDownloaded(song.id)) {
        await libraryStore.removeDownload(song);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download removed.')),
          );
        }
        return;
      }

      if (!song.isDownloadable) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This source does not mark the track as downloadable.'),
            ),
          );
        }
        return;
      }

      try {
        await DownloadService.instance.download(
          song,
          onProgress: (_) {},
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved for offline playback.')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: $error')),
          );
        }
      }
      return;
    }

    if (action == 'playlist') {
      if (!context.mounted) return;
      final selected = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => ListView(
          shrinkWrap: true,
          children: libraryStore.playlistNames
              .map(
                (name) => ListTile(
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(name),
                  onTap: () => Navigator.pop(context, name),
                ),
              )
              .toList(),
        ),
      );
      if (selected != null) {
        await libraryStore.addToPlaylist(selected, song);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: libraryStore,
      builder: (context, _) {
        final favorite = libraryStore.isFavorite(song.id);
        final downloaded = libraryStore.isDownloaded(song.id);

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            onLongPress: () => _showActions(context),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      song.artworkUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallbackArt(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .65),
                          ),
                        ),
                        Text(
                          song.source + ' • ' + song.qualityLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: Colors.white54),
                        ),
                        if (downloaded)
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              'Offline available',
                              style: TextStyle(
                                color: Color(0xFFFFC857),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (favorite)
                    const Icon(
                      Icons.favorite_rounded,
                      size: 19,
                      color: Color(0xFFFFC857),
                    ),
                  IconButton(
                    tooltip: 'Song actions',
                    onPressed: () => _showActions(context),
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                  const Icon(Icons.play_circle_fill_rounded, size: 34),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackArt() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0x22FFC857),
      alignment: Alignment.center,
      child: const Icon(Icons.music_note_rounded),
    );
  }
}
