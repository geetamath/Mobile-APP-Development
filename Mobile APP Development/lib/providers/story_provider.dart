import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/quiz_model.dart';

// ---------------------------------------------------------------------------
// Quiz provider — loads quiz_data.json from the app's asset bundle at runtime.
// Swap the asset path (or replace with an http.get call) to go fully remote.
// ---------------------------------------------------------------------------
final quizProvider = FutureProvider<QuizQuestion>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/quiz_data.json');
  final map = jsonDecode(jsonStr) as Map<String, dynamic>;
  return QuizQuestion.fromJson(map);
});

// ---------------------------------------------------------------------------
// Story state
// ---------------------------------------------------------------------------
enum StoryPhase { idle, loading, playing, complete }

enum BuddyMood { idle, excited, happy }

class StoryState {
  final StoryPhase storyPhase;
  final bool quizVisible;
  final bool isCorrect;
  final BuddyMood buddyMood;
  final String? errorMessage;
  final String? lastTappedOption;
  final int wrongAttemptCount;

  const StoryState({
    this.storyPhase = StoryPhase.idle,
    this.quizVisible = false,
    this.isCorrect = false,
    this.buddyMood = BuddyMood.idle,
    this.errorMessage,
    this.lastTappedOption,
    this.wrongAttemptCount = 0,
  });

  StoryState copyWith({
    StoryPhase? storyPhase,
    bool? quizVisible,
    bool? isCorrect,
    BuddyMood? buddyMood,
    String? errorMessage,
    bool clearError = false,
    String? lastTappedOption,
    int? wrongAttemptCount,
  }) {
    return StoryState(
      storyPhase: storyPhase ?? this.storyPhase,
      quizVisible: quizVisible ?? this.quizVisible,
      isCorrect: isCorrect ?? this.isCorrect,
      buddyMood: buddyMood ?? this.buddyMood,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastTappedOption: lastTappedOption ?? this.lastTappedOption,
      wrongAttemptCount: wrongAttemptCount ?? this.wrongAttemptCount,
    );
  }
}

// ---------------------------------------------------------------------------
// Story notifier
// ---------------------------------------------------------------------------
class StoryNotifier extends StateNotifier<StoryState> {
  final FlutterTts _tts = FlutterTts();
  bool _ttsInitialized = false;

  static const String kStoryText =
      'Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods...';

  StoryNotifier() : super(const StoryState()) {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.1);
      await _tts.setVolume(1.0);

      _tts.setCompletionHandler(() {
        if (mounted) {
          state = state.copyWith(
            storyPhase: StoryPhase.complete,
            quizVisible: true,
            buddyMood: BuddyMood.excited,
          );
        }
      });

      _tts.setErrorHandler((dynamic message) {
        if (mounted) {
          state = state.copyWith(
            storyPhase: StoryPhase.idle,
            buddyMood: BuddyMood.idle,
            errorMessage:
                "Oops! Pip couldn't speak right now.\nTap to try again! 🤖",
          );
        }
      });

      _tts.setCancelHandler(() {
        if (mounted && state.storyPhase == StoryPhase.playing) {
          state = state.copyWith(storyPhase: StoryPhase.idle);
        }
      });

      _ttsInitialized = true;
    } catch (_) {
      _ttsInitialized = false;
    }
  }

  Future<void> readStory() async {
    if (state.storyPhase == StoryPhase.playing) return;

    state = state.copyWith(
      storyPhase: StoryPhase.loading,
      clearError: true,
      buddyMood: BuddyMood.excited,
    );

    if (!_ttsInitialized) {
      await _initTts();
    }

    try {
      final result = await _tts.speak(kStoryText);
      if (result == 1) {
        state = state.copyWith(storyPhase: StoryPhase.playing);
      } else {
        _setError();
      }
    } catch (_) {
      _setError();
    }
  }

  void _setError() {
    state = state.copyWith(
      storyPhase: StoryPhase.idle,
      buddyMood: BuddyMood.idle,
      errorMessage:
          "Oops! Pip couldn't speak right now.\nTap to try again! 🤖",
    );
  }

  void selectOption(String option, String correctAnswer) {
    if (state.isCorrect) return;

    if (option == correctAnswer) {
      state = state.copyWith(
        isCorrect: true,
        buddyMood: BuddyMood.happy,
        lastTappedOption: option,
      );
    } else {
      state = state.copyWith(
        lastTappedOption: option,
        wrongAttemptCount: state.wrongAttemptCount + 1,
      );
    }
  }

  void dismissError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

final storyProvider =
    StateNotifierProvider<StoryNotifier, StoryState>((ref) => StoryNotifier());
