# SafeHerBD Flutter Frontend

SafeHerBD is a Flutter web/mobile frontend for a women safety platform in Bangladesh. It connects to the SafeHerBD Laravel backend and ML API to provide SOS, safe routes, Mitra guidance, women-only community, legal aid, admin monitoring, guardian access, evidence/case tracking, emergency tools, and learning resources.

## Core Features

- Login and authenticated dashboard
- Live safety index and risk breakdown
- Emergency SOS with queue dispatch, check-in, escalation, and contacts
- Mitra safety chatbot with Bangla and English guidance
- Safe route map with risk scoring, safe stops, and journey safety mode
- Women-only Sister Circle community
- Legal Aid with helpline support
- Admin dashboard with active SOS, moderation queue, and system health
- Safety Hub for guardian control, women-only verification, and sub-admin incident reporting
- Evidence & Case Center for incident reports, evidence metadata, and GD/FIR tracking
- Stealth & Emergency Tools with decoy call, quick exit, witness mode, allies nearby, and helplines
- Learning & Rights Center with rights, self-defense basics, safety tips, and verification request
- Notifications and profile/settings screens

## Local Project Paths

Backend: D:\safeher-backend  
Flutter frontend: D:\safeher_flutter

## Requirements

- Flutter SDK
- Chrome for web testing
- SafeHerBD backend running at http://127.0.0.1:8000/api
- SafeHerBD ML API running at http://127.0.0.1:8001

## Install

cd "D:\safeher_flutter"
flutter pub get

## Run

cd "D:\safeher_flutter"

flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api --dart-define=ML_API_BASE_URL=http://127.0.0.1:8001

If the app is already running, press R in the Flutter terminal to hot restart.

## Backend and ML API

Start backend:

cd "D:\safeher-backend"
php artisan serve --host=127.0.0.1 --port=8000

Start queue worker:

cd "D:\safeher-backend"
php artisan queue:work --queue=sos,default

Start ML API:

cd "D:\safeher-backend\ml_api"
.\venv\Scripts\activate
python -m uvicorn main:app --host 127.0.0.1 --port 8001

## Verify

cd "D:\safeher_flutter"

flutter analyze
flutter test

Expected:
No issues found
All tests passed

## Smoke Test Checklist

1. Login
2. Dashboard loads with safety index and modules
3. Trigger SOS and confirm queued dispatch
4. Open Mitra and send Bangla/English safety messages
5. Open Safe Route and calculate a route
6. Open Sister Circle community
7. Open Legal Aid and helpline details
8. Open Admin Dashboard and check SOS/moderation/system health
9. Open Safety Hub and verify guardian/sub-admin sections
10. Open Evidence & Case Center
11. Open Stealth & Emergency Tools
12. Open Learning & Rights and check back navigation
13. Open Notifications and Profile

## Notes

- Firebase/FCM is optional for local demo.
- Local backup folders and generated patch artifacts should not be committed.
- Keep backend .env secrets private.
## Advanced Admin Management

The Admin Dashboard includes an Advanced Admin Management entry for incident review, women verification, role assignment, evidence review, and legal case review.
## Advanced Safety Modules

The Learning & Rights screen links to an Advanced Safety Modules screen covering Safe Ride, NID/trust verification, officer dispatch design, heatmap zone control, privacy center, audit log, helpline operator workflow, and shake/voice trigger settings.

## Native Emergency Pack

The Advanced Safety Modules screen links to a Native Emergency Pack covering Safe Walk timer, local alarm/vibration, offline SOS draft, shake-to-SOS settings, voice trigger settings, flashlight workflow, and missed check-in escalation without paid APIs.

- Guardian Live Tracking with Safe Walk timer, check-ins, and missed check-in escalation.

## Evidence Vault Plus

The Advanced Safety Modules screen links to Evidence Vault Plus, covering PIN lock, protected metadata, timestamp/location labels, checksum preview, export summary, and phone-native capture workflow without paid APIs.

## Admin / Community Intelligence

The Advanced Safety Modules screen links to Admin Intelligence, covering risk-zone review, community trends, audit log preview, and CSV export workflow without paid APIs.
