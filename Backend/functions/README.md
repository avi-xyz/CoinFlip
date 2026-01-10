# Supabase Edge Functions

This folder contains Supabase Edge Functions - serverless TypeScript/JavaScript functions that run on the edge.

## What are Edge Functions?

Edge Functions are server-side TypeScript functions that run close to your users globally. They're perfect for:
- Complex business logic
- API integrations (e.g., fetching crypto prices)
- Data transformations
- Webhook handlers
- Scheduled tasks

## Structure

Each function is in its own folder:

```
functions/
  ├── fetch-crypto-prices/
  │   ├── index.ts
  │   └── README.md
  ├── calculate-leaderboard/
  │   ├── index.ts
  │   └── README.md
  └── send-notifications/
      ├── index.ts
      └── README.md
```

## Potential Functions for CoinFlip

### fetch-crypto-prices
- Fetch real-time prices from CoinGecko
- Cache results
- Return formatted data to iOS app

### calculate-leaderboard
- Calculate user rankings
- Aggregate portfolio values
- Sort by net worth

### send-notifications
- Price alerts
- Portfolio milestones
- Trading notifications

## Development

### Setup Supabase CLI

```bash
# Install CLI
npm install -g supabase

# Login
supabase login

# Link project
supabase link --project-ref your-project-ref
```

### Create New Function

```bash
# Create function
supabase functions new function-name

# Edit function
# functions/function-name/index.ts

# Test locally
supabase functions serve function-name

# Deploy
supabase functions deploy function-name
```

### Example Function

```typescript
// functions/hello-world/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { name } = await req.json()

  return new Response(
    JSON.stringify({ message: `Hello, ${name}!` }),
    { headers: { "Content-Type": "application/json" } }
  )
})
```

## Calling from iOS

```swift
// Call edge function from Swift
let response = try await supabase.functions.invoke(
    "function-name",
    options: FunctionInvokeOptions(
        body: ["name": "CoinFlip"]
    )
)
```

## Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Deno Documentation](https://deno.land/)
- [Deploy Guide](https://supabase.com/docs/guides/functions/deploy)

## Note

Edge Functions are optional. We can implement most features directly in the iOS app. Use them only when:
- You need server-side secrets (API keys)
- You need scheduled tasks
- You need webhook handlers
