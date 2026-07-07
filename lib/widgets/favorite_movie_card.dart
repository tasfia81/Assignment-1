import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../core/app_colors.dart';
import '../core/app_sizes.dart';

class FavoriteMovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  const FavoriteMovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    required this.onUnfavorite,
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
            //---------------------------- Poster ------------------------------------
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
            //------------------------ Info & Actions -------------------------------------
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
                        SizedBox(width: AppSizes.spaceLarge),
                        Icon(Icons.access_time_filled_rounded, color: AppColors.accentPurple, size: AppSizes.iconSmall),
                        SizedBox(width: AppSizes.spaceXSmall),
                        Text(
                          movie.duration,
                          style: TextStyle(color: AppColors.textWhite70, fontSize: AppSizes.fontMedium),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.spaceSmall),
                    Text(
                      movie.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: AppSizes.fontSmall, color: AppColors.textWhite54),
                    ),
                  ],
                ),
              ),
            ),
            //------------------------ Unfavorite Action -------------------------------------
            IconButton(
              icon: Icon(Icons.favorite_rounded, color: AppColors.accentRed, size: AppSizes.iconBar),
              onPressed: onUnfavorite,
            ),
            SizedBox(width: AppSizes.spaceSmall),
          ],
        ),
      ),
    );
  }
}
