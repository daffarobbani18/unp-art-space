# 🤖 AI Art Detector - Setup & Deployment Guide

## 📋 Overview

Fitur **AI Art Detector** menggunakan **Sightengine API** (gratis) untuk mendeteksi artwork yang dibuat dengan AI secara otomatis setelah upload.

**Flow:**
```
Artist Upload Artwork → Database INSERT → Trigger → Edge Function → Sightengine API → Update Score
```

---

## 🚀 Deployment Steps

### **1️⃣ Setup Sightengine API**

1. **Sign up gratis**: https://sightengine.com/signup
2. **Get credentials** dari dashboard:
   - `API User` (contoh: `123456789`)
   - `API Secret` (contoh: `abc123def456`)
3. **Free tier**: 2,000 requests/month

---

### **2️⃣ Deploy Edge Function**

#### **A. Deploy Function**
```bash
cd d:\Mobile\unp-art-space-mobile
supabase functions deploy detect-ai
```

#### **B. Set Environment Variables**
```bash
# Set Sightengine credentials
supabase secrets set SIGHTENGINE_USER=YOUR_API_USER
supabase secrets set SIGHTENGINE_SECRET=YOUR_API_SECRET

# Verify secrets
supabase secrets list
```

**Expected output:**
```
SIGHTENGINE_USER
SIGHTENGINE_SECRET
SUPABASE_URL (auto-set)
SUPABASE_SERVICE_ROLE_KEY (auto-set)
```

---

### **3️⃣ Run Database Migrations**

#### **A. Add Columns to Artworks Table**

**File:** `supabase/migrations/20251130_add_ai_detection_columns.sql`

```bash
# Run via Supabase SQL Editor
# Copy-paste dan run
```

**Atau via CLI:**
```bash
supabase db push
```

**Verify:**
```sql
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'artworks'
  AND column_name IN ('ai_generated_score', 'is_ai_suspected');
```

**Expected:**
| column_name | data_type |
|------------|----------|
| ai_generated_score | real |
| is_ai_suspected | boolean |

---

#### **B. Create Database Trigger**

**File:** `supabase/migrations/20251130_create_ai_detection_trigger.sql`

**⚠️ IMPORTANT - Edit file first:**

1. **Line 65-66**: Set your project URL
```sql
ALTER DATABASE postgres 
SET app.settings.supabase_url = 'https://YOUR_PROJECT_REF.supabase.co';
```

2. **Line 69-71**: Set your service role key
```sql
ALTER DATABASE postgres 
SET app.settings.service_role_key = 'YOUR_SERVICE_ROLE_KEY';
```

**Get Service Role Key:**
- Supabase Dashboard → Settings → API → `service_role` (secret)

3. **Run SQL:**
```bash
# Copy-paste to SQL Editor dan run
```

**Verify trigger:**
```sql
SELECT trigger_name, event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'trigger_artwork_ai_detection';
```

---

## ✅ Testing

### **Test 1: Manual Edge Function Call**

```bash
curl -X POST \
  'https://vepmvxiddwmpetxfdwjn.supabase.co/functions/v1/detect-ai' \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "INSERT",
    "table": "artworks",
    "record": {
      "id": 999,
      "media_url": "https://example.com/test-image.jpg"
    }
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "result": {
    "artwork_id": 999,
    "score": 0.95,
    "is_ai_suspected": true,
    "timestamp": "2025-11-30T14:00:00.000Z"
  },
  "duration_ms": 1234
}
```

---

### **Test 2: Insert Artwork via App**

1. **Login sebagai Artist**
2. **Upload artwork baru**
3. **Check console logs** (Supabase Dashboard → Edge Functions → Logs)

**Expected logs:**
```
🤖 [AI Detector] Function invoked
🆔 Artwork ID: 123
🖼️ Media URL: https://...
🔍 Calling Sightengine API...
📊 Sightengine Response: {...}
🎯 AI Score: 0.850 (85.0%)
⚠️ AI SUSPECTED! Score 0.850 > 0.8
💾 Updating database...
✅ Database updated successfully
✨ Detection completed in 1234ms
```

---

### **Test 3: Check Database**

```sql
-- Get latest artwork with AI scores
SELECT 
  id,
  title,
  artist_name,
  ai_generated_score,
  is_ai_suspected,
  status,
  created_at
FROM public.artworks
ORDER BY created_at DESC
LIMIT 10;
```

**Expected:**
| id | title | ai_generated_score | is_ai_suspected |
|----|-------|-------------------|----------------|
| 123 | Test Art | 0.95 | true |
| 122 | Human Art | 0.12 | false |

---

### **Test 4: Check HTTP Logs**

```sql
-- Check pg_net requests
SELECT 
  id,
  created,
  status_code,
  content::text as response
FROM net._http_response
ORDER BY created DESC
LIMIT 5;
```

**Expected:**
- `status_code: 200`
- `response: {"success": true, ...}`

---

## 🎯 Configuration

### **AI Threshold (Default: 0.8)**

Edit `detect-ai/index.ts` line 43:
```typescript
const AI_THRESHOLD = 0.8; // 80% confidence
```

**Recommendations:**
- **Strict**: `0.7` (70%) - Lebih banyak flag AI
- **Balanced**: `0.8` (80%) - Default recommended
- **Lenient**: `0.9` (90%) - Hanya AI yang jelas

After edit, redeploy:
```bash
supabase functions deploy detect-ai
```

---

## 🔍 Monitoring

### **Check Edge Function Logs**

