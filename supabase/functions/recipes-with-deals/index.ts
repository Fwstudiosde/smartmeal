import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Recipe Matcher - TypeScript Port
class RecipeMatcher {
  private supabase: any

  constructor(supabaseClient: any) {
    this.supabase = supabaseClient
  }

  // Meat/protein categories with exclusions
  private meatCategories: Record<string, string[]> = {
    'hähnchen': ['schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele'],
    'chicken': ['schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele', 'pork', 'beef'],
    'schwein': ['hähnchen', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
    'pork': ['hähnchen', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
    'rind': ['hähnchen', 'schwein', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
    'beef': ['hähnchen', 'schwein', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
    'pute': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
    'turkey': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
    'lachs': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'thun', 'garnele'],
    'salmon': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'thun', 'garnele', 'chicken'],
    'thun': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'garnele'],
    'tuna': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'garnele', 'chicken'],
  }

  hasConflictingTerms(productName: string, ingredientKeywords: string[]): boolean {
    const productLower = productName.toLowerCase()

    for (const ingKeyword of ingredientKeywords) {
      const ingLower = ingKeyword.toLowerCase()
      if (ingLower in this.meatCategories) {
        const exclusions = this.meatCategories[ingLower]
        for (const exclusion of exclusions) {
          if (productLower.includes(exclusion)) {
            return true
          }
        }
      }
    }

    return false
  }

  matchIngredientToDeals(
    ingredientName: string,
    keywords: Array<[string, number]>,
    deals: any[],
  ): Array<[any, number, number]> {
    const matches: Array<[any, number, number]> = []
    const keywordStrings = keywords.map(([kw]) => kw)

    for (const deal of deals) {
      const productName = (deal.product_name || '').toLowerCase()
      const description = (deal.description || '').toLowerCase()

      // Check for conflicting terms FIRST
      if (this.hasConflictingTerms(productName, keywordStrings)) {
        continue
      }

      let bestScore = 0
      let bestPriority = 0

      for (const [keyword, priority] of keywords) {
        const keywordLower = keyword.toLowerCase()

        // STRICT: ONLY exact substring matching
        if (keywordLower.length <= 2) {
          // Short keywords need word boundaries
          const pattern = new RegExp(`\\b${keywordLower.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`)
          if (pattern.test(productName)) {
            const score = 100
            if (score > bestScore || (score === bestScore && priority > bestPriority)) {
              bestScore = score
              bestPriority = priority
            }
          }
        } else {
          // Longer keywords use simple substring matching
          if (productName.includes(keywordLower)) {
            const score = 100
            if (score > bestScore || (score === bestScore && priority > bestPriority)) {
              bestScore = score
              bestPriority = priority
            }
          }
        }
      }

      if (bestScore > 0) {
        matches.push([deal, bestScore, bestPriority])
      }
    }

    // Sort by match score (descending)
    matches.sort((a, b) => b[1] - a[1])

    return matches
  }

  calculateRecipeScore(
    recipeIngredients: any[],
    matchedIngredients: Record<string, Array<[any, number, number]>>
  ): [number, any] {
    const totalIngredients = recipeIngredients.length
    const optionalIngredients = recipeIngredients.filter(ing => ing.is_optional).length
    const requiredIngredients = totalIngredients - optionalIngredients

    const matchedCount = Object.keys(matchedIngredients).length

    let priority3Matched = 0
    let priority2Matched = 0
    let priority1Matched = 0
    let totalMatchQuality = 0

    for (const [ingredientName, matches] of Object.entries(matchedIngredients)) {
      if (matches && matches.length > 0) {
        const [deal, matchScore, priority] = matches[0]

        if (priority === 3) {
          priority3Matched++
        } else if (priority === 2) {
          priority2Matched++
        } else {
          priority1Matched++
        }

        totalMatchQuality += priority * matchScore
      }
    }

    const coveragePercentage = totalIngredients > 0 ? (matchedCount / totalIngredients) * 100 : 0

    const priorityScore = (priority3Matched * 3) + (priority2Matched * 2) + (priority1Matched * 1)
    const coverageBonus = coveragePercentage / 10
    const qualityBonus = totalMatchQuality / 1000

    const overallScore = priorityScore + coverageBonus + qualityBonus

    const scoreBreakdown = {
      total_ingredients: totalIngredients,
      required_ingredients: requiredIngredients,
      optional_ingredients: optionalIngredients,
      matched_count: matchedCount,
      coverage_percentage: Math.round(coveragePercentage * 10) / 10,
      priority_3_matched: priority3Matched,
      priority_2_matched: priority2Matched,
      priority_1_matched: priority1Matched,
      priority_score: priorityScore,
      coverage_bonus: Math.round(coverageBonus * 10) / 10,
      quality_bonus: Math.round(qualityBonus * 10) / 10,
      overall_score: Math.round(overallScore * 100) / 100,
    }

    return [overallScore, scoreBreakdown]
  }

