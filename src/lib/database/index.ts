// Type exports
export * from './types/database.types'
import type { Tables } from './types/database.types'

// Convenience type aliases
export type User = Tables<'users'>

// Client exports
export * from './lib/client'
export * from './lib/browser'
export * from './lib/server'
export * from './lib/auth'
export * from './lib/realtime'

// Typed client exports (avoiding naming conflicts)
export {
  type TypedSupabaseClient,
  type TableRow,
  type TableInsert,
  type TableUpdate,
  type TableName,
  getTypedClient,
  typedFrom,
} from './lib/typed-client'

export * from './lib/type-guards'

// Utility exports
export { FriksiAuth, ServerAuth } from './lib/auth'
export { FriksiRealtime } from './lib/realtime'

// Helper class exports (avoiding naming conflicts with types)
export {
  ThreadHelpers,
  CommentHelpers,
  UserHelpers,
  VoteHelpers,
} from './helpers'
