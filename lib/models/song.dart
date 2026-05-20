import 'package:flutter/material.dart';

enum RepeatMode { none, one, all }
enum PlaybackSource { local, spotify, youtube }

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? genre;
  final String? filePath;
  final String? albumArtPath;
  final String? albumArtUrl;
  final int duration; // seconds
  final int? bitrate;
  final int? sampleRate;
  final String? format;
  final int? fileSize;
  final bool isFavorite;
  final int playCount;
  final DateTime? lastPlayed;
  final DateTime? dateAdded;
  final PlaybackSource source;
  final String? spotifyId;
  final String? spotifyUri;
  final String? lyrics;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.genre,
    this.filePath,
    this.albumArtPath,
    this.albumArtUrl,
    required this.duration,
    this.bitrate,
    this.sampleRate,
    this.format,
    this.fileSize,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayed,
    this.dateAdded,
    this.source = PlaybackSource.local,
    this.spotifyId,
    this.spotifyUri,
    this.lyrics,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? filePath,
    String? albumArtPath,
    String? albumArtUrl,
    int? duration,
    int? bitrate,
    int? sampleRate,
    String? format,
    int? fileSize,
    bool? isFavorite,
    int? playCount,
    DateTime? lastPlayed,
    DateTime? dateAdded,
    PlaybackSource? source,
    String? spotifyId,
    String? spotifyUri,
    String? lyrics,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      filePath: filePath ?? this.filePath,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      duration: duration ?? this.duration,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      format: format ?? this.format,
      fileSize: fileSize ?? this.fileSize,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      dateAdded: dateAdded ?? this.dateAdded,
      source: source ?? this.source,
      spotifyId: spotifyId ?? this.spotifyId,
      spotifyUri: spotifyUri ?? this.spotifyUri,
      lyrics: lyrics ?? this.lyrics,
    );
  }

  @override
  bool operator ==(Object other) => other is Song && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Playlist {
  final String id;
  final String name;
  final String? description;
  final List<Song> songs;
  final String? coverPath;
  final String? coverUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSmartPlaylist;
  final PlaybackSource source;
  final String? spotifyId;
  final Color? color;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.songs = const [],
    this.coverPath,
    this.coverUrl,
    required this.createdAt,
    this.updatedAt,
    this.isSmartPlaylist = false,
    this.source = PlaybackSource.local,
    this.spotifyId,
    this.color,
  });

  int get songCount => songs.length;

  Duration get totalDuration => Duration(
    seconds: songs.fold(0, (sum, s) => sum + s.duration),
  );

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<Song>? songs,
    String? coverPath,
    String? coverUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSmartPlaylist,
    PlaybackSource? source,
    String? spotifyId,
    Color? color,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songs: songs ?? this.songs,
      coverPath: coverPath ?? this.coverPath,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSmartPlaylist: isSmartPlaylist ?? this.isSmartPlaylist,
      source: source ?? this.source,
      spotifyId: spotifyId ?? this.spotifyId,
      color: color ?? this.color,
    );
  }
}

class Album {
  final String id;
  final String name;
  final String artist;
  final List<Song> songs;
  final String? coverPath;
  final String? coverUrl;
  final int? year;
  final String? genre;
  final PlaybackSource source;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    this.songs = const [],
    this.coverPath,
    this.coverUrl,
    this.year,
    this.genre,
    this.source = PlaybackSource.local,
  });

  int get songCount => songs.length;
}

class Artist {
  final String id;
  final String name;
  final List<Album> albums;
  final List<Song> songs;
  final String? imageUrl;
  final String? imagePath;
  final int? monthlyListeners;

  const Artist({
    required this.id,
    required this.name,
    this.albums = const [],
    this.songs = const [],
    this.imageUrl,
    this.imagePath,
    this.monthlyListeners,
  });

  int get albumCount => albums.length;
  int get songCount => songs.length;
}
