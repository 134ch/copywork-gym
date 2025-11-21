class CopyworkChallenge {
  final int dayId;
  final String title;
  final String content;
  final bool isCompleted;
  final double score;
  final int manualCompletions;
  final int digitalCompletions;
  final String? evidenceImagePath;

  CopyworkChallenge({
    required this.dayId,
    required this.title,
    required this.content,
    required this.isCompleted,
    required this.score,
    required this.manualCompletions,
    required this.digitalCompletions,
    this.evidenceImagePath,
  });

  // Calculate XP earned for the next manual completion
  double get potentialManualReward {
    if (manualCompletions == 0 && digitalCompletions == 0) {
      return 100; // First ever completion
    } else if (manualCompletions == 0) {
      return 75; // First manual after digital
    } else {
      return 10; // Repeat
    }
  }

  // Calculate XP earned for the next digital completion
  double get potentialDigitalReward {
    if (digitalCompletions == 0 && manualCompletions == 0) {
      return 25; // First ever completion
    } else {
      return 2.5; // Repeat
    }
  }

  // Total repetitions
  int get totalReps => manualCompletions + digitalCompletions;

  // Manual repetitions
  int get totalManualReps => manualCompletions;

  // Digital repetitions
  int get totalDigitalReps => digitalCompletions;

  // Complete a manual (analog) challenge
  CopyworkChallenge completeManual({String? evidencePath}) {
    final earnedXp = potentialManualReward;
    return CopyworkChallenge(
      dayId: dayId,
      title: title,
      content: content,
      isCompleted: true,
      score: score + earnedXp,
      manualCompletions: manualCompletions + 1,
      digitalCompletions: digitalCompletions,
      evidenceImagePath: evidencePath ?? evidenceImagePath,
    );
  }

  // Complete a digital challenge
  CopyworkChallenge completeDigital() {
    final earnedXp = potentialDigitalReward;
    return CopyworkChallenge(
      dayId: dayId,
      title: title,
      content: content,
      isCompleted: true,
      score: score + earnedXp,
      manualCompletions: manualCompletions,
      digitalCompletions: digitalCompletions + 1,
      evidenceImagePath: evidenceImagePath,
    );
  }

  // Copy with method for immutable updates
  CopyworkChallenge copyWith({
    int? dayId,
    String? title,
    String? content,
    bool? isCompleted,
    double? score,
    int? manualCompletions,
    int? digitalCompletions,
    String? evidenceImagePath,
  }) {
    return CopyworkChallenge(
      dayId: dayId ?? this.dayId,
      title: title ?? this.title,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      score: score ?? this.score,
      manualCompletions: manualCompletions ?? this.manualCompletions,
      digitalCompletions: digitalCompletions ?? this.digitalCompletions,
      evidenceImagePath: evidenceImagePath ?? this.evidenceImagePath,
    );
  }
}
