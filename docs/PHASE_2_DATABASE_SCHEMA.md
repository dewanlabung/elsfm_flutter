# Phase 2 Database Schema

**Backend:** BeMusic (Laravel) - www.elsfm.com/api/v1

## Schema Overview

### Core Tables

#### `users` (EXISTING)
User accounts with authentication
```sql
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  avatar_url VARCHAR(512),
  subscription_tier VARCHAR(50), -- 'free', 'premium'
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

---

### Phase 2: Search & Discovery

#### `playlists`
User-created and curated playlists
```sql
CREATE TABLE playlists (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  artwork_url VARCHAR(512),
  is_collaborative BOOLEAN DEFAULT FALSE,
  is_deleted BOOLEAN DEFAULT FALSE, -- soft delete
  version INT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_playlists (user_id),
  INDEX idx_user_active_playlists (user_id, is_deleted)
);
```

#### `playlist_songs`
Songs in playlists with order tracking
```sql
CREATE TABLE playlist_songs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  playlist_id INT NOT NULL,
  track_id INT NOT NULL,
  position INT NOT NULL, -- order in playlist
  added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY unique_playlist_track (playlist_id, track_id),
  FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
  INDEX idx_playlist_songs (playlist_id, position)
);
```

---

### Phase 2: User Library

#### `user_favorites`
Liked songs (favorites)
```sql
CREATE TABLE user_favorites (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  track_id INT NOT NULL,
  liked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY unique_user_track_favorite (user_id, track_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_favorites (user_id),
  INDEX idx_user_favorite_tracks (user_id, liked_at)
);
```

#### `user_history`
Play history tracking
```sql
CREATE TABLE user_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  track_id INT NOT NULL,
  played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  duration_played_seconds INT,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_history (user_id, played_at DESC),
  INDEX idx_user_history_recent (user_id, played_at DESC)
);

-- Cleanup: Keep only last 1000 plays per user
CREATE EVENT cleanup_old_history
ON SCHEDULE EVERY 1 DAY
DO
  DELETE FROM user_history WHERE (user_id, id) NOT IN (
    SELECT user_id, id FROM (
      SELECT user_id, id FROM user_history 
      ORDER BY user_id, played_at DESC 
      LIMIT 1000
    ) t
  );
```

---

### Phase 2: Audio Quality & Offline

#### `audio_qualities`
Available quality options
```sql
CREATE TABLE audio_qualities (
  id VARCHAR(50) PRIMARY KEY, -- '128', '320', 'lossless'
  label VARCHAR(100) NOT NULL,
  bitrate INT NOT NULL, -- kbps
  format VARCHAR(50), -- 'AAC', 'MP3', 'FLAC'
  
  UNIQUE KEY unique_bitrate_format (bitrate, format),
  INDEX idx_bitrate (bitrate)
);

