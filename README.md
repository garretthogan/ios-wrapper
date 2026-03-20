# iOS Edge-to-Edge Web Shell

This repository now contains a minimal iOS app shell that wraps a `WKWebView` and renders your web app edge-to-edge on supported devices.

## What is configured

- SwiftUI app shell with a full-screen `WKWebView`
- Safe-area inset auto-adjustment disabled in the web view scroll container
- `viewport-fit=cover` injected so the page can fill into notches/home-indicator regions
- URL loaded from app Info key `WebShellURL`

## Configure the wrapped site

Update `WebShellURL` in the target build settings in Xcode (or edit `INFOPLIST_KEY_WebShellURL` in `WebShell.xcodeproj/project.pbxproj`).

Default value:

- `http://localhost:5173`

## Run

1. Open `WebShell.xcodeproj` in Xcode.
2. Select the `WebShell` scheme.
3. Run on an iPhone simulator or device.

## Notes

- The host page should still handle safe-area CSS with `env(safe-area-inset-*)` if it needs content padding around cutouts.
- Links that request a new window are loaded in the same web view.

## Publish to GitHub

Run these commands from the project root after creating an empty GitHub repository:

```bash
git add .
git commit -m "Initial iOS edge-to-edge web shell"
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```
