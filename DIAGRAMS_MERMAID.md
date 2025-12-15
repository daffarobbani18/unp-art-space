# CAMPUS ART SPACE - MERMAID DIAGRAMS

Dokumen ini berisi semua diagram dalam laporan Tugas Akhir Campus Art Space dalam format **Mermaid**. 

Anda dapat meng-copy kode Mermaid di bawah ini dan paste ke [mermaid.live](https://mermaid.live) untuk melihat visualisasi atau mengeditnya.

---

## 1. Arsitektur Three-Tier System (BAB 3.2.1)

```mermaid
graph TB
    subgraph "PRESENTATION LAYER"
        A[Flutter Mobile App<br/>Viewer, Artist, Organizer]
        B[Flutter Web Dashboard<br/>Admin Only]
    end
    
    subgraph "APPLICATION LAYER - Supabase Backend"
        C[Authentication JWT]
        D[PostgreSQL Database]
        E[Storage Files]
        F[Realtime WebSocket]
        G[Edge Functions Serverless]
    end
    
    subgraph "DATA LAYER"
        H[PostgreSQL Database<br/>Relational Data]
        I[Object Storage Bucket<br/>Images, Videos, PDF]
    end
    
    subgraph "EXTERNAL SERVICES"
        J[Sightengine API<br/>AI Art Detection]
        K[Firebase Cloud Messaging<br/>Push Notifications]
    end
    
    A -->|HTTPS/WSS| C
    A -->|HTTPS/WSS| D
    A -->|HTTPS/WSS| E
    A -->|HTTPS/WSS| F
    
    B -->|HTTPS/WSS| C
    B -->|HTTPS/WSS| D
    B -->|HTTPS/WSS| E
    B -->|HTTPS/WSS| F
    
    C --> H
    D --> H
    E --> I
    F --> H
    G --> H
    G --> I
    
    G -->|API Call| J
    G -->|Push Notification| K
    
    style A fill:#e1bee7
    style B fill:#ce93d8
    style C fill:#90caf9
    style D fill:#90caf9
    style E fill:#90caf9
    style F fill:#90caf9
    style G fill:#90caf9
    style H fill:#a5d6a7
    style I fill:#a5d6a7
    style J fill:#ffcc80
    style K fill:#ffcc80
```

---

## 2. Entity Relationship Diagram - Simplified (BAB 3.3.1)

```mermaid
erDiagram
    AUTH_USERS ||--|| PROFILES : "has"
    AUTH_USERS ||--|| USERS : "has_detail"
    PROFILES ||--o{ ARTWORKS : "creates"
    PROFILES ||--o{ EVENTS : "organizes"
    PROFILES ||--o{ COMMENTS : "writes"
    PROFILES ||--o{ LIKES : "gives"
    PROFILES ||--o{ ARTIST_FOLLOWS : "follows/followed_by"
    PROFILES ||--o{ NOTIFICATIONS : "receives"
    PROFILES ||--o{ FCM_TOKENS : "owns_device"
    PROFILES ||--o{ EVENT_SUBMISSIONS : "submits"
    ARTWORKS ||--o{ COMMENTS : "receives"
    ARTWORKS ||--o{ LIKES : "receives"
    ARTWORKS ||--o{ EVENT_SUBMISSIONS : "submitted_to"
    EVENTS ||--o{ EVENT_SUBMISSIONS : "has_submissions"
    EVENTS ||--o{ NOTIFICATIONS : "triggers"
    ARTWORKS ||--o{ NOTIFICATIONS : "triggers"
    
    AUTH_USERS {
        uuid id PK
        varchar email
        varchar encrypted_password
        timestamp email_confirmed_at
        timestamp created_at
        jsonb raw_user_meta_data
    }
    
    PROFILES {
        uuid id PK_FK
        timestamp created_at
        text role
        text username
    }
    
    USERS {
        uuid id PK_FK
        timestamp created_at
        text name
        text email
        text role
        text specialization
        text bio
        jsonb social_media
        text profile_image_url
    }
    
    ARTWORKS {
        bigint id PK
        timestamp created_at
        text title
        text description
        text media_url
        text external_link
        text category
        text status
        uuid artist_id FK
        bigint likes_count
        text artist_name
        text artwork_type
        text thumbnail_url
        bigint views_count
        bigint shares_count
        real ai_generated_score
        boolean is_ai_suspected
    }
    
    EVENTS {
        uuid id PK
        timestamp created_at
        text title
        text content
        timestamp event_date
        text location
        text image_url
        text status
        uuid artist_id FK
        text rejection_reason
        uuid organizer_id FK
    }
    
    COMMENTS {
        uuid id PK
        timestamp created_at
        uuid user_id FK
        bigint artwork_id FK
        text content
    }
    
    LIKES {
        uuid id PK
        timestamp created_at
        uuid user_id FK
        bigint artwork_id FK
    }
    
    EVENT_SUBMISSIONS {
        uuid id PK
        timestamp created_at
        uuid event_id FK
        bigint artwork_id FK
        uuid artist_id FK
        text status
        text curator_note
    }
    
    ARTIST_FOLLOWS {
        uuid id PK
        uuid follower_id FK
        uuid artist_id FK
        timestamp created_at
    }
    
    NOTIFICATIONS {
        uuid id PK
        timestamp created_at
        uuid user_id FK
        text type
        text title
        text message
        boolean is_read
        bigint artwork_id FK
        uuid event_id FK
        uuid submission_id FK
        text action_url
        text icon_type
    }
    
    FCM_TOKENS {
        uuid id PK
        timestamp created_at
        timestamp updated_at
        uuid user_id FK
        text token
        text device_id
        text platform
        boolean is_active
    }
    
    CATEGORIES {
        uuid id PK
        timestamp created_at
        text name
    }
    
    ANNOUNCEMENTS {
        uuid id PK
        timestamp created_at
        text tittle
        text content
    }
```

---

## 3. Siklus Publikasi dan Apresiasi Karya (BAB 2.3.1)

```mermaid
flowchart TD
    A[Artist Upload Karya] --> B[Sistem AI Detection<br/>Automatic Scan]
    B --> C[Admin Moderasi<br/>Review + AI Score]
    C --> D{Decision}
    D -->|Approve| E[Karya Dipublikasikan<br/>Muncul di Feed]
    D -->|Reject| F[Notifikasi Penolakan<br/>ke Artist]
    E --> G[Viewer Eksplorasi Karya<br/>di Feed]
    G --> H[Viewer Berikan Apresiasi<br/>Like / Comment / Share]
    H --> I[Notifikasi Real-time<br/>ke Artist]
    I --> J[Artist Lihat Statistik<br/>& Feedback]
    J --> K{Feedback Positif?}
    K -->|Ya| L[Motivasi Upload<br/>Karya Baru]
    L --> A
    K -->|Tidak| M[Evaluasi & Improve]
    M --> A
    
    style A fill:#e1bee7
    style B fill:#90caf9
    style C fill:#ffcc80
    style D fill:#fff59d
    style E fill:#a5d6a7
    style F fill:#ef9a9a
    style G fill:#b39ddb
    style H fill:#ce93d8
    style I fill:#90caf9
    style J fill:#e1bee7
    style K fill:#fff59d
    style L fill:#a5d6a7
    style M fill:#ffab91
```

---

## 4. Siklus Penyelenggaraan Event Hybrid - Exhibition System (BAB 2.3.2)

```mermaid
flowchart TD
    A[Artist Ajukan Event<br/>Form Proposal Exhibition] --> B[Admin Review Proposal<br/>Policy Check]
    B --> C{Decision}
    C -->|Approve| D[Event Created<br/>Status: Approved]
    C -->|Reject| E[Notifikasi Penolakan<br/>dengan Alasan]
    D --> F[Artist Submit Karya<br/>ke Event]
    F --> G[Organizer Review<br/>Submission Karya]
    G --> H{Karya Layak<br/>Dipamerkan?}
    H -->|Ya, Approve| I[System Generate QR Code<br/>per Artwork]
    H -->|Tidak| J[Reject Submission<br/>dengan Catatan]
    I --> K[QR Code Link ke<br/>Web Artwork Detail URL]
    K --> L[Organizer Cetak PDF<br/>Semua QR Codes Event]
    L --> M[Pasang QR Code<br/>di Lokasi Pameran Fisik]
    M --> N[Pengunjung Datang<br/>ke Exhibition]
    N --> O[Pengunjung Scan QR Code<br/>dengan Smartphone]
    O --> P[Browser Buka Otomatis<br/>Artwork Detail Web Page]
    P --> Q[Tampilkan Info Lengkap:<br/>Title, Desc, Artist, Media]
    Q --> R{Pengunjung<br/>Sudah Login?}
    R -->|Ya| S[Dapat Like/Comment/Share<br/>pada Karya]
    R -->|Tidak| T[View Only Mode<br/>Bisa Login untuk Interaksi]
    S --> U[Notifikasi Real-time<br/>ke Artist]
    U --> V[Organizer & Admin Monitoring<br/>Statistik & Engagement]
    V --> W[Evaluasi & Dokumentasi<br/>Event Success]
    E --> X[Artist Revisi<br/>& Ajukan Ulang]
    X --> A
    J --> Y[Artist Pilih Karya Lain<br/>atau Perbaiki]
    Y --> F
    
    style A fill:#e1bee7
    style B fill:#ffcc80
    style C fill:#fff59d
    style D fill:#a5d6a7
    style E fill:#ef9a9a
    style F fill:#ce93d8
    style G fill:#ffcc80
    style H fill:#fff59d
    style I fill:#90caf9
    style J fill:#ef9a9a
    style K fill:#90caf9
    style L fill:#ffab91
    style M fill:#ffab91
    style N fill:#b39ddb
    style O fill:#b39ddb
    style P fill:#90caf9
    style Q fill:#a5d6a7
    style R fill:#fff59d
    style S fill:#ce93d8
    style T fill:#c5cae9
    style U fill:#90caf9
    style V fill:#ffcc80
    style W fill:#a5d6a7
    style X fill:#ffab91
    style Y fill:#ffab91
```

---

## 5. Flow Upload Artwork dengan AI Detection (BAB 3.4.1)

```mermaid
flowchart TD
    A[Artist pilih gambar<br/>dari galeri] --> B[Sistem kompres gambar<br/>untuk optimasi ukuran]
    B --> C[Upload gambar ke<br/>Supabase Storage]
    C --> D[Simpan data karya<br/>ke Database<br/>Status: Pending]
    D --> E[Sistem otomatis<br/>panggil AI Detection]
    E --> F[Kirim gambar ke<br/>Sightengine API]
    F --> G[Terima hasil<br/>Confidence Score]
    G --> H{Score AI >= 80%?}
    H -->|Ya| I[Tandai sebagai<br/>Terindikasi AI]
    H -->|Tidak| J[Tandai sebagai<br/>Lolos Deteksi]
    I --> K[Notifikasi ke Artist:<br/>Karya terindikasi AI<br/>Menunggu review Admin]
    J --> L[Notifikasi ke Artist:<br/>Karya lolos deteksi<br/>Menunggu review Admin]
    K --> M[Artist dapat lihat status<br/>di Dashboard]
    L --> M
    
    style A fill:#e1bee7
    style B fill:#90caf9
    style C fill:#90caf9
    style D fill:#90caf9
    style E fill:#ffcc80
    style F fill:#ffcc80
    style G fill:#ffcc80
    style H fill:#fff59d
    style I fill:#ef9a9a
    style J fill:#a5d6a7
    style K fill:#ef9a9a
    style L fill:#a5d6a7
    style M fill:#b39ddb
```

---

## 6. Flow Admin Moderasi Karya (BAB 3.4.2)

```mermaid
flowchart TD
    A[Admin buka halaman<br/>Moderasi Karya] --> B[Sistem tampilkan<br/>daftar karya pending<br/>beserta AI Score]
    B --> C[Admin pilih karya<br/>untuk direview]
    C --> D[Tampilkan detail karya:<br/>Gambar, Deskripsi,<br/>AI Confidence Score]
    D --> E{Keputusan Admin}
    E -->|Approve| F[Karya disetujui<br/>Status: Approved]
    E -->|Reject| G[Admin input alasan<br/>penolakan]
    G --> H[Karya ditolak<br/>Status: Rejected]
    F --> I[Sistem kirim notifikasi<br/>ke Artist:<br/>Karya disetujui!]
    H --> J[Sistem kirim notifikasi<br/>ke Artist:<br/>Karya ditolak + Alasan]
    I --> K[Karya muncul<br/>di Feed publik]
    J --> L[Artist dapat lihat<br/>alasan penolakan<br/>& upload ulang]
    K --> M[Viewer dapat<br/>lihat & berinteraksi<br/>dengan karya]
    
    style A fill:#ffcc80
    style B fill:#90caf9
    style C fill:#ffcc80
    style D fill:#90caf9
    style E fill:#fff59d
    style F fill:#a5d6a7
    style G fill:#ef9a9a
    style H fill:#ef9a9a
    style I fill:#a5d6a7
    style J fill:#ef9a9a
    style K fill:#a5d6a7
    style L fill:#ffab91
    style M fill:#b39ddb
```

---

## 7. Flow Event Management & QR Poster Generation (BAB 3.4.3)

```mermaid
flowchart TD
    A[Artist ajukan event<br/>isi form + upload poster] --> B[Proposal tersimpan<br/>Status: Pending]
    B --> C[Admin review<br/>proposal event]
    C --> D{Keputusan Admin}
    D -->|Reject| E[Notifikasi ke Artist:<br/>Event ditolak + Alasan]
    E --> F[Artist dapat<br/>revisi & ajukan ulang]
    F --> A
    D -->|Approve| G[Event disetujui<br/>Status: Approved]
    G --> H[Sistem otomatis<br/>generate QR Code<br/>untuk poster]
    H --> I[QR Code ditambahkan<br/>ke poster original]
    I --> J[Poster dengan QR<br/>disimpan sebagai PDF]
    J --> K[Organizer download<br/>PDF poster]
    K --> L[Cetak poster fisik<br/>atau bagikan digital]
    L --> M[Poster dipasang<br/>untuk promosi event]
    M --> N[Viewer lihat event<br/>& simpan tiket digital]
    N --> O[QR Code tiket siap<br/>untuk scan di lokasi]
    
    style A fill:#e1bee7
    style B fill:#90caf9
    style C fill:#ffcc80
    style D fill:#fff59d
    style E fill:#ef9a9a
    style F fill:#ffab91
    style G fill:#a5d6a7
    style H fill:#90caf9
    style I fill:#90caf9
    style J fill:#90caf9
    style K fill:#ffcc80
    style L fill:#ffab91
    style M fill:#b39ddb
    style N fill:#ce93d8
    style O fill:#a5d6a7
```

---

## 8. Flow QR Ticket Scanning di Lokasi Event (BAB 3.4.4)

```mermaid
flowchart TD
    A[Organizer tap tombol<br/>Scan QR] --> B[Buka kamera<br/>QR Scanner]
    B --> C[Arahkan kamera ke<br/>QR Code tiket viewer]
    C --> D[Sistem baca<br/>data QR Code]
    D --> E[Cari tiket di database<br/>berdasarkan kode]
    E --> F{Validasi Tiket}
    F -->|Tiket tidak ditemukan| G[Tampilan MERAH<br/>❌ TIKET TIDAK VALID<br/>+ Bunyi buzzer]
    F -->|Tiket sudah digunakan| H[Tampilan KUNING<br/>⚠️ SUDAH DIGUNAKAN<br/>Info scan sebelumnya]
    F -->|Tiket valid| I[Tandai tiket sebagai<br/>sudah digunakan]
    I --> J[Tambah counter<br/>jumlah pengunjung hadir]
    J --> K[Tampilan HIJAU<br/>✅ CHECK-IN BERHASIL<br/>Nama pengunjung<br/>+ Bunyi chime]
    K --> L[Admin Dashboard<br/>update real-time<br/>jumlah attendance]
    G --> M[Kembali ke mode scan<br/>siap untuk tiket berikutnya]
    H --> N{Organizer pilih}
    N -->|Override| I
    N -->|Batal| M
    L --> M
    
    style A fill:#ffcc80
    style B fill:#90caf9
    style C fill:#b39ddb
    style D fill:#90caf9
    style E fill:#90caf9
    style F fill:#fff59d
    style G fill:#ef9a9a
    style H fill:#fff59d
    style I fill:#a5d6a7
    style J fill:#a5d6a7
    style K fill:#a5d6a7
    style L fill:#ffcc80
    style M fill:#90caf9
    style N fill:#fff59d
```

---

## 9. Interaksi Multi-Aktor dalam Sistem (BAB 2.3)

```mermaid
graph TD
    subgraph "VIEWER ACTIONS"
        V1[Eksplorasi Karya]
        V2[Like/Comment/Share]
        V3[Follow Artist]
        V4[Simpan Tiket Event]
    end
    
    subgraph "ARTIST ACTIONS"
        A1[Upload Karya]
        A2[Balas Comment]
        A3[Ajukan Event]
        A4[Lihat Analytics]
    end
    
    subgraph "ORGANIZER ACTIONS"
        O1[Scan QR Tiket]
        O2[Monitor Attendance]
        O3[Koordinasi Tim]
    end
    
    subgraph "ADMIN ACTIONS"
        AD1[Moderasi Karya]
        AD2[Approve Event]
        AD3[Generate QR Poster]
        AD4[Analytics Dashboard]
    end
    
    V1 --> V2
    V2 --> A2
    A2 --> V3
    V3 --> A4
    A4 --> A1
    A1 --> AD1
    AD1 --> V1
    
    V4 --> O1
    O1 --> O2
    O2 --> AD4
    
    A3 --> AD2
    AD2 --> AD3
    AD3 --> V4
    
    style V1 fill:#b39ddb
    style V2 fill:#ce93d8
    style V3 fill:#e1bee7
    style V4 fill:#f3e5f5
    style A1 fill:#ffccbc
    style A2 fill:#ffab91
    style A3 fill:#ff8a65
    style A4 fill:#ff7043
    style O1 fill:#90caf9
    style O2 fill:#64b5f6
    style O3 fill:#42a5f5
    style AD1 fill:#a5d6a7
    style AD2 fill:#81c784
    style AD3 fill:#66bb6a
    style AD4 fill:#4caf50
```

---

## 10. Role-Based Access Control (RBAC) Matrix

```mermaid
graph LR
    subgraph "Mobile App Users"
        V[Viewer]
        AR[Artist]
        O[Organizer]
    end
    
    subgraph "Web Dashboard"
        AD[Admin]
    end
    
    subgraph "Features & Permissions"
        F1[View Artworks]
        F2[Like/Comment/Share]
        F3[Follow Artists]
        F4[Upload Artwork]
        F5[Submit Event Proposal]
        F6[View Analytics]
        F7[Scan QR Tickets]
        F8[Monitor Event]
        F9[Moderate Content]
        F10[Approve Events]
        F11[Generate QR Posters]
        F12[User Management]
    end
    
    V --> F1
    V --> F2
    V --> F3
    
    AR --> F1
    AR --> F2
    AR --> F3
    AR --> F4
    AR --> F5
    AR --> F6
    
    O --> F1
    O --> F7
    O --> F8
    
    AD --> F9
    AD --> F10
    AD --> F11
    AD --> F12
    
    style V fill:#b39ddb
    style AR fill:#ffab91
    style O fill:#90caf9
    style AD fill:#a5d6a7
```

---

## Cara Menggunakan Diagram Ini:

1. **Copy kode Mermaid** dari salah satu section di atas
2. Buka [mermaid.live](https://mermaid.live)
3. **Paste kode** di editor sebelah kiri
4. Diagram akan otomatis ter-render di sebelah kanan
5. Anda bisa **edit** kode untuk customize diagram
6. **Export** diagram sebagai PNG, SVG, atau PDF untuk dimasukkan ke laporan

## Tips Editing:

- Ubah warna dengan mengubah value `fill:` di `style` statements
- Tambah node baru dengan format: `NodeID[Label Text]`
- Tambah edge/connection dengan `-->` (arrow) atau `---` (line)
- Untuk flowchart, gunakan shapes berbeda:
  - `[]` = rectangle
  - `()` = rounded rectangle
  - `{}` = diamond (decision)
  - `[[]]` = subroutine
  - `[()]` = stadium/pill

## Referensi Mermaid Syntax:

- Official Docs: https://mermaid.js.org/intro/
- Flowchart: https://mermaid.js.org/syntax/flowchart.html
- Sequence Diagram: https://mermaid.js.org/syntax/sequenceDiagram.html
- ER Diagram: https://mermaid.js.org/syntax/entityRelationshipDiagram.html

---

**Note:** Semua diagram ini dapat di-integrate langsung ke Markdown files yang support Mermaid rendering (GitHub, GitLab, Notion, VS Code dengan extension, dll) dengan membungkus kode dalam code block:

\```mermaid
[kode mermaid di sini]
\```
