import { TableRow, TableName } from './typed-client'

/**
 * Type guard for vote types
 */
export function isVoteType(value: string): value is 'upvote' | 'downvote' {
  return value === 'upvote' || value === 'downvote'
}

/**
 * Type guard for account status
 */
export function isAccountStatus(
  value: string
): value is 'active' | 'restricted' | 'shadowbanned' | 'banned' {
  return ['active', 'restricted', 'shadowbanned', 'banned'].includes(value)
}

/**
 * Type guard for bot classification
 */
export function isBotClassification(
  value: string
): value is 'human' | 'suspicious' | 'bot' {
  return ['human', 'suspicious', 'bot'].includes(value)
}

/**
 * Validate table row at runtime
 * This is a simplified version - add more specific validation as needed
 */
export function validateTableRow<T extends TableName>(
  table: T,
  data: unknown
): data is TableRow<T> {
  // Basic validation - data must be an object
  return typeof data === 'object' && data !== null
}