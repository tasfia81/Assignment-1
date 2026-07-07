import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../core/app_colors.dart';
import '../core/app_sizes.dart';

class DownloadedMovieCard extends StatelessWidget {
  final Movie movie;
  final String localPath;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const DownloadedMovieCard({
    super.key,
    required this.movie,
    required this.localPath,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBg,
      margin: EdgeInsets.only(bottom: AppSizes.spaceMedium),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMedium)),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Row(
        children: [
          //-------------------------- Poster -----------------------------------------
          CachedNetworkImage(
            imageUrl: movie.posterUrl,
            width: 80,
            height: 110,
            fit: BoxFit.cover,
            memCacheWidth: 160,
            memCacheHeight: 220,
            errorWidget: (context, url, error) => Container(
              width: 80,
              height: 110,
              color: Colors.grey.shade900,
              child: Icon(Icons.movie, color: Colors.grey, size: AppSizes.iconBig),
            ),
          ),
          SizedBox(width: AppSizes.spaceMedium),
          //--------------------------- Info & Actions ------------------------------------
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
                  SizedBox(height: AppSizes.spaceXSmall),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, color: AppColors.accentPurple, size: AppSizes.iconMedium),
                      SizedBox(width: AppSizes.spaceXSmall),
                      Text(
                        movie.duration,
                        style: TextStyle(color: AppColors.textWhite70, fontSize: AppSizes.fontMedium),
                      ),
                      SizedBox(width: AppSizes.spaceLarge),
                      Icon(Icons.star_rounded, color: AppColors.starAmber, size: AppSizes.iconMedium),
                      SizedBox(width: AppSizes.spaceXSmall),
                      Text(
                        movie.rating.toString(),
                        style: TextStyle(color: AppColors.textWhite70, fontSize: AppSizes.fontMedium),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.spaceSmall),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium, vertical: AppSizes.paddingXSmall),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSmall)),
                        ),
                        onPressed: onPlay,
                        icon: Icon(Icons.play_arrow_rounded, color: Colors.white, size: AppSizes.iconLarge),
                        label: Text('Play Offline', style: TextStyle(color: Colors.white, fontSize: AppSizes.fontSmall)),
                      ),
                      SizedBox(width: AppSizes.spaceSmall),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentRed,
                          side: const BorderSide(color: AppColors.accentRed),
                          padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium, vertical: AppSizes.paddingXSmall),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSmall)),
                        ),
                        onPressed: onDelete,
                        icon: Icon(Icons.delete_outline_rounded, size: AppSizes.iconMedium),
                        label: Text('Delete', style: TextStyle(fontSize: AppSizes.fontSmall)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
