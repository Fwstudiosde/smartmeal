// Admin Verification Edge Function
// Verifies admin credentials for second-factor authentication

/// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AdminVerifyRequest {
  email: string
  password: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, password }: AdminVerifyRequest = await req.json()

    if (!email || !password) {
      return new Response(
        JSON.stringify({ error: 'Email and password required', verified: false }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Admin credentials (hardcoded for security - only accessible server-side)
    const ADMIN_EMAIL = 'accounts@fwstudios.de'
    const ADMIN_PASSWORD = 'Lian0302!'

    // Verify credentials
    if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
      return new Response(
        JSON.stringify({ verified: true, message: 'Admin verification successful' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    } else {
      return new Response(
        JSON.stringify({ verified: false, error: 'Invalid admin credentials' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message, verified: false }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
