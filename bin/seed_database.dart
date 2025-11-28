import 'dart:math';
import 'package:supabase/supabase.dart';
import 'package:faker/faker.dart';

// ========================================
// KONFIGURASI SUPABASE
// ========================================
const String SUPABASE_URL = 'https://vepmvxiddwmpetxfdwjn.supabase.co';
const String SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZlcG12eGlkZHdtcGV0eGZkd2puIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQyMzkyMCwiZXhwIjoyMDc0OTk5OTIwfQ.lTBWwtQ97jUFZ-OG2f0SfPr-ptoXy-fMWjvX6JxRdyw'; // Ganti dengan Service Role Key

// ========================================
// MAIN FUNCTION
// ========================================
void main() async {
  print('🚀 Starting Database Seeding...\n');

  final supabase = SupabaseClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  final seeder = DatabaseSeeder(supabase);

  try {
    await seeder.runFullSeed();
    print('\n✅ Database seeding completed successfully!');
  } catch (e, stackTrace) {
    print('\n❌ Error during seeding: $e');
    print('Stack trace: $stackTrace');
  }
}

// ========================================
// DATABASE SEEDER CLASS
// ========================================
class DatabaseSeeder {
  final SupabaseClient supabase;
  final Faker faker = Faker();
  final Random random = Random();

  // Store created user IDs
  late String adminId;
  late String organizerId;
  late String artistId;
  late String viewerId;

  // Store created content IDs
  List<String> eventIds = [];
  List<int> artworkIds = [];
  List<int> approvedArtworkIds = [];

  DatabaseSeeder(this.supabase);

  // ========================================
  // MAIN SEED FLOW
  // ========================================
  Future<void> runFullSeed() async {
    await cleanup();
    await seedUsers();
    await seedContent();
    await adminVerification();
    await seedInteractions();
  }

  // ========================================
  // 1. CLEANUP - Delete old data
  // ========================================
  Future<void> cleanup() async {
    print('🧹 Step 1: Cleaning up old data...');

    try {
      // Delete in correct order (child tables first)
      print('  - Deleting event_submissions...');
      await supabase.from('event_submissions').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      print('  - Deleting comments...');
      await supabase.from('comments').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      print('  - Deleting likes...');
      await supabase.from('likes').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      print('  - Deleting artist_follows...');
      await supabase.from('artist_follows').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      print('  - Deleting artworks...');
      await supabase.from('artworks').delete().neq('id', 0);

      print('  - Deleting events...');
      await supabase.from('events').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      print('  - Deleting users...');
      await supabase.from('users').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      print('  - Deleting profiles...');
      await supabase.from('profiles').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      // Delete auth users for test accounts
      print('  - Deleting auth users...');
      await _deleteAuthUsers();

      print('✅ Cleanup completed!\n');
    } catch (e) {
      print('⚠️  Warning during cleanup: $e\n');
    }
  }

  // Delete auth users by email
  Future<void> _deleteAuthUsers() async {
    final testEmails = [
      'admin@campus.art',
      'organizer@campus.art',
      'artist@campus.art',
      'viewer@campus.art',
    ];

    for (final email in testEmails) {
      try {
        // Get user by email
        final users = await supabase.auth.admin.listUsers();
        final user = users.firstWhere(
          (u) => u.email == email,
          orElse: () => throw Exception('User not found'),
        );
        
        // Delete user
        await supabase.auth.admin.deleteUser(user.id);
        print('    ✓ Deleted auth user: $email');
      } catch (e) {
        // User doesn't exist, skip
        print('    - Auth user not found: $email (skipped)');
      }
    }
  }

  // ========================================
  // 2. SEED USERS - Create 4 main actors
  // ========================================
  Future<void> seedUsers() async {
    print('👥 Step 2: Creating users...');

    // Create Admin
    adminId = await createUser(
      email: 'admin@campus.art',
      password: 'admin123',
      role: 'admin',
      name: 'Admin Campus',
      bio: 'Platform administrator',
    );
    print('  ✓ Admin created: admin@campus.art');

    // Create Organizer
    organizerId = await createUser(
      email: 'organizer@campus.art',
      password: 'organizer123',
      role: 'organizer',
      name: 'Event Organizer',
      bio: 'Professional event organizer specializing in art exhibitions',
      specialization: 'Event Management',
    );
    print('  ✓ Organizer created: organizer@campus.art');

    // Create Artist
    artistId = await createUser(
      email: 'artist@campus.art',
      password: 'artist123',
      role: 'artist',
      name: faker.person.name(),
      bio: 'Digital artist and painter',
      specialization: 'Digital Art, Painting',
    );
    print('  ✓ Artist created: artist@campus.art');

    // Create Viewer
    viewerId = await createUser(
      email: 'viewer@campus.art',
      password: 'viewer123',
      role: 'viewer',
      name: faker.person.name(),
      bio: 'Art enthusiast and collector',
    );
    print('  ✓ Viewer created: viewer@campus.art');

    print('✅ Users created successfully!\n');
  }

  // Helper function to create user
  Future<String> createUser({
    required String email,
    required String password,
    required String role,
    required String name,
    String? bio,
    String? specialization,
  }) async {
    try {
      // Create auth user
      final response = await supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true, // Auto-confirm email
        ),
      );

      final userId = response.user!.id;

    // Insert into profiles
    await supabase.from('profiles').insert({
      'id': userId,
      'role': role,
      'username': email.split('@')[0],
    });

      // Insert into users (extended profile)
      await supabase.from('users').insert({
        'id': userId,
        'name': name,
        'email': email,
        'role': role,
        'bio': bio,
        'specialization': specialization,
        'social_media': {
          'instagram': '@${email.split('@')[0]}',
          'twitter': '@${email.split('@')[0]}',
        },
        'profile_image_url': 'https://i.pravatar.cc/300?u=$userId',
      });

