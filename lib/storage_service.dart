import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'challenge_model.dart';

class StorageService {
  static Future<void> saveProgress(CopyworkChallenge challenge) async {
    final prefs = await SharedPreferences.getInstance();

    final progressData = {
      'score': challenge.score,
      'manualCompletions': challenge.manualCompletions,
      'digitalCompletions': challenge.digitalCompletions,
      'evidenceImagePath': challenge.evidenceImagePath,
    };

    final key = 'progress_${challenge.dayId}';
    await prefs.setString(key, json.encode(progressData));
  }

  static Future<void> loadProgress(List<CopyworkChallenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < challenges.length; i++) {
      final challenge = challenges[i];
      final key = 'progress_${challenge.dayId}';
      final savedData = prefs.getString(key);

      if (savedData != null) {
        try {
          final Map<String, dynamic> data = json.decode(savedData);

          // Update the challenge with saved progress
          challenges[i] = CopyworkChallenge(
            dayId: challenge.dayId,
            title: challenge.title,
            content: challenge.content,
            isCompleted: (data['manualCompletions'] as int) > 0 ||
                (data['digitalCompletions'] as int) > 0,
            score: (data['score'] as num).toDouble(),
            manualCompletions: data['manualCompletions'] as int,
            digitalCompletions: data['digitalCompletions'] as int,
            evidenceImagePath: data['evidenceImagePath'] as String?,
          );
        } catch (e) {
          // If there's an error parsing saved data, skip it
          continue;
        }
      }
    }
  }

  static Future<void> saveImagePaths(int dayId, List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'images_$dayId';
    await prefs.setStringList(key, paths);
  }

  static Future<List<String>> loadImagePaths(int dayId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'images_$dayId';
    return prefs.getStringList(key) ?? [];
  }
}
