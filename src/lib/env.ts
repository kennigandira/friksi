/**
 * Environment Variables Validation and Type-Safe Access
 *
 * Validates required environment variables on startup and provides
 * type-safe access to configuration values.
 */

import { logger } from './logger'

// Required environment variables (app cannot run without these)
const requiredEnvVars = [
  'NEXT_PUBLIC_SUPABASE_URL',
  'NEXT_PUBLIC_SUPABASE_ANON_KEY',
] as const

// Optional environment variables (have defaults or only used in specific contexts)
const optionalEnvVars = [
  'SUPABASE_SERVICE_ROLE_KEY', // Server-side only
  'NEXT_PUBLIC_APP_URL', // Defaults to localhost
  'SUPABASE_DB_URL', // For direct DB connections
  'SUPABASE_JWT_SECRET', // For token verification
  'NODE_ENV', // Set by Next.js
] as const

/**
 * Validates that all required environment variables are set
 * Throws an error with helpful message if any are missing
 */
export function validateEnv(): void {
  const missing: string[] = []

  // Check each required variable
  for (const key of requiredEnvVars) {
    if (!process.env[key]) {
      missing.push(key)
    }
  }

  // If any are missing, throw descriptive error
  if (missing.length > 0) {
    const errorMessage = [
      '❌ Missing required environment variables:',
      '',
      ...missing.map(key => `  - ${key}`),
      '',
      '📝 To fix this:',
      '  1. Copy .env.example to .env.local',
      '  2. Fill in the missing values',
      '  3. Restart the development server',
      '',
      '🔗 Get your Supabase credentials:',
      '   https://supabase.com/dashboard/project/_/settings/api',
    ].join('\n')

    throw new Error(errorMessage)
  }

  // Log success in development
  if (process.env.NODE_ENV === 'development') {
    logger.info('✅ Environment variables validated')
  }
}

/**
 * Type-safe environment variable access
 * Use this instead of process.env for better type safety
 */
export const env = {
  // Supabase Configuration
  supabase: {
    url: process.env['NEXT_PUBLIC_SUPABASE_URL']!,
    anonKey: process.env['NEXT_PUBLIC_SUPABASE_ANON_KEY']!,
    serviceRoleKey: process.env['SUPABASE_SERVICE_ROLE_KEY'],
    dbUrl: process.env['SUPABASE_DB_URL'],
    jwtSecret: process.env['SUPABASE_JWT_SECRET'],
  },

  // Application Configuration
  app: {
    url: process.env['NEXT_PUBLIC_APP_URL'] || 'http://localhost:3000',
    nodeEnv: process.env['NODE_ENV'] || 'development',
    isDevelopment: process.env['NODE_ENV'] === 'development',
    isProduction: process.env['NODE_ENV'] === 'production',
  },
} as const

/**
 * Check if running on server-side
 */
export const isServer = typeof window === 'undefined'

/**
 * Check if running on client-side
 */
export const isClient = typeof window !== 'undefined'