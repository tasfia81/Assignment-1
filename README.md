# Cineb.live Mobile Streaming App

A native-feeling, production-ready mobile application version of the **Cineb.live** movie and TV streaming experience built using Flutter and Dart. 

This repository was created as part of the **Khizex Mobile Engineering Intern 1-Week Build Challenge**. It implements advanced system-level engineering, private sandboxed storage, resilient offline database caching, Picture-in-Picture support, and strict memory budgeting.

---

## 📱 Features & System Implementation

### 1. OS-Level Background Downloads
*   **Engine**: Built using `background_downloader` which interfaces directly with **Android's WorkManager** and **iOS's NSURLSession** background configurations.
*   **Resilience**: Downloads run on a native OS level, meaning **they survive app minimization or the app being swiped away / killed** from the task switcher. The OS manages the thread and resumes downloads seamlessly when connectivity recovers.
*   **Notifications**: Displays progress and completion/failed notifications directly in the system status bar.
*   **In-App Tracking**: Enqueued downloads report real-time progress percentages and status updates to the UI.
*   **Web Support**: Implemented a timer-based mock download queue for web browsers (like Chrome) so reviewers can test the full flow without native bindings.

### 2. Secure Sandboxed Video Storage
*   **Location**: All downloaded movie files are stored in the app's **private sandboxed Documents directory** (`BaseDirectory.applicationDocuments`), specifically under `videos/`.
*   **Security**: These directories are isolated by the operating system. Downloaded video files do **not** appear in the device's public Gallery, Photos, Files, or Downloads folders. It prevents casual user extraction and sideloading.
*   **Local Playback**: Tapping "Play Offline" reads the file descriptor from the secure sandbox path and streams it directly to the video controller.

### 3. Native & In-App Picture-in-Picture (PiP)
*   **System-Level PiP**: Wrapped with `simple_pip_mode`. On Android, pressing the Home button or clicking the PiP icon automatically shrinks the app into the native floating PiP overlay. The layout swaps to display *only* the video player widget inside the small floating window, hiding the rest of the application.
*   **In-App PiP**: Built a floating container overlay (`FloatingPlayerContainer`) managed by a global `FloatingPlayerManager`. If a user pops or exits the movie details page during streaming, the video player minimizes to a tiny floating window in the bottom-right corner, letting them browse other catalog screens.

### 4. Smooth Paginated Infinite Scrolling
*   **Virtualization**: Uses Flutter's virtualized `ListView.builder` which dynamically mounts and recycles widget list cells as they enter and leave the viewport.
*   **Memory Downsizing (Crucial)**: Implemented image cache-limiting on the poster cards. Instead of loading high-resolution poster images into tiny containers, we use `memCacheWidth: 180` and `memCacheHeight: 260` inside `CachedNetworkImage`. This forces the cache manager to downscale images before storing them in memory, resulting in a flat memory profile under extended scrolling.

### 5. Resilient Offline Caching & Auto-Reconnect
*   **Local DB**: Built on top of `sqflite` (SQLite) on mobile and an in-memory fallback database on the Web.
*   **Page-by-Page Cache**: Every paginated movie list fetched from the API is cached inside the `cached_movies` table.
*   **Offline Mode**: If the device loses internet connection, the app remains fully responsive. It automatically queries the local database cache to render lists and movie details without showing blank screens.
*   **UI Banner**: Includes an animated `OfflineBanner` widget. It slides up a red warning when offline, and flashes a green success banner for 2 seconds upon reconnection before sliding away.
*   **Action Safeguards**: Genuinely online actions (like starting a new remote video stream or starting a new download) are gracefully disabled and show warnings when offline, while downloaded content and cached pages remain fully accessible.

### 6. Strict Type Safety
*   Full null-safety and explicitly defined type structures across all models and services.
*   No loose dictionaries/maps or `dynamic` data bypasses.
*   Safe JSON serialization in `lib/models/movie.dart`.

---

## 🛠️ Architecture & Code References

The codebase is organized logically following clean architectural layers:

