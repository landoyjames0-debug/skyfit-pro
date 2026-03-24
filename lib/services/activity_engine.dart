import 'dart:math';
import '../models/user_model.dart';
import '../models/weather_model.dart';

/// A suggested workout activity returned by [ActivityEngine].
class ActivitySuggestion {
  final String name;
  final String description;
  final String intensity; // 'Low' | 'Moderate' | 'High'
  final int durationMinutes;
  final String emoji;
  final String? videoAsset;

  const ActivitySuggestion({
    required this.name,
    required this.description,
    required this.intensity,
    required this.durationMinutes,
    required this.emoji,
    this.videoAsset,
  });
}

/// Determines suggested activities from weather + user profile.
///
/// FIX 1 — Finer age tiers (was only <50 / >=50):
///   • Youth    : age < 18
///   • Young    : 18–34
///   • Middle   : 35–49
///   • Senior   : 50–64
///   • Elderly  : 65+
///
/// FIX 2 — Randomised selection:
///   Each preset method now holds a POOL of activities (4-6 items).
///   [suggest] shuffles the pool with a fresh Random() and picks
///   [_pickCount] items, so the same weather + profile gives a
///   different combination on every fetch.
class ActivityEngine {
  // How many activities to show per fetch. Change to 3 if you prefer.
  static const int _pickCount = 3;

  /// Returns [_pickCount] randomly-selected suggestions for the
  /// current weather + user combination.
  static List<ActivitySuggestion> suggest({
    required WeatherModel weather,
    required UserModel user,
  }) {
    final condition = _classify(weather);
    final tier = _ageTier(user.age);
    final isOverweight = _isOverweight(user.weightCategory);

    List<ActivitySuggestion> pool;

    switch (condition) {
      case _WeatherClass.clearSunny:
        pool = _clearPool(tier, isOverweight);
        break;
      case _WeatherClass.cloudy:
        pool = _cloudyPool(tier, isOverweight);
        break;
      case _WeatherClass.rainSnow:
        pool = _rainPool(tier);
        break;
      case _WeatherClass.extremeHeat:
        pool = _heatPool(tier, isOverweight);
        break;
      case _WeatherClass.thunderstorm:
        pool = _thunderPool(tier);
        break;
      case _WeatherClass.mistFog:
        pool = _mistPool(tier);
        break;
    }

    // ── FIX 2: shuffle → pick ──────────────────────────────────────────────
    final rng = Random();
    final shuffled = List<ActivitySuggestion>.from(pool)..shuffle(rng);
    return shuffled.take(_pickCount).toList();
  }

  // ── Age tier classifier ────────────────────────────────────────────────────
  // FIX 1: five tiers instead of two so age changes actually matter.
  static _AgeTier _ageTier(int age) {
    if (age < 18) return _AgeTier.youth;
    if (age < 35) return _AgeTier.young;
    if (age < 50) return _AgeTier.middle;
    if (age < 65) return _AgeTier.senior;
    return _AgeTier.elderly;
  }

  // ── Weather classifier ─────────────────────────────────────────────────────
  static _WeatherClass _classify(WeatherModel w) {
    final condition = w.condition.toLowerCase();
    final temp = w.temperature;

    if (temp >= 35) return _WeatherClass.extremeHeat;
    if (condition == 'thunderstorm') return _WeatherClass.thunderstorm;
    if (condition == 'snow') return _WeatherClass.rainSnow;
    if (condition == 'rain' || condition == 'drizzle')
      return _WeatherClass.rainSnow;
    if (condition == 'mist' ||
        condition == 'fog' ||
        condition == 'haze' ||
        condition == 'smoke' ||
        condition == 'dust' ||
        condition == 'sand') return _WeatherClass.mistFog;
    if (condition == 'clear') return _WeatherClass.clearSunny;
    if (condition == 'clouds') return _WeatherClass.cloudy;
    return _WeatherClass.cloudy;
  }

