# Phase 2.1: Engagement Features Implementation Guide

## 📋 Overview

Phase 2.1 adds critical engagement tracking features to UNP Art Space, focusing on High Impact, Low Effort improvements that enhance user interaction analytics and community building.

**Implementation Date**: December 2024
**Status**: ✅ Artwork View Counter (Completed) | ⏳ Artist Follow System (Pending) | ⏳ Share Enhancement (Pending)

## 🎯 Features Implemented

### 1. ⭐ Artwork View Counter (COMPLETED)

**Purpose**: Track and display artwork views for better engagement analytics.

**Database Changes**:
```sql
-- Add views_count column to artworks table
ALTER TABLE artworks ADD COLUMN views_count bigint DEFAULT 0 NOT NULL;

-- Create index for performance
CREATE INDEX idx_artworks_views_count ON artworks(views_count DESC);
```

**Implementation Details**:

#### State Variables (Line 47-48):
```dart
int _viewCount = 0;
int _shareCount = 0;
```

#### View Tracking Method (Line 440-468):
```dart
Future<void> _incrementViewCount() async {
  try {
    if (_artwork?.id == null) return;

    // Fetch current view count
    final response = await Supabase.instance.client
        .from('artworks')
        .select('views_count')
        .eq('id', _artwork!.id)
        .single();

    final currentCount = response['views_count'] as int? ?? 0;
    final newCount = currentCount + 1;

    // Update view count in database
    await Supabase.instance.client
        .from('artworks')
        .update({'views_count': newCount})
        .eq('id', _artwork!.id);

    // Update local state
    if (mounted) {
      setState(() {
        _viewCount = newCount;
      });
    }
  } catch (e) {
    // Silently fail - view counting is not critical
    debugPrint('Error incrementing view count: $e');
  }
}
```

#### Load View/Share Counts (Line 470-490):
```dart
Future<void> _loadViewCount() async {
  try {
    if (_artwork?.id == null) return;

    final response = await Supabase.instance.client
        .from('artworks')
        .select('views_count, shares_count')
        .eq('id', _artwork!.id)
        .single();

    if (mounted) {
      setState(() {
        _viewCount = response['views_count'] as int? ?? 0;
        _shareCount = response['shares_count'] as int? ?? 0;
      });
    }
  } catch (e) {
    debugPrint('Error loading view count: $e');
  }
}
```

#### UI Implementation (Line 520-583):

**3 Mini Stat Cards Row**:
```dart
// Statistics Section - 3 Mini Cards
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    children: [
      // Likes Card (Pink Gradient)
      Expanded(
        child: _buildStatMiniCard(
          icon: Icons.favorite_rounded,
          count: _likeCount,
          label: 'Likes',
          gradient: const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Views Card (Blue Gradient)
      Expanded(
        child: _buildStatMiniCard(
          icon: Icons.visibility_rounded,
          count: _viewCount,
          label: 'Views',
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Shares Card (Green Gradient)
      Expanded(
        child: _buildStatMiniCard(
          icon: Icons.share_rounded,
          count: _shareCount,
          label: 'Shares',
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF34D399)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    ],
  ),
),
```

**Widget Builder Method** (Line 1077-1139):
```dart
Widget _buildStatMiniCard({
  required IconData icon,
  required int count,
  required String label,
  required Gradient gradient,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient Icon Container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            // Count Display
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            // Label
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

#### Share Counter Integration (Line 1766-1779):
```dart
Future<void> _shareArtwork(String title, String imageUrl) async {
  // Increment share count
  await _incrementShareCount();
  
  final shareText = '''
🎨 $title

Lihat karya seni ini di UNP Art Space!

#UNPArtSpace #KaryaSeni
  ''';

  Share.share(shareText, subject: title);
}
```

**Design Pattern**:
- Glass morphism cards with blur effect
- Color-coded gradients (Pink=Likes, Blue=Views, Green=Shares)
- Compact layout with icon + count + label
- Consistent border radius (12px) and spacing
- Responsive design with Expanded widgets

**User Flow**:
1. User opens artwork detail page
2. View counter automatically increments (line 89)
3. UI displays 3 mini stat cards: Likes, Views, Shares
4. Share button click increments share counter
5. Analytics dashboard can query these metrics

---

### 2. ⭐ Artist Follow System (PENDING)

**Purpose**: Enable users to follow their favorite artists and build community.

**Database Schema**:
```sql
-- Create artist_follows table
CREATE TABLE artist_follows (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  artist_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(follower_id, artist_id),
  CHECK (follower_id != artist_id)
);

-- Create indexes
CREATE INDEX idx_artist_follows_follower ON artist_follows(follower_id);
CREATE INDEX idx_artist_follows_artist ON artist_follows(artist_id);
CREATE INDEX idx_artist_follows_created_at ON artist_follows(created_at DESC);

-- RLS Policies
ALTER TABLE artist_follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view follows"
  ON artist_follows FOR SELECT
  USING (true);

CREATE POLICY "Users can follow artists"
  ON artist_follows FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow artists"
  ON artist_follows FOR DELETE
  USING (auth.uid() = follower_id);
