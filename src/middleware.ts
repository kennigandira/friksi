import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { createServerClientWithAuth } from '@/lib/database/lib/server'

/**
 * Middleware for server-side session validation and security
 */

// Protected routes that require authentication
const protectedRoutes = [
  '/category/*/create',
  '/threads/*/edit',
  '/profile',
  '/settings',
]

// Moderator-only routes
const moderatorRoutes = [
  '/moderator',
  '/admin',
]

export async function middleware(request: NextRequest) {
  const response = NextResponse.next()
  const pathname = request.nextUrl.pathname

  // Add security headers to all responses
  response.headers.set('X-Frame-Options', 'DENY')
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('X-XSS-Protection', '1; mode=block')
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin')

  // Check if the route is protected
  const isProtected = protectedRoutes.some(route => {
    const pattern = route.replace(/\*/g, '.*')
    return new RegExp(`^${pattern}$`).test(pathname)
  })

  const isModerator = moderatorRoutes.some(route =>
    pathname.startsWith(route)
  )

  if (isProtected || isModerator) {
    try {
      // Get the auth token from cookies
      const cookieStore = request.cookies
      const supabaseToken = cookieStore.get('sb-access-token')?.value ||
                           cookieStore.get('supabase-auth-token')?.value

      if (!supabaseToken) {
        // Redirect to login if no token
        return NextResponse.redirect(new URL('/login', request.url))
      }

      // Validate the session server-side
      const supabase = createServerClientWithAuth(supabaseToken)
      const { data: { user }, error } = await supabase.auth.getUser()

      if (error || !user) {
        // Invalid or expired session
        return NextResponse.redirect(new URL('/login', request.url))
      }

      // For moderator routes, check moderator status
      if (isModerator) {
        const { data: moderatorData } = await supabase
          .from('moderators')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .single()

        if (!moderatorData) {
          // Not a moderator, redirect to home
          return NextResponse.redirect(new URL('/', request.url))
        }
      }

      // Add user ID to request headers for downstream use
      response.headers.set('X-User-Id', user.id)
      response.headers.set('X-Session-Valid', 'true')

    } catch (error) {
      console.error('Middleware auth error:', error)
      return NextResponse.redirect(new URL('/login', request.url))
    }
  }

  // CSRF validation for state-changing requests
  if (request.method === 'POST' || request.method === 'PUT' || request.method === 'DELETE') {
    const csrfToken = request.headers.get('X-CSRF-Token')

    // Skip CSRF check for API routes that handle their own validation
    const isApiRoute = pathname.startsWith('/api/')

    if (!isApiRoute && !csrfToken) {
      return new NextResponse('Missing CSRF token', { status: 403 })
    }
  }

  return response
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     * - api/health (health check endpoint)
     */
    '/((?!_next/static|_next/image|favicon.ico|public|api/health).*)',
  ],
}