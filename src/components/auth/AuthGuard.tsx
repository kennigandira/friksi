'use client'

import { useAuth } from '@/hooks/use-auth'
import { Alert, Center, Loader } from '@mantine/core'
import { IconAlertCircle } from '@tabler/icons-react'
import { useRouter } from 'next/navigation'
import { ReactNode, useEffect } from 'react'

interface AuthGuardProps {
  children: ReactNode
  minLevel?: number
  requireModerator?: boolean
  requireAdmin?: boolean
}

export function AuthGuard({
  children,
  minLevel,
  requireModerator = false,
  requireAdmin = false,
}: AuthGuardProps) {
  const { user, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login')
    }
  }, [user, loading, router])

  if (loading) {
    return (
      <Center h="50vh">
        <Loader size="lg" />
      </Center>
    )
  }

  if (!user) {
    return null // Will redirect
  }

  // Check minimum level requirement
  if (minLevel && (user.level ?? 1) < minLevel) {
    return (
      <Alert
        icon={<IconAlertCircle size={16} />}
        title="Access Denied"
        color="red"
        m="md"
      >
        You need to be at least level {minLevel} to access this page. Your
        current level is {user.level}.
      </Alert>
    )
  }

  // Check moderator requirement (level 4+ has moderation privileges)
  if (requireModerator && (user.level ?? 1) < 4) {
    return (
      <Alert
        icon={<IconAlertCircle size={16} />}
        title="Moderator Access Required"
        color="red"
        m="md"
      >
        This page is only accessible to community moderators.
      </Alert>
    )
  }

  // Check admin requirement
  if (requireAdmin && (user.level ?? 1) < 5) {
    return (
      <Alert
        icon={<IconAlertCircle size={16} />}
        title="Administrator Access Required"
        color="red"
        m="md"
      >
        This page is only accessible to platform administrators.
      </Alert>
    )
  }

  return <>{children}</>
}
