import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../constants/api_constants.dart';
import 'auth_manager.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class VoiceAssistantService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isInitialized = false;
  
  VoiceAssistantService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speechToText.initialize(
      onError: (error) => print('STT Error: $error'),
      onStatus: (status) => print('STT Status: $status'),
    );
    return _isInitialized;
  }

  /// Starts listening to the user, sends the transcribed text to the backend, and speaks the response.
  Future<void> startVoiceAssistant({
    required Function(VoiceState state, String? message) onStateChanged,
  }) async {
    final bool available = await initialize();
    if (!available) {
      onStateChanged(VoiceState.error, 'Speech recognition not available.');
      return;
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
      onStateChanged(VoiceState.idle, null);
      return;
    }
    
    // Stop any ongoing speech
    await _flutterTts.stop();

    onStateChanged(VoiceState.listening, 'Listening...');

    String recognizedText = '';

    await _speechToText.listen(
      onResult: (result) async {
        recognizedText = result.recognizedWords;
        
        if (!result.finalResult) {
          onStateChanged(VoiceState.listening, recognizedText);
        }

        // When the user stops speaking
        if (result.finalResult) {
          onStateChanged(VoiceState.processing, 'Processing...');
          await _processAndSpeak(recognizedText, onStateChanged);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stop() async {
    await _speechToText.stop();
    await _flutterTts.stop();
  }

  Future<void> _processAndSpeak(
    String userText, 
    Function(VoiceState state, String? message) onStateChanged,
  ) async {
    if (userText.isEmpty) {
      onStateChanged(VoiceState.idle, null);
      return;
    }

    try {
      final token = await AuthManager().getToken();
      if (token == null) throw Exception('No auth token');

      // Add instruction for shorter voice response
      final prompt = '$userText\n\n(Please provide a very concise 1-2 sentence response suitable for voice assistant output)';

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/ai/chat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'message': prompt}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final aiMessage = decoded['message']?.toString() ?? 'I could not process that request.';
        
        onStateChanged(VoiceState.speaking, aiMessage);
        
        await _flutterTts.speak(aiMessage);
        
        _flutterTts.setCompletionHandler(() {
          onStateChanged(VoiceState.idle, null);
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      onStateChanged(VoiceState.error, 'Sorry, something went wrong.');
      print('VoiceAssistant Error: $e');
      await _flutterTts.speak("Sorry, something went wrong.");
      
      Future.delayed(const Duration(seconds: 3), () {
        onStateChanged(VoiceState.idle, null);
      });
    }
  }
}
