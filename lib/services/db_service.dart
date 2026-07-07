import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class DbService {
  static Database? _db;
  static final List<Movie> _webMovieCache = [];

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final String dbPath = await getDatabasesPath();
    final String pathString = join(dbPath, 'cineb_cache.db');

    return await openDatabase(
      pathString,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_movies (
            id TEXT PRIMARY KEY,
            title TEXT,
            overview TEXT,
            posterUrl TEXT,
            videoUrl TEXT,
            releaseDate TEXT,
            duration TEXT,
            rating REAL,
            page INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE downloaded_movies (
            id TEXT PRIMARY KEY,
            title TEXT,
            overview TEXT,
            posterUrl TEXT,
            videoUrl TEXT,
            releaseDate TEXT,
            duration TEXT,
            rating REAL,
            localPath TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE favorites (
            id TEXT PRIMARY KEY,
            title TEXT,
            overview TEXT,
            posterUrl TEXT,
            videoUrl TEXT,
            releaseDate TEXT,
            duration TEXT,
            rating REAL
          )
        ''');
      },
    );
  }

  // ============================ Movie Cache helpers ============================
  static Future<void> cacheMovies(List<Movie> movies, int page) async {
    if (kIsWeb) {
      for (final movie in movies) {
        if (!_webMovieCache.any((m) => m.id == movie.id)) {
          _webMovieCache.add(movie);
        }
      }
      return;
    }

    final db = await database;
    final batch = db.batch();
    for (var movie in movies) {
      batch.insert(
        'cached_movies',
        {
          'id': movie.id,
          'title': movie.title,
          'overview': movie.overview,
          'posterUrl': movie.posterUrl,
          'videoUrl': movie.videoUrl,
          'releaseDate': movie.releaseDate,
          'duration': movie.duration,
          'rating': movie.rating,
          'page': page,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Movie>> getCachedMovies({required int page}) async {
    if (kIsWeb) {
      final int start = (page - 1) * 10;
      if (start >= _webMovieCache.length) return [];
      final int end = start + 10 > _webMovieCache.length ? _webMovieCache.length : start + 10;
      return _webMovieCache.sublist(start, end);
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_movies',
      where: 'page = ?',
      whereArgs: [page],
    );

    return List.generate(maps.length, (i) {
      return Movie.fromJson(maps[i]);
    });
  }

  static Future<Movie?> getCachedMovie(String id) async {
    if (kIsWeb) {
      final idx = _webMovieCache.indexWhere((m) => m.id == id);
      return idx != -1 ? _webMovieCache[idx] : null;
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_movies',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Movie.fromJson(maps.first);
    }
    return null;
  }

  static Future<void> clearCache() async {
    if (kIsWeb) {
      _webMovieCache.clear();
      return;
    }

    final db = await database;
    await db.delete('cached_movies');
  }

  // ============================ Downloaded Movies Persistent Web helpers ============================
  static Future<void> saveDownloadedMovie(Movie movie, String localPath) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('web_downloads') ?? [];
      final bool exists = list.any((item) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id'] == movie.id;
      });
      if (!exists) {
        final map = movie.toJson();
        map['localPath'] = localPath;
        list.add(jsonEncode(map));
        await prefs.setStringList('web_downloads', list);
      }
      return;
    }

    final db = await database;
    await db.insert(
      'downloaded_movies',
      {
        'id': movie.id,
        'title': movie.title,
        'overview': movie.overview,
        'posterUrl': movie.posterUrl,
        'videoUrl': movie.videoUrl,
        'releaseDate': movie.releaseDate,
        'duration': movie.duration,
        'rating': movie.rating,
        'localPath': localPath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteDownloadedMovie(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('web_downloads') ?? [];
      list.removeWhere((item) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id'] == id;
      });
      await prefs.setStringList('web_downloads', list);
      return;
    }

    final db = await database;
    await db.delete(
      'downloaded_movies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getDownloadedMovies() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('web_downloads') ?? [];
      return list.map((item) {
        return jsonDecode(item) as Map<String, dynamic>;
      }).toList();
    }

    final db = await database;
    return await db.query('downloaded_movies');
  }

  static Future<bool> isMovieDownloaded(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('web_downloads') ?? [];
      return list.any((item) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id'] == id;
      });
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloaded_movies',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // ============================ Favorite Movies Persistent Web helpers ============================
  static Future<void> saveFavorite(Movie movie) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('web_favorites') ?? [];
      final bool exists = list.any((item) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id'] == movie.id;
      });
      if (!exists) {
        list.add(jsonEncode(movie.toJson()));
        await prefs.setStringList('web_favorites', list);
      }
      return;
    }

    final db = await database;
    await db.insert(
      'favorites',
      {
        'id': movie.id,
        'title': movie.title,
        'overview': movie.overview,
        'posterUrl': movie.posterUrl,
        'videoUrl': movie.videoUrl,
        'releaseDate': movie.releaseDate,
        'duration': movie.duration,
        'rating': movie.rating,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeFavorite(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('web_favorites') ?? [];
      list.removeWhere((item) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id'] == id;
      });
      await prefs.setStringList('web_favorites', list);
      return;
    }

    final db = await database;
    await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Movie>> getFavorites() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('web_favorites') ?? [];
      return list.map((item) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return Movie.fromJson(map);
      }).toList();
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return maps.map((map) => Movie.fromJson(map)).toList();
  }

  static Future<bool> isFavorite(String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('web_favorites') ?? [];
      return list.any((item) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        return map['id'] == id;
      });
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
