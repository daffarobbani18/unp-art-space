// ============================================================================
// FCM Push Notification Edge Function - Modern & Robust Version
// ============================================================================
// Library: djwt untuk JWT generation (RS256)
// FCM API: V1 (OAuth2 Bearer Token)
// Auto-cleanup: Invalid tokens otomatis dihapus dari database
// ============================================================================

// deno-lint-ignore-file no-explicit-any
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { create } from "https://deno.land/x/djwt@v2.9.1/mod.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// ============================================================================
// CORS Headers
// ============================================================================
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TypeScript Interfaces
// ============================================================================
interface NotificationPayload {
  userId: string      // User ID yang akan terima notifikasi
  title: string       // Judul notifikasi
  body: string        // Isi notifikasi
  data?: Record<string, any>  // Data tambahan untuk navigation
}

interface ServiceAccount {
  type: string
  project_id: string
  private_key_id: string
  private_key: string
  client_email: string
  client_id: string
  auth_uri: string
  token_uri: string
  auth_provider_x509_cert_url: string
  client_x509_cert_url: string
}

interface FCMToken {
  id: string
  token: string
  platform: string
  device_id?: string
}

interface FCMResponse {
  name?: string
  error?: {
    code: number
    message: string
    status: string
    details?: Array<{
      '@type': string
      errorCode?: string
    }>
  }
}

// ============================================================================
// Generate Google OAuth2 Access Token using djwt
// ============================================================================
async function getGoogleAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  console.log('🔐 Generating OAuth2 access token...')
  console.log(`📧 Service Account: ${serviceAccount.client_email}`)
  
  const now = Math.floor(Date.now() / 1000)
  
  // JWT payload untuk Google OAuth2
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,  // Expire dalam 1 jam
    iat: now,
  }

  // Import private key dari PEM format
  const privateKeyPEM = serviceAccount.private_key
  const pemHeader = '-----BEGIN PRIVATE KEY-----'
  const pemFooter = '-----END PRIVATE KEY-----'
  const pemContents = privateKeyPEM
    .replace(pemHeader, '')
    .replace(pemFooter, '')
    .replace(/\s/g, '')

  // Convert base64 PEM ke binary
  const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))

  // Import key untuk signing
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer.buffer,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign']
  )

  // Create JWT menggunakan djwt
  const jwt = await create(
    { alg: 'RS256', typ: 'JWT' },
    payload,
    privateKey
  )

  console.log('✅ JWT created successfully')

  // Exchange JWT untuk access token
  console.log('🔄 Exchanging JWT for access token...')
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text()
    console.error('❌ OAuth2 token exchange failed:', tokenResponse.status, errorText)
    throw new Error(`Failed to get access token: ${tokenResponse.status} ${errorText}`)
  }

  const tokenData = await tokenResponse.json()
  console.log('✅ OAuth2 access token obtained successfully')
  
  return tokenData.access_token
}

// ============================================================================
// Send FCM Message dengan FCM API V1
// ============================================================================
async function sendFCMMessage(
  accessToken: string,
  projectId: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, any>
): Promise<{ success: boolean; response: FCMResponse; token: string }> {
  
  // FCM API V1 Payload
  const payload = {
    message: {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        // Convert all data values to string (FCM requirement)
        ...Object.fromEntries(
          Object.entries(data).map(([key, value]) => [
            key,
            typeof value === 'string' ? value : JSON.stringify(value)
          ])
        ),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',  // PENTING: High priority untuk heads-up notification
        notification: {
          sound: 'default',
          channel_id: 'high_importance_channel',  // Match dengan Flutter channel
          default_sound: true,
          default_vibrate_timings: true,
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',  // High priority untuk iOS
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            'content-available': 1,
            alert: {
              title: title,
              body: body,
            },
          },
        },
      },
    },
  }

  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`
  
  console.log(`📤 Sending to FCM token: ${fcmToken.substring(0, 20)}...`)
  
  const response = await fetch(fcmUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`,
    },
    body: JSON.stringify(payload),
  })

  const responseData: FCMResponse = await response.json()

  // Log detail jika gagal (DETEKTIF MODE)
  if (!response.ok) {
    console.error('❌ FCM API Error Response:', {
      status: response.status,
      statusText: response.statusText,
      body: responseData,
      token: fcmToken.substring(0, 30) + '...',
    })
  } else {
    console.log(`✅ FCM message sent successfully: ${responseData.name}`)
  }

  return {
    success: response.ok,
    response: responseData,
    token: fcmToken,
  }
}

