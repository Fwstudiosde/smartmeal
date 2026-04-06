// Deal Extraction Edge Function
// Extracts deal information from prospectus PDFs/images using OpenAI GPT-4o Vision API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import "https://deno.land/x/xhr@0.1.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ExtractDealsRequest {
  image: string // base64 encoded image
  storeName: string
  validFrom?: string // ISO date format
  validUntil?: string // ISO date format
}

interface Deal {
  product_name: string
  original_price: number
  discount_price: number
  discount_percentage: number
  valid_from: string
  valid_until: string
  category: string
  description: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      throw new Error('OPENAI_API_KEY not configured')
    }

    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { image, storeName, validFrom, validUntil }: ExtractDealsRequest = await req.json()

    if (!image || !storeName) {
      return new Response(
        JSON.stringify({ error: 'Image and storeName required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Calculate default dates if not provided
    const today = new Date()
    const defaultValidFrom = validFrom || today.toISOString().split('T')[0]
    const defaultValidUntil = validUntil || new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]

    // Call OpenAI GPT-4o Vision API for deal extraction
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiApiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: `Analysiere dieses Supermarkt-Prospekt von ${storeName} und extrahiere ALLE Angebote.

Für jedes Angebot, extrahiere:
- product_name: Name des Produkts
- original_price: Originalpreis (falls sichtbar, sonst berechne aus Rabatt)
- discount_price: Angebotspreis
- discount_percentage: Rabatt in Prozent
- valid_from: Gültig ab (Format: YYYY-MM-DD, falls nicht sichtbar nutze ${defaultValidFrom})
- valid_until: Gültig bis (Format: YYYY-MM-DD, falls nicht sichtbar nutze ${defaultValidUntil})
- category: Kategorie (Fleisch & Wurst, Obst & Gemüse, Milchprodukte, Getränke, Backwaren, Tiefkühlprodukte, oder Sonstiges)
- description: Kurze Beschreibung mit allen Details (Marke, Menge, etc.)

Wichtig:
- Extrahiere NUR die tatsächlichen Angebote/Rabatte, keine regulären Produkte
- Achte auf Prozentangaben, durchgestrichene Preise oder "statt"-Preise
- Wenn nur ein Preis sichtbar ist, versuche aus dem Rabatt den Originalpreis zu berechnen
- Gib die Daten als JSON-Array zurück

Antworte NUR mit einem JSON-Array in diesem Format:
[
  {
    "product_name": "Produktname",
    "original_price": 4.99,
    "discount_price": 2.99,
    "discount_percentage": 40,
    "valid_from": "${defaultValidFrom}",
    "valid_until": "${defaultValidUntil}",
    "category": "Kategorie",
    "description": "Beschreibung mit Details"
  }
]`,
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:image/jpeg;base64,${image}`,
                },
              },
            ],
          },
        ],
        max_tokens: 4096,
        temperature: 0.1,
      }),
    })

    if (!response.ok) {
      const errorData = await response.text()
      throw new Error(`OpenAI API error: ${response.status} - ${errorData}`)
    }

    const data = await response.json()

    // Extract deals from GPT-4o's response
    const messageContent = data.choices[0]?.message?.content
    if (!messageContent) {
      throw new Error('No response from OpenAI')
    }

    // Parse JSON from response (handle markdown code blocks)
    let dealsJson = messageContent
    const jsonMatch = messageContent.match(/```json\s*([\s\S]*?)\s*```/) ||
                     messageContent.match(/\[[\s\S]*\]/)

    if (jsonMatch) {
      dealsJson = jsonMatch[1] || jsonMatch[0]
    }

    let deals: Deal[]
    try {
      deals = JSON.parse(dealsJson)
    } catch (e) {
      console.error('Failed to parse deals JSON:', dealsJson)
      throw new Error('Failed to parse deals from OpenAI response')
    }

    // Validate and normalize deals
    const validatedDeals = deals.map(deal => ({
      product_name: deal.product_name || 'Unbekanntes Produkt',
      original_price: Number(deal.original_price) || 0,
      discount_price: Number(deal.discount_price) || 0,
      discount_percentage: Number(deal.discount_percentage) || 0,
      valid_from: deal.valid_from || defaultValidFrom,
      valid_until: deal.valid_until || defaultValidUntil,
      category: deal.category || 'Sonstiges',
      description: deal.description || '',
    }))

    return new Response(
      JSON.stringify({
        success: true,
        store_name: storeName,
        deals: validatedDeals,
        count: validatedDeals.length,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