*   **Models**:
    *   [`lib/models/movie.dart`](file:///c:/android%20studio%20project/assignment_1/lib/models/movie.dart): Pure type-safe data schemas.
*   **Services**:
    *   [`lib/services/api_service.dart`](file:///c:/android%20studio%20project/assignment_1/lib/services/api_service.dart): Paginated mock API fetching 100+ movie entries with network simulation.
    *   [`lib/services/db_service.dart`](file:///c:/android%20studio%20project/assignment_1/lib/services/db_service.dart): SQLite schema configurations, page caching, and download records index.
    *   [`lib/services/download_service.dart`](file:///c:/android%20studio%20project/assignment_1/lib/services/download_service.dart): Native background downloader wrapper and web mock queue.
    *   [`lib/services/player_manager.dart`](file:///c:/android%20studio%20project/assignment_1/lib/services/player_manager.dart): Centralized controller managing the Chewie player state, minimization, and file vs URL playback.
*   **Widgets**:
    *   [`lib/widgets/offline_banner.dart`](file:///c:/android%20studio%20project/assignment_1/lib/widgets/offline_banner.dart): Connectivity observer and slide-in notifications.
    *   [`lib/widgets/floating_player_container.dart`](file:///c:/android%20studio%20project/assignment_1/lib/widgets/floating_player_container.dart): In-app PiP overlay layout stack.
*   **Screens**:
    *   [`lib/screens/catalog_screen.dart`](file:///c:/android%20studio%20project/assignment_1/lib/screens/catalog_screen.dart): Virtualized catalog grid.
    *   [`lib/screens/detail_screen.dart`](file:///c:/android%20studio%20project/assignment_1/lib/screens/detail_screen.dart): Description, video player integration, and download controller.
    *   [`lib/screens/downloads_screen.dart`](file:///c:/android%20studio%20project/assignment_1/lib/screens/downloads_screen.dart): Offline files library.

---

## 🚀 Setup & Run Instructions

### Prerequisites
- Flutter SDK (Channel stable, ^3.11.0 or higher)
- Android SDK / Xcode (for native building)

### 1. Install Dependencies
Run the package getter from the root directory:
```bash
flutter pub get
```

### 2. Native Android Configurations
The configurations for Picture-in-Picture, notifications, and foreground sync services are already embedded in the android manifest:
*   **Permissions** (`AndroidManifest.xml`):
    ```xml
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
    ```
*   **Activity settings** (`AndroidManifest.xml`):
    ```xml
    android:supportsPictureInPicture="true"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    ```
*   **Foreground Service** (`AndroidManifest.xml`):
    ```xml
    <service
        android:name="androidx.work.impl.foreground.SystemForegroundService"
        android:foregroundServiceType="dataSync"
        android:exported="false" />
    ```

### 3. Run Locally
To compile and launch the application on a connected device, emulator, or Chrome browser:
```bash
flutter run
```

To build a release APK:
```bash
flutter build apk --release
```

---

## 🧪 Testing Scenarios

### Test Background Downloads
1. Open the app, click a movie card, and tap **Download for Offline**.
2. Minimize the app or swipe it away (force kill) from the system multitasking tray.
3. Relaunch the app after a minute; notice the progress bar completes and is marked **Available Offline**.
4. Check the device's native Gallery or Files app; verify the video file does *not* appear there.

### Test Picture-in-Picture
- **In-App PiP**: While a video is playing in the details page, press the system back button. The player will minimize to the bottom-right corner. Continue scrolling the catalog; tap the mini-player to expand it back to full-screen.
- **System PiP**: Press the system Home button while a video is playing. The app will minimize to a system-wide floating PiP player.

### Test Resilient Offline Caching
1. Scroll through 40–60 items in the catalog while online to fill the local database cache.
2. Turn on **Airplane Mode** (disconnecting Wi-Fi/cellular).
3. The red `Offline Banner` will slide up from the bottom.
4. Browse pages and click details of already-viewed items; notice details render fully from the cache.
5. Play a downloaded movie offline; try streaming a non-downloaded movie (it will show a safe warning).
6. Disable Airplane Mode; the banner flashes green for 2 seconds and restores online streaming.
