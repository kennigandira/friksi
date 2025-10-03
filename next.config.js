/** @type {import('next').NextConfig} */

// Determine if we're in development mode
const isDevelopment = process.env.NODE_ENV === 'development'

const nextConfig = {
  images: {
    remotePatterns: [
      // Add patterns when needed, example:
      // {
      //   protocol: 'https',
      //   hostname: '**.supabase.co',
      //   pathname: '/storage/v1/object/public/**',
      // },
    ],
  },
  // Security and PWA configuration
  async headers() {
    // Build CSP based on environment
    const cspConnectSrc = isDevelopment
      ? "'self' http://localhost:* ws://localhost:* https://*.supabase.co wss://*.supabase.co"
      : "'self' https://*.supabase.co wss://*.supabase.co"

    // Remove upgrade-insecure-requests in development to allow HTTP localhost
    const cspDirectives = [
      "default-src 'self'",
      "script-src 'self' 'unsafe-eval' 'unsafe-inline' https://*.supabase.co",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https: blob:",
      "font-src 'self' data:",
      `connect-src ${cspConnectSrc}`,
      "frame-src 'self'",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "frame-ancestors 'none'",
    ]

    // Only add upgrade-insecure-requests in production
    if (!isDevelopment) {
      cspDirectives.push('upgrade-insecure-requests')
    }

    return [
      {
        // Apply security headers to all routes
        source: '/:path*',
        headers: [
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on',
          },
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload',
          },
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=(), payment=()',
          },
          {
            key: 'Content-Security-Policy',
            value: cspDirectives.join('; '),
          },
        ],
      },
      {
        // PWA manifest specific headers
        source: '/manifest.json',
        headers: [
          {
            key: 'Content-Type',
            value: 'application/json',
          },
          {
            key: 'Cache-Control',
            value: 'public, max-age=3600',
          },
        ],
      },
      {
        // API routes specific headers
        source: '/api/:path*',
        headers: [
          {
            key: 'Cache-Control',
            value: 'no-store, no-cache, must-revalidate, private',
          },
        ],
      },
    ]
  },
}

module.exports = nextConfig