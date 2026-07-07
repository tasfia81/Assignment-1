import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/movie.dart';
import '../services/db_service.dart';
import '../services/download_service.dart';
import '../services/player_manager.dart';
import '../widgets/downloaded_movie_card.dart';
import 'detail_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161622),
        elevation: 0,
        // Only show back button if the screen is pushed in navigation stack
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18.r),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'My Downloads',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.sp),
        ),
      ),
      body: ListenableBuilder(
        listenable: DownloadService(),
        builder: (context, _) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: DbService.getDownloadedMovies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
                );
              }

              final downloadedMovies = snapshot.data ?? [];

              if (downloadedMovies.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                itemCount: downloadedMovies.length,
                padding: EdgeInsets.only(
                  left: 12.w,
                  right: 12.w,
                  top: 8.h,
                  bottom: 100.h,
                ),
                itemBuilder: (context, index) {
                  final item = downloadedMovies[index];
                  final movie = Movie(
                    id: item['id'] as String,
                    title: item['title'] as String,
                    overview: item['overview'] as String,
                    posterUrl: item['posterUrl'] as String,
                    videoUrl: item['videoUrl'] as String,
                    releaseDate: item['releaseDate'] as String,
                    duration: item['duration'] as String,
                    rating: (item['rating'] as num).toDouble(),
                  );
                  final String localPath = item['localPath'] as String;

                  return DownloadedMovieCard(
                    movie: movie,
                    localPath: localPath,
                    onPlay: () {
                      //===================== Play local file path offline =======================================
                      FloatingPlayerManager().playMovie(movie, localFilePath: localPath);
                      //================ Navigate to details screen to show controls ==============================
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DetailScreen(movie: movie)),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    onDelete: () async {
                      //================ Delete local file and db record ==============================
                      await DownloadService().deleteDownload(movie.id);
                      setState(() {});
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_for_offline_outlined, size: 80.r, color: Colors.grey.shade800),
          SizedBox(height: 16.h),
          Text(
            'No Downloads Yet',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8.h),
          Text(
            'Movies you download will appear here.\nAvailable to watch offline.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, height: 1.4, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}
