// Rate Limit Monitor Edge Function
// Serves rate limit event data for the monitoring dashboard
// Deploy: supabase functions deploy rate-limit-monitor --project-ref qzlnlwwrnmvqdxnqdief

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RateLimitEvent {
  id: string
  api_name: string
  endpoint: string
  call_count: number
  session_duration_seconds: number
  calls_per_minute: number
  device_model: string | null
  app_version: string | null
  timestamp: string
  created_at: string
}

interface HourlyStat {
  hour: string
  count: number
  api_name: string
}

interface ApiStat {
  api_name: string
  total_events: number
  avg_calls_per_minute: number
  max_calls_per_minute: number
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client with service role (for reading all events)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const url = new URL(req.url)
    const timeRange = url.searchParams.get('range') || '24h'

    // Calculate time filter
    let hoursAgo: number
    switch (timeRange) {
      case '1h': hoursAgo = 1; break
      case '6h': hoursAgo = 6; break
      case '24h': hoursAgo = 24; break
      case '7d': hoursAgo = 168; break
      case '30d': hoursAgo = 720; break
      default: hoursAgo = 24
    }

    const sinceTime = new Date(Date.now() - hoursAgo * 60 * 60 * 1000).toISOString()

    // Fetch recent events
    const { data: recentEvents, error: eventsError } = await supabase
      .from('api_rate_limit_events')
      .select('*')
      .gte('timestamp', sinceTime)
      .order('timestamp', { ascending: false })
      .limit(100)

    if (eventsError) {
      throw new Error(`Failed to fetch events: ${eventsError.message}`)
    }

    // Calculate stats by API
    const { data: apiStats, error: statsError } = await supabase
      .rpc('get_rate_limit_stats', { since_time: sinceTime })
      .select('*')

    // Fallback: calculate stats in-memory if RPC doesn't exist
    let stats: ApiStat[] = []
    if (statsError || !apiStats) {
      // Group by API name and calculate stats
      const byApi: Record<string, RateLimitEvent[]> = {}
      for (const event of (recentEvents || [])) {
        if (!byApi[event.api_name]) byApi[event.api_name] = []
        byApi[event.api_name].push(event)
      }

      stats = Object.entries(byApi).map(([apiName, events]) => ({
        api_name: apiName,
        total_events: events.length,
        avg_calls_per_minute: events.reduce((sum, e) => sum + e.calls_per_minute, 0) / events.length,
        max_calls_per_minute: Math.max(...events.map(e => e.calls_per_minute))
      }))
    } else {
      stats = apiStats
    }

    // Calculate hourly distribution
    const hourlyBuckets: Record<string, Record<string, number>> = {}
    for (const event of (recentEvents || [])) {
      const hour = new Date(event.timestamp).toISOString().slice(0, 13) + ':00:00Z'
      if (!hourlyBuckets[hour]) hourlyBuckets[hour] = {}
      if (!hourlyBuckets[hour][event.api_name]) hourlyBuckets[hour][event.api_name] = 0
      hourlyBuckets[hour][event.api_name]++
    }

    const hourlyStats: HourlyStat[] = []
    for (const [hour, apis] of Object.entries(hourlyBuckets)) {
      for (const [apiName, count] of Object.entries(apis)) {
        hourlyStats.push({ hour, api_name: apiName, count })
      }
    }
    hourlyStats.sort((a, b) => a.hour.localeCompare(b.hour))

    // Calculate summary
    const totalEvents = recentEvents?.length || 0
    const coinGeckoEvents = recentEvents?.filter(e => e.api_name === 'CoinGecko').length || 0
    const geckoTerminalEvents = recentEvents?.filter(e => e.api_name === 'GeckoTerminal').length || 0

    // Get unique app versions
    const appVersions = [...new Set(recentEvents?.map(e => e.app_version).filter(Boolean))]

    // Get unique device models
    const deviceModels = [...new Set(recentEvents?.map(e => e.device_model).filter(Boolean))]

    const response = {
      timeRange,
      summary: {
        totalEvents,
        coinGeckoEvents,
        geckoTerminalEvents,
        uniqueAppVersions: appVersions.length,
        uniqueDevices: deviceModels.length,
      },
      apiStats: stats,
      hourlyStats,
      recentEvents: recentEvents?.slice(0, 50) || [],
      appVersions,
      deviceModels,
      generatedAt: new Date().toISOString()
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    })

  } catch (error) {
    console.error('Rate limit monitor error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500
    })
  }
})
