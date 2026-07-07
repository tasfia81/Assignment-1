import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../services/db_service.dart';
import '../services/download_service.dart';
import '../core/app_colors.dart';
import '../core/app_sizes.dart';

class CatalogMovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const CatalogMovieCard({
    super.key,
    required this.movie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBg,
      margin: EdgeInsets.only(bottom: AppSizes.spaceMedium),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMedium)),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            //--------------------------- Poster Image --------------------------------------
            CachedNetworkImage(
              imageUrl: movie.posterUrl,
              width: 90,
              height: 130,
              fit: BoxFit.cover,
              memCacheWidth: 180, 
              memCacheHeight: 260,
              placeholder: (context, url) => Container(
                width: 90,
                height: 130,
                color: Colors.grey.shade900,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPurple),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 90,
                height: 130,
                color: Colors.grey.shade900,
                child: Icon(Icons.movie, color: Colors.grey, size: AppSizes.iconBig),
              ),
            ),
            SizedBox(width: AppSizes.spaceMedium),
            //------------------------ Details ---------------------------------------
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.paddingSmall, horizontal: AppSizes.paddingXSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSizes.fontXXLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceSmall),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: AppColors.starAmber, size: AppSizes.iconMedium),
                        SizedBox(width: AppSizes.spaceXSmall),
                        Text(
                          movie.rating.toString(),
                          style: TextStyle(color: AppColors.textWhite70, fontSize: AppSizes.fontMedium),
                        ),
                        SizedBox(width: AppSizes.spaceMedium),
                        Icon(Icons.access_time_filled_rounded, color: AppColors.accentPurple, size: AppSizes.iconSmall),
                        SizedBox(width: AppSizes.spaceXSmall),
                        Text(
                          movie.duration,
                          style: TextStyle(color: AppColors.textWhite70, fontSize: AppSizes.fontMedium),
                        ),
                        SizedBox(width: AppSizes.spaceMedium),
                        Text(
                          movie.releaseDate.split('-').first,
                          style: TextStyle(color: AppColors.textWhite38, fontSize: AppSizes.fontMedium),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.spaceSmall),
                    Text(
                      movie.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSizes.fontSmall,
                        color: AppColors.textWhite54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            //------------------------- Download State Badge ----------------------------------
            ListenableBuilder(
              listenable: DownloadService(),
              builder: (context, _) {
                final dlService = DownloadService();
                return FutureBuilder<bool>(
                  future: DbService.isMovieDownloaded(movie.id),
                  builder: (context, snapshot) {
                    final bool isDownloaded = snapshot.data ?? false;
                    final bool isActive = dlService.isActive(movie.id);

                    if (isDownloaded) {
                      return Padding(
                        padding: EdgeInsets.only(right: AppSizes.paddingMedium),
                        child: Icon(Icons.check_circle_rounded, color: Colors.green, size: AppSizes.iconBar),
                      );
                    } else if (isActive) {
                      final double progress = dlService.progressOf[movie.id] ?? 0.0;
                      return Padding(
                        padding: EdgeInsets.only(right: AppSizes.paddingMedium),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: progress > 0 ? progress : null,
                            strokeWidth: 2.5,
                            color: AppColors.accentPurple,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
