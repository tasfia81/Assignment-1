import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:chewie/chewie.dart';
import '../models/movie.dart';
import '../services/db_service.dart';
import '../services/download_service.dart';
import '../services/player_manager.dart';

class DetailScreen extends StatefulWidget {
  final Movie movie;

  const DetailScreen({super.key, required this.movie});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isOffline = false;
  bool _isDownloaded = false;
  bool _isFavorite = false;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final bool offline = results.isEmpty ||
          (results.length == 1 && results.first == ConnectivityResult.none);
      if (offline != _isOffline) {
        if (mounted) {
          setState(() {
            _isOffline = offline;
          });
        }
      }
    });
  }

  Future<void> _checkStatus() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    final bool offline = results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);

    final bool downloaded = await DbService.isMovieDownloaded(widget.movie.id);
    final bool favorited = await DbService.isFavorite(widget.movie.id);
    String? path;
    if (downloaded) {
      final List<Map<String, dynamic>> downloadedList = await DbService.getDownloadedMovies();
      final downloadedMovie = downloadedList.firstWhere((element) => element['id'] == widget.movie.id);
      path = downloadedMovie['localPath'] as String;
    }

    if (mounted) {
      setState(() {
        _isOffline = offline;
        _isDownloaded = downloaded;
        _isFavorite = favorited;
        _localPath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Auto-minimize video playback to float in-app when popping detail page
          final manager = FloatingPlayerManager();
          if (manager.isPlaying && manager.movie?.id == widget.movie.id && !manager.isMinimized) {
            manager.minimize();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F14),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18.r),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.movie.title,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18.sp),
          ),
          actions: [
            // Favorites heart toggler
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isFavorite ? Colors.redAccent : Colors.white,
                size: 24.r,
              ),
              onPressed: () async {
                if (_isFavorite) {
                  await DbService.removeFavorite(widget.movie.id);
                } else {
                  await DbService.saveFavorite(widget.movie);
                }
                setState(() {
                  _isFavorite = !_isFavorite;
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
                      backgroundColor: Colors.purple,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            SizedBox(width: 8.w),
          ],
        ),
        body: ListenableBuilder(
          listenable: FloatingPlayerManager(),
          builder: (context, _) {
            final playerManager = FloatingPlayerManager();
            final bool isCurrentlyPlayingThis = playerManager.isPlaying &&
                playerManager.movie?.id == widget.movie.id &&
                !playerManager.isMinimized;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Player OR Poster Backdrop
                  Container(
                    width: double.infinity,
                    height: 220.h,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.white10, width: 1.h),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isCurrentlyPlayingThis && playerManager.chewieController != null
                        ? Stack(
                            children: [
                              Chewie(controller: playerManager.chewieController!),
                              Positioned(
                                top: 8.h,
                                left: 8.w,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white, size: 20.r),
                                    onPressed: () {
                                      playerManager.minimize();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: widget.movie.posterUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 600,
                              ),
                              Container(
                                color: Colors.black45,
                              ),
                              Center(
                                child: FloatingActionButton(
                                  backgroundColor: Colors.deepPurpleAccent,
                                  onPressed: () async {
                                    if (_isDownloaded && _localPath != null) {
                                      await playerManager.playMovie(widget.movie, localFilePath: _localPath);
                                    } else if (!_isOffline) {
                                      await playerManager.playMovie(widget.movie);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Offline: Cannot stream. Download this movie first.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: Icon(Icons.play_arrow_rounded, size: 36.r, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                  ),
                  SizedBox(height: 20.h),
                  //========================= Title, rating, duration =======================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movie.title,
                              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber, size: 18.r),
                                SizedBox(width: 4.w),
                                Text(
                                  widget.movie.rating.toString(),
                                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                                ),
                                SizedBox(width: 16.w),
                                Icon(Icons.access_time_filled_rounded, color: Colors.purpleAccent, size: 16.r),
                                SizedBox(width: 4.w),
                                Text(
                                  widget.movie.duration,
                                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                                ),
                                SizedBox(width: 16.w),
                                Text(
                                  widget.movie.releaseDate.split('-').first,
                                  style: TextStyle(color: Colors.white38, fontSize: 14.sp),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(color: Colors.white10, height: 32.h),
                  //============================ Downloads Section ============================================
                  _buildDownloadControls(),
                  Divider(color: Colors.white10, height: 32.h),
                  //============================ Description ==================================================
                  Text(
                    'Synopsis',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.movie.overview,
                    style: TextStyle(fontSize: 13.sp, color: Colors.white70, height: 1.5),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDownloadControls() {
    return ListenableBuilder(
      listenable: DownloadService(),
      builder: (context, _) {
        final dlService = DownloadService();
        final bool isActive = dlService.isActive(widget.movie.id);
        final TaskStatus? status = dlService.statusOf[widget.movie.id];
        final double progress = dlService.progressOf[widget.movie.id] ?? 0.0;

        return FutureBuilder<bool>(
          future: DbService.isMovieDownloaded(widget.movie.id),
          builder: (context, snapshot) {
            final bool downloaded = snapshot.data ?? _isDownloaded;

            if (downloaded) {
              return Row(
                children: [
                  Icon(Icons.offline_pin_rounded, color: Colors.green, size: 28.r),
                  SizedBox(width: 12.w),
                  Text(
                    'Available Offline',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16.sp),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      await dlService.deleteDownload(widget.movie.id);
                      await _checkStatus();
                    },
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18.r),
                    label: Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 14.sp)),
                  ),
                ],
              );
            }

            if (isActive) {
              final bool isPaused = status == TaskStatus.paused;
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPaused ? 'Paused' : 'Downloading...',
                              style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.w600, fontSize: 13.sp),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: SizedBox(
                            height: 6.h,
                            child: LinearProgressIndicator(
                              value: progress > 0 ? progress : null,
                              color: Colors.purpleAccent,
                              backgroundColor: Colors.white10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  IconButton(
                    icon: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: Colors.purpleAccent,
                      size: 22.r,
                    ),
                    onPressed: () {
                      if (isPaused) {
                        dlService.resumeDownload(widget.movie.id);
                      } else {
                        dlService.pauseDownload(widget.movie.id);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.redAccent, size: 22.r),
                    onPressed: () {
                      dlService.cancelDownload(widget.movie.id);
                    },
                  ),
                ],
              );
            }

            //================== Normal state: not downloaded ========================================
            return SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF161622),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  side: BorderSide(color: _isOffline ? Colors.white10 : Colors.purpleAccent, width: 1.h),
                ),
                onPressed: _isOffline
                    ? null
                    : () async {
                        await dlService.startDownload(widget.movie);
                        setState(() {});
                      },
                icon: Icon(
                  Icons.download_rounded,
                  color: _isOffline ? Colors.white24 : Colors.purpleAccent,
                  size: 18.r,
                ),
                label: Text(
                  _isOffline ? 'Offline - Connect to Download' : 'Download for Offline',
                  style: TextStyle(
                    color: _isOffline ? Colors.white24 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
