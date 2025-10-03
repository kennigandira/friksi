import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import { ColorSchemeScript, MantineProvider } from '@mantine/core'
import { Notifications } from '@mantine/notifications'
import { ModalsProvider } from '@mantine/modals'
import { AuthProvider } from '@/hooks/use-auth'
import { validateEnv } from '@/lib/env'
import './globals.css'
import '@mantine/core/styles.css'

// Validate environment variables on server startup
if (typeof window === 'undefined') {
  validateEnv()
}

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Friksi - Democratic Civic Engagement',
  description:
    'A next-generation civic engagement platform with democratic moderation and anti-bot protection',
  keywords: [
    'civic engagement',
    'democracy',
    'community',
    'discussion',
    'voting',
  ],
  authors: [{ name: 'Friksi Team' }],
  creator: 'Friksi',
  publisher: 'Friksi',
  manifest: '/manifest.json',
}

export const viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  themeColor: '#2563eb',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <ColorSchemeScript defaultColorScheme="light" />
      </head>
      <body className={inter.className}>
        <MantineProvider defaultColorScheme="auto">
          <ModalsProvider>
            <AuthProvider>
              <>
                <Notifications />
                {children}
              </>
            </AuthProvider>
          </ModalsProvider>
        </MantineProvider>
      </body>
    </html>
  )
}
