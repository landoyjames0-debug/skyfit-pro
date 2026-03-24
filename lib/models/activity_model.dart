class ActivityModel {
  final String title;
  final String description;
  final String emoji;
  final String intensity; // Low, Medium, High
  final String videoUrl;
  final int durationMinutes;

  ActivityModel({
    required this.title,
    required this.description,
    required this.emoji,
    required this.intensity,
    required this.videoUrl,
    required this.durationMinutes,
  });
}
