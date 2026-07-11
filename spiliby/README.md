# Spiliby

Spiliby is an offline-first expense splitting PWA for college groups, roommates,
and travel buddies. There is no backend or login; everything is stored locally in
IndexedDB on the device.

## What it does

- Create a profile and add friends
- Create groups and add shared expenses
- Split expenses equally, by percentage, or by custom amounts
- View who owes what and who should receive money
- Work fully offline
- Share group data between nearby phones using QR codes
- Export and import backups as JSON when needed

## How offline sync works

1. Create your group and add expenses on one phone.
2. Open Settings and tap Share via QR.
3. On the other phone, open Settings and tap Scan QR.
4. The app imports and merges the shared data so balances are recalculated.

If QR sharing is too large for one code, use the JSON export/import flow instead.

## Run locally

```bash
npm install
npm run dev
```

## Build for production

```bash
npm run build
```

The generated dist/ folder is a static, installable PWA. It can be deployed to
any static host, or wrapped into an Android APK later.

## Notes

- The app is designed to work offline first and use QR-based sharing as a
  practical fallback for nearby-device sync.
- Camera access is required for built-in QR scanning on supported devices.
- Notification permissions are optional and can be enabled from Settings.
