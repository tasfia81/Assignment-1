import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'db_service.dart';
import '../models/movie.dart';

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Map<String, double> progressOf = {};
  final Map<String, TaskStatus> statusOf = {};
  final Map<String, Movie> _movieQueue = {};
  final Map<String, Timer> _webTimers = {};

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      // Skip background downloader registration on web
      return;
    }

    //========================== Configure notifications ==========================================
    FileDownloader().configureNotification(
      running: const TaskNotification('Downloading Movie', '{filename} - {progress}'),
      complete: const TaskNotification('Download Complete', '{filename} saved offline'),
      error: const TaskNotification('Download Failed', 'Failed to download {filename}'),
      progressBar: true,
      tapOpensFile: false,
    );

    //=========================== Listen to updates ===================================================
    FileDownloader().updates.listen((update) async {
      final String movieId = update.task.taskId;

      if (update is TaskStatusUpdate) {
        statusOf[movieId] = update.status;
        if (kDebugMode) {
          print('Download Task status changed: $movieId -> ${update.status}');
        }

        if (update.status == TaskStatus.complete) {
          progressOf[movieId] = 1.0;
          final Movie? movie = _movieQueue[movieId];
          if (movie != null) {
            final String localPath = await getFilePath(update.task);
            await DbService.saveDownloadedMovie(movie, localPath);
            _movieQueue.remove(movieId);
          } else {
            final cachedMovie = await DbService.getCachedMovie(movieId);
            if (cachedMovie != null) {
              final String localPath = await getFilePath(update.task);
              await DbService.saveDownloadedMovie(cachedMovie, localPath);
            }
          }
        } else if (update.status == TaskStatus.failed ||
                   update.status == TaskStatus.canceled) {
          progressOf.remove(movieId);
          _movieQueue.remove(movieId);
        }
        notifyListeners();
      } else if (update is TaskProgressUpdate) {
        progressOf[movieId] = update.progress;
        notifyListeners();
      }
    });

    // Track existing background tasks (helps resume tracking if app restarted)
    await FileDownloader().trackTasks();
  }

  Future<String> getFilePath(Task task) async {
    if (kIsWeb) return '';
    final docsDir = await getApplicationDocumentsDirectory();
    final String subDir = task.directory;
    if (subDir.isNotEmpty) {
      return p.join(docsDir.path, subDir, task.filename);
    }
    return p.join(docsDir.path, task.filename);
  }

  Future<void> startDownload(Movie movie) async {
    await initialize();

    final String movieId = movie.id;

    if (kIsWeb) {
      _movieQueue[movieId] = movie;
      progressOf[movieId] = 0.0;
      statusOf[movieId] = TaskStatus.running;
      notifyListeners();

      //============================ Mock download with a timer on web =============================================
      double currentProgress = 0.0;
      _webTimers[movieId]?.cancel();
      _webTimers[movieId] = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
        currentProgress += 0.1;
        if (currentProgress >= 1.0) {
          timer.cancel();
          _webTimers.remove(movieId);
          progressOf[movieId] = 1.0;
          statusOf[movieId] = TaskStatus.complete;
          await DbService.saveDownloadedMovie(movie, '');
          _movieQueue.remove(movieId);
        } else {
          progressOf[movieId] = currentProgress;
        }
        notifyListeners();
      });
      return;
    }

    final String filename = '${movie.title.replaceAll(' ', '_')}.mp4';

    final task = DownloadTask(
      taskId: movieId,
      url: movie.videoUrl,
      filename: filename,
      baseDirectory: BaseDirectory.applicationDocuments, // Sandboxed!
      directory: 'videos',
      updates: Updates.statusAndProgress,
      allowPause: true,
      displayName: movie.title,
    );

    _movieQueue[movieId] = movie;
    progressOf[movieId] = 0.0;
    statusOf[movieId] = TaskStatus.enqueued;
    notifyListeners();

    final success = await FileDownloader().enqueue(task);
    if (!success) {
      statusOf[movieId] = TaskStatus.failed;
      progressOf.remove(movieId);
      _movieQueue.remove(movieId);
      notifyListeners();
    }
  }

  Future<void> cancelDownload(String movieId) async {
    if (kIsWeb) {
      _webTimers[movieId]?.cancel();
      _webTimers.remove(movieId);
      progressOf.remove(movieId);
      statusOf.remove(movieId);
      _movieQueue.remove(movieId);
      notifyListeners();
      return;
    }

    final task = await FileDownloader().taskForId(movieId);
    if (task != null) {
      await FileDownloader().cancelTasksWithIds([movieId]);
    }
    progressOf.remove(movieId);
    statusOf.remove(movieId);
    _movieQueue.remove(movieId);
    notifyListeners();
  }

  Future<void> pauseDownload(String movieId) async {
    if (kIsWeb) {
      _webTimers[movieId]?.cancel();
      statusOf[movieId] = TaskStatus.paused;
      notifyListeners();
      return;
    }

    final task = await FileDownloader().taskForId(movieId);
    if (task is DownloadTask) {
      await FileDownloader().pause(task);
    }
  }

  Future<void> resumeDownload(String movieId) async {
    if (kIsWeb) {
      statusOf[movieId] = TaskStatus.running;
      notifyListeners();

      final movie = _movieQueue[movieId];
      if (movie == null) return;

      double currentProgress = progressOf[movieId] ?? 0.0;
      _webTimers[movieId]?.cancel();
      _webTimers[movieId] = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
        currentProgress += 0.1;
        if (currentProgress >= 1.0) {
          timer.cancel();
          _webTimers.remove(movieId);
          progressOf[movieId] = 1.0;
          statusOf[movieId] = TaskStatus.complete;
          await DbService.saveDownloadedMovie(movie, '');
          _movieQueue.remove(movieId);
        } else {
          progressOf[movieId] = currentProgress;
        }
        notifyListeners();
      });
      return;
    }

    final task = await FileDownloader().taskForId(movieId);
    if (task is DownloadTask) {
      await FileDownloader().resume(task);
    }
  }

  Future<void> deleteDownload(String movieId) async {
    if (kIsWeb) {
      await DbService.deleteDownloadedMovie(movieId);
      progressOf.remove(movieId);
      statusOf.remove(movieId);
      notifyListeners();
      return;
    }

    final bool isDownloaded = await DbService.isMovieDownloaded(movieId);
    if (isDownloaded) {
      final List<Map<String, dynamic>> downloadedList = await DbService.getDownloadedMovies();
      final downloadedMovie = downloadedList.firstWhere((element) => element['id'] == movieId);
      final String path = downloadedMovie['localPath'] as String;

      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting file: $e');
        }
      }

      await DbService.deleteDownloadedMovie(movieId);
    }

    progressOf.remove(movieId);
    statusOf.remove(movieId);
    notifyListeners();
  }

  bool isActive(String movieId) {
    final status = statusOf[movieId];
    return status != null &&
        (status == TaskStatus.running ||
         status == TaskStatus.enqueued ||
         status == TaskStatus.paused ||
         status == TaskStatus.waitingToRetry);
  }
}
