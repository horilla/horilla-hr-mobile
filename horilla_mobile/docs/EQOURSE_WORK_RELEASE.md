# eQOURSE Work Android handoff

## Identity and server

- Android application ID: `com.eqourse.work`
- API host: `https://work.eqourse.com`
- Google sign-in accepts only active employee accounts whose verified email ends in `@eqourse.com`.
- The server OAuth setting `GOOGLE_ANDROID_CLIENT_ID` must be the Android client ID configured for this package and release certificate. The mobile app does not contain a client secret.

The release certificate fingerprint is intentionally not committed or guessed. Bhavesh should generate it from the private release keystore and register it in Google Cloud before pilot testing:

```powershell
keytool -list -v -keystore <private-release-keystore> -alias <release-alias>
```

Keep the keystore and passwords outside GitHub. Use the same keystore for every future update; changing it prevents Android updates from installing over the pilot build.

## Attendance contract

Every check-in and check-out collects:

- a fresh high-accuracy GPS fix;
- reported GPS accuracy and location timestamp;
- a confirmed front-camera JPEG containing exactly one detected face.

The app sends these fields as multipart data to the existing `/api/v1/attendance/clock-in/` or `/api/v1/attendance/clock-out/` route. The server compares the live image with the approved employee photo and applies the office/WFH policy. The app never treats a client-side face result as identity proof.

## Release gate

Do not make this build mandatory until Bhavesh and Kartik have tested on their phones at the office entrance and usual indoor punch spot. Record check-in and check-out results for inside/outside radius, denied camera/location permissions, weak GPS, wrong face, printed photo, and photo shown on another phone. If either photo spoof is accepted by server matching, add an explicit liveness challenge before employee rollout.

Build only after the private signing configuration is supplied:

```powershell
flutter pub get
flutter build apk --release
```

The signed APK must be hosted over HTTPS by Bhavesh. AWS, production deployment, OAuth client setup, and release signing remain with Bhavesh.
