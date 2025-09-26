// Type exports
export * from './types/database.types'

// Client exports
export * from './lib/client'
export * from './lib/browser'
export * from './lib/server'
export * from './lib/auth'
export * from './lib/realtime'

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
