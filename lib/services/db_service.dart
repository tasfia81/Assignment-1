import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/movie.dart';

class DbService {
  static Database? _db;
  static final List<Movie> _webMovieCache = [];
  static final List<Movie> _webDownloadedMovies = [];
  static final List<Movie> _webFavorites = [];

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

  //========================= Cache list of movies ========================================
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

    for (final movie in movies) {
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

  //========================= Retrieve cached movies page-by-page ========================================
  static Future<List<Movie>> getCachedMovies({required int page, int limit = 20}) async {
    if (kIsWeb) {
      final int offset = (page - 1) * limit;
      if (offset >= _webMovieCache.length) return [];
      final end = offset + limit > _webMovieCache.length ? _webMovieCache.length : offset + limit;
      return _webMovieCache.sublist(offset, end);
    }

    final db = await database;
    final int offset = (page - 1) * limit;

    //========================== First try querying by page ======================================
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_movies',
      where: 'page = ?',
      whereArgs: [page],
      limit: limit,
    );

    if (maps.isNotEmpty) {
      return maps.map((map) => Movie.fromJson(map)).toList();
    }

    //====================== Fallback to offset query if pages aren't cleanly saved ===========================
    final List<Map<String, dynamic>> fallbackMaps = await db.query(
      'cached_movies',
      orderBy: 'id ASC',
      limit: limit,
      offset: offset,
    );

    return fallbackMaps.map((map) => Movie.fromJson(map)).toList();
  }

  //===================== Retrieve specific movie detail =============================================
  static Future<Movie?> getCachedMovie(String id) async {
    if (kIsWeb) {
      final match = _webMovieCache.where((m) => m.id == id);
      return match.isNotEmpty ? match.first : null;
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

  //========================= Clear cached movies ============================================
  static Future<void> clearCache() async {
    if (kIsWeb) {
      _webMovieCache.clear();
      return;
    }

    final db = await database;
    await db.delete('cached_movies');
  }

  //============================ Save a downloaded movie ===============================================
  static Future<void> saveDownloadedMovie(Movie movie, String localPath) async {
    if (kIsWeb) {
      if (!_webDownloadedMovies.any((m) => m.id == movie.id)) {
        _webDownloadedMovies.add(movie);
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

  // Delete a downloaded movie
  static Future<void> deleteDownloadedMovie(String id) async {
    if (kIsWeb) {
      _webDownloadedMovies.removeWhere((m) => m.id == id);
      return;
    }

    final db = await database;
    await db.delete(
      'downloaded_movies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Retrieve all downloaded movies
  static Future<List<Map<String, dynamic>>> getDownloadedMovies() async {
    if (kIsWeb) {
      return _webDownloadedMovies.map((movie) => {
        'id': movie.id,
        'title': movie.title,
        'overview': movie.overview,
        'posterUrl': movie.posterUrl,
        'videoUrl': movie.videoUrl,
        'releaseDate': movie.releaseDate,
        'duration': movie.duration,
        'rating': movie.rating,
        'localPath': '',
      }).toList();
    }

    final db = await database;
    return await db.query('downloaded_movies');
  }

  // Check if a movie is downloaded
  static Future<bool> isMovieDownloaded(String id) async {
    if (kIsWeb) {
      return _webDownloadedMovies.any((m) => m.id == id);
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

  // Save a movie to favorites
  static Future<void> saveFavorite(Movie movie) async {
    if (kIsWeb) {
      if (!_webFavorites.any((m) => m.id == movie.id)) {
        _webFavorites.add(movie);
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

  // Remove a movie from favorites
  static Future<void> removeFavorite(String id) async {
    if (kIsWeb) {
      _webFavorites.removeWhere((m) => m.id == id);
      return;
    }

    final db = await database;
    await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Retrieve all favorite movies
  static Future<List<Movie>> getFavorites() async {
    if (kIsWeb) {
      return List.from(_webFavorites);
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return maps.map((map) => Movie.fromJson(map)).toList();
  }

  // Check if a movie is favorited
  static Future<bool> isFavorite(String id) async {
    if (kIsWeb) {
      return _webFavorites.any((m) => m.id == id);
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