**Dashboard:**
```
Supabase Dashboard → Edge Functions → detect-ai → Logs
```

**CLI:**
```bash
supabase functions logs detect-ai
```

---

### **Check Detection Results**

```sql
-- AI suspected artworks
SELECT 
  COUNT(*) as total_ai_suspected,
  AVG(ai_generated_score) as avg_score
FROM public.artworks
WHERE is_ai_suspected = true;

-- Score distribution
SELECT 
  CASE 
    WHEN ai_generated_score >= 0.9 THEN 'Very High (>90%)'
    WHEN ai_generated_score >= 0.8 THEN 'High (80-90%)'
    WHEN ai_generated_score >= 0.5 THEN 'Medium (50-80%)'
    ELSE 'Low (<50%)'
  END as score_range,
  COUNT(*) as count
FROM public.artworks
WHERE ai_generated_score IS NOT NULL
GROUP BY score_range
ORDER BY score_range DESC;
```

---

## 🛠️ Troubleshooting

### **Problem 1: Trigger tidak jalan**

**Check:**
```sql
-- Verify trigger enabled
SELECT 
  tgenabled::int as status,
  CASE tgenabled::int
    WHEN 1 THEN '✅ Enabled'
    WHEN 0 THEN '❌ Disabled'
  END as status_text
FROM pg_trigger
WHERE tgname = 'trigger_artwork_ai_detection';
```

**Fix:**
```sql
ALTER TABLE public.artworks 
ENABLE TRIGGER trigger_artwork_ai_detection;
```

---

### **Problem 2: Edge Function error**

**Check logs:**
```bash
supabase functions logs detect-ai --tail
```

**Common errors:**

1. **Missing credentials:**
   ```
   ❌ Missing Sightengine credentials
   ```
   **Fix:** `supabase secrets set SIGHTENGINE_USER=...`

2. **Invalid media_url:**
   ```
   ❌ Sightengine API error: 400
   ```
   **Fix:** Pastikan URL gambar valid dan accessible

3. **Database update failed:**
   ```
   ❌ Database update failed
   ```
   **Fix:** Check RLS policies atau service role key

---

### **Problem 3: Sightengine API limit**

**Free tier:** 2,000 requests/month

**Check usage:**
- Dashboard: https://sightengine.com/dashboard

**Solutions:**
- Upgrade plan ($29/month = 10,000 requests)
- Only detect artworks with `status = 'pending'`
- Add daily limit di trigger

---

## 📊 Usage Examples

### **Get All AI Suspected Artworks**

```sql
SELECT 
  a.id,
  a.title,
  a.artist_name,
  a.ai_generated_score,
  a.is_ai_suspected,
  a.status,
  a.created_at
FROM public.artworks a
WHERE a.is_ai_suspected = true
ORDER BY a.ai_generated_score DESC;
```

---

### **Admin Review Queue**

```sql
-- Artworks yang perlu direview (AI suspected + pending)
SELECT 
  id,
  title,
  artist_name,
  ai_generated_score,
  media_url,
  created_at
FROM public.artworks
WHERE is_ai_suspected = true
  AND status = 'pending'
ORDER BY ai_generated_score DESC, created_at ASC;
```

---

### **Statistics**

```sql
-- Overall statistics
SELECT 
  COUNT(*) as total_artworks,
  COUNT(ai_generated_score) as analyzed,
  COUNT(CASE WHEN is_ai_suspected THEN 1 END) as ai_suspected,
  ROUND(AVG(ai_generated_score)::numeric, 3) as avg_score,
  ROUND(
    (COUNT(CASE WHEN is_ai_suspected THEN 1 END)::float / 
     NULLIF(COUNT(ai_generated_score), 0) * 100)::numeric, 
    1
  ) as ai_percentage
FROM public.artworks;
```

---

## 🔒 Security Notes

1. **Service Role Key** disimpan di database settings (encrypted)
2. **Sightengine API credentials** di Edge Function secrets (encrypted)
3. **Trigger** menggunakan `SECURITY DEFINER` untuk bypass RLS
4. **Edge Function** tidak exposed ke public (triggered via database only)

---

## 💰 Cost Estimation

**Sightengine Free Tier:**
- 2,000 requests/month = FREE
- ~66 artworks/day
- Perfect untuk testing & small scale

**Paid Plans:**
- **Starter**: $29/month = 10,000 requests
- **Pro**: $99/month = 50,000 requests
- **Enterprise**: Custom pricing

---

## 📚 References

- **Sightengine API Docs**: https://sightengine.com/docs/ai-generated-detection
- **Supabase Edge Functions**: https://supabase.com/docs/guides/functions
- **pg_net Extension**: https://supabase.com/docs/guides/database/extensions/pg_net

---

## ✅ Checklist

- [ ] Sign up Sightengine & get API credentials
- [ ] Deploy Edge Function (`supabase functions deploy detect-ai`)
- [ ] Set secrets (`SIGHTENGINE_USER`, `SIGHTENGINE_SECRET`)
- [ ] Run migration 1 (add columns)
- [ ] Edit migration 2 (set URL & service key)
- [ ] Run migration 2 (create trigger)
- [ ] Test manual Edge Function call
- [ ] Test artwork upload via app
- [ ] Verify database updates
- [ ] Monitor logs & errors

---

## 🎉 Done!

Fitur AI Art Detector sudah siap! Setiap artwork yang diupload akan otomatis dianalisis dan di-flag jika terdeteksi AI-generated (score > 80%).
