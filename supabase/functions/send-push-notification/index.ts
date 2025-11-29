import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationPayload {
  user_id: string
  title: string
  body: string
  data?: Record<string, any>
}

interface ServiceAccount {
  project_id: string
  private_key: string
  client_email: string
}

// Function to get OAuth2 access token using Service Account
async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const jwtHeader = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  
  const now = Math.floor(Date.now() / 1000)
  const jwtClaimSet = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }
  const jwtClaimSetEncoded = btoa(JSON.stringify(jwtClaimSet))
  
  const signatureInput = `${jwtHeader}.${jwtClaimSetEncoded}`
  
  // Import private key for signing
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )
  
  // Sign the JWT
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signatureInput)
  )
  
  const jwtSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
  const jwt = `${signatureInput}.${jwtSignature}`
  
  // Exchange JWT for access token
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  
  const result = await response.json()
  return result.access_token
}

// Helper to convert PEM to ArrayBuffer
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const pemContents = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  
  const binaryString = atob(pemContents)
  const bytes = new Uint8Array(binaryString.length)
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }
  return bytes.buffer
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get Firebase Service Account from environment
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT not configured')
    }

    const serviceAccount: ServiceAccount = JSON.parse(serviceAccountJson)
    const projectId = serviceAccount.project_id

    // Parse request body
    const { user_id, title, body, data = {} }: NotificationPayload = await req.json()

    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get all active FCM tokens for this user
    const { data: tokens, error: tokensError } = await supabaseClient
      .from('fcm_tokens')
      .select('token, platform')
      .eq('user_id', user_id)
      .eq('is_active', true)

    if (tokensError) {
      console.error('Error fetching FCM tokens:', tokensError)
      throw tokensError
    }

    if (!tokens || tokens.length === 0) {
      console.log(`No FCM tokens found for user ${user_id}`)
      return new Response(
        JSON.stringify({ success: true, message: 'No devices to send to', sent: 0 }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    // Get OAuth2 access token
    const accessToken = await getAccessToken(serviceAccount)

    // Send push notification to each token using FCM API V1
    const results = await Promise.allSettled(
      tokens.map(async ({ token, platform }) => {
        // FCM API V1 payload format
        const fcmPayload = {
          message: {
            token: token,
            notification: {
              title: title,
              body: body,
            },
            data: {
              ...data,
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                channel_id: 'high_importance_channel',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                  'content-available': 1,
                },
              },
            },
          },
        }

        const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`
        
        const response = await fetch(fcmUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`,
          },
          body: JSON.stringify(fcmPayload),
        })

        const result = await response.json()

        // If token is invalid, mark it as inactive
        if (!response.ok && result.error) {
          const errorCode = result.error.details?.[0]?.errorCode || result.error.status
          if (errorCode === 'UNREGISTERED' || errorCode === 'INVALID_ARGUMENT') {
            await supabaseClient
              .from('fcm_tokens')
              .update({ is_active: false })
              .eq('token', token)
            
            console.log(`Marked token as inactive: ${token}`)
          }
        }

        return {
          token,
          platform,
          success: response.ok,
          result,
        }
      })
    )

    // Count successful sends
    const successCount = results.filter(
      (r) => r.status === 'fulfilled' && r.value.success
    ).length

    console.log(`Push notifications sent: ${successCount}/${tokens.length}`)

    return new Response(
      JSON.stringify({
        success: true,
        sent: successCount,
        total: tokens.length,
        results: results.map(r => r.status === 'fulfilled' ? r.value : { error: r.reason }),
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error('Error in send-push-notification function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
