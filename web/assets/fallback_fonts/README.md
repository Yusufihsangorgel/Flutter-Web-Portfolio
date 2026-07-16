# Flutter engine fallback fonts

These WOFF2 files mirror the fallback URLs used by the pinned Flutter 3.44
web engine so the renderer does not contact `fonts.gstatic.com` for Roboto or
emoji glyphs.

- Roboto: Google Fonts, Apache License 2.0.
- Noto Color Emoji: Google Fonts, SIL Open Font License 1.1.

The files are served only from this application's same-origin fallback path.