  async loadIngredientKeywords(): Promise<Record<string, Array<[string, number]>>> {
    const { data, error } = await this.supabase
      .from('ingredient_keywords')
      .select('ingredient_name, keyword, priority')

    if (error) throw error

    const keywordsMap: Record<string, Array<[string, number]>> = {}

    for (const row of data || []) {
      const ingredientName = row.ingredient_name
      if (!keywordsMap[ingredientName]) {
        keywordsMap[ingredientName] = []
      }
      keywordsMap[ingredientName].push([row.keyword, row.priority])
    }

    return keywordsMap
  }

  async loadRecipeIngredients(recipeId: string): Promise<any[]> {
    const { data, error } = await this.supabase
      .from('recipe_ingredients')
      .select('*')
      .eq('recipe_id', recipeId)
      .order('ingredient_order')

    if (error) throw error
    return data || []
  }

  async loadRecipeInstructions(recipeId: string): Promise<any[]> {
    const { data, error } = await this.supabase
      .from('recipe_instructions')
      .select('*')
      .eq('recipe_id', recipeId)
      .order('step_number')

    if (error) throw error
    return data || []
  }

  async matchRecipesWithDeals(
    deals: any[],
    minCoveragePercentage: number = 50.0,
    category?: string,
    limit?: number
  ): Promise<any[]> {
    // Load recipes
    let query = this.supabase
      .from('recipes')
      .select(`
        id, name, description, image_url, prep_time, cook_time,
        servings, difficulty, calories, protein, carbs, fat, fiber,
        created_at, updated_at, categories(name, name_de)
      `)

    if (category) {
      query = query.eq('categories.name', category)
    }

    if (limit) {
      query = query.limit(limit)
    }

    const { data: recipes, error: recipesError } = await query

    if (recipesError) throw recipesError

    const keywordsMap = await this.loadIngredientKeywords()
    const matchedRecipes = []

    for (const recipe of recipes || []) {
      const recipeId = recipe.id

      // Load recipe ingredients
      const ingredients = await this.loadRecipeIngredients(recipeId)

      if (!ingredients || ingredients.length === 0) {
        continue
      }

      // Match each ingredient to deals
      const matchedIngredients: Record<string, Array<[any, number, number]>> = {}

      for (const ingredient of ingredients) {
        const ingredientName = ingredient.ingredient_name

        // Get keywords for this ingredient
        const keywords = keywordsMap[ingredientName] || [[ingredientName, 1]]

        // Find matching deals
        const matches = this.matchIngredientToDeals(
          ingredientName,
          keywords,
          deals
        )

        if (matches && matches.length > 0) {
          matchedIngredients[ingredientName] = matches
        }
      }

      // Calculate score
      const [overallScore, scoreBreakdown] = this.calculateRecipeScore(
        ingredients,
        matchedIngredients
      )

      // Filter by minimum coverage
      if (scoreBreakdown.coverage_percentage >= minCoveragePercentage) {
        // Build matched deals list
        const matchedDeals = []
        for (const [ingredientName, matches] of Object.entries(matchedIngredients)) {
          if (matches && matches.length > 0) {
            const [deal, matchScore, priority] = matches[0]
            matchedDeals.push({
              ingredient_name: ingredientName,
              priority,
              match_score: matchScore,
              deal,
            })
          }
        }

        // Sort matched deals by priority
        matchedDeals.sort((a, b) => {
          if (b.priority !== a.priority) return b.priority - a.priority
          return b.match_score - a.match_score
        })

        // Transform category format
        const recipeData = {
          ...recipe,
          category: recipe.categories?.name,
          category_de: recipe.categories?.name_de,
        }
        delete recipeData.categories

        // Add full recipe details
        recipeData.ingredients = ingredients
        recipeData.instructions = await this.loadRecipeInstructions(recipeId)
        recipeData.matched_deals = matchedDeals
        recipeData.match_score = overallScore
        recipeData.score_breakdown = scoreBreakdown

        matchedRecipes.push(recipeData)
      }
    }

    // Sort by overall score (descending)
    matchedRecipes.sort((a, b) => b.match_score - a.match_score)

    return matchedRecipes
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get query parameters
    const url = new URL(req.url)
    const minCoverage = parseFloat(url.searchParams.get('min_coverage') || '0.5') * 100
    const category = url.searchParams.get('category') || undefined
    const limit = url.searchParams.get('limit') ? parseInt(url.searchParams.get('limit')!) : undefined

    // Create Supabase client with service role key
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Load current deals from database
    const { data: deals, error: dealsError } = await supabaseAdmin
      .from('deals')
      .select('*')
      .order('created_at', { ascending: false })

    if (dealsError) throw dealsError

    // Initialize matcher and match recipes
    const matcher = new RecipeMatcher(supabaseAdmin)
    const matchedRecipes = await matcher.matchRecipesWithDeals(
      deals || [],
      minCoverage,
      category,
      limit
    )

    return new Response(
      JSON.stringify({
        success: true,
        recipes: matchedRecipes,
        total: matchedRecipes.length,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})
