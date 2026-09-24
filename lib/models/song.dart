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
    this.source = 'Local',
    this.sourcePageUrl = '',
    this.qualityLabel = 'Source quality',
    this.isDownloadable = true,
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
  final String source;
  final String sourcePageUrl;
  final String qualityLabel;
  final bool isDownloadable;

  Song copyWith({bool? isFavorite, String? lyrics}) => Song(
        id: id,
        title: title,
        artist: artist,
        album: album,
        artworkUrl: artworkUrl,
        streamUrl: streamUrl,
        category: category,
        isFavorite: isFavorite ?? this.isFavorite,
        lyrics: lyrics ?? this.lyrics,
        source: source,
        sourcePageUrl: sourcePageUrl,
        qualityLabel: qualityLabel,
        isDownloadable: isDownloadable,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'artworkUrl': artworkUrl,
        'streamUrl': streamUrl,
        'category': category,
        'isFavorite': isFavorite,
        'lyrics': lyrics,
        'source': source,
        'sourcePageUrl': sourcePageUrl,
        'qualityLabel': qualityLabel,
        'isDownloadable': isDownloadable,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Unknown title',
        artist: json['artist']?.toString() ?? 'Unknown artist',
        album: json['album']?.toString() ?? '',
        artworkUrl: json['artworkUrl']?.toString() ?? '',
        streamUrl: json['streamUrl']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Trending',
        isFavorite: json['isFavorite'] == true,
        lyrics: json['lyrics']?.toString() ?? '',
        source: json['source']?.toString() ?? 'Local',
        sourcePageUrl: json['sourcePageUrl']?.toString() ?? '',
        qualityLabel: json['qualityLabel']?.toString() ?? 'Source quality',
        isDownloadable: json['isDownloadable'] != false,
      );
}
