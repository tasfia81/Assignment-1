import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/movie.dart';

class FloatingPlayerManager extends ChangeNotifier {
  static final FloatingPlayerManager _instance = FloatingPlayerManager._internal();
  factory FloatingPlayerManager() => _instance;
  FloatingPlayerManager._internal();

  Movie? _movie;
  Movie? get movie => _movie;

  VideoPlayerController? _videoPlayerController;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  ChewieController? _chewieController;
  ChewieController? get chewieController => _chewieController;

  bool _isMinimized = false;
  bool get isMinimized => _isMinimized;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // Initialize and play a video (either from URL or local file path)
  Future<void> playMovie(Movie movie, {String? localFilePath}) async {
    // If playing the same movie and it's minimized, just restore it
    if (_movie?.id == movie.id && _isPlaying) {
      restore();
      return;
    }

    //========================== Stop current playback first ===========================================
    await stop();

    _movie = movie;
    _isPlaying = true;
    _isMinimized = false;
    notifyListeners();

    try {
      if (localFilePath != null && localFilePath.isNotEmpty) {
        _videoPlayerController = VideoPlayerController.file(File(localFilePath));
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(movie.videoUrl));
      }

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false, // Prevents browser autoplay blocking policies
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        // Premium customized UI colors
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.deepPurple,
          handleColor: Colors.deepPurpleAccent,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white10,
        ),
      );
    } catch (e, stack) {
      debugPrint('Error initializing video player: $e\n$stack');
      _isPlaying = false;
      _movie = null;
      _videoPlayerController = null;
      _chewieController = null;
    }
    notifyListeners();
  }

  void minimize() {
    if (!_isPlaying) return;
    _isMinimized = true;
    notifyListeners();
  }

  void restore() {
    if (!_isPlaying) return;
    _isMinimized = false;
    notifyListeners();
  }

  Future<void> stop() async {
    _isPlaying = false;
    _isMinimized = false;
    _movie = null;

    final oldChewie = _chewieController;
    final oldVideo = _videoPlayerController;

    _chewieController = null;
    _videoPlayerController = null;
    notifyListeners();

    if (oldChewie != null) {
      oldChewie.dispose();
    }
    if (oldVideo != null) {
      await oldVideo.dispose();
    }
  }
}
