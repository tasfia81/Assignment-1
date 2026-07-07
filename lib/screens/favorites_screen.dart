import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/movie.dart';
import '../services/db_service.dart';
import '../widgets/favorite_movie_card.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161622),
        elevation: 0,
        title: Text(
          'My Favorites',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.sp),
        ),
      ),
      body: FutureBuilder<List<Movie>>(
        future: DbService.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            );
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: favorites.length,
            padding: EdgeInsets.only(
              left: 12.w,
              right: 12.w,
              top: 8.h,
              bottom: 100.h,
            ),
            itemBuilder: (context, index) {
              final movie = favorites[index];
              return FavoriteMovieCard(
                movie: movie,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DetailScreen(movie: movie)),
                  ).then((_) {
                    setState(() {}); // Force rebuild to reload sqlite favorite status
                  });
                },
                onUnfavorite: () async {
                  await DbService.removeFavorite(movie.id);
                  setState(() {}); // Force rebuild to remove item immediately
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
          Icon(Icons.favorite_border_rounded, size: 70.r, color: Colors.grey.shade800),
          SizedBox(height: 16.h),
          Text(
            'No Favorites Yet',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Text(
              'Tap the heart icon on any movie detail page to add it to your collection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13.sp, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
