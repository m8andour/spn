# Smart Pharma Net

A Flutter application for managing pharmacies and medicines.

## Features

- Pharmacy Management
  - Add, edit, and delete pharmacies
  - View pharmacy details
  - Search pharmacies
  - Pharmacy authentication

- Medicine Management
  - Add, edit, and delete medicines
  - Categorize medicines
  - Track medicine inventory
  - Manage expiry dates

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository
```bash
git clone [your-repository-url]
```

2. Navigate to the project directory
```bash
cd SPN
```

3. Install dependencies
```bash
flutter pub get
```

4. Run the app
```bash
flutter run
```

## API Integration

The app integrates with the Smart Pharma Net API:
- Base URL: https://smart-pharma-net.vercel.app
- Authentication using JWT tokens
- RESTful endpoints for pharmacies and medicines

## Architecture

- MVVM (Model-View-ViewModel) architecture
- Provider for state management
- Repository pattern for data access
- Clean separation of concerns

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request 

git remote add origin https://github.com/m8andour/smart-pharma-net.git
git branch -M main
git push -u origin main # smart-pharma-net
# smart-pharma-net
