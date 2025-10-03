import { useState, useEffect } from 'react'
import { getBrowserSupabaseClient } from '@/lib/database/lib/browser'
import { logger } from '@/lib/logger'

/**
 * CSRF Protection utilities for state-changing operations
 */

/**
 * Generate a CSRF token for the current session
 * Uses the Supabase session token as a basis for CSRF validation
 */
export async function generateCSRFToken(): Promise<string | null> {
  try {
    const supabase = getBrowserSupabaseClient()
    const { data: { session } } = await supabase.auth.getSession()

    if (!session?.access_token) {
      return null
    }

    // Use a portion of the JWT as CSRF token
    // This ensures the token is tied to the user's session
    const tokenParts = session.access_token.split('.')
    if (tokenParts.length < 3) {
      return null
    }

    // Use the signature part of the JWT as CSRF token
    const signature = tokenParts[2]
    if (!signature) {
      return null
    }
    return signature.substring(0, 32)
  } catch (error) {
    logger.error('Failed to generate CSRF token:', error)
    return null
  }
}

/**
 * Validate a CSRF token against the current session
 */
export async function validateCSRFToken(token: string): Promise<boolean> {
  try {
    const expectedToken = await generateCSRFToken()

    if (!expectedToken || !token) {
      return false
    }

    // Constant-time comparison to prevent timing attacks
    return timingSafeEqual(token, expectedToken)
  } catch (error) {
    logger.error('CSRF validation error:', error)
    return false
  }
}

/**
 * Constant-time string comparison to prevent timing attacks
 */
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false
  }

  let result = 0
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i)
  }

  return result === 0
}

/**
 * Get headers with CSRF token for protected requests
 */
export async function getProtectedHeaders(): Promise<HeadersInit> {
  const csrfToken = await generateCSRFToken()

  return {
    'Content-Type': 'application/json',
    ...(csrfToken ? { 'X-CSRF-Token': csrfToken } : {})
  }
}

/**
 * Hook for React components to use CSRF protection
 */
export function useCSRFToken() {
  const [csrfToken, setCSRFToken] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    generateCSRFToken().then(token => {
      setCSRFToken(token)
      setLoading(false)
    })
  }, [])

  return { csrfToken, loading }
}