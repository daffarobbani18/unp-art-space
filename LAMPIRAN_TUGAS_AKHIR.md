# LAMPIRAN TUGAS AKHIR
# CAMPUS ART SPACE - PLATFORM DIGITAL SENI KAMPUS

---

## LAMPIRAN A: KODE PROGRAM

### A.1 Modul Autentikasi dan RBAC (Role-Based Access Control)

#### A.1.1 Login Admin dengan Validasi Role

**File:** `lib/admin/screens/admin_login_screen.dart`

```dart
// Fungsi login dengan validasi role admin
Future<void> _performLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // 1. Autentikasi dengan Supabase Auth
    final authResponse = await Supabase.instance.client.auth.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (authResponse.user == null) throw Exception('Login gagal');

    // 2. Cek role di tabel profiles
    final profileResponse = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', authResponse.user!.id)
        .maybeSingle();

    // 3. Validasi role adalah admin
    if (profileResponse == null) {
      await Supabase.instance.client.auth.signOut();
      throw Exception('Akses Ditolak: Profile tidak ditemukan.');
    }

    final role = profileResponse['role'] as String?;
    
    if (role != 'admin') {
      await Supabase.instance.client.auth.signOut();
      throw Exception('Akses Ditolak: Anda bukan administrator');
    }

    // 4. Navigasi ke dashboard admin
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminMainScreen()),
      );
    }
  } catch (e) {
    setState(() {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    });
  }
}
```

**Penjelasan:**
- Sistem melakukan double validation: pertama dengan Supabase Auth, kedua dengan checking role di database
- Jika role bukan 'admin', user akan di-signOut dan tidak dapat mengakses dashboard
- JWT token dari Supabase Auth digunakan untuk semua request selanjutnya

---

#### A.1.2 Auth Gate - Routing Berdasarkan Role

**File:** `lib/app/core/navigation/auth_gate.dart`

```dart
Future<Map<String, dynamic>?> _getUserRole() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    
    // Query role dari database
    final response = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    
    return response;
  } catch (e) {
    debugPrint('Error getting user role: $e');
    return null;
  }
}

// Routing berdasarkan role
Widget build(BuildContext context) {
  return StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final session = snapshot.data!.session;
        
        if (session != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.data != null) {
                final role = roleSnapshot.data!['role'] as String?;
                
                // Routing berdasarkan role
                if (role == 'organizer') {
                  return const OrganizerMainScreen();
                } else {
                  // Default: artist, viewer, admin (via web)
                  return const MainPage();
                }
              }
              return const MainPage();
            },
          );
        }
      }
      return const LoginPage();
    },
  );
}
```

**Penjelasan:**
- Menggunakan `StreamBuilder` untuk mendeteksi perubahan status autentikasi
- Setiap kali user login, sistem query role dari database
- Organizer diarahkan ke panel khusus, role lain ke MainPage

---

### A.2 Modul AI Detection - Integrasi Sightengine API

#### A.2.1 Edge Function untuk Deteksi AI

**File:** `supabase/functions/detect-ai/index.ts`

```typescript
// Konstanta
const AI_THRESHOLD = 0.8; // 80% confidence threshold
const SIGHTENGINE_API_URL = 'https://api.sightengine.com/1.0/check.json';

serve(async (req: Request) => {
  const startTime = Date.now();
  
  try {
    // Parse payload dari database trigger
    const payload: RequestPayload = await req.json();
    
    if (!payload.record?.media_url) {
      throw new Error('Missing media_url in payload');
    }

    const artworkId = payload.record.id;
    const mediaUrl = payload.record.media_url;
    
    console.log(`🤖 [AI Detector] Artwork ID: ${artworkId}`);
    console.log(`🖼️ Media URL: ${mediaUrl}`);

    // Call Sightengine API
    const sightengineUrl = new URL(SIGHTENGINE_API_URL);
    sightengineUrl.searchParams.set('models', 'genai');
    sightengineUrl.searchParams.set('url', mediaUrl);
    sightengineUrl.searchParams.set('api_user', sightengineUser);
    sightengineUrl.searchParams.set('api_secret', sightengineSecret);

    const apiResponse = await fetch(sightengineUrl.toString());
    const sightengineData: SightengineResponse = await apiResponse.json();
    
    // Extract AI score
    const aiScore = sightengineData.type?.ai_generated;
    console.log(`🎯 AI Score: ${(aiScore * 100).toFixed(1)}%`);
    // Determine if AI suspected
    const isAiSuspected = aiScore > AI_THRESHOLD;
    
    if (isAiSuspected) {
      console.log(`⚠️ AI SUSPECTED! Score ${aiScore} > ${AI_THRESHOLD}`);
    } else {
      console.log(`✅ Likely human-made (score ${aiScore} ≤ ${AI_THRESHOLD})`);
    }

    // Update database
    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    
    const { error: updateError } = await supabase
      .from('artworks')
      .update({
        ai_generated_score: aiScore,
        is_ai_suspected: isAiSuspected,
      })
      .eq('id', artworkId);

    if (updateError) {
      console.error('❌ Database update failed:', updateError);
      throw updateError;
    }

    console.log('✅ Database updated successfully');
    
    const processingTime = Date.now() - startTime;
    console.log(`✨ Detection completed in ${processingTime}ms`);

    return new Response(
      JSON.stringify({
        success: true,
        artwork_id: artworkId,
        detection: {
          is_ai: isAiSuspected,
          confidence: aiScore,
          threshold_used: AI_THRESHOLD,
        },
        processing_time_ms: processingTime,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('❌ Error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

**Penjelasan:**
- Edge Function dipanggil otomatis via database trigger setelah artwork di-insert
- Sightengine API mengembalikan confidence score 0.0-1.0 (0-100%)
- Threshold 80% digunakan untuk flag karya sebagai AI-suspected
- Hasil scan disimpan ke database untuk moderasi admin

---

#### A.2.2 Database Trigger untuk Auto-Scan

**File:** `supabase/migrations/20251130_create_ai_detection_trigger.sql`

```sql
-- Function untuk trigger AI detection
CREATE OR REPLACE FUNCTION trigger_ai_detection()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_request_id bigint;
  v_function_url text;
  v_service_key text;
BEGIN
  -- Skip jika tidak ada media_url
  IF NEW.media_url IS NULL OR NEW.media_url = '' THEN
    RAISE NOTICE '⏭️ Skipping: No media_url for artwork %', NEW.id;
    RETURN NEW;
  END IF;

  -- URL Edge Function dan Service Key
  v_function_url := 'https://PROJECT_ID.supabase.co/functions/v1/detect-ai';
  v_service_key := 'SERVICE_ROLE_KEY';

  RAISE NOTICE '🚀 Triggering AI detection for artwork %', NEW.id;

  -- Panggil Edge Function via HTTP POST
  SELECT net.http_post(
    url := v_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_key
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'artworks',
      'record', row_to_json(NEW),
      'schema', 'public'
    )
  ) INTO v_request_id;

  RAISE NOTICE '✅ HTTP request sent, request_id: %', v_request_id;
  RETURN NEW;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ Error in trigger: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger on artworks table
CREATE TRIGGER trigger_artwork_ai_detection
  AFTER INSERT ON public.artworks
  FOR EACH ROW
  EXECUTE FUNCTION trigger_ai_detection();
```

**Penjelasan:**
- Trigger dijalankan AFTER INSERT pada tabel artworks
- Menggunakan extension `pg_net` untuk HTTP request dari database
- Jika terjadi error, artwork tetap ter-insert (tidak blocking)

---

### A.3 Modul Admin - Moderasi Karya dengan AI Warning System

#### A.3.1 Screen Moderasi dengan Filter AI

**File:** `lib/admin/screens/work_moderation_screen.dart`

```dart
class WorkModerationScreen extends StatefulWidget {
  @override
  _WorkModerationScreenState createState() => _WorkModerationScreenState();
}

class _WorkModerationScreenState extends State<WorkModerationScreen> {
  List<Map<String, dynamic>> _artworks = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, pending, approved, rejected, ai_suspected

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    setState(() => _isLoading = true);
    
    try {
      var query = Supabase.instance.client
          .from('artworks')
          .select('''
            *,
            artist:users!artworks_artist_id_fkey(
              id, name, username, profile_image_url
            )
          ''')
          .order('created_at', ascending: false);

      // Apply filter
      switch (_selectedFilter) {
        case 'pending':
          query = query.eq('status', 'pending');
          break;
        case 'approved':
          query = query.eq('status', 'approved');
          break;
        case 'rejected':
          query = query.eq('status', 'rejected');
          break;
        case 'ai_suspected':
          query = query.eq('is_ai_suspected', true);
          break;
      }

      final response = await query;
      
      setState(() {
        _artworks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading artworks: $e');
      setState(() => _isLoading = false);
    }
  }

  // Function untuk approve artwork
  Future<void> _approveArtwork(int artworkId) async {
    try {
      await Supabase.instance.client
          .from('artworks')
          .update({'status': 'approved'})
          .eq('id', artworkId);
      
      _loadArtworks(); // Reload data
      _showSnackBar('Karya berhasil disetujui', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  // Function untuk reject artwork
  Future<void> _rejectArtwork(int artworkId, String reason) async {
    try {
      await Supabase.instance.client
          .from('artworks')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
          })
          .eq('id', artworkId);
      
      _loadArtworks();
      _showSnackBar('Karya ditolak', Colors.orange);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),
          
          // Artwork Grid
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _artworks.length,
                    itemBuilder: (context, index) {
                      final artwork = _artworks[index];
                      return _buildArtworkCard(artwork);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkCard(Map<String, dynamic> artwork) {
    final isAISuspected = artwork['is_ai_suspected'] == true;
    final aiScore = artwork['ai_generated_score'] ?? 0.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Artwork Image
          Positioned.fill(
            child: Image.network(
              artwork['media_url'],
              fit: BoxFit.cover,
            ),
          ),
          
          // AI Warning Badge (jika terdeteksi AI)
          if (isAISuspected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6584), Color(0xFFFFA726)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'AI ${(aiScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Bottom Info & Actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork['title'] ?? 'Untitled',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'by ${artwork['artist']?['name'] ?? 'Unknown'}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.check, size: 16),
                          label: Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => _approveArtwork(artwork['id']),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.close, size: 16),
                          label: Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => _showRejectDialog(artwork['id']),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Penjelasan:**
- Admin dapat filter artwork berdasarkan status dan AI detection
- Karya yang terdeteksi AI diberi badge warning merah/orange dengan confidence score
- Admin dapat approve atau reject dengan alasan penolakan
- Real-time update setelah aksi moderasi

---

### A.4 Modul Organizer - Generate QR Code PDF

#### A.4.1 Service Generator PDF Label QR Code

**File:** `lib/app/Features/event/services/pdf_label_generator.dart`

```dart
class PdfLabelGenerator {
  static const double qrSize = 5.0 * PdfPageFormat.cm; // 5cm x 5cm
  static const int labelsPerPage = 6; // 2 kolom x 3 baris

  /// Generate dan preview PDF
  static Future<void> generateAndPreview({
    required List<ArtworkModel> artworks,
    required String eventTitle,
  }) async {
    final pdf = await _generatePdf(artworks: artworks, eventTitle: eventTitle);
    
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'QR_Labels_${eventTitle.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Generate PDF document
  static Future<pw.Document> _generatePdf({
    required List<ArtworkModel> artworks,
    required String eventTitle,
  }) async {
    final pdf = pw.Document(title: 'QR Code Labels - $eventTitle');
    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontRegular = await PdfGoogleFonts.poppinsRegular();

    // Split artworks into pages (6 per page)
    for (var i = 0; i < artworks.length; i += labelsPerPage) {
      final pageArtworks = artworks.sublist(
        i,
        (i + labelsPerPage < artworks.length) ? i + labelsPerPage : artworks.length,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              _buildPageHeader(eventTitle, fontBold),
              pw.SizedBox(height: 16),
              pw.Expanded(
                child: pw.Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: pageArtworks.map((artwork) {
                    return _buildLabel(artwork, fontBold, fontRegular);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return pdf;
  }

  /// Build single label
  static pw.Widget _buildLabel(
    ArtworkModel artwork,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final qrUrl = 'https://campus-art-space.vercel.app/submission/${artwork.submissionId}';
    
    return pw.Container(
      width: 9.5 * PdfPageFormat.cm,
      height: 8.0 * PdfPageFormat.cm,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(8),
      child: pw.Row(
        children: [
          // Info artwork
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(artwork.title, style: pw.TextStyle(font: fontBold, fontSize: 14)),
                pw.Text('by ${artwork.artistName}', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                pw.Text('${artwork.category} • ${artwork.year}', style: pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
          // QR Code
          pw.Container(
            width: qrSize,
            height: qrSize,
            padding: pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.deepPurple, width: 2),
            ),
            child: pw.BarcodeWidget(
              data: qrUrl,
              barcode: pw.Barcode.qrCode(),
              drawText: false,
            ),
          ),
        ],
      ),
    );
  }

  /// Share PDF
  static Future<void> sharePdf({
    required List<ArtworkModel> artworks,
    required String eventTitle,
  }) async {
    final pdfBytes = await generatePdfBytes(artworks: artworks, eventTitle: eventTitle);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'QR_Labels_${eventTitle.replaceAll(' ', '_')}.pdf',
    );
  }
}
```

**Penjelasan:**
- Generate PDF A4 dengan 6 label per halaman (grid 2x3)
- Label berisi info artwork dan QR Code 5x5cm
- QR Code mengarah ke URL submission untuk akses public
- Support preview, print, atau share via WhatsApp/email

---

### A.5 Modul Event Management - Organizer

#### A.5.1 Create Event - Pengajuan Event Baru

**File:** `lib/organizer/create_event_screen.dart`

```dart
Future<void> _submitEvent() async {
  if (!_formKey.currentState!.validate()) return;
  
  if (_selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Harap upload banner event'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (_selectedDate == null || _selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Harap pilih tanggal dan waktu event'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User tidak login');

    // 1. Upload banner ke Supabase Storage
    final imageUrl = await _uploadBanner(_selectedImage!);
    if (imageUrl == null) {
      throw Exception('Gagal upload banner');
    }

    // 2. Gabungkan tanggal dan waktu
    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // 3. Insert event ke database
    await Supabase.instance.client.from('events').insert({
      'title': _titleController.text.trim(),
      'content': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'event_date': eventDateTime.toIso8601String(),
      'image_url': imageUrl,
      'organizer_id': user.id,
      'status': 'pending', // Menunggu approval admin
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event berhasil dibuat! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context); // Kembali ke dashboard
    }
  } on StorageException catch (e) {
    String message = 'Gagal upload banner';
    if (e.statusCode == '413') {
      message = 'Ukuran file terlalu besar (max 5MB)';
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

Future<String?> _uploadBanner(File imageFile) async {
  try {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'event_banners/$fileName';

    // Upload ke Supabase Storage
    await Supabase.instance.client.storage
        .from('event_banners')
        .upload(path, imageFile);

    // Dapatkan public URL
    final publicUrl = Supabase.instance.client.storage
        .from('event_banners')
        .getPublicUrl(path);

    return publicUrl;
  } catch (e) {
    debugPrint('Error uploading banner: $e');
    return null;
  }
}
```

**Penjelasan:**
- Organizer upload banner, set tanggal/waktu, lokasi, dan deskripsi event
- Event disimpan dengan status 'pending' untuk approval admin
- Banner disimpan di Supabase Storage bucket 'event_banners'
- Validasi ukuran file maksimal 5MB

---

#### A.5.2 Review Submission - Kurasi Karya untuk Pameran

**File:** `lib/organizer/organizer_event_curation_page.dart`

```dart
// Approve artwork submission
Future<void> _updateSubmissionStatus(String submissionId, String status) async {
  try {
    await supabase
        .from('event_submissions')
        .update({'status': status})
        .eq('id', submissionId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Karya telah disetujui!'
                : 'Karya telah ditolak.',
          ),
          backgroundColor:
              status == 'approved' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Show QR Code untuk artwork yang approved
void _showQrDialog(BuildContext context, String submissionId, 
                   String artworkTitle, String artistName) {
  // QR Code URL menggunakan submission ID (unique per event)
  final qrUrl = 'https://campus-art-space.vercel.app/submission/$submissionId';
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Label Pameran',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purple, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrUrl,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              Text(
                artworkTitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'by $artistName',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

**Penjelasan:**
- Organizer review submission artwork untuk event mereka
- Dapat approve atau reject submission
- Artwork yang approved akan generate QR Code
- QR Code mengarah ke public URL dengan submission ID (unique per event)

---

### A.6 Modul Upload Artwork - Artist

#### A.6.1 Upload Artwork dengan Validasi

**File:** `lib/app/Features/artwork/screens/upload_artwork_page.dart`

```dart
Future<void> _submitArtwork() async {
  if (!_formKey.currentState!.validate()) return;
  
  if (_selectedMediaFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Harap pilih gambar karya terlebih dahulu.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() => _isUploading = true);

  try {
    // 1. Cek user authentication dan role
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("User tidak login.");
    
    final roleRow = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    
    final role = roleRow != null ? (roleRow['role'] as String?) : null;
    if (role != 'artist') {
      throw Exception('Akses ditolak: akun Anda bukan Artist.');
    }

    // 2. Upload media ke Supabase Storage
    final fileExt = _selectedMediaFile!.path.split('.').last;
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final mediaBytes = await _selectedMediaFile!.readAsBytes();

    final storagePath = 'public/${user.id}/$fileName';
    await Supabase.instance.client.storage
        .from('artworks')
        .uploadBinary(storagePath, mediaBytes);

    // Dapatkan URL publik
    final mediaUrl = Supabase.instance.client.storage
        .from('artworks')
        .getPublicUrl(storagePath);

    // 3. Handle thumbnail untuk video
    String? thumbnailUrl;
    if (_selectedMediaType == 'video' && _selectedThumbnailFile != null) {
      final thumbExt = _selectedThumbnailFile!.path.split('.').last;
      final thumbName = '${user.id}_thumb_${DateTime.now().millisecondsSinceEpoch}.$thumbExt';
      final thumbBytes = await _selectedThumbnailFile!.readAsBytes();
      final thumbPath = 'public/${user.id}/$thumbName';
      
      await Supabase.instance.client.storage
          .from('artworks')
          .uploadBinary(thumbPath, thumbBytes);
      
      thumbnailUrl = Supabase.instance.client.storage
          .from('artworks')
          .getPublicUrl(thumbPath);
    }

    // 4. Ambil nama artist
    final userResponse = await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('id', user.id)
        .maybeSingle();
    
    final artistName = (userResponse != null && userResponse['name'] != null)
        ? userResponse['name']
        : 'Nama Tidak Ditemukan';

    // 5. Simpan data ke database
    final artworkData = {
      'title': _judulController.text.trim(),
      'description': _deskripsiController.text.trim(),
      'external_link': _linkController.text.trim().isEmpty
          ? null
          : _linkController.text.trim(),
      'category': _selectedKategori,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'artwork_type': _selectedMediaType ?? 'image',
      'artist_id': user.id,
      'artist_name': artistName,
      'created_at': DateTime.now().toIso8601String(),
      'likes_count': 0,
      'status': 'pending', // Menunggu moderasi admin
    };

    await Supabase.instance.client.from('artworks').insert(artworkData);
    
    // NOTE: AI Detection akan otomatis triggered oleh database trigger
    // setelah INSERT berhasil

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Karya berhasil diunggah dan sedang menunggu persetujuan.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah karya: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isUploading = false);
  }
}
```

**Penjelasan:**
- Validasi role user harus 'artist' sebelum upload
- Upload file ke Supabase Storage dengan path structure `public/{user_id}/{filename}`
- Support image dan video (dengan thumbnail)
- Status awal 'pending' untuk moderasi admin
- Database trigger akan otomatis call AI Detection API setelah INSERT

---

### A.7 Modul Social Features - Interaksi Pengguna

#### A.7.1 Like/Unlike Artwork

**File:** `lib/app/Features/artwork/screens/artwork_detail_page.dart`

```dart
Future<void> _toggleLike() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
  }

  // Optimistic UI update (update UI dulu, baru request ke server)
  final previousLiked = _isLiked;
  final previousCount = _likeCount;
  
  setState(() {
    _isLiking = true;
    _isLiked = !_isLiked;
    _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
  });

  try {
    final artwork = _loadedArtwork ?? widget.artwork;
    if (artwork == null) return;

    final artworkId = artwork['id'].toString();

    if (previousLiked) {
      // Unlike: Delete dari tabel likes
      await Supabase.instance.client
          .from('likes')
          .delete()
          .eq('user_id', user.id)
          .eq('artwork_id', artworkId);
    } else {
      // Like: Insert ke tabel likes
      await Supabase.instance.client.from('likes').insert({
        'user_id': user.id,
        'artwork_id': artworkId,
      });
    }
  } catch (e) {
    debugPrint('Error toggling like: $e');
    
    // Revert UI jika error
    if (mounted) {
      setState(() {
        _isLiked = previousLiked;
        _likeCount = previousCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLiking = false);
  }
}
```

**Penjelasan:**
- Menggunakan optimistic UI update untuk responsiveness
- Like/unlike tersimpan di tabel `likes` dengan composite key (user_id, artwork_id)
- Jika request gagal, UI akan di-revert ke state sebelumnya
- User harus login untuk like/unlike

---

#### A.7.2 Comment pada Artwork

**File:** `lib/app/Features/artwork/screens/artwork_detail_page.dart`

```dart
Future<void> _sendComment() async {
  if (_commentController.text.trim().isEmpty) return;

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
  }

  setState(() => _isSending = true);

  try {
    // Insert comment ke database
    await Supabase.instance.client.from('comments').insert({
      'artwork_id': widget.artworkId,
      'user_id': user.id,
      'content': _commentController.text.trim(),
    });

    _commentController.clear();
    widget.onCommentAdded(); // Callback untuk refresh comment list

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komentar berhasil dikirim'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error sending comment: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim komentar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isSending = false);
  }
}
```

**Penjelasan:**
- Comment tersimpan di tabel `comments` dengan relasi ke `artworks` dan `users`
- User harus login untuk comment
- Setelah berhasil, list comment di-refresh via callback
- Validasi content tidak boleh kosong

---

### A.8 Database Schema & Row Level Security (RLS)

#### A.8.1 Schema Database Utama

**File:** `schema.sql`

```sql
-- Tabel Users (Profile pengguna)
CREATE TABLE public.users (
  id uuid PRIMARY KEY,
  created_at timestamp with time zone DEFAULT now(),
  name text,
  email text UNIQUE,
  role text DEFAULT 'viewer', -- viewer, artist, organizer, admin
  specialization text,
  bio text,
  social_media jsonb,
  profile_image_url text
);

-- Tabel Profiles (untuk Auth Supabase)
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY,
  created_at timestamp with time zone DEFAULT now(),
  role text DEFAULT 'user' 
    CHECK (role IN ('admin', 'artist', 'viewer', 'organizer')),
  username text,
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) 
    REFERENCES auth.users(id)
);

-- Tabel Artworks (Karya Seni)
CREATE TABLE public.artworks (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at timestamp with time zone DEFAULT now(),
  title text,
  description text,
  media_url text,
  thumbnail_url text,
  external_link text,
  category text,
  artwork_type text DEFAULT 'image', -- image, video
  status text DEFAULT 'pending', -- pending, approved, rejected
  artist_id uuid,
  artist_name text,
  likes_count bigint DEFAULT 0,
  ai_generated_score float4, -- 0.0 - 1.0 dari Sightengine
  is_ai_suspected boolean DEFAULT false,
  CONSTRAINT artworks_artist_id_fkey 
    FOREIGN KEY (artist_id) REFERENCES public.profiles(id)
);

-- Tabel Events (Pameran/Exhibition)
CREATE TABLE public.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamp with time zone DEFAULT now(),
  title text NOT NULL,
  content text,
  event_date timestamp with time zone,
  location text,
  image_url text,
  status text DEFAULT 'pending', -- pending, approved, rejected
  organizer_id uuid,
  rejection_reason text,
  CONSTRAINT events_organizer_id_fkey 
    FOREIGN KEY (organizer_id) REFERENCES public.profiles(id)
);

-- Tabel Event Submissions (Artwork submit ke event)
CREATE TABLE public.event_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamp with time zone DEFAULT now(),
  event_id uuid NOT NULL,
  artwork_id bigint NOT NULL,
  artist_id uuid NOT NULL,
  status text DEFAULT 'pending', -- pending, approved, rejected
  curator_note text,
  CONSTRAINT event_submissions_event_id_fkey 
    FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT event_submissions_artwork_id_fkey 
    FOREIGN KEY (artwork_id) REFERENCES public.artworks(id),
  CONSTRAINT event_submissions_artist_id_fkey 
    FOREIGN KEY (artist_id) REFERENCES public.profiles(id)
);

-- Tabel Likes (Like pada artwork)
CREATE TABLE public.likes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamp with time zone DEFAULT now(),
  user_id uuid NOT NULL,
  artwork_id bigint NOT NULL,
  CONSTRAINT likes_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT likes_artwork_id_fkey 
    FOREIGN KEY (artwork_id) REFERENCES public.artworks(id)
);

-- Tabel Comments (Komentar pada artwork)
CREATE TABLE public.comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamp with time zone DEFAULT now(),
  user_id uuid NOT NULL,
  artwork_id bigint NOT NULL,
  content text NOT NULL,
  CONSTRAINT comments_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT comments_artwork_id_fkey 
    FOREIGN KEY (artwork_id) REFERENCES public.artworks(id)
);

-- Index untuk optimasi query
CREATE INDEX idx_artworks_ai_suspected 
  ON public.artworks(is_ai_suspected) 
  WHERE is_ai_suspected = true;

CREATE INDEX idx_artworks_status 
  ON public.artworks(status);

CREATE INDEX idx_likes_user_artwork 
  ON public.likes(user_id, artwork_id);
```

**Penjelasan:**
- Schema dirancang dengan relasi foreign key yang ketat
- Support multi-role system (viewer, artist, organizer, admin)
- AI detection fields: `ai_generated_score` dan `is_ai_suspected`
- Event submissions untuk kurasi artwork di pameran
- Likes dan comments untuk social interaction

---

#### A.8.2 Row Level Security (RLS) Policies

**File:** `supabase_rls_simple.sql`

```sql
-- Enable RLS pada semua tabel
ALTER TABLE public.artworks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- ARTWORKS POLICIES
-- 1. SELECT: Semua authenticated user bisa lihat semua artwork
CREATE POLICY "authenticated_select_artworks"
ON public.artworks FOR SELECT
TO authenticated
USING (true);