  static bool _isOverweight(String category) {
    final c = category.toLowerCase();
    return c.contains('overweight') || c.contains('obese');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIVITY POOLS — every method returns 5-6 items so the random pick
  // produces genuine variety.  Intensity scales down with age tier.
  // ══════════════════════════════════════════════════════════════════════════

  // ── ☀️  Clear / Sunny ──────────────────────────────────────────────────────
  static List<ActivitySuggestion> _clearPool(_AgeTier tier, bool isOverweight) {
    if (isOverweight) {
      // All ages that are overweight get low-moderate, with slight
      // duration reduction for older tiers.
      final duration = tier.index >= _AgeTier.senior.index ? 25 : 35;
      return [
        ActivitySuggestion(
          name: 'Brisk Walking',
          description:
              'A steady-paced walk that burns calories without straining joints.',
          intensity: 'Low',
          durationMinutes: duration,
          emoji: '🚶',
          videoAsset: 'assets/videos/brisk_walk.mp4',
        ),
        ActivitySuggestion(
          name: 'Light Cycling',
          description:
              'Low-impact outdoor cycling ideal for burning calories comfortably.',
          intensity: 'Moderate',
          durationMinutes: duration,
          emoji: '🚴',
          videoAsset: 'assets/videos/cycling.mp4',
        ),
        const ActivitySuggestion(
          name: 'Water Aerobics',
          description:
              'Pool-based cardio that is easy on joints and great for weight loss.',
          intensity: 'Moderate',
          durationMinutes: 40,
          emoji: '🏊',
          videoAsset: 'assets/videos/swimming.mp4',
        ),
        const ActivitySuggestion(
          name: 'Outdoor Stretching & Walking Lunges',
          description:
              'Combine a scenic walk with bodyweight lunges for toning and cardio.',
          intensity: 'Low',
          durationMinutes: 30,
          emoji: '🌳',
          videoAsset: 'assets/videos/brisk_walk.mp4',
        ),
        const ActivitySuggestion(
          name: 'Resistance Band Walk',
          description:
              'Attach bands to ankles for a resistance-boosted outdoor walk.',
          intensity: 'Low',
          durationMinutes: 30,
          emoji: '🏋️',
          videoAsset: 'assets/videos/resistance_bands.mp4',
        ),
        const ActivitySuggestion(
          name: 'Slow-Pace Jogging',
          description:
              'Light jog with walk breaks — builds stamina without overexertion.',
          intensity: 'Moderate',
          durationMinutes: 30,
          emoji: '🏃',
          videoAsset: 'assets/videos/outdoor_running.mp4',
        ),
      ];
    }

    switch (tier) {
      case _AgeTier.youth:
        return [
          const ActivitySuggestion(
            name: 'Outdoor Running',
            description:
                'Perfect weather to push your speed and build endurance.',
            intensity: 'High',
            durationMinutes: 40,
            emoji: '🏃',
            videoAsset: 'assets/videos/outdoor_running.mp4',
          ),
          const ActivitySuggestion(
            name: 'HIIT Training',
            description:
                'High-Intensity Interval Training for maximum calorie burn.',
            intensity: 'High',
            durationMinutes: 30,
            emoji: '💪',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Sprint Intervals',
            description:
                'Short explosive sprints with recovery walks to boost speed.',
            intensity: 'High',
            durationMinutes: 25,
            emoji: '⚡',
            videoAsset: 'assets/videos/outdoor_running.mp4',
          ),
          const ActivitySuggestion(
            name: 'Outdoor Circuit Training',
            description: 'Park benches and open space for a full-body circuit.',
            intensity: 'High',
            durationMinutes: 35,
            emoji: '🏋️',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Jump Rope Outdoors',
            description:
                'Classic high-calorie cardio — great for coordination too.',
            intensity: 'High',
            durationMinutes: 20,
            emoji: '🪢',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Skateboarding',
            description:
                'Fun outdoor cardio that builds balance and leg strength.',
            intensity: 'Moderate',
            durationMinutes: 45,
            emoji: '🛹',
            videoAsset: 'assets/videos/outdoor_running.mp4',
          ),
        ];

      case _AgeTier.young:
        return [
          const ActivitySuggestion(
            name: 'Outdoor Running',
            description: 'Great weather for a morning run! Push your limits.',
            intensity: 'High',
            durationMinutes: 45,
            emoji: '🏃',
            videoAsset: 'assets/videos/outdoor_running.mp4',
          ),
          const ActivitySuggestion(
            name: 'HIIT Training',
            description:
                'High-Intensity Interval Training for maximum calorie burn.',
            intensity: 'High',
            durationMinutes: 30,
            emoji: '💪',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Outdoor Circuit Training',
            description:
                'Use park benches and open space for a full-body circuit.',
            intensity: 'High',
            durationMinutes: 35,
            emoji: '🏋️',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Sprint Intervals',
            description: 'Short explosive sprints with recovery walks.',
            intensity: 'High',
            durationMinutes: 25,
            emoji: '⚡',
            videoAsset: 'assets/videos/outdoor_running.mp4',
          ),
          const ActivitySuggestion(
            name: 'Cycling + Hill Climb',
            description: 'Tackle inclines for a more intense outdoor ride.',
            intensity: 'High',
            durationMinutes: 50,
            emoji: '🚴',
            videoAsset: 'assets/videos/cycling.mp4',
          ),
          const ActivitySuggestion(
            name: 'Calisthenics Park Workout',
            description:
                'Pull-ups, dips, and push-ups using outdoor gym equipment.',
            intensity: 'High',
            durationMinutes: 35,
            emoji: '🤸',
            videoAsset: 'assets/videos/bodyweight.mp4',
          ),
        ];

      case _AgeTier.middle:
        return [
          const ActivitySuggestion(
            name: 'Moderate Jog',
            description:
                'Steady-state jog — great for heart health at a sustainable pace.',
            intensity: 'Moderate',
            durationMinutes: 40,
            emoji: '🏃',
            videoAsset: 'assets/videos/outdoor_running.mp4',
          ),
          const ActivitySuggestion(
            name: 'Outdoor Cycling',
            description: 'Low-impact endurance ride on a clear morning.',
            intensity: 'Moderate',
            durationMinutes: 45,
            emoji: '🚴',
            videoAsset: 'assets/videos/cycling.mp4',
          ),
          const ActivitySuggestion(
            name: 'Bodyweight Strength',
            description:
                'Squats, lunges, and push-ups to maintain muscle mass.',
            intensity: 'Moderate',
            durationMinutes: 35,
            emoji: '💪',
            videoAsset: 'assets/videos/bodyweight.mp4',
          ),
          const ActivitySuggestion(
            name: 'Power Walking',
            description:
                'Fast-paced walk with arm swing for a full-body workout.',
            intensity: 'Moderate',
            durationMinutes: 40,
            emoji: '🚶',
            videoAsset: 'assets/videos/brisk_walk.mp4',
          ),
          const ActivitySuggestion(
            name: 'Outdoor Yoga Flow',
            description:
                'A dynamic yoga flow to improve flexibility and reduce stress.',
            intensity: 'Low',
            durationMinutes: 35,
            emoji: '🧘',
            videoAsset: 'assets/videos/yoga.mp4',
          ),
          const ActivitySuggestion(
            name: 'Light HIIT',
            description:
                'Modified HIIT with longer rest periods — intensity without injury risk.',
            intensity: 'Moderate',
            durationMinutes: 25,
            emoji: '⚡',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
        ];

      case _AgeTier.senior:
        return [
          const ActivitySuggestion(
            name: 'Brisk Morning Walk',
            description: 'A sunrise stroll to energise the body gently.',
            intensity: 'Low',
            durationMinutes: 35,
            emoji: '🚶',
            videoAsset: 'assets/videos/morning_walk.mp4',
          ),
          const ActivitySuggestion(
            name: 'Tai Chi',
            description:
                'Slow, flowing movements that improve balance and calm the mind.',
            intensity: 'Low',
            durationMinutes: 30,
            emoji: '🧘',
            videoAsset: 'assets/videos/tai_chi.mp4',
          ),
          const ActivitySuggestion(
            name: 'Outdoor Stretching',
            description:
                'Full-body flexibility routine in the fresh morning air.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🌿',
            videoAsset: 'assets/videos/stretching.mp4',
          ),
          const ActivitySuggestion(
            name: 'Light Cycling',
            description: 'Gentle flat-road cycling for cardiovascular health.',
            intensity: 'Low',
            durationMinutes: 30,
            emoji: '🚴',
            videoAsset: 'assets/videos/cycling.mp4',
          ),
          const ActivitySuggestion(
            name: 'Resistance Band Walk',
            description: 'Easy resistance walk to maintain leg strength.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🏋️',
            videoAsset: 'assets/videos/resistance_bands.mp4',
          ),
          const ActivitySuggestion(
            name: 'Balance Drills',
            description:
                'Simple drills outdoors to improve stability and coordination.',
            intensity: 'Low',
            durationMinutes: 20,
            emoji: '⚖️',
            videoAsset: 'assets/videos/tai_chi.mp4',
          ),
        ];

      case _AgeTier.elderly:
        return [
          const ActivitySuggestion(
            name: 'Slow Morning Walk',
            description:
                'A very gentle pace stroll — motion is the best medicine.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🚶',
            videoAsset: 'assets/videos/morning_walk.mp4',
          ),
          const ActivitySuggestion(
            name: 'Seated Tai Chi',
            description:
                'Gentle flowing movements, mostly seated, for joint health.',
            intensity: 'Low',
            durationMinutes: 20,
            emoji: '🧘',
            videoAsset: 'assets/videos/tai_chi.mp4',
          ),
          const ActivitySuggestion(
            name: 'Gentle Stretching',
            description:
                'Full-body stretching with no impact — reduces stiffness.',
            intensity: 'Low',
            durationMinutes: 20,
            emoji: '🌿',
            videoAsset: 'assets/videos/stretching.mp4',
          ),
          const ActivitySuggestion(
            name: 'Chair Yoga Outdoors',
            description: 'Enjoy fresh air while doing supported yoga poses.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🪑',
            videoAsset: 'assets/videos/yoga.mp4',
          ),
          const ActivitySuggestion(
            name: 'Bird Watching Walk',
            description:
                'A mindful, leisurely stroll — easy on the body, great for mood.',
            intensity: 'Low',
            durationMinutes: 30,
            emoji: '🐦',
            videoAsset: 'assets/videos/morning_walk.mp4',
          ),
        ];
    }
  }

  // ── ⛅ Cloudy ──────────────────────────────────────────────────────────────
  static List<ActivitySuggestion> _cloudyPool(
      _AgeTier tier, bool isOverweight) {
    if (isOverweight) {
      return [
        const ActivitySuggestion(
          name: 'Brisk Walk',
          description: 'Keep a steady pace to maintain your heart rate zone.',
          intensity: 'Low',
          durationMinutes: 40,
          emoji: '🚶',
          videoAsset: 'assets/videos/brisk_walk.mp4',
        ),
        const ActivitySuggestion(
          name: 'Resistance Band Training',
          description:
              'Gentle resistance work to tone muscles without heavy load.',
          intensity: 'Moderate',
          durationMinutes: 25,
          emoji: '🏋️',
          videoAsset: 'assets/videos/resistance_bands.mp4',
        ),
        const ActivitySuggestion(
          name: 'Low-Impact Aerobics',
          description:
              'Step-based cardio routine that raises heart rate gently.',
          intensity: 'Moderate',
          durationMinutes: 30,
          emoji: '🕺',
          videoAsset: 'assets/videos/hiit.mp4',
        ),
        const ActivitySuggestion(
          name: 'Swimming',
          description: 'Full-body workout with zero joint impact.',
          intensity: 'Moderate',
          durationMinutes: 35,
          emoji: '🏊',
          videoAsset: 'assets/videos/swimming.mp4',
        ),
        const ActivitySuggestion(
          name: 'Slow-Pace Jogging',
          description:
              'Gentle jog with walk breaks — builds stamina without overexertion.',
          intensity: 'Moderate',
          durationMinutes: 30,
          emoji: '🏃',
          videoAsset: 'assets/videos/outdoor_running.mp4',
        ),
      ];
    }

    switch (tier) {
      case _AgeTier.youth:
      case _AgeTier.young:
        return [
          const ActivitySuggestion(
            name: 'Outdoor Cycling',
            description:
                'Overcast skies make for a comfortable endurance ride.',
            intensity: 'Moderate',
            durationMinutes: 40,
            emoji: '🚴',
            videoAsset: 'assets/videos/cycling.mp4',
          ),
          const ActivitySuggestion(
            name: 'Jogging',
            description:
                'Cool cloudy conditions are perfect for a sustained jog.',
            intensity: 'Moderate',
            durationMinutes: 35,
            emoji: '🏃',
            videoAsset: 'assets/videos/outdoor_running.mp4',
          ),
          const ActivitySuggestion(
            name: 'Calisthenics Park Workout',
            description:
                'Pull-ups, dips, and push-ups using outdoor gym equipment.',
            intensity: 'High',
            durationMinutes: 30,
            emoji: '💪',
            videoAsset: 'assets/videos/bodyweight.mp4',
          ),
          const ActivitySuggestion(
            name: 'Skateboarding or Rollerblading',
            description:
                'Fun cardio that builds balance and leg strength outdoors.',
            intensity: 'Moderate',
            durationMinutes: 40,
            emoji: '🛹',
            videoAsset: 'assets/videos/outdoor_running.mp4',
          ),
          const ActivitySuggestion(
            name: 'Interval Running',
            description:
                'Alternate between fast and slow running for endurance gains.',
            intensity: 'High',
            durationMinutes: 35,
            emoji: '⚡',
            videoAsset: 'assets/videos/outdoor_running.mp4',
          ),
          const ActivitySuggestion(
            name: 'Outdoor Yoga Flow',
            description:
                'Dynamic yoga in cool air — perfect stretch and breathwork combo.',
            intensity: 'Low',
            durationMinutes: 30,
            emoji: '🧘',
            videoAsset: 'assets/videos/yoga.mp4',
          ),
        ];

      case _AgeTier.middle:
        return [
          const ActivitySuggestion(
            name: 'Moderate Jog',
            description:
                'Comfortable pace jog — cool weather makes it even better.',
            intensity: 'Moderate',
            durationMinutes: 35,
            emoji: '🏃',
            videoAsset: 'assets/videos/outdoor_running.mp4',
          ),
          const ActivitySuggestion(
            name: 'Cycling',
            description: 'Flat-road cycling session on a pleasant cloudy day.',
            intensity: 'Moderate',
            durationMinutes: 40,
            emoji: '🚴',
            videoAsset: 'assets/videos/cycling.mp4',
          ),
          const ActivitySuggestion(
            name: 'Bodyweight Circuit',
            description:
                'Squats, lunges, and push-ups outdoors in mild weather.',
            intensity: 'Moderate',
            durationMinutes: 30,
            emoji: '💪',
            videoAsset: 'assets/videos/bodyweight.mp4',
          ),
          const ActivitySuggestion(
            name: 'Power Walking',
            description:
                'Fast-paced walk with arm swing for a full-body workout.',
            intensity: 'Moderate',
            durationMinutes: 40,
            emoji: '🚶',
            videoAsset: 'assets/videos/brisk_walk.mp4',
          ),
          const ActivitySuggestion(
            name: 'Resistance Band Outdoor',
            description:
                'Light resistance work in the park — easy on the joints.',
            intensity: 'Moderate',
            durationMinutes: 25,
            emoji: '🏋️',
            videoAsset: 'assets/videos/resistance_bands.mp4',
          ),
        ];

      case _AgeTier.senior:
      case _AgeTier.elderly:
        return [
          const ActivitySuggestion(
            name: 'Light Walk',
            description: 'Easy-paced stroll to stay active on a cloudy day.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🚶',
            videoAsset: 'assets/videos/morning_walk.mp4',
          ),
          const ActivitySuggestion(
            name: 'Gentle Stretching',
            description:
                'Full-body stretching to improve flexibility and reduce stiffness.',
            intensity: 'Low',
            durationMinutes: 20,
            emoji: '🧘',
            videoAsset: 'assets/videos/stretching.mp4',
          ),
          const ActivitySuggestion(
            name: 'Chair Yoga',
            description:
                'Modified yoga poses using a chair for support and balance.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🪑',
            videoAsset: 'assets/videos/yoga.mp4',
          ),
          const ActivitySuggestion(
            name: 'Balance & Coordination Drills',
            description:
                'Simple drills to improve stability and prevent falls.',
            intensity: 'Low',
            durationMinutes: 20,
            emoji: '⚖️',
            videoAsset: 'assets/videos/tai_chi.mp4',
          ),
          const ActivitySuggestion(
            name: 'Gentle Tai Chi',
            description: 'Slow flowing movements for balance and calm.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🌿',
            videoAsset: 'assets/videos/tai_chi.mp4',
          ),
        ];
    }
  }

  // ── 🌧️  Rain / Snow ───────────────────────────────────────────────────────
  static List<ActivitySuggestion> _rainPool(_AgeTier tier) {
    // Base indoor pool shared by all — shuffle gives variety
    final base = [
      const ActivitySuggestion(
        name: 'Indoor Yoga',
        description:
            'Perfect for a rainy day — stretch, breathe, and restore energy.',
        intensity: 'Low',
        durationMinutes: 40,
        emoji: '🧘',
        videoAsset: 'assets/videos/yoga.mp4',
      ),
      const ActivitySuggestion(
        name: 'Bodyweight Circuit',
        description:
            'No equipment needed — squats, push-ups, and planks indoors.',
        intensity: 'Moderate',
        durationMinutes: 30,
        emoji: '💪',
        videoAsset: 'assets/videos/bodyweight.mp4',
      ),
      const ActivitySuggestion(
        name: 'Dance Workout',
        description:
            'Put on your favourite playlist and dance for a fun cardio session.',
        intensity: 'Moderate',
        durationMinutes: 30,
        emoji: '💃',
        videoAsset: 'assets/videos/hiit.mp4',
      ),
      const ActivitySuggestion(
        name: 'Indoor Pilates',
        description:
            'Core-focused exercises that build strength and posture indoors.',
        intensity: 'Low',
        durationMinutes: 35,
        emoji: '🏠',
        videoAsset: 'assets/videos/bodyweight.mp4',
      ),
    ];

    // Age-specific additions injected into the pool
    switch (tier) {
      case _AgeTier.youth:
      case _AgeTier.young:
        return [
          ...base,
          const ActivitySuggestion(
            name: 'Stair Climbing',
            description:
                'Use your home stairs for an intense leg and cardio workout.',
            intensity: 'High',
            durationMinutes: 20,
            emoji: '🪜',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Indoor HIIT',
            description:
                'Burpees, mountain climbers, and jumping jacks — no gym needed.',
            intensity: 'High',
            durationMinutes: 25,
            emoji: '⚡',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
        ];
      case _AgeTier.middle:
        return [
          ...base,
          const ActivitySuggestion(
            name: 'Stair Climbing',
            description: 'A steady stair climb for low-impact cardio.',
            intensity: 'Moderate',
            durationMinutes: 20,
            emoji: '🪜',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Resistance Band Full-Body',
            description:
                'Complete upper and lower body workout using resistance bands.',
            intensity: 'Moderate',
            durationMinutes: 30,
            emoji: '🏋️',
            videoAsset: 'assets/videos/resistance_bands.mp4',
          ),
        ];
      case _AgeTier.senior:
      case _AgeTier.elderly:
        return [
          const ActivitySuggestion(
            name: 'Seated Stretching',
            description:
                'Gentle seated stretches to keep joints mobile on a rainy day.',
            intensity: 'Low',
            durationMinutes: 20,
            emoji: '🪑',
            videoAsset: 'assets/videos/stretching.mp4',
          ),
          const ActivitySuggestion(
            name: 'Indoor Tai Chi',
            description:
                'Slow, mindful movement practice — perfect for any weather.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🧘',
            videoAsset: 'assets/videos/tai_chi.mp4',
          ),
          const ActivitySuggestion(
            name: 'Chair Yoga',
            description:
                'Supported yoga poses that improve flexibility safely.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🪑',
            videoAsset: 'assets/videos/yoga.mp4',
          ),
          const ActivitySuggestion(
            name: 'Light Indoor Walk',
            description:
                'Walk laps around the house or hallway to keep moving.',
            intensity: 'Low',
            durationMinutes: 20,
            emoji: '🚶',
            videoAsset: 'assets/videos/morning_walk.mp4',
          ),
          const ActivitySuggestion(
            name: 'Breathing & Meditation',
            description:
                'Deep breathing exercises to reduce stress and improve focus.',
            intensity: 'Low',
            durationMinutes: 20,
            emoji: '🌬️',
            videoAsset: 'assets/videos/yoga.mp4',
          ),
        ];
    }
  }

  // ── 🔥  Extreme Heat ───────────────────────────────────────────────────────
  static List<ActivitySuggestion> _heatPool(_AgeTier tier, bool isOverweight) {
    if (isOverweight || tier.index >= _AgeTier.senior.index) {
      return [
        const ActivitySuggestion(
          name: 'Swimming',
          description:
              'Stay cool while torching calories — the ultimate heat-safe cardio.',
          intensity: 'Moderate',
          durationMinutes: 40,
          emoji: '🏊',
          videoAsset: 'assets/videos/swimming.mp4',
        ),
        const ActivitySuggestion(
          name: 'Hydrated Light Stretching',
          description:
              'Gentle stretches in a cool, shaded area — keep water close.',
          intensity: 'Low',
          durationMinutes: 20,
          emoji: '🧘',
          videoAsset: 'assets/videos/stretching.mp4',
        ),
        const ActivitySuggestion(
          name: 'Water Aerobics',
          description:
              'Low-impact pool exercises that keep your body cool and active.',
          intensity: 'Moderate',
          durationMinutes: 35,
          emoji: '💦',
          videoAsset: 'assets/videos/swimming.mp4',
        ),
        const ActivitySuggestion(
          name: 'Indoor Fan Cycling',
          description:
              'Stationary bike in an air-conditioned room for a safe heat-day workout.',
          intensity: 'Moderate',
          durationMinutes: 30,
          emoji: '🚴',
          videoAsset: 'assets/videos/cycling.mp4',
        ),
        const ActivitySuggestion(
          name: 'Indoor Yoga',
          description: 'Cool down indoors with a restorative yoga session.',
          intensity: 'Low',
          durationMinutes: 30,
          emoji: '🧘',
          videoAsset: 'assets/videos/yoga.mp4',
        ),
        const ActivitySuggestion(
          name: 'Seated Strength Training',
          description: 'Light weights or bands in an air-conditioned room.',
          intensity: 'Low',
          durationMinutes: 25,
          emoji: '🏋️',
          videoAsset: 'assets/videos/resistance_bands.mp4',
        ),
      ];
    }

    // Young / middle-aged normal weight
    return [
      const ActivitySuggestion(
        name: 'Early-Morning Run',
        description:
            'Beat the heat — go before 7 AM for the best running conditions.',
        intensity: 'High',
        durationMinutes: 35,
        emoji: '🏃',
        videoAsset: 'assets/videos/outdoor_running.mp4',
      ),
      const ActivitySuggestion(
        name: 'Indoor Cardio',
        description:
            'Air-conditioned cardio session: jump rope, stepping, or cycling.',
        intensity: 'Moderate',
        durationMinutes: 30,
        emoji: '🏋️',
        videoAsset: 'assets/videos/hiit.mp4',
      ),
      const ActivitySuggestion(
        name: 'Swimming Laps',
        description:
            'Cool down while building endurance with freestyle lap swimming.',
        intensity: 'High',
        durationMinutes: 40,
        emoji: '🏊',
        videoAsset: 'assets/videos/swimming.mp4',
      ),
      const ActivitySuggestion(
        name: 'Indoor Rock Climbing',
        description:
            'Beat the heat at a climbing gym — full-body strength and fun.',
        intensity: 'High',
        durationMinutes: 45,
        emoji: '🧗',
        videoAsset: 'assets/videos/bodyweight.mp4',
      ),
      const ActivitySuggestion(
        name: 'Pre-Dawn Cycling',
        description:
            'Early morning ride before the heat peaks — great for endurance.',
        intensity: 'Moderate',
        durationMinutes: 45,
        emoji: '🚴',
        videoAsset: 'assets/videos/cycling.mp4',
      ),
      const ActivitySuggestion(
        name: 'Indoor HIIT',
        description: 'High-intensity intervals in an air-conditioned space.',
        intensity: 'High',
        durationMinutes: 25,
        emoji: '⚡',
        videoAsset: 'assets/videos/hiit.mp4',
      ),
    ];
  }

  // ── ⛈️  Thunderstorm ────────────────────────────────────────────────────────
  static List<ActivitySuggestion> _thunderPool(_AgeTier tier) {
    final base = [
      const ActivitySuggestion(
        name: 'Meditation & Breathing',
        description:
            'Deep breathing and mindfulness to reduce stress and boost focus.',
        intensity: 'Low',
        durationMinutes: 20,
        emoji: '🧘',
        videoAsset: 'assets/videos/yoga.mp4',
      ),
      const ActivitySuggestion(
        name: 'Home Pilates',
        description:
            'Core strengthening and flexibility work — no equipment needed.',
        intensity: 'Low',
        durationMinutes: 30,
        emoji: '💪',
        videoAsset: 'assets/videos/bodyweight.mp4',
      ),
      const ActivitySuggestion(
        name: 'Foam Rolling & Mobility',
        description: 'Release muscle tightness and improve range of motion.',
        intensity: 'Low',
        durationMinutes: 25,
        emoji: '🔵',
        videoAsset: 'assets/videos/stretching.mp4',
      ),
    ];

    switch (tier) {
      case _AgeTier.youth:
      case _AgeTier.young:
        return [
          ...base,
          const ActivitySuggestion(
            name: 'Indoor Shadow Boxing',
            description:
                'Punch combinations in place for a fun cardio and coordination workout.',
            intensity: 'Moderate',
            durationMinutes: 25,
            emoji: '🥊',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Resistance Band Full Body',
            description:
                'Complete upper and lower body workout using resistance bands.',
            intensity: 'Moderate',
            durationMinutes: 30,
            emoji: '🏋️',
            videoAsset: 'assets/videos/resistance_bands.mp4',
          ),
          const ActivitySuggestion(
            name: 'Indoor HIIT',
            description: 'Burpees and mountain climbers — no gym needed.',
            intensity: 'High',
            durationMinutes: 25,
            emoji: '⚡',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
        ];
      case _AgeTier.middle:
        return [
          ...base,
          const ActivitySuggestion(
            name: 'Indoor Shadow Boxing',
            description:
                'Light punch combinations for a moderate cardio session.',
            intensity: 'Moderate',
            durationMinutes: 20,
            emoji: '🥊',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Resistance Band Full Body',
            description: 'Effective at-home resistance training.',
            intensity: 'Moderate',
            durationMinutes: 30,
            emoji: '🏋️',
            videoAsset: 'assets/videos/resistance_bands.mp4',
          ),
        ];
      case _AgeTier.senior:
      case _AgeTier.elderly:
        return [
          ...base,
          const ActivitySuggestion(
            name: 'Seated Gentle Yoga',
            description:
                'Calm, restorative poses to ease tension during stormy weather.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🪑',
            videoAsset: 'assets/videos/yoga.mp4',
          ),
          const ActivitySuggestion(
            name: 'Breathing Exercises',
            description:
                'Diaphragmatic breathing to reduce anxiety and improve lung capacity.',
            intensity: 'Low',
            durationMinutes: 15,
            emoji: '🌬️',
            videoAsset: 'assets/videos/yoga.mp4',
          ),
        ];
    }
  }

  // ── 🌫️  Mist / Fog ─────────────────────────────────────────────────────────
  static List<ActivitySuggestion> _mistPool(_AgeTier tier) {
    final base = [
      const ActivitySuggestion(
        name: 'Indoor Treadmill',
        description:
            'Avoid the fog and run safely on a treadmill at your own pace.',
        intensity: 'Moderate',
        durationMinutes: 35,
        emoji: '🏃',
        videoAsset: 'assets/videos/outdoor_running.mp4',
      ),
      const ActivitySuggestion(
        name: 'Stationary Bike',
        description:
            'Pedal at your own pace indoors while watching your favourite show.',
        intensity: 'Moderate',
        durationMinutes: 35,
        emoji: '🚴',
        videoAsset: 'assets/videos/cycling.mp4',
      ),
      const ActivitySuggestion(
        name: 'Indoor Rowing',
        description: 'Full-body low-impact cardio on a rowing machine.',
        intensity: 'Moderate',
        durationMinutes: 30,
        emoji: '🚣',
        videoAsset: 'assets/videos/bodyweight.mp4',
      ),
    ];

    switch (tier) {
      case _AgeTier.youth:
      case _AgeTier.young:
        return [
          ...base,
          const ActivitySuggestion(
            name: 'Jump Rope Workout',
            description: 'High-efficiency cardio that fits any indoor space.',
            intensity: 'High',
            durationMinutes: 20,
            emoji: '🪢',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Indoor Martial Arts',
            description:
                'Basic karate or taekwondo forms to sharpen focus and strength.',
            intensity: 'High',
            durationMinutes: 30,
            emoji: '🥋',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Indoor HIIT',
            description:
                'High-intensity training for maximum indoor calorie burn.',
            intensity: 'High',
            durationMinutes: 25,
            emoji: '⚡',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
        ];
      case _AgeTier.middle:
        return [
          ...base,
          const ActivitySuggestion(
            name: 'Jump Rope',
            description:
                'Quick high-calorie cardio — great for a foggy day indoors.',
            intensity: 'Moderate',
            durationMinutes: 20,
            emoji: '🪢',
            videoAsset: 'assets/videos/hiit.mp4',
          ),
          const ActivitySuggestion(
            name: 'Resistance Band Circuit',
            description: 'Full-body resistance training without leaving home.',
            intensity: 'Moderate',
            durationMinutes: 30,
            emoji: '🏋️',
            videoAsset: 'assets/videos/resistance_bands.mp4',
          ),
        ];
      case _AgeTier.senior:
      case _AgeTier.elderly:
        return [
          const ActivitySuggestion(
            name: 'Indoor Slow Walk',
            description:
                'Walk gentle laps indoors — keeps joints moving safely.',
            intensity: 'Low',
            durationMinutes: 20,
            emoji: '🚶',
            videoAsset: 'assets/videos/morning_walk.mp4',
          ),
          const ActivitySuggestion(
            name: 'Seated Stretching',
            description: 'Chair-based stretches for the whole body.',
            intensity: 'Low',
            durationMinutes: 20,
            emoji: '🪑',
            videoAsset: 'assets/videos/stretching.mp4',
          ),
          const ActivitySuggestion(
            name: 'Indoor Tai Chi',
            description:
                'Flowing movements to improve balance and calm the mind.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🧘',
            videoAsset: 'assets/videos/tai_chi.mp4',
          ),
          const ActivitySuggestion(
            name: 'Stationary Bike (Easy)',
            description:
                'Very low resistance pedalling to keep circulation going.',
            intensity: 'Low',
            durationMinutes: 25,
            emoji: '🚴',
            videoAsset: 'assets/videos/cycling.mp4',
          ),
          const ActivitySuggestion(
            name: 'Breathing Exercises',
            description:
                'Breathing routines to improve lung capacity and reduce tension.',
            intensity: 'Low',
            durationMinutes: 15,
            emoji: '🌬️',
            videoAsset: 'assets/videos/yoga.mp4',
          ),
        ];
    }
  }
}

enum _WeatherClass {
  clearSunny,
  cloudy,
  rainSnow,
  extremeHeat,
  thunderstorm,
  mistFog,
}

// FIX 1: Five age tiers instead of two.
// Changing age across a tier boundary now produces a genuinely different
// activity set; changing within a tier still randomises via the shuffle.
enum _AgeTier {
  youth, // < 18
  young, // 18–34
  middle, // 35–49
  senior, // 50–64
  elderly, // 65+
}
