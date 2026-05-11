# EmoTune: Emotion-Based Music Player

![EmoTune Banner](https://placehold.co/800x400/8e44ad/ffffff/png?text=EmoTune)

EmoTune is a mobile application that intelligently curates and plays music based on your real-time facial expressions. Using a sophisticated machine learning model, the app detects your current emotion—such as happiness, sadness, or neutrality—and generates a playlist to match your mood, creating a truly personalized listening experience.

This repository contains the **Flutter mobile application**. The backend Flask API, which serves the emotion detection model, is located in a separate repository: [**Emotion-Flask**](https://github.com/ChinmayBansal010/EmotionRecognitionFlask).

---

## ✨ Features

* **Real-Time Emotion Detection**: Utilizes the device's camera to detect facial emotions in real-time by communicating with a dedicated backend service.
* **Dynamic Music Curation**: Automatically plays songs that match the detected emotion.
* **Cross-Platform**: Built with Flutter for a seamless experience on both Android and iOS.
* **Simple & Intuitive UI**: A clean and user-friendly interface that requires no manual input.

---

## 🛠️ Tech Stack

### Frontend (Mobile App)
* **Framework**: Flutter
* **Language**: Dart
* **HTTP Client**: `http` package
* **Camera**: `camera` package

### Backend
The backend is a **Flask API** hosted on Render. The source code is available in the [**Emotion-Flask**](https://github.com/ChinmayBansal010/EmotionRecognitionFlask) repository.

---

## 📁 Project Structure

```
EmoTune/
├── lib/
│   ├── main.dart    
│   └── ...
├── pubspec.yaml       
└── ...
```

---

## 🚀 Getting Started

Follow these instructions to get the mobile application up and running on your local machine.

### Prerequisites

* Flutter SDK and Dart
* Git
* A running instance of the backend service from the [**Emotion-Flask**](https://github.com/ChinmayBansal010/EmotionRecognitionFlask).

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/ChinmayBansal010/EmotionRecognitionApp.git
    cd EmoTune
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3.  **Configure the API Endpoint:**
    In `lib/services/api_service.dart`, ensure the `API_URL` points to your deployed backend server.
    ```dart
    const String API_URL = 'https://your-render-app-name.onrender.com/predict';
    ```

### Running the Application

1.  **Ensure the Backend is Running:**
    Before running the app, make sure your backend server from the `emo-flask-repo` is deployed and accessible at the URL you configured.

2.  **Run the Flutter App:**
    * Open a terminal and navigate to the `EmoTune` (this repository's) directory.
    * Ensure you have an emulator running or a physical device connected.
    ```sh
    flutter run
    ```

---

## Usage

1.  Launch the EmoTune app on your device.
2.  Grant camera permissions when prompted.
3.  The app will display the camera view and begin analyzing your facial expression via the backend service.
4.  Once an emotion is detected, a curated playlist will automatically start playing.

---

## 🤝 Contributing

Contributions are welcome! If you have ideas for new features or improvements, please fork the repository and create a pull request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/NewFeature`)
3.  Commit your Changes (`git commit -m 'Add some NewFeature'`)
4.  Push to the Branch (`git push origin feature/NewFeature`)
5.  Open a Pull Request

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.
