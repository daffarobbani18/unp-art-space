import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_animations.dart';
import '../../artwork/screens/upload_artwork_page.dart';
import '../../events/upload_event_screen.dart';
import '../../../../main/main_app.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({Key? key}) : super(key: key);

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? _currentUserRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    setState(() => _isLoading = true);
    
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _currentUserRole = null;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final result = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _currentUserRole = result != null ? (result['role'] as String?) : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUserRole = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: AppTheme.textTertiary.withOpacity(0.1),
        title: Text(
          'Upload Karya',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
              ),
            )
          : _currentUserRole != 'artist'
              ? Center(
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.secondary.withOpacity(0.2),
                                  AppTheme.accent.withOpacity(0.2),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 80,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceLg),
                          Text(
                            'Akses Terbatas',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontFamily: 'Playfair Display',
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceSm),
                          Text(
                            'Hanya akun Artist yang dapat mengunggah karya seni atau mengajukan event.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spaceLg),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceMd),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppTheme.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spaceXs),
                                Text(
                                  'Daftar sebagai Artist untuk mengakses fitur ini',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      FadeSlideAnimation(
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spaceMd),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.secondary.withOpacity(0.1),
                                AppTheme.accent.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spaceSm),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: Icon(
                                  Icons.palette_rounded,
                                  color: AppTheme.secondary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selamat Datang, Artist!',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bagikan karya terbaik Anda',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceLg),

                      // Title
                      FadeSlideAnimation(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'Pilih Jenis Upload',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'Playfair Display',
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXs),
                      FadeSlideAnimation(
                        delay: const Duration(milliseconds: 150),
                        child: Text(
                          'Pilih salah satu opsi di bawah untuk mulai mengunggah',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceLg),

                      // Upload Artwork Card
                      ScaleInAnimation(
                        delay: const Duration(milliseconds: 200),
                        child: BounceAnimation(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UploadArtworkPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.secondary, AppTheme.secondaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.secondary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  ),
                                  child: const Icon(
                                    Icons.palette_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceMd),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unggah Karya Seni',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Playfair Display',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Upload foto, video, atau karya digital Anda',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),

                      // Upload Event Card
                      ScaleInAnimation(
                        delay: const Duration(milliseconds: 300),
                        child: BounceAnimation(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UploadEventScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accentOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  ),
                                  child: const Icon(
                                    Icons.event_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceMd),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ajukan Event',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Playfair Display',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ajukan pameran seni atau event kreatif',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceLg),

                      // Tips Section
                      FadeSlideAnimation(
                        delay: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spaceMd),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            boxShadow: AppTheme.shadowSm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: AppTheme.accentYellow,
                                    size: 24,
                                  ),
                                  const SizedBox(width: AppTheme.spaceXs),
                                  Text(
                                    'Tips Upload',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spaceSm),
                              _buildTipItem('Gunakan foto berkualitas tinggi'),
                              _buildTipItem('Berikan deskripsi yang jelas'),
                              _buildTipItem('Pilih kategori yang sesuai'),
                              _buildTipItem('Upload akan direview oleh admin'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spaceXs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
