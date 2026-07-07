import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/player_manager.dart';
import '../screens/detail_screen.dart';

class FloatingPlayerContainer extends StatelessWidget {
  final Widget child;

  const FloatingPlayerContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FloatingPlayerManager(),
      builder: (context, _) {
        final manager = FloatingPlayerManager();

        return Stack(
          children: [
            child,
            if (manager.isPlaying && manager.isMinimized && manager.movie != null)
              Positioned(
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 64, // Keep offset from bottom bar
                child: GestureDetector(
                  onTap: () {
                    manager.restore();
                    //-------------------- Re-open detail screen to maximize the video ----------------------------
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(movie: manager.movie!),
                      ),
                    );
                  },
                  child: Container(
                    width: 180,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.deepPurple.withAlpha(128), width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        if (manager.videoPlayerController != null && manager.videoPlayerController!.value.isInitialized)
                          IgnorePointer(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: manager.videoPlayerController!.value.size.width,
                                height: manager.videoPlayerController!.value.size.height,
                                child: VideoPlayer(manager.videoPlayerController!),
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        //------------------ Overlay to capture clicks and close --------------------------------
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              manager.stop();
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
