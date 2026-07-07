import '../models/movie.dart';

class ApiService {
  static final List<Movie> _movies = _generateMockMovies();

  // Fetches paginated movies
  static Future<List<Movie>> getMovies({required int page, int limit = 20}) async {
    //===================== Simulate network delay =========================================
    await Future.delayed(const Duration(milliseconds: 1200));

    final int startIndex = (page - 1) * limit;
    if (startIndex >= _movies.length) {
      return [];
    }

    final int endIndex = startIndex + limit;
    final int safeEndIndex = endIndex > _movies.length ? _movies.length : endIndex;

    return _movies.sublist(startIndex, safeEndIndex);
  }

  //====================== Generates 100 mock movies ==================================
  static List<Movie> _generateMockMovies() {
    final List<String> videoUrls = [
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'https://photo-sphere-viewer-data.netlify.app/assets/equirectangular-video/Ayutthaya_HD.mp4',
    ];

    // High quality Unsplash imagery (using random collection or search terms for movie posters)
    final List<String> posterIds = [
      'photo-1536440136628-849c177e76a1', // Cinema
      'photo-1489599849927-2ee91cede3ba', // Movie theater
      'photo-1517604931442-7e0c8ed2963c', // Theater seats
      'photo-1478720568477-152d9b164e26', // Projector
      'photo-1518709268805-4e9042af9f23', // Retro cinema
      'photo-1542204111-3685117966ec', // Neon screen
      'photo-1598899134739-24c46f58b8c0', // Clapperboard
      'photo-1513151233558-d860c5398176', // Colorful abstract
      'photo-1509198397868-475647b2a1e5', // Cyberpunk neon
      'photo-1485846234645-a62644f84728', // Video tape
    ];

    final List<String> adjectives = [
      'Cosmic', 'Terminal', 'Aura of', 'Quantum', 'Whispering', 'Silent', 'Chronos', 'Iron', 'Dark', 'Neon',
      'Apex', 'Cyber', 'Forgotten', 'Solar', 'Underground', 'Infinite', 'Binary', 'Shadow', 'Phoenix', 'Gravity',
      'Stealth', 'Frostbite', 'Desert', 'Redline', 'Hyperdrive', 'Starlight', 'Skyward', 'Overlord', 'Rogue', 'Ironclad',
      'Wildfire', 'Tomb', 'Deadlock', 'Gridlock', 'Vortex', 'Shattered', 'Shockwave', 'Thunderbolt', 'Blizzard', 'Cyclone',
    ];

    final List<String> nouns = [
      'Voyager', 'Protocol', 'Mystery', 'Collapse', 'Winds', 'Assassin', 'Paradox', 'Heart', 'Nebula', 'Pulse',
      'Legend', 'Nexus', 'Realms', 'Flare', 'Syndicate', 'Loop', 'Sunset', 'Ninja', 'Rising', 'Zero',
      'Ops', 'Bandit', 'Storm', 'Out', 'Nightcrawler', 'Knight', 'Agent', 'Raider', 'Freeze', 'Wilderness',
      'Survival', 'Outcast', 'Nomad', 'Wanderer', 'Drifter', 'Seeker', 'Explorer', 'Pioneer', 'Pathfinder', 'Sentinel',
    ];

    final List<Movie> list = [];

    for (int i = 0; i < 100; i++) {
      final String adj = adjectives[i % adjectives.length];
      final String noun = nouns[(i + 3) % nouns.length];
      final String title = '$adj $noun';
      final String id = 'movie_${i + 1}';

      final String videoUrl = videoUrls[i % videoUrls.length];
      // Use different poster images and w=500 for compact size (avoids loading massive images into memory)
      final String posterId = posterIds[i % posterIds.length];
      final String posterUrl = 'https://images.unsplash.com/$posterId?w=400&q=80&fit=crop';

      final double rating = 5.0 + (i % 5) + (i % 10) * 0.1;
      final int durationMinutes = 90 + (i * 7) % 65;
      final int year = 2018 + (i % 9);

      final String overview = 'Step into the world of $title. This highly acclaimed cinematic masterpiece takes you on an '
          'extraordinary journey filled with suspense, stunning visuals, and deep storytelling. '
          'Directed by visionary filmmakers, it explores the boundaries of imagination and human spirit. '
          'Featuring an award-winning cast and a breathtaking musical score, $title is a must-watch experience for all movie enthusiasts.';

      list.add(Movie(
        id: id,
        title: title,
        overview: overview,
        posterUrl: posterUrl,
        videoUrl: videoUrl,
        releaseDate: '$year-05-${10 + (i % 18)}',
        duration: '${durationMinutes}m',
        rating: rating > 10.0 ? 9.8 : double.parse(rating.toStringAsFixed(1)),
      ));
    }

    return list;
  }
}
