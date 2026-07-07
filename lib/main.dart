
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:simple_pip_mode/pip_widget.dart';
import 'package:chewie/chewie.dart';
import 'screens/main_navigation_screen.dart';
import 'widgets/floating_player_container.dart';
import 'services/download_service.dart';
import 'services/player_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the download service so that listeners catch background tasks immediately
  final downloadService = DownloadService();
  await downloadService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //------------------ Initialize ScreenUtil for responsive scaling ------------------------------
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Cineb.live',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.deepPurple,
            scaffoldBackgroundColor: const Color(0xFF0F0F14),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
            ),
          ),
          home: PipWidget(
            pipChild: ListenableBuilder(
              listenable: FloatingPlayerManager(),
              builder: (context, _) {
                final manager = FloatingPlayerManager();
                if (manager.isPlaying && manager.chewieController != null) {
                  return Theme(
                    data: ThemeData.dark(),
                    child: Chewie(controller: manager.chewieController!),
                  );
                }
                return const Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.purpleAccent),
                  ),
                );
              },
            ),
            child: const FloatingPlayerContainer(
              child: MainNavigationScreen(),
            ),
          ),
        );
      },
    );
  }
}
