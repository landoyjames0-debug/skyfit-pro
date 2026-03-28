class ActivityModel {
  final String title;
  final String description;
  final String emoji;
  final String intensity; // Low, Medium, High
  final String videoUrl;
  final String videoAsset; // Local asset path e.g. 'assets/videos/yoga.mp4'
  final int durationMinutes;

  ActivityModel({
    required this.title,
    required this.description,
    required this.emoji,
    required this.intensity,
    required this.videoUrl,
    required this.videoAsset,
    required this.durationMinutes,
  });
}
