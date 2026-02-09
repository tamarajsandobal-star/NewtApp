import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple provider to hold the state
final lowStimulationModeProvider = StateNotifierProvider<LowStimulationNotifier, bool>((ref) {
  return LowStimulationNotifier();
});

class LowStimulationNotifier extends StateNotifier<bool> {
  LowStimulationNotifier() : super(false) {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('low_stimulation') ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('low_stimulation', state);
  }
}
