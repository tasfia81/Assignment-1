import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import '../widgets/catalog_movie_card.dart';
import 'detail_screen.dart';
import '../widgets/offline_banner.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final List<Movie> _movies = [];
  final ScrollController _scrollController = ScrollController();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _loadNextPage();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        _loadNextPage();
      }
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final bool offline = results.isEmpty ||
          (results.length == 1 && results.first == ConnectivityResult.none);
      if (offline != _isOffline) {
        setState(() {
          _isOffline = offline;
        });
        if (!offline) {
          _refreshCatalog();
        }
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    final bool offline = results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _isOffline = offline;
      });
    }
  }

  Future<void> _refreshCatalog() async {
    setState(() {
      _movies.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = false;
    });
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Movie> newMovies = [];

      if (_isOffline) {
        newMovies = await DbService.getCachedMovies(page: _currentPage);
      } else {
        newMovies = await ApiService.getMovies(page: _currentPage);
        if (newMovies.isNotEmpty) {
          await DbService.cacheMovies(newMovies, _currentPage);
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (newMovies.isEmpty) {
            _hasMore = false;
          } else {
            _movies.addAll(newMovies);
            _currentPage++;
          }
        });
      }
    } catch (e) {
      final fallbackMovies = await DbService.getCachedMovies(page: _currentPage);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (fallbackMovies.isEmpty) {
            _hasMore = false;
          } else {
            _movies.addAll(fallbackMovies);
            _currentPage++;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161622),
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.deepPurpleAccent, Colors.purpleAccent, Colors.pinkAccent],
          ).createShader(bounds),
          child: Text(
            'Cineb.live',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _movies.isEmpty && _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
                      )
                    : RefreshIndicator(
                        color: Colors.deepPurpleAccent,
                        backgroundColor: const Color(0xFF161622),
                        onRefresh: _refreshCatalog,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _movies.length + (_isLoading ? 1 : 0),
                          padding: EdgeInsets.only(
                            left: 12.w,
                            right: 12.w,
                            top: 8.h,
                            bottom: 100.h,
                          ),
                          itemBuilder: (context, index) {
                            if (index == _movies.length) {
                              return Padding(
                                padding: EdgeInsets.all(16.r),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
                                ),
                              );
                            }

                            final movie = _movies[index];
                            return CatalogMovieCard(
                              movie: movie,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => DetailScreen(movie: movie)),
                                ).then((_) {
                                  setState(() {});
                                });
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OfflineBanner(),
          ),
        ],
      ),
    );
  }
}
