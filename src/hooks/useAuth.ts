'use client'

import { useEffect, useState } from 'react'
import { User } from '@supabase/supabase-js'
import { FriksiAuth, FriksiUser } from '@/lib/database/lib/auth'

export function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [profile, setProfile] = useState<FriksiUser | null>(null)
  const [loading, setLoading] = useState(true)
  const [isModerator, setIsModerator] = useState(false)

  useEffect(() => {
    const fetchAuthData = async () => {
      try {
        const currentUser = await FriksiAuth.getCurrentUser()
        setUser(currentUser)

        if (currentUser) {
          const userProfile = await FriksiAuth.getCurrentUserProfile()
          setProfile(userProfile)

          const modStatus = await FriksiAuth.isModerator()
          setIsModerator(modStatus)
        }
      } catch (error) {
        console.error('Error fetching auth data:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchAuthData()

    // Subscribe to auth state changes
    const { data: authListener } = FriksiAuth.onAuthStateChange(
      async (event, session) => {
        setUser(session?.user ?? null)

        if (session?.user) {
          const userProfile = await FriksiAuth.getCurrentUserProfile()
          setProfile(userProfile)

          const modStatus = await FriksiAuth.isModerator()
          setIsModerator(modStatus)
        } else {
          setProfile(null)
          setIsModerator(false)
        }
      }
    )

    return () => {
      authListener.subscription.unsubscribe()
    }
  }, [])

  const signIn = async (email: string, password: string) => {
    const { user, error } = await FriksiAuth.signIn({ email, password })
    if (user && !error) {
      setUser(user)
      const userProfile = await FriksiAuth.getCurrentUserProfile()
      setProfile(userProfile)
    }
    return { user, error }
  }

  const signOut = async () => {
    const { error } = await FriksiAuth.signOut()
    if (!error) {
      setUser(null)
      setProfile(null)
      setIsModerator(false)
    }
    return { error }
  }

  return {
    user,
    profile,
    loading,
    isAuthenticated: !!user,
    isModerator,
    signIn,
    signOut,
  }
}