class Movie {
  final String id;
  final String title;
  final String overview;
  final String posterUrl;
  final String videoUrl;
  final String releaseDate;
  final String duration;
  final double rating;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterUrl,
    required this.videoUrl,
    required this.releaseDate,
    required this.duration,
    required this.rating,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as String,
      title: json['title'] as String,
      overview: json['overview'] as String,
      posterUrl: json['posterUrl'] as String,
      videoUrl: json['videoUrl'] as String,
      releaseDate: json['releaseDate'] as String,
      duration: json['duration'] as String,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'posterUrl': posterUrl,
      'videoUrl': videoUrl,
      'releaseDate': releaseDate,
      'duration': duration,
      'rating': rating,
    };
  }
}
