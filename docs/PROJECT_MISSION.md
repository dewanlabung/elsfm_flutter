# ELSFM Project Mission & Vision

## 🎯 Mission

Build a **lightweight, fast, and secure** music streaming platform that combines the best features of Spotify and Apple Music with a focus on reliability and performance — inspired by Facebook Lite's efficiency principles.

## 🏆 Core Features

### Frontend (Flutter Mobile App)
- **Spotify-inspired** playback UI with Material Design 3
- **Apple Music-style** personalization and curation
- **Lightweight** native app (minimal APK size)
- **Fast response** times (<100ms interactions)
- **Offline-ready** with service worker caching
- **Multi-platform** (Android, iOS, Web)

### Backend (BeMusic Laravel API)
- **RESTful API** powering all frontend clients
- **Secure authentication** with encrypted credentials
- **Real-time** playback sync across devices
- **Efficient data** transfer and caching
- **Production-grade** reliability and uptime

### Web (ELSFM.com)
- **Responsive** design (mobile-first)
- **Fast loading** (<1.5s FCP, <2.5s LCP)
- **Accessible** (WCAG 2.2 compliant)
- **PWA-ready** for offline support

## 🔐 Security Standards

- ✅ End-to-end encrypted credential storage
- ✅ OAuth 2.0 + PKCE authentication flow
- ✅ Biometric authentication (fingerprint, face unlock)
- ✅ Rate-limited API endpoints
- ✅ HTTPS-only communication
- ✅ Secure session management
- ✅ Automatic token refresh

## ⚡ Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| App Launch | <2s | 🔄 In Progress |
| Track Load | <500ms | ✅ Achieved |
| API Response | <100ms p95 | ✅ Achieved |
| APK Size | <100MB | 🔄 Optimizing |
| Bundle Size | <150KB gzip | ✅ Achieved |

## 💾 Data Storage

### Encrypted Local Storage
- **flutter_secure_storage**: OS-level encryption for credentials
- **Hive**: Fast local database for offline playlists
- **Shared Preferences**: Non-sensitive app settings

### API Authentication
- **Bearer Token**: JWT tokens with 1-hour expiry
- **Refresh Token**: 30-day rotation
- **Device ID**: Unique per installation
- **Session ID**: Per-login tracking

## 🧪 Testing Credentials

**DO NOT SHARE PUBLICLY**

Test Account (Encrypted Storage):
- Email: `test.elsfm@gmail.com`
- Password: Encrypted via flutter_secure_storage + AES-256

Auto-login flow:
1. App detects dev/test environment
2. Retrieves encrypted credentials from secure storage
3. Decrypts using device-specific key
4. Authenticates silently on startup
5. Restores previous session state

## 🚀 Release Roadmap

### Phase 1: MVP (June 2026) ✅
- [x] Dev-mode auto-login
- [x] Material 3 UI
- [x] Basic playback controls
- [x] Google Sign-In integration
- [x] Biometric authentication

### Phase 2: Feature Expansion (July 2026) 🔄
- [ ] Playlist management
- [ ] Search & discovery
- [ ] User profiles
- [ ] Offline sync
- [ ] Equalizer & audio effects

### Phase 3: Production (August 2026) ⏳
- [ ] Play Store release
- [ ] App Store submission
- [ ] Beta testing program
- [ ] Analytics & monitoring
- [ ] 24/7 support

## 📊 Success Metrics

- **User Retention**: >60% DAU after 30 days
- **App Rating**: 4.5+ stars on both stores
- **Performance**: All CWV metrics green
- **Reliability**: 99.9% API uptime
- **Security**: 0 data breaches

## 🎨 Design Philosophy

**"Speed + Security + Simplicity"**

Every feature must:
1. Load fast (no unnecessary delays)
2. Secure sensitive data (zero shortcuts on auth)
3. Stay simple (intuitive for first-time users)

Like Facebook Lite: powerful core features, zero bloat.

---

**Last Updated:** June 28, 2026  
**Owner:** ELSFM Development Team  
**Status:** 🔄 Active Development
