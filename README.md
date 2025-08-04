# TUBify Frontend – Your Guide to TU Berlin Campus Life

**TUBify** is a smart, student-centered campus navigation app designed to simplify everyday life at TU Berlin.  
From personalized campus routing to real-time schedules, mensa menus, and favorite places — 
**TUBify** brings together everything students need to navigate university life efficiently.

## 🚀 Features

- Campus Routing (walking, public transport, e-bike)
- User Authentication and Guest Access
- Favorite Places + Meals
- Categorized Points of Interest
- Weekly Mensa Menus
- Student Schedule Integration (Moses TU Berlin)  
- Real-Time Weather Information  
- Universal Search: Buildings, Lecture halls, Rooms  
- 3D Map/Weather/Dark Mode Support  

## 📁 Project Structure (Frontend)

```markdown
lib/ → Main application source (Flutter)
│
├── common/ → Shared UI components and BLoC state management
├── core/ → Core utilities: API clients, configs, constants
├── data/ → Data layer: models, repositories, services
├── domain/ → Clean Architecture: entities and use cases
├── presentation/ → Screens, pages, UI logic
│
assets/ → Static assets: icons, fonts, images
android/, ios/, web/ → Platform-specific project folders
config.env → Environment configuration
pubspec.yaml → Project dependencies and configuration
```

## 🔧 Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)  
- [Dart SDK](https://dart.dev/get-dart)
- Xcode or Android Studio
- Android/iOS emulator or physical device

## 🚀 Installation

1. **Clone the repository:**

    ```bash
    git clone https://github.com/GMSDaniil/TURunner.Unimap_Frontend.git
    cd TURunner.Unimap_Frontend
    ```

2. **Configure environment variables**

   Create a file named `config.env` in the root directory of the project and add the following lines:

   ```dart
   BASE_URL=your_base_url
   MAPBOX_ACCESS_TOKEN=your_mapbox_access_token
   X_APP_TOKEN=your_app_token
   ```

   Replace the placeholders (`your_base_url`, `your_mapbox_access_token`, `your_app_token`) with your own credentials.

   **Note:** The config.env file is already included in .gitignore and will not be committed to the repository.


4. **Clean the build (recommended for first-time setup):**

    ```bash
    flutter clean
    ```

5. **Install dependencies:**

    ```bash
    flutter pub get
    ```

6. **Start an emulator or connect a device.**

7. **Run the app:**

    ```bash
    flutter run
    ```

## 🤝 Contributing & Support

Feel free to fork the repository or open an issue if you find a bug or have suggestions!

For any questions, reach out on GitHub or contact us via email:  
📬 daniil.cherepko@campus.tu-berlin.de

## 👥 The Frontend Team

Group D – PP3S @ TU Berlin  
**Daniil, Yura, Malika, Ivan**


A new Flutter project.
