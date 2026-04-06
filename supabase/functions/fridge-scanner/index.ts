// Fridge Scanner Edge Function
// Analyzes fridge images and generates recipes using OpenAI GPT-4o Vision API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import "https://deno.land/x/xhr@0.1.0/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AnalyzeImageRequest {
  image: string // base64 encoded image
}

interface GenerateRecipesRequest {
  ingredients: Array<{
    name: string
    category: string
    quantity: string
  }>
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

    const url = new URL(req.url)
    const path = url.pathname

    // Route: POST /fridge-scanner/analyze-image
    if (path.endsWith('/analyze-image') && req.method === 'POST') {
      const { image }: AnalyzeImageRequest = await req.json()

      if (!image) {
        return new Response(
          JSON.stringify({ error: 'Image data required' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Call OpenAI GPT-4o Vision API for image analysis
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
                  text: `Analysiere dieses Bild eines Kühlschranks oder einer Speisekammer und identifiziere alle sichtbaren Lebensmittel.

Antworte NUR mit einem JSON-Array in diesem Format:
[
  {"name": "Zutat", "category": "Kategorie", "quantity": "geschätzte Menge"},
  ...
]

Kategorien: dairy, meat, fish, vegetables, fruits, grains, spices, beverages, frozen, snacks, other`,
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

      // Extract ingredients from GPT-4o's response
      const messageContent = data.choices[0]?.message?.content
      if (!messageContent) {
        throw new Error('No response from OpenAI')
      }

      // Parse JSON from response (handle markdown code blocks)
      let ingredientsJson = messageContent
      const jsonMatch = messageContent.match(/```json\s*([\s\S]*?)\s*```/) ||
                       messageContent.match(/\[[\s\S]*\]/)

      if (jsonMatch) {
        ingredientsJson = jsonMatch[1] || jsonMatch[0]
      }

      let ingredients
      try {
        ingredients = JSON.parse(ingredientsJson)
      } catch (e) {
        console.error('Failed to parse ingredients JSON:', ingredientsJson)
        throw new Error('Failed to parse ingredients from OpenAI response')
      }

      return new Response(
        JSON.stringify({ ingredients }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Route: POST /fridge-scanner/generate-recipes
    if (path.endsWith('/generate-recipes') && req.method === 'POST') {
      const { ingredients }: GenerateRecipesRequest = await req.json()

      if (!ingredients || ingredients.length === 0) {
        return new Response(
          JSON.stringify({ error: 'Ingredients required' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Create ingredient list for prompt
      const ingredientList = ingredients
        .map(ing => `- ${ing.name} (${ing.quantity})`)
        .join('\n')

      // Call OpenAI GPT-4o for recipe generation
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
              content: `Generiere 3-5 kreative Rezepte basierend auf diesen verfügbaren Zutaten:

${ingredientList}

Antworte NUR mit einem JSON-Array in diesem Format:
[
  {
    "name": "Rezeptname",
    "description": "Kurze Beschreibung",
    "prepTime": 15,
    "cookTime": 30,
    "servings": 2,
    "difficulty": "Einfach|Mittel|Schwer",
    "ingredients": [
      {"name": "Zutat", "quantity": "Menge", "unit": "Einheit", "isAvailable": true}
    ],
    "instructions": ["Schritt 1", "Schritt 2"],
    "matchPercentage": 85.5,
    "tags": ["vegetarisch", "schnell"]
  }
]

Wichtig:
- Verwende hauptsächlich die verfügbaren Zutaten
- Markiere verfügbare Zutaten mit isAvailable: true
- Füge bei Bedarf wenige zusätzliche Grundzutaten hinzu (isAvailable: false)
- Berechne matchPercentage als Prozentsatz verfügbarer Zutaten
- Sortiere nach matchPercentage (höchste zuerst)
- Gib realistische Mengen und Einheiten an`,
            },
          ],
          max_tokens: 4096,
          temperature: 0.7,
        }),
      })

      if (!response.ok) {
        const errorData = await response.text()
        throw new Error(`OpenAI API error: ${response.status} - ${errorData}`)
      }

      const data = await response.json()

      // Extract recipes from GPT-4o's response
      const messageContent = data.choices[0]?.message?.content
      if (!messageContent) {
        throw new Error('No response from OpenAI')
      }

      // Parse JSON from response (handle markdown code blocks)
      let recipesJson = messageContent
      const jsonMatch = messageContent.match(/```json\s*([\s\S]*?)\s*```/) ||
                       messageContent.match(/\[[\s\S]*\]/)

      if (jsonMatch) {
        recipesJson = jsonMatch[1] || jsonMatch[0]
      }

      let recipes
      try {
        recipes = JSON.parse(recipesJson)
      } catch (e) {
        console.error('Failed to parse recipes JSON:', recipesJson)
        throw new Error('Failed to parse recipes from OpenAI response')
      }

      // Add placeholder images for each recipe
      const recipesWithImages = recipes.map((recipe: any) => {
        // Use Lorem Picsum for consistent placeholder images
        // Each recipe gets a unique seed based on its name for consistency
        const seed = Math.abs(recipe.name.split('').reduce((acc: number, char: string) => acc + char.charCodeAt(0), 0))
        const imageUrl = `https://picsum.photos/seed/${seed}/400/300`

        return {
          ...recipe,
          imageUrl,
        }
      })

      return new Response(
        JSON.stringify({ recipes: recipesWithImages }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Unknown route
    return new Response(
      JSON.stringify({ error: 'Not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