```

**Helper Functions**:
```sql
-- Get follower count for an artist
CREATE OR REPLACE FUNCTION get_follower_count(artist_id uuid)
RETURNS bigint AS $$
  SELECT COUNT(*)::bigint
  FROM artist_follows
  WHERE artist_id = $1;
$$ LANGUAGE sql STABLE;

-- Get following count for a user
CREATE OR REPLACE FUNCTION get_following_count(user_id uuid)
RETURNS bigint AS $$
  SELECT COUNT(*)::bigint
  FROM artist_follows
  WHERE follower_id = $1;
$$ LANGUAGE sql STABLE;

-- Check if user is following an artist
CREATE OR REPLACE FUNCTION is_following(follower_id uuid, artist_id uuid)
RETURNS boolean AS $$
  SELECT EXISTS(
    SELECT 1
    FROM artist_follows
    WHERE follower_id = $1 AND artist_id = $2
  );
$$ LANGUAGE sql STABLE;
```

**Implementation Plan**:

1. **Follow Button Widget** (artwork_detail_page.dart):
```dart
// Add state variable
bool _isFollowing = false;

// Check follow status
Future<void> _checkFollowStatus() async {
  final response = await Supabase.instance.client
    .rpc('is_following', params: {
      'follower_id': userId,
      'artist_id': artistId,
    });
  setState(() => _isFollowing = response as bool);
}

// Toggle follow
Future<void> _toggleFollow() async {
  if (_isFollowing) {
    await Supabase.instance.client
      .from('artist_follows')
      .delete()
      .match({'follower_id': userId, 'artist_id': artistId});
  } else {
    await Supabase.instance.client
      .from('artist_follows')
      .insert({
        'follower_id': userId,
        'artist_id': artistId,
      });
  }
  setState(() => _isFollowing = !_isFollowing);
}

// UI Button
ElevatedButton.icon(
  onPressed: _toggleFollow,
  icon: Icon(_isFollowing ? Icons.check : Icons.person_add),
  label: Text(_isFollowing ? 'Following' : 'Follow'),
  style: ElevatedButton.styleFrom(
    backgroundColor: _isFollowing ? Colors.grey : Color(0xFF8B5CF6),
  ),
)
```

2. **Enhanced Artist Profile Integration**:
- Display follower count in profile header
- Show following count in user stats
- Add "Following Artists" page to view followed artists
- Filter artworks from followed artists

3. **UI Locations**:
- Artwork detail page (below artist name)
- Enhanced artist profile page (header button)
- Search results (inline follow button)
- Comments section (follow from comment list)

---

### 3. ⭐ Share Enhancement (PENDING)

**Purpose**: Improve sharing with QR codes and better tracking.

**Database Changes**:
```sql
-- Add shares_count column (already added with views_count)
ALTER TABLE artworks ADD COLUMN shares_count bigint DEFAULT 0 NOT NULL;
```

**Implementation Plan**:

1. **QR Code Generation**:
```dart
// Dependencies: qr_flutter package
import 'package:qr_flutter/qr_flutter.dart';

// Generate QR Code for artwork URL
String getArtworkUrl(String artworkId) {
  return 'https://unp-art-space.vercel.app/artwork/$artworkId';
}

// QR Code Dialog
void _showQRCodeDialog() {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scan to View Artwork', style: titleStyle),
            SizedBox(height: 20),
            QrImageView(
              data: getArtworkUrl(widget.artworkId),
              version: QrVersions.auto,
              size: 250,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _downloadQRCode,
              child: Text('Download QR Code'),
            ),
          ],
        ),
      ),
    ),
  );
}
```

2. **Enhanced Share Menu**:
```dart
// Share options menu
void _showShareMenu() {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.link),
            title: Text('Copy Link'),
            onTap: _copyLink,
          ),
          ListTile(
            leading: Icon(Icons.qr_code),
            title: Text('Show QR Code'),
            onTap: _showQRCodeDialog,
          ),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Share via...'),
            onTap: () => _shareArtwork(title, imageUrl),
          ),
        ],
      ),
    ),
  );
}
```

3. **Share Counter** (already implemented):
- Increment share count on any share action
- Display in mini stat card
- Track share analytics in organizer dashboard

---

## 📁 File Structure

```
lib/app/Features/artwork/screens/
  └── artwork_detail_page.dart          # View counter + Share counter
  
lib/app/Features/profile/screens/
  └── enhanced_artist_profile_page.dart # Follow system integration (pending)
  
supabase_phase2_engagement_features.sql # Database migration
```

## 🗄️ Database Schema

### Tables Created:
1. **artist_follows**
   - id (uuid, PK)
   - follower_id (uuid, FK → profiles.id)
   - artist_id (uuid, FK → profiles.id)
   - created_at (timestamp)

### Columns Added:
1. **artworks.views_count** (bigint, default 0)
2. **artworks.shares_count** (bigint, default 0)

### Indexes Created:
- idx_artist_follows_follower
- idx_artist_follows_artist
- idx_artist_follows_created_at
- idx_artworks_views_count
- idx_artworks_shares_count

### Functions Created:
- get_follower_count(artist_id)
- get_following_count(user_id)
- is_following(follower_id, artist_id)

## 🚀 Deployment Steps

### 1. Database Migration
```bash
# Run in Supabase SQL Editor
# Execute: supabase_phase2_engagement_features.sql
```

### 2. Build & Deploy
```bash
# Build production
flutter build web --release

