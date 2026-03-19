# caloríq — Weight & Calorie Tracker

A calm, minimal Flutter app for tracking weight, calories, and food intake.  
No ads. No subscriptions. No noise.

---

## Features

### 🏠 Dashboard
- Calorie ring with live remaining/over budget
- 7-day calorie bar chart with your goal line
- Goal projection (days + estimated date to reach target weight)
- Macro breakdown (protein, carbs, fat)
- Today's weight snapshot

### ⚖️ Weight Calendar
- Line graph with your actual weight + target weight dashed line
- Log morning + optional evening weight (averaged automatically)
- Calendar view with green dots on logged days
- Tap any past date to log/edit forgotten entries
- Swipe-to-delete or edit any entry

### 🍽️ Food Diary
- Breakfast / Lunch / Dinner / Snacks / Exercise sections
- Search food via **OpenFoodFacts** (massive free database, no API key needed)
- Live calorie + macro preview as you type the amount
- Swipe left to delete any entry
- Switch date to log for past days
- Exercise logging with quick templates (Walking, Running, HIIT…)
- Exercise calories subtracted from daily total

### 👤 Profile & TDEE
- **Mifflin-St Jeor** BMR formula + activity multiplier
- Live preview of TDEE, calorie goal, deficit
- BMI display with color coding
- Days to goal + estimated goal date
- Preset deficit chips (250 / 500 / 750 / 1000 kcal)

---

## Setup

### Prerequisites
- Flutter SDK 3.x ([install guide](https://docs.flutter.dev/get-started/install))
- Android Studio or VS Code with Flutter extension
- Android device or emulator (Android 6.0+)

### Run

```bash
cd caloriq
flutter pub get
flutter run
```

### Build APK

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Architecture

```
lib/
├── main.dart              # App entry, shell, onboarding
├── theme.dart             # Colors, typography (DM Sans + Cormorant Garamond)
├── models/
│   └── models.dart        # UserProfile, WeightEntry, FoodItem, FoodLog, ExerciseLog
├── providers/
│   └── app_provider.dart  # State management (ChangeNotifier)
├── services/
│   ├── database_service.dart   # SQLite (sqflite)
│   └── food_api_service.dart   # OpenFoodFacts API
├── screens/
│   ├── dashboard_screen.dart
│   ├── weight_screen.dart
│   ├── food_diary_screen.dart
│   └── tdee_screen.dart
└── widgets/
    └── common_widgets.dart     # CCard, MacroBar, RingProgress, etc.
```

---

## Samsung Health Integration

Samsung Health doesn't expose a public API for third-party apps.

**Workaround (current):**
1. After a workout on your Galaxy Watch / Fit 3, note the calories in Samsung Health
2. Tap "Exercise" in the Food Diary → log it manually (name, duration, calories)

**Future deep integration options:**
- Samsung Health SDK (requires Samsung developer enrollment + APK signature)
- Export health data CSV from Samsung Health → import feature (can be added)

---

## Tech Stack

| Package | Use |
|---|---|
| `provider` | State management |
| `sqflite` | Local SQLite database |
| `fl_chart` | Line + bar charts |
| `table_calendar` | Weight calendar |
| `http` | OpenFoodFacts API calls |
| `google_fonts` | DM Sans + Cormorant Garamond |
| `shared_preferences` | User profile persistence |

---

## Design

Dark warm palette — like journaling by lamplight.  
- **Background:** `#0F0F11`  
- **Accent:** `#D4A853` (warm gold)  
- **Typography:** Cormorant Garamond (display) + DM Sans (body)

---

## Privacy

Everything stored **locally on your device**. No accounts, no cloud sync, no analytics.
OpenFoodFacts queries are anonymous search requests.