INSERT INTO audio_qualities VALUES
('128', 'Low', 128, 'AAC'),
('320', 'High', 320, 'AAC'),
('lossless', 'Lossless', NULL, 'FLAC');
```

#### `user_quality_preferences`
User's preferred audio quality
```sql
CREATE TABLE user_quality_preferences (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNIQUE NOT NULL,
  preferred_quality VARCHAR(50) NOT NULL DEFAULT '320',
  updated_at TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (preferred_quality) REFERENCES audio_qualities(id)
);
```

#### `downloads`
Offline download tracking
```sql
CREATE TABLE downloads (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  track_id INT NOT NULL,
  quality_id VARCHAR(50) NOT NULL,
  file_size_bytes BIGINT,
  file_hash VARCHAR(64), -- SHA-256 for verification
  is_deleted BOOLEAN DEFAULT FALSE, -- soft delete
  expires_at TIMESTAMP, -- license expiry
  downloaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE KEY unique_user_track_quality (user_id, track_id, quality_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (quality_id) REFERENCES audio_qualities(id),
  INDEX idx_user_downloads (user_id),
  INDEX idx_user_active_downloads (user_id, is_deleted),
  INDEX idx_expired_downloads (expires_at)
);
```

---

### Phase 2: Recommendations

#### `recommendations`
Curated playlists
```sql
CREATE TABLE recommendations (
  id VARCHAR(100) PRIMARY KEY, -- 'release_radar', 'discover_weekly', etc.
  user_id INT,
  type VARCHAR(100) NOT NULL, -- 'release_radar', 'discover_weekly', 'top_hits', etc.
  title VARCHAR(255) NOT NULL,
  description TEXT,
  artwork_url VARCHAR(512),
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  refreshed_at TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_type (type),
  INDEX idx_user_recommendations (user_id),
  INDEX idx_refreshed_at (refreshed_at)
);
```

#### `recommendation_songs`
Songs in recommendations
```sql
CREATE TABLE recommendation_songs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  recommendation_id VARCHAR(100) NOT NULL,
  track_id INT NOT NULL,
  position INT,
  
  FOREIGN KEY (recommendation_id) REFERENCES recommendations(id) ON DELETE CASCADE,
  INDEX idx_recommendation_songs (recommendation_id)
);
```

#### `user_recommendation_interactions`
Track user interactions with recommendations
```sql
CREATE TABLE user_recommendation_interactions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  recommendation_id VARCHAR(100) NOT NULL,
  interaction_type VARCHAR(50), -- 'view', 'skip', 'save', 'share'
  interacted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (recommendation_id) REFERENCES recommendations(id) ON DELETE CASCADE,
  INDEX idx_user_interactions (user_id, interacted_at)
);
```

---

## Security & Privacy

### User Isolation
- All tables use `user_id` foreign key
- Queries ALWAYS filter by `user_id` to prevent cross-user data access
- Soft deletes (`is_deleted`) preserve data for recovery

### Data Encryption
- Sensitive data encrypted at application layer (TLS in transit)
- Database connections use SSL/TLS
- Credentials stored in secure_storage app-side (never sent to API)

### Audit Trail
- All writes logged with `created_at` and `updated_at`
- Version tracking for playlists
- Interaction tracking for recommendations

### Privacy Controls
- User can delete history, playlists, favorites (soft delete)
- User can clear all history with single call
- Anonymous mode available (no tracking)

---

## Performance Optimization

### Indexes
- User-scoped queries: `(user_id, created_at DESC)`
- Soft deletes: `(user_id, is_deleted)` composite index
- Pagination: `created_at` for cursor-based pagination
- Trending: `(type, created_at DESC)`

### Query Patterns
- Top 100 history: `user_id DESC LIMIT 100`
- User playlists: `user_id, is_deleted = FALSE`
- Recent favorites: `user_id ORDER BY liked_at DESC LIMIT 50`
- Active downloads: `user_id, is_deleted = FALSE`

### Caching Strategy
- User library cached 5 minutes (favorites, history)
- Recommendations cached 1 hour (regenerated weekly)
- Quality options cached 24 hours (static)
- Downloads status cached 10 minutes (changes frequently)

---

## Migration Path

### When to Deploy
1. Phase 2.1 (Search): playlists, playlist_songs
2. Phase 2.2 (Library): user_favorites, user_history
3. Phase 2.3 (Quality): audio_qualities, user_quality_preferences
4. Phase 2.4 (Offline): downloads
5. Phase 2.5 (Recommendations): recommendations, recommendation_songs

### Backward Compatibility
- All Phase 2 tables are NEW (no migrations needed for Phase 1)
- Phase 1 tables (users, tracks, artists, albums, channels) remain UNCHANGED
- No breaking changes to existing API endpoints

---

## Testing Gates

- [ ] All tables created successfully
- [ ] Foreign keys enforced
- [ ] Indexes created for performance
- [ ] User isolation verified
- [ ] Soft delete recovery tested
- [ ] Version tracking tested
- [ ] No data leaks between users
- [ ] Query performance < 100ms for typical operations
- [ ] Pagination working correctly
- [ ] Caching strategy verified

---

## Deployment Checklist

- [ ] Database backup created
- [ ] Migration scripts tested on staging
- [ ] Rollback plan documented
- [ ] Monitoring alerts configured
- [ ] Performance baselines recorded
- [ ] Security scan completed
- [ ] Data privacy verified
- [ ] User isolation tested end-to-end
- [ ] Rate limiting configured
- [ ] Audit logging enabled