      return userId;
    } catch (e) {
      print('    ⚠️  Error creating user $email: $e');
      rethrow;
    }
  }

  // ========================================
  // 3. GENERATE CONTENT - Events & Artworks
  // ========================================
  Future<void> seedContent() async {
    print('🎨 Step 3: Creating content...');

    // Create Events by Organizer
    await createEvents();

    // Create Artworks by Artist
    await createArtworks();

    print('✅ Content created successfully!\n');
  }

  Future<void> createEvents() async {
    print('  📅 Creating events...');

    final eventTitles = [
      'Campus Art Exhibition 2025',
      'Digital Art Showcase',
      'Contemporary Art Fair',
    ];

    for (var i = 0; i < 3; i++) {
      final response = await supabase.from('events').insert({
        'title': eventTitles[i],
        'content': faker.lorem.sentences(3).join(' '),
        'event_date': DateTime.now().add(Duration(days: 30 + (i * 15))).toIso8601String(),
        'location': faker.address.city(),
        'image_url': 'https://picsum.photos/seed/event$i/800/600',
        'status': 'approved', // Changed from 'open' to 'approved' so events appear in home page
        'organizer_id': organizerId,
      }).select('id').single();

      eventIds.add(response['id'] as String);
      print('    ✓ Event created: ${eventTitles[i]}');
    }
  }

  Future<void> createArtworks() async {
    print('  🖼️  Creating artworks...');

    final categories = ['Digital Art', 'Painting', 'Photography', 'Sculpture', 'Mixed Media'];
    final artworkTypes = ['image', 'video'];

    for (var i = 0; i < 10; i++) {
      final isVideo = random.nextBool() && i < 2; // Only 2 videos
      final artworkType = isVideo ? 'video' : 'image';

      final response = await supabase.from('artworks').insert({
        'title': '${faker.lorem.words(2).join(' ').capitalize()} ${i + 1}',
        'description': faker.lorem.sentences(2).join(' '),
        'media_url': isVideo
            ? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
            : 'https://picsum.photos/seed/artwork$i/1200/800',
        'thumbnail_url': 'https://picsum.photos/seed/thumb$i/400/300',
        'category': categories[random.nextInt(categories.length)],
        'status': 'pending', // IMPORTANT: Start as pending
        'artist_id': artistId,
        'artist_name': 'Campus Artist',
        'artwork_type': artworkType,
        'likes_count': 0,
        'views_count': random.nextInt(100),
        'shares_count': 0,
      }).select('id').single();

      artworkIds.add(response['id'] as int);
    }

    print('    ✓ Created ${artworkIds.length} artworks (all pending approval)');
  }

  // ========================================
  // 4. ADMIN VERIFICATION - Approve artworks
  // ========================================
  Future<void> adminVerification() async {
    print('🛡️  Step 4: Admin verification process...');

    // Approve 7 out of 10 artworks
    final artworksToApprove = artworkIds.take(7).toList();
    approvedArtworkIds = artworksToApprove;

    for (var artworkId in artworksToApprove) {
      await supabase.from('artworks').update({
        'status': 'approved',
      }).eq('id', artworkId);
    }

    print('  ✓ Approved ${artworksToApprove.length} artworks');
    print('  ✓ ${artworkIds.length - artworksToApprove.length} artworks remain pending');
    print('✅ Admin verification completed!\n');
  }

  // ========================================
  // 5. SEED INTERACTIONS - Likes, Comments, Submissions
  // ========================================
  Future<void> seedInteractions() async {
    print('💬 Step 5: Creating interactions...');

    // Event Submissions
    await createEventSubmissions();

    // Viewer interactions (likes & comments)
    await createViewerInteractions();

    // Artist follows
    await createFollows();

    print('✅ Interactions created successfully!\n');
  }

  Future<void> createEventSubmissions() async {
    print('  📝 Creating event submissions...');

    // Submit 3 approved artworks to first event
    final artworksToSubmit = approvedArtworkIds.take(3).toList();

    for (var artworkId in artworksToSubmit) {
      await supabase.from('event_submissions').insert({
        'event_id': eventIds[0], // First event
        'artwork_id': artworkId,
        'artist_id': artistId,
        'status': 'approved',
      });
    }

    print('    ✓ Submitted ${artworksToSubmit.length} artworks to event');
  }

  Future<void> createViewerInteractions() async {
    print('  👍 Creating likes and comments...');

    int likeCount = 0;
    int commentCount = 0;

    // Viewer likes and comments on approved artworks
    for (var artworkId in approvedArtworkIds) {
      // Add like
      await supabase.from('likes').insert({
        'user_id': viewerId,
        'artwork_id': artworkId,
      });
      likeCount++;

      // Update likes_count on artwork
      await supabase.from('artworks').update({
        'likes_count': 1,
      }).eq('id', artworkId);

      // Add comment (50% chance)
      if (random.nextBool()) {
        await supabase.from('comments').insert({
          'user_id': viewerId,
          'artwork_id': artworkId,
          'content': faker.lorem.sentence(),
        });
        commentCount++;
      }
    }

    print('    ✓ Created $likeCount likes');
    print('    ✓ Created $commentCount comments');
  }

  Future<void> createFollows() async {
    print('  🔗 Creating artist follows...');

    // Viewer follows Artist
    await supabase.from('artist_follows').insert({
      'follower_id': viewerId,
      'artist_id': artistId,
    });

    // Organizer follows Artist
    await supabase.from('artist_follows').insert({
      'follower_id': organizerId,
      'artist_id': artistId,
    });

    print('    ✓ Created 2 follows');
  }
}

// ========================================
// HELPER EXTENSIONS
// ========================================
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
