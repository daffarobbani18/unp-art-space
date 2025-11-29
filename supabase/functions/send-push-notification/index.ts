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

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get Firebase Server Key from environment
    const FIREBASE_SERVER_KEY = Deno.env.get('FIREBASE_SERVER_KEY')
    if (!FIREBASE_SERVER_KEY) {
      throw new Error('FIREBASE_SERVER_KEY not configured')
    }

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

    // Send push notification to each token
    const results = await Promise.allSettled(
      tokens.map(async ({ token, platform }) => {
        const fcmPayload = {
          to: token,
          notification: {
            title,
            body,
            sound: 'default',
            badge: '1',
          },
          data: {
            ...data,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          priority: 'high',
          content_available: true,
        }

        const response = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `key=${FIREBASE_SERVER_KEY}`,
          },
          body: JSON.stringify(fcmPayload),
        })

        const result = await response.json()

        // If token is invalid, mark it as inactive
        if (result.failure === 1 && result.results?.[0]?.error) {
          const error = result.results[0].error
          if (error === 'NotRegistered' || error === 'InvalidRegistration') {
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
          success: result.success === 1,
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