# Deploy via script
.\deploy.ps1

# Commit changes
git add .
git commit -m "feat(phase2.1): implement engagement features (view counter, follow system, share enhancement)"
git push origin main
```

## ✅ Testing Checklist

### Artwork View Counter:
- [ ] View count increments on page load
- [ ] View count displays correctly in UI
- [ ] View count persists in database
- [ ] Works for both guest and logged-in users
- [ ] Analytics dashboard shows view metrics
- [ ] Share counter increments on share action
- [ ] Share count displays in UI

### Artist Follow System (Pending):
- [ ] Follow button toggles correctly
- [ ] Follow status persists after page refresh
- [ ] Follower count displays accurately
- [ ] Following count shows in user profile
- [ ] Can't follow yourself
- [ ] Unfollow works correctly
- [ ] "Following Artists" page loads correctly

### Share Enhancement (Pending):
- [ ] QR code generates correctly
- [ ] QR code can be downloaded
- [ ] Copy link works
- [ ] Share menu displays all options
- [ ] Share counter increments on all actions
- [ ] QR code scans to correct URL

## 📊 Analytics Integration

### New Metrics Available:
1. **Views per Artwork**: `artworks.views_count`
2. **Shares per Artwork**: `artworks.shares_count`
3. **Follower Count**: `get_follower_count(artist_id)`
4. **Following Count**: `get_following_count(user_id)`
5. **Total Platform Views**: `SUM(artworks.views_count)`

### Dashboard Queries:
```sql
-- Most viewed artworks
SELECT title, views_count 
FROM artworks 
ORDER BY views_count DESC 
LIMIT 10;

-- Most followed artists
SELECT p.full_name, get_follower_count(p.id) as followers
FROM profiles p
ORDER BY followers DESC
LIMIT 10;

-- Engagement rate (likes + views + shares)
SELECT 
  title,
  (likes_count + views_count + shares_count) as total_engagement
FROM artworks
ORDER BY total_engagement DESC;
```

## 🎨 Design System

### Color Scheme:
- **Likes**: Pink gradient (#EC4899 → #F472B6)
- **Views**: Blue gradient (#3B82F6 → #60A5FA)
- **Shares**: Green gradient (#10B981 → #34D399)
- **Follow**: Purple (#8B5CF6)

### Glass Morphism Pattern:
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      // ... content
    ),
  ),
)
```

## 🔐 Security Considerations

### RLS Policies:
- ✅ Anyone can view artwork stats (public data)
- ✅ Only authenticated users can follow/unfollow
- ✅ Users can only manage their own follows
- ✅ Can't follow yourself (CHECK constraint)
- ✅ View/share counts can be incremented by anyone

### Data Validation:
- Follower ID must match authenticated user
- Artist ID must exist in profiles table
- View/share counts are non-negative integers
- Unique constraint on (follower_id, artist_id)

## 📈 Performance Optimizations

1. **Database Indexes**:
   - Fast lookup of followers by artist_id
   - Fast lookup of following by follower_id
   - Efficient sorting by view count

2. **Caching Strategy**:
   - View counts loaded once on page load
   - Follow status cached in local state
   - Follower counts cached in profile page

3. **Silent Failures**:
   - View counter fails silently (non-critical)
   - Error messages logged but not shown to user
   - Graceful degradation for offline mode

## 🔮 Future Enhancements (Phase 2.2+)

1. **Trending Algorithm**:
   - Weight recent views higher than old views
   - Factor in likes, shares, comments
   - Time-decay function for trending score

2. **Follow Feed**:
   - Chronological feed of followed artists' artworks
   - Push notifications for new uploads
   - Weekly digest emails

3. **Advanced Analytics**:
   - View duration tracking
   - Click-through rates
   - Geographic data
   - Device/platform breakdown

4. **Social Sharing**:
   - Direct sharing to Instagram, WhatsApp
   - Share templates with artwork preview
   - Track share conversion rates

## 📝 Notes

- View counter increments on every page load (may include duplicates)
- Consider implementing IP-based deduplication in future
- Share counter only tracks in-app shares (not external)
- Follow system requires authentication (guest users can't follow)
- QR codes use dynamic URLs for better tracking

## 🐛 Known Issues

None currently. Report issues to development team.

## 📚 Related Documentation

- [Phase 1 Implementation Guide](PHASE1_IMPLEMENTATION_GUIDE.md)
- [Custom Network Image Guide](CUSTOM_NETWORK_IMAGE_GUIDE.md)
- [Supabase Storage Setup](SUPABASE_STORAGE_SETUP.md)

---

**Last Updated**: December 2024
**Author**: Development Team
**Status**: Phase 2.1 - Artwork View Counter ✅ Complete | Artist Follow & Share Enhancement ⏳ Pending
