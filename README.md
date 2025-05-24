# Silent Spaces

**Silent Spaces** is a Flutter-based mobile application designed to help users discover and contribute information about quiet public locations such as cafés, libraries, and parks. The application enables users to add, view, and manage silent spots based on noise levels, Wi-Fi speed, seating availability, and distance from their current location.

## Features

* Interactive map interface displaying the user's current location
* Ability to add new silent spots by tapping on the map or using the current location
* Form-based input for capturing spot attributes:
  * Name
  * Type (Café, Library, Park)
  * Noise Level (1–5)
  * Wi-Fi Speed (Slow, Medium, Fast)
  * Seating Availability (Low, Medium, Available)
* Persistent storage of user-added spots using local device storage
* Viewing and filtering of saved spots in a list
* Calculation of distance between user and saved locations
* Support for removing individual or all stored spots
  
### Prerequisites

* Flutter SDK installed
* Device or emulator with location services enabled
* Internet connectivity for map tile rendering

### Dependencies

Ensure the following dependencies are included in your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_map: ^6.0.0
  latlong2: ^0.8.1
  geolocator: ^11.0.0
  shared_preferences: ^2.2.0
```

Install the dependencies:

```bash
flutter pub get
```

### Running the Application

1. Clone the repository.
2. Run the application using the following command:

```bash
flutter run
```

## Usage

1. Launch the application to automatically detect your current location.
2. Tap on any point on the map to add a silent spot at that location.
3. Fill in the required details in the form presented:

   * Place Name
   * Type of location
   * Noise level
   * Wi-Fi speed
   * Seating availability
4. Alternatively, use the "Add Current Location" button to mark your present location.
5. Use the "View Spots" button to browse, filter, and manage your saved spots.

## Data Model

The application uses the following model to represent a silent spot:

```dart
class SilentSpot {
  final String name;
  final String type;
  final int noiseLevel;
  final String wifiSpeed;
  final String seating;
  final LatLng location;
}
```

Each spot is saved locally using `SharedPreferences` in serialized JSON format.

## File Structure Overview

* `main.dart`: Contains the entire application logic, including UI components, state management, persistent storage, and geolocation features.

## Potential Enhancements

* Cloud-based synchronization using Firebase or a backend server
* User authentication and individual profile management
* User ratings and reviews for each spot
* Enhanced UI with dark mode and theme customization

## License

This project is licensed under the MIT License. You are free to use, modify, and distribute this software as per the terms of the license.