-- 2. INSERT: Artist bisa insert artwork sendiri
CREATE POLICY "artist_insert_artworks"
ON public.artworks FOR INSERT
TO authenticated
WITH CHECK (artist_id = auth.uid());

-- 3. UPDATE: Artist bisa update artwork sendiri
CREATE POLICY "artist_update_own_artworks"
ON public.artworks FOR UPDATE
TO authenticated
USING (artist_id = auth.uid());

-- 4. DELETE: Artist bisa delete artwork sendiri
CREATE POLICY "artist_delete_own_artworks"
ON public.artworks FOR DELETE
TO authenticated
USING (artist_id = auth.uid());

-- LIKES POLICIES
-- 1. SELECT: Semua bisa lihat likes
CREATE POLICY "authenticated_select_likes"
ON public.likes FOR SELECT
TO authenticated
USING (true);

-- 2. INSERT: User bisa like artwork
CREATE POLICY "user_insert_likes"
ON public.likes FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- 3. DELETE: User bisa unlike (delete like sendiri)
CREATE POLICY "user_delete_own_likes"
ON public.likes FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- COMMENTS POLICIES
-- 1. SELECT: Semua bisa lihat comments
CREATE POLICY "authenticated_select_comments"
ON public.comments FOR SELECT
TO authenticated
USING (true);

