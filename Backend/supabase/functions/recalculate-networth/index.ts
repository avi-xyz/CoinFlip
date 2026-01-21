// Supabase Edge Function: Recalculate Net Worth for All Users
// Schedule: Every 1 hour via Supabase cron
// Purpose: Keep leaderboard accurate for ALL users (active + inactive)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface Holding {
  id: string
  coin_id: string
  coin_symbol: string
  quantity: number
  average_buy_price: number
  portfolio_id: string
  chain_id: string | null
}

interface Portfolio {
  id: string
  user_id: string
  cash_balance: number
  starting_balance: number
}

interface CoinPrice {
  [coinId: string]: number
}

serve(async (req) => {
  try {
    const startTime = Date.now()

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    console.log('🔄 Starting net worth recalculation...')

    // Step 1: Fetch all portfolios
    const { data: portfolios, error: portfoliosError } = await supabase
      .from('portfolios')
      .select('id, user_id, cash_balance, starting_balance')

    if (portfoliosError) throw portfoliosError
    console.log(`📊 Found ${portfolios.length} portfolios`)

    // Step 2: Fetch all holdings WITH average_buy_price for fallback
    const { data: holdings, error: holdingsError } = await supabase
      .from('holdings')
      .select('id, portfolio_id, coin_id, coin_symbol, quantity, average_buy_price, chain_id')

    if (holdingsError) throw holdingsError
    console.log(`💎 Found ${holdings.length} holdings`)

    // Step 3: Get unique coins
    const uniqueCoins = [...new Set(holdings.map(h => h.coin_id))]
    console.log(`🪙 Fetching prices for ${uniqueCoins.length} unique coins...`)

    // Step 4: Try GeckoTerminal for viral coins (contract addresses with chainId)
    const coinPrices: CoinPrice = {}
    const viralHoldings = holdings.filter(h => h.chain_id !== null)

    for (const holding of viralHoldings) {
      try {
        const response = await fetch(
          `https://api.geckoterminal.com/api/v2/networks/${holding.chain_id}/tokens/${holding.coin_id}`,
          {
            headers: {
              'Accept': 'application/json',
            }
          }
        )

        if (response.ok) {
          const data = await response.json()
          const priceUsd = parseFloat(data?.data?.attributes?.price_usd || '0')

          if (priceUsd > 0) {
            coinPrices[holding.coin_id] = priceUsd
            console.log(`   ✅ GeckoTerminal: ${holding.coin_symbol} = $${priceUsd}`)
          }
        }
      } catch (error) {
        console.log(`   ⚠️ GeckoTerminal failed for ${holding.coin_symbol}:`, error.message)
      }
    }

    // Step 5: Fetch remaining prices from CoinGecko (batched)
    const missingCoins = uniqueCoins.filter(id => !coinPrices[id])
    const batchSize = 50

    for (let i = 0; i < missingCoins.length; i += batchSize) {
      const batch = missingCoins.slice(i, i + batchSize)
      const ids = batch.join(',')

      try {
        const response = await fetch(
          `https://api.coingecko.com/api/v3/simple/price?ids=${ids}&vs_currencies=usd`,
          {
            headers: {
              'Accept': 'application/json',
            }
          }
        )

        if (response.ok) {
          const data = await response.json()

          // Map prices
          for (const [coinId, priceData] of Object.entries(data)) {
            const price = (priceData as any).usd || 0
            if (price > 0) {
              coinPrices[coinId] = price
            }
          }
        }
      } catch (error) {
        console.error(`⚠️ Failed to fetch batch ${i}-${i+batchSize}:`, error)
      }
    }

    console.log(`💰 Fetched ${Object.keys(coinPrices).length} prices from APIs`)

    // Step 6: Calculate net worth for each portfolio
    const updates = portfolios.map((portfolio: Portfolio) => {
      const portfolioHoldings = holdings.filter(h => h.portfolio_id === portfolio.id)

      const holdingsValue = portfolioHoldings.reduce((total, holding) => {
        // Try to get price from APIs, fallback to purchase price
        let price = coinPrices[holding.coin_id]

        if (!price || price === 0) {
          // Use purchase price as fallback
          price = holding.average_buy_price
          console.log(`   💡 Using purchase price for ${holding.coin_symbol}: $${price}`)
        }

        return total + (holding.quantity * price)
      }, 0)

      const netWorth = portfolio.cash_balance + holdingsValue
      const gainPercentage = portfolio.starting_balance > 0
        ? ((netWorth - portfolio.starting_balance) / portfolio.starting_balance) * 100
        : 0

      return {
        id: portfolio.id,
        net_worth: netWorth,
        gain_percentage: gainPercentage,
        last_networth_update: new Date().toISOString()
      }
    })

    // Step 7: Batch update portfolios
    console.log(`📝 Updating ${updates.length} portfolios...`)

    // Update in batches to avoid timeout
    const updateBatchSize = 100
    let updatedCount = 0

    for (let i = 0; i < updates.length; i += updateBatchSize) {
      const batch = updates.slice(i, i + updateBatchSize)

      for (const update of batch) {
        const { error } = await supabase
          .from('portfolios')
          .update({
            net_worth: update.net_worth,
            gain_percentage: update.gain_percentage,
            last_networth_update: update.last_networth_update
          })
          .eq('id', update.id)

        if (!error) {
          updatedCount++
        } else {
          console.error(`❌ Failed to update portfolio ${update.id}:`, error)
        }
      }
    }

    const duration = Date.now() - startTime

    console.log(`✅ Recalculation complete!`)
    console.log(`   Updated: ${updatedCount}/${portfolios.length} portfolios`)
    console.log(`   Duration: ${duration}ms`)

    return new Response(
      JSON.stringify({
        success: true,
        portfolios_updated: updatedCount,
        portfolios_total: portfolios.length,
        unique_coins: uniqueCoins.length,
        prices_fetched: Object.keys(coinPrices).length,
        duration_ms: duration
      }),
      {
        headers: { 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('❌ Fatal error:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  }
})
