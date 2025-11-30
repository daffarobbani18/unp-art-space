// =============================================================================
// SUPABASE EDGE FUNCTION: detect-ai
// =============================================================================
// Purpose: Detect AI-generated artwork using Sightengine API
// Trigger: Database webhook after artwork INSERT
// API: https://sightengine.com/docs/ai-generated-detection

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

// =============================================================================
// TYPES
// =============================================================================

interface RequestPayload {
  type: string;
  table: string;
  record: ArtworkRecord;
  schema: string;
  old_record?: ArtworkRecord | null;
}

interface ArtworkRecord {
  id: number;
  media_url: string;
  title?: string;
  artist_id?: string;
  artist_name?: string;
}

interface SightengineResponse {
  status: string;
  request: {
    id: string;
    timestamp: number;
    operations: number;
  };
  type: {
    ai_generated: number; // Score 0.0 - 1.0
  };
  media?: {
    uri: string;
  };
}

interface DetectionResult {
  artwork_id: number;
  score: number;
  is_ai_suspected: boolean;
  timestamp: string;
}

// =============================================================================
// CONSTANTS
// =============================================================================

const AI_THRESHOLD = 0.8; // 80% confidence = AI suspected
const SIGHTENGINE_API_URL = 'https://api.sightengine.com/1.0/check.json';

// =============================================================================
// MAIN HANDLER
// =============================================================================

serve(async (req: Request) => {
  const startTime = Date.now();

  try {
    // Step 1: Parse request
    console.log('🤖 [AI Detector] Function invoked');
    const payload: RequestPayload = await req.json();

    console.log(`📝 Table: ${payload.table}`);
    console.log(`🆔 Artwork ID: ${payload.record.id}`);
    console.log(`🖼️ Media URL: ${payload.record.media_url}`);

    // Step 2: Validate payload
    if (!payload.record?.id || !payload.record?.media_url) {
      console.error('❌ Invalid payload: missing id or media_url');
      return new Response(
        JSON.stringify({
          error: 'Invalid payload',
          details: 'Record must contain id and media_url',
        }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    // Step 3: Get environment variables
    const sightengineUser = Deno.env.get('SIGHTENGINE_USER');
    const sightengineSecret = Deno.env.get('SIGHTENGINE_SECRET');
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!sightengineUser || !sightengineSecret) {
      console.error('❌ Missing Sightengine credentials in environment');
      return new Response(
        JSON.stringify({
          error: 'Configuration error',
          details: 'SIGHTENGINE_USER or SIGHTENGINE_SECRET not set',
        }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('❌ Missing Supabase credentials');
      return new Response(
        JSON.stringify({
          error: 'Configuration error',
          details: 'SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set',
        }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    // Step 4: Call Sightengine API
    console.log('🔍 Calling Sightengine API...');

    const sightengineUrl = new URL(SIGHTENGINE_API_URL);
    sightengineUrl.searchParams.set('models', 'genai');
    sightengineUrl.searchParams.set('url', payload.record.media_url);
    sightengineUrl.searchParams.set('api_user', sightengineUser);
    sightengineUrl.searchParams.set('api_secret', sightengineSecret);

    const apiResponse = await fetch(sightengineUrl.toString(), {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    if (!apiResponse.ok) {
      const errorText = await apiResponse.text();
      console.error(`❌ Sightengine API error: ${apiResponse.status}`);
      console.error(`Response: ${errorText}`);

      return new Response(
        JSON.stringify({
          error: 'Sightengine API failed',
          status: apiResponse.status,
          details: errorText,
        }),
        {
          status: 502,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    const sightengineData: SightengineResponse = await apiResponse.json();
    console.log(`📊 Sightengine Response: ${JSON.stringify(sightengineData)}`);

    // Step 5: Extract AI score
    const aiScore = sightengineData.type?.ai_generated;

    if (typeof aiScore !== 'number') {
      console.error('❌ Invalid Sightengine response: missing ai_generated score');
      return new Response(
        JSON.stringify({
          error: 'Invalid API response',
          details: 'Missing type.ai_generated in response',
          response: sightengineData,
        }),
        {
          status: 502,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    console.log(`🎯 AI Score: ${aiScore.toFixed(3)} (${(aiScore * 100).toFixed(1)}%)`);

    // Step 6: Determine if AI suspected
    const isAiSuspected = aiScore > AI_THRESHOLD;

    if (isAiSuspected) {
      console.log(`⚠️ AI SUSPECTED! Score ${aiScore.toFixed(3)} > ${AI_THRESHOLD}`);
    } else {
      console.log(`✅ Likely human-made (score ${aiScore.toFixed(3)} ≤ ${AI_THRESHOLD})`);
    }

    // Step 7: Update database
    console.log('💾 Updating database...');

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const { data: updateData, error: updateError } = await supabase
      .from('artworks')
      .update({
        ai_generated_score: aiScore,
        is_ai_suspected: isAiSuspected,
      })
      .eq('id', payload.record.id)
      .select();

    if (updateError) {
      console.error('❌ Database update failed:', updateError);
      return new Response(
        JSON.stringify({
          error: 'Database update failed',
          details: updateError.message,
          code: updateError.code,
        }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    console.log('✅ Database updated successfully');
    console.log(`Updated data: ${JSON.stringify(updateData)}`);

    // Step 8: Return success
    const result: DetectionResult = {
      artwork_id: payload.record.id,
      score: aiScore,
      is_ai_suspected: isAiSuspected,
      timestamp: new Date().toISOString(),
    };

    const duration = Date.now() - startTime;
    console.log(`✨ Detection completed in ${duration}ms`);

    return new Response(
      JSON.stringify({
        success: true,
        result,
        duration_ms: duration,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );

  } catch (error) {
    console.error('❌ Unexpected error:', error);

    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error',
        stack: error instanceof Error ? error.stack : undefined,
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
});

// =============================================================================
// NOTES
// =============================================================================
/*
Required Environment Variables:
- SIGHTENGINE_USER: Your Sightengine API user
- SIGHTENGINE_SECRET: Your Sightengine API secret
- SUPABASE_URL: Your Supabase project URL (auto-set)
- SUPABASE_SERVICE_ROLE_KEY: Service role key (auto-set)

Sightengine API Response Example:
{
  "status": "success",
  "request": {
    "id": "req_abc123",
    "timestamp": 1701360000,
    "operations": 1
  },
  "type": {
    "ai_generated": 0.95  // Score 0.0 - 1.0
  },
  "media": {
    "uri": "https://..."
  }
}

Detection Logic:
- Score > 0.8 (80%) → is_ai_suspected = true
- Score ≤ 0.8 (80%) → is_ai_suspected = false

Usage:
1. Deploy: supabase functions deploy detect-ai
2. Set secrets: 
   supabase secrets set SIGHTENGINE_USER=your_user
   supabase secrets set SIGHTENGINE_SECRET=your_secret
3. Test: curl -X POST https://PROJECT.supabase.co/functions/v1/detect-ai \
          -H "Authorization: Bearer SERVICE_KEY" \
          -d '{"record":{"id":123,"media_url":"https://..."}}'
*/