-- 2. INSERT: User bisa insert comment
CREATE POLICY "user_insert_comments"
ON public.comments FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- 3. DELETE: User bisa delete comment sendiri
CREATE POLICY "user_delete_own_comments"
ON public.comments FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- USERS POLICIES
-- 1. SELECT: Semua bisa lihat user profiles (public)
CREATE POLICY "authenticated_select_users"
ON public.users FOR SELECT
TO authenticated
USING (true);

-- 2. UPDATE: User bisa update profile sendiri
CREATE POLICY "user_update_own_profile"
ON public.users FOR UPDATE
TO authenticated
USING (id = auth.uid());
```

**Penjelasan:**
- RLS memastikan data isolation di level database
- Policies menggunakan `auth.uid()` untuk validasi ownership
- Artist hanya bisa edit/delete artwork milik sendiri
- User hanya bisa like/comment dengan ID mereka sendiri
- Public read access untuk browse content, private write untuk ownership
- Admin access handled di application level (bypass RLS dengan service role)

---

## LAMPIRAN B: SCREENSHOTS APLIKASI

> **CATATAN:** Screenshots akan ditambahkan dari dokumentasi yang sudah ada di file-file panduan seperti:
> - `LAPORAN_FITUR_AI_DETECTION.md` (Screenshots AI detection)
> - `LAPORAN_FITUR_QR_CODE.md` (Screenshots QR code generation)
> - `LAPORAN_KEMAJUAN_PANEL_ADMIN.md` (Screenshots admin dashboard)
> - `CREATE_EVENT_SCREEN_GUIDE.md` (Screenshots event creation)
> - File-file guide lainnya

**Struktur Screenshot yang akan dilampirkan:**

### B.1 Modul Autentikasi
- Login screen (mobile & web admin)
- Register screen dengan role selection
- Email verification flow

### B.2 Modul AI Detection
- Upload artwork dengan AI warning info
- Artwork detail dengan AI badge
- Admin moderation dengan AI score filter
- AI detection result notification

### B.3 Modul Admin Dashboard
- Dashboard statistik overview
- Work moderation screen (pending, approved, rejected)
- Event moderation screen
- User management screen
- Artwork detail dengan AI warning badge

### B.4 Modul Organizer
- Create event form
- Event submission review (curation page)
- QR code generation preview
- PDF export QR labels

### B.5 Modul Artist
- Upload artwork form
- My artworks gallery
- Artwork analytics
- Event submission process

### B.6 Modul Viewer
- Home feed dengan artwork cards
- Artwork detail dengan like/comment
- Artist profile page
- Event list dan detail

### B.7 Social Features
- Like/unlike interaction
- Comment thread
- Follow/unfollow artist
- Notification list

### B.8 QR Code System
- QR code pada PDF label
- QR code scanning result
- Artwork detail dari QR scan
- Label printing preview

---

**Tanggal:** 12 Desember 2025  
**Status:** ✅ Lampiran Kode Selesai | 🟡 Screenshots Pending