// ============================================================================
// Main Serve Handler
// ============================================================================
serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const startTime = Date.now()
  console.log('\n' + '='.repeat(70))
  console.log('🚀 Push Notification Request Received')
  console.log('='.repeat(70))

  try {
    // ========================================================================
    // 1. LOAD FIREBASE SERVICE ACCOUNT
    // ========================================================================
    console.log('\n📋 Step 1: Loading Firebase Service Account...')
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    
    if (!serviceAccountJson) {
      console.error('❌ FIREBASE_SERVICE_ACCOUNT environment variable not set!')
      throw new Error('FIREBASE_SERVICE_ACCOUNT not configured')
    }

    const serviceAccount: ServiceAccount = JSON.parse(serviceAccountJson)
    const projectId = serviceAccount.project_id
    console.log(`✅ Service Account loaded for project: ${projectId}`)

    // ========================================================================
    // 2. PARSE REQUEST BODY
    // ========================================================================
    console.log('\n📋 Step 2: Parsing request body...')
    const requestBody: NotificationPayload = await req.json()
    const { userId, title, body, data = {} } = requestBody
    
    console.log('📬 Notification Details:')
    console.log(`   User ID: ${userId}`)
    console.log(`   Title: ${title}`)
    console.log(`   Body: ${body}`)
    console.log(`   Data: ${JSON.stringify(data)}`)

    // ========================================================================
    // 3. INITIALIZE SUPABASE CLIENT
    // ========================================================================
    console.log('\n📋 Step 3: Initializing Supabase client...')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Supabase credentials not configured')
    }

    const supabase = createClient(supabaseUrl, supabaseKey)
    console.log('✅ Supabase client initialized')

    // ========================================================================
    // 4. FETCH FCM TOKENS FROM DATABASE
    // ========================================================================
    console.log('\n📋 Step 4: Fetching FCM tokens from database...')
    const { data: tokens, error: tokensError } = await supabase
      .from('fcm_tokens')
      .select('id, token, platform, device_id')
      .eq('user_id', userId)
      .eq('is_active', true)

    if (tokensError) {
      console.error('❌ Database error:', tokensError)
      throw tokensError
    }

    if (!tokens || tokens.length === 0) {
      console.log('⚠️  No active FCM tokens found for this user')
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'No devices registered for this user',
          sent: 0,
          total: 0,
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      )
    }

    console.log(`✅ Found ${tokens.length} active token(s)`)
    tokens.forEach((t: FCMToken, idx: number) => {
      console.log(`   ${idx + 1}. Platform: ${t.platform}, Device: ${t.device_id || 'N/A'}`)
    })

    // ========================================================================
    // 5. GENERATE OAUTH2 ACCESS TOKEN
    // ========================================================================
    console.log('\n📋 Step 5: Generating OAuth2 access token...')
    const accessToken = await getGoogleAccessToken(serviceAccount)

    // ========================================================================
    // 6. SEND PUSH NOTIFICATIONS
    // ========================================================================
    console.log('\n📋 Step 6: Sending push notifications...')
    console.log(`📤 Sending to ${tokens.length} device(s)...`)

    const sendPromises = tokens.map((tokenData: FCMToken) =>
      sendFCMMessage(
        accessToken,
        projectId,
        tokenData.token,
        title,
        body,
        data
      ).then(result => ({ ...result, tokenId: tokenData.id }))
    )

    const results = await Promise.allSettled(sendPromises)

    // ========================================================================
    // 7. PROCESS RESULTS & AUTO-CLEANUP
    // ========================================================================
    console.log('\n📋 Step 7: Processing results & cleanup...')
    
    let successCount = 0
    let failedCount = 0
    const tokensToDelete: string[] = []

    for (const result of results) {
      if (result.status === 'fulfilled') {
        const { success, response, token, tokenId } = result.value

        if (success) {
          successCount++
        } else {
          failedCount++
          
          // Check error code untuk auto-cleanup
          const errorCode = response.error?.details?.[0]?.errorCode || 
                           response.error?.status

          console.log(`❌ Failed for token ...${token.substring(token.length - 20)}`)
          console.log(`   Error: ${errorCode} - ${response.error?.message}`)

          // Auto-delete invalid tokens
          if (errorCode === 'UNREGISTERED' || 
              errorCode === 'INVALID_ARGUMENT' ||
              response.error?.status === 'INVALID_ARGUMENT') {
            
            console.log(`🗑️  Marking token as invalid (will be deleted)`)
            tokensToDelete.push(tokenId)
          }
        }
      } else {
        failedCount++
        console.error('❌ Promise rejected:', result.reason)
      }
    }

    // Delete invalid tokens dari database
    if (tokensToDelete.length > 0) {
      console.log(`\n🗑️  Deleting ${tokensToDelete.length} invalid token(s) from database...`)
      
      const { error: deleteError } = await supabase
        .from('fcm_tokens')
        .delete()
        .in('id', tokensToDelete)

      if (deleteError) {
        console.error('❌ Error deleting tokens:', deleteError)
      } else {
        console.log(`✅ Successfully deleted ${tokensToDelete.length} invalid token(s)`)
      }
    }

    // ========================================================================
    // 8. RETURN RESPONSE
    // ========================================================================
    const duration = Date.now() - startTime
    console.log('\n' + '='.repeat(70))
    console.log('📊 SUMMARY')
    console.log('='.repeat(70))
    console.log(`✅ Success: ${successCount}/${tokens.length}`)
    console.log(`❌ Failed: ${failedCount}/${tokens.length}`)
    console.log(`🗑️  Cleaned up: ${tokensToDelete.length} invalid token(s)`)
    console.log(`⏱️  Duration: ${duration}ms`)
    console.log('='.repeat(70) + '\n')

    return new Response(
      JSON.stringify({
        success: true,
        sent: successCount,
        failed: failedCount,
        total: tokens.length,
        cleaned: tokensToDelete.length,
        duration: `${duration}ms`,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('\n' + '='.repeat(70))
    console.error('💥 FATAL ERROR')
    console.error('='.repeat(70))
    console.error(error)
    console.error('='.repeat(70) + '\n')

    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    const errorStack = error instanceof Error ? error.stack : undefined

    return new Response(
      JSON.stringify({ 
        success: false,
        error: errorMessage,
        details: errorStack,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})
