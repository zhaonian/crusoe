# Offline AI Chat

A Flutter-based offline AI chatbot that runs completely on your device for privacy and offline functionality.

## ✨ Features

- **💬 Clean Chat Interface** - Modern, intuitive chat UI with message bubbles
- **🔒 Complete Privacy** - All conversations stay on your device
- **📱 Cross-Platform** - Works on Android, iOS, and web
- **⚡ Fast Response** - No internet required, instant responses
- **🎨 Beautiful Design** - Light/dark theme support with smooth animations
- **🤖 Smart Responses** - Context-aware AI responses using Gemma models

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point with theme configuration
├── screens/
│   └── chat_screen.dart     # Main chat interface with message handling
└── services/
    └── gemma_service.dart   # Service for Gemma model integration
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code
- Compatible device (4GB+ RAM recommended for best performance)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/offline-ai.git
   cd offline-ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 🤖 Supported Models

### Current Support (Ready to integrate)
- **Gemma 3 1B** - Only 529MB, runs at up to 2,585 tok/sec (Recommended)
- **Gemma 2B & 7B** - Google's efficient models for mobile deployment
- **Gemma 3 Nano 1.5B** - Optimized for mobile with MediaPipe GenAI

### Coming Soon
- Phi-2 (2.7B parameters) - Compact model suitable for mobile devices
- Phi-3 Mini (3.8B parameters) - Designed to run on phones, achieves 69% on MMLU
- Llama 3.2 1B/3B (Meta) - Good mobile options
- DeepSeek R1 Distill - Compressed reasoning model
- Mistral Small 3.1 - Compact yet powerful

## 🔧 Integrating Real AI Models

The app currently runs with simulated responses. To integrate real Gemma models:

### Option 1: Using flutter_gemma Plugin (Recommended)

1. **Add dependency to pubspec.yaml:**
   ```yaml
   dependencies:
     flutter_gemma: ^0.2.0
   ```

2. **Update GemmaService in `lib/services/gemma_service.dart`:**
   ```dart
   // Replace the TODO sections with:
   import 'package:flutter_gemma/flutter_gemma.dart';
   
   // In initialize():
   await FlutterGemma.initialize(
     modelPath: 'assets/models/gemma-3-1b-it-int4.bin',
     maxTokens: 512,
     temperature: 0.8,
   );
   
   // In generateResponse():
   final response = await FlutterGemma.generateResponse(prompt);
   ```

3. **Download and add model file:**
   - Download Gemma model from [Hugging Face LiteRT Community](https://huggingface.co/litert-community/Gemma3-1B-IT)
   - Add to `assets/models/` folder
   - Update `pubspec.yaml` assets section

### Option 2: Method Channels (Advanced)

For custom integration or platform-specific optimizations, implement method channels as shown in the detailed tutorials.

## 📱 Usage

1. **Launch the app** - The chat interface loads immediately
2. **Wait for model loading** - Status shows in the app bar
3. **Start chatting** - Type your message and press send
4. **Enjoy offline AI** - All processing happens on your device

## 🎨 Customization

### Themes
- **Light Theme** - Clean, modern interface
- **Dark Theme** - OLED-friendly dark mode
- **Auto Theme** - Follows system preference

### Chat Features
- Message timestamps
- Loading indicators
- Error handling
- Auto-scroll to latest message
- Clear chat functionality

## 🔍 How It Works

1. **Flutter Frontend** - Beautiful, responsive UI built with Flutter widgets
2. **LiteRT/MediaPipe** - Runs optimized AI models directly on device
3. **Gemma Models** - Small, efficient language models designed for mobile
4. **Local Storage** - Messages and model data stay on your device

## 🛠️ Development

### Adding New Models
1. Update `ModelStatus` enum if needed
2. Add model-specific logic in `GemmaService`
3. Test performance on target devices
4. Update documentation

### Customizing UI
- Modify `chat_screen.dart` for interface changes
- Update themes in `main.dart`
- Add new message types or features

## 📊 Performance

- **Model Size**: Gemma 3 1B = 529MB (recommended)
- **RAM Usage**: 2-4GB during inference
- **Speed**: Up to 2,585 tokens/sec on high-end devices
- **Battery**: Optimized for mobile efficiency

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Google for Gemma models and LiteRT
- Flutter team for the amazing framework
- MediaPipe team for on-device AI tools

---

**Note**: This app demonstrates offline AI capabilities. Replace simulated responses with real model integration for production use.
