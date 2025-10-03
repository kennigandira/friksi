/**
 * Development-only logging utility
 *
 * Prevents console statements from appearing in production builds
 * while maintaining useful debug output during development.
 */

const isDev = process.env.NODE_ENV === 'development'

export const logger = {
  /**
   * Log informational messages (development only)
   */
  info: (...args: any[]) => {
    if (isDev) {
      console.log(...args)
    }
  },

  /**
   * Log error messages (development only)
   */
  error: (...args: any[]) => {
    if (isDev) {
      console.error(...args)
    }
  },

  /**
   * Log warning messages (development only)
   */
  warn: (...args: any[]) => {
    if (isDev) {
      console.warn(...args)
    }
  },

  /**
   * Log debug messages (development only)
   */
  debug: (...args: any[]) => {
    if (isDev) {
      console.debug(...args)
    }
  },
}