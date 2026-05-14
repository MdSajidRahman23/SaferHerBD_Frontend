# SafeHer Batch 1 — Compile Error Fixes

These files fix the 4 compile errors you hit:

| Error | Cause | Fixed |
|---|---|---|
| `NotificationService.initialize()` not defined | I used `init()`, you called `initialize()` | ✅ Method renamed/aliased |
| `locationSettings` not a valid parameter (×3) | geolocator 12.0.0 still uses old API | ✅ Switched to `desiredAccuracy:` |
| `tag:` not a valid parameter for createPost | api_service patch not applied | ✅ Forum uses existing `tags:` list |

---

## 🎯 What to Replace

Replace these 4 files in your project:

| Source (this zip) | Destination |
|---|---|
| `flutter/lib/services/notification_service.dart` | `lib/services/notification_service.dart` |
| `flutter/lib/services/sos_service.dart` | `lib/services/sos_service.dart` |
| `flutter/lib/screens/sos/sos_screen.dart` | `lib/screens/sos/sos_screen.dart` |
| `flutter/lib/screens/forum/forum_screen.dart` | `lib/screens/forum/forum_screen.dart` |

---

## 🚀 After replacing — run

```powershell
cd D:\safeher_flutter
flutter clean
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api --dart-define=ML_API_BASE_URL=http://10.0.2.2:8001
```

---

## ⚠️ Note on Web vs Mobile

তুমি Chrome-এ চালাচ্ছিলে (web build)। Web-এ:
- ✅ HTTP calls work
- ✅ Geolocator works (via browser API)
- ⚠️ Local notifications **don't work** on web — they'll silently fail (no crash)
- ⚠️ Background SOS retry doesn't work on web

**সর্বোত্তম experience-এর জন্য Android emulator চালাও:**
```powershell
# Android Studio → Tools → Device Manager → Start an emulator
# তারপর flutter run চালালে emulator-এ deploy হবে
```

URL conventions:
- Android emulator → `http://10.0.2.2:8000` (already in your command)
- Chrome/Edge → `http://127.0.0.1:8000` (need to change `--dart-define`)

For Chrome:
```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api --dart-define=ML_API_BASE_URL=http://127.0.0.1:8001
```

---

## 📝 What's NOT changed (Batch 1 still applies as-is)

- `emergency_contacts_screen.dart` — same as before, needs api_service patches
- `EmergencyContactController.php` — same backend file
- `PATCH_api_service.dart` — still apply these 4 methods to your api_service.dart for the contacts CRUD to work

---

## 🐛 If you see new errors after this fix

The most likely next error is on the Emergency Contacts screen:
```
The method 'createContact' isn't defined for the type 'ApiService'
The method 'updateContact' isn't defined for the type 'ApiService'
```

Fix: Apply the api_service patches from `batch1/flutter/lib/services/PATCH_api_service.dart`:
1. Add `_safePut` helper
2. Add `createContact` method
3. Add `updateContact` method

(You can skip the `createPost` patch since this fix already adjusts forum_screen to use the existing `tags:` list parameter.)
