# SafeHer Bangladesh Frontend ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â Final Run Guide

This repository contains the Flutter frontend for **SafeHer Bangladesh**, an AI-driven women safety and digital empowerment platform.

---

## 1. Local Path

```powershell
D:\safeher_flutter
```

The backend should be available at:

```powershell
D:\safeher-backend
```

---

## 2. Main Modules

| Module | Description |
|---|---|
| Dashboard | Safety index, risk breakdown, alerts, quick access |
| Emergency SOS | SOS trigger, queued dispatch, ACK latency, escalation, helplines |
| Mitra | Bengali/Banglish safety guidance chatbot |
| Safe Route | Map, transport modes, route preference, nearby safe stops |
| Sister Circle | Women-only community forum with masked identity |
| Legal Aid | Legal resources, reporting guide, emergency helpline actions |
| Notifications | Safety notifications and alert status |
| Settings/Profile | User profile and emergency contact management |

---

## 3. Run Commands

Start backend, queue worker, and ML API first. Then run:

```powershell
cd "D:\safeher_flutter"
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api --dart-define=ML_API_BASE_URL=http://127.0.0.1:8001
```

For Android emulator:

```powershell
cd "D:\safeher_flutter"
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api --dart-define=ML_API_BASE_URL=http://10.0.2.2:8001
```

---

## 4. Verification

```powershell
cd "D:\safeher_flutter"
flutter pub get
flutter analyze
flutter test
```

Expected:

```text
No issues found
All tests passed
```

Package update warnings are acceptable if tests and analysis pass.

---

## 5. Demo Screenshots to Capture

1. Login screen.
2. Dashboard with Risk Breakdown.
3. Emergency SOS queued screen with ACK latency.
4. Mitra safety guidance response.
5. Safe Route with safe stops.
6. Sister Circle feed.
7. Legal Aid reporting guide.
8. Settings/Profile with emergency contact flow.
9. Backend request logs.
10. ML API health.
11. Backend and Flutter test results.

---

## 6. Web vs Android Notes

Chrome/web is best for fast demo screenshots. Android emulator is better for mobile-specific permission testing.

Web limitations:

- Browser may request location permission.
- Local notifications/background retry may not behave like Android.
- Always verify SOS API response and queue worker output for reliability evidence.

---

## 7. Git Safety

Do not commit:

```text
.env
.env.*
build/
.dart_tool/
coverage/
_safeher_backups/
_safeher_reports/
_safeher_tools/
*.backup_*
Firebase private config files
```
## Admin Dashboard

The dashboard includes an Admin quick action. It calls authenticated `/api/admin/*` endpoints.

For local demo, enable admin access in the backend `.env`:

```env
ADMIN_PHONES=+8801XXXXXXXXX
```

Then run `php artisan config:clear` and log in with the matching account.
## Community Safety Hub

The dashboard includes a Safety Hub entry for:

- Women-only forum verification
- Guardian/parental control setup
- Sub-admin incident submission

Backend must expose `/api/community/profile`, `/api/guardian-links`, and `/api/sub-admin/incidents`.
## Sprint-7 Evidence & Case Center

The Flutter app now includes an Evidence & Case Center screen for:

- Guided incident reports
- Private evidence-vault metadata
- GD/FIR/legal-aid case tracking

Open it from the dashboard card: **Evidence & Case Center**.
## Sprint-8 Emergency Utility Toolkit

The Flutter app now includes a Stealth & Emergency Tools screen for decoy calls, quick exit, witness reports, allies-nearby alerts, and helpline network access.
## Sprint-9 Learning & Rights Center

The Flutter app now includes a Learning & Rights Center for trust profile, verification request, Know Your Rights modules, self-defense lessons, and safety tips.