class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artworkUrl,
    required this.streamUrl,
    this.category = 'Trending',
    this.isFavorite = false,
    this.lyrics = '',
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String artworkUrl;
  final String streamUrl;
  final String category;
  final bool isFavorite;
  final String lyrics;

  Song copyWith({bool? isFavorite}) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      artworkUrl: artworkUrl,
      streamUrl: streamUrl,
      category: category,
      isFavorite: isFavorite ?? this.isFavorite,
      lyrics: lyrics,
    );
  }
}
