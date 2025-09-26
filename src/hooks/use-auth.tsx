'use client'

import React, { useState, useEffect, createContext, useContext, ReactNode } from 'react'
import { FriksiAuth, type User } from '@/lib/database'

interface AuthContextType {
  user: User | null
  loading: boolean
  login: (email: string, password: string) => Promise<{ error?: string }>
  register: (data: { username: string; email: string; password: string }) => Promise<{ error?: string }>
  logout: () => Promise<void>
  resetPassword: (email: string) => Promise<{ error?: string }>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Check for existing session
    checkSession()

    // Listen for auth state changes
    const { data: { subscription } } = FriksiAuth.onAuthStateChange(
      async (event, session) => {
        if (session?.user) {
          const profile = await FriksiAuth.getCurrentUserProfile()
          setUser(profile)
        } else {
          setUser(null)
        }
        setLoading(false)
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  const checkSession = async () => {
    try {
      const profile = await FriksiAuth.getCurrentUserProfile()
      setUser(profile)
    } catch (error) {
      console.error('Error checking session:', error)
    } finally {
      setLoading(false)
    }
  }

  const login = async (email: string, password: string) => {
    try {
      const { user: authUser, error } = await FriksiAuth.signIn({ email, password })

      if (error) {
        return { error: error.message }
      }

      if (authUser) {
        const profile = await FriksiAuth.getCurrentUserProfile()
        setUser(profile)
      }

      return {}
    } catch (error) {
      return { error: 'An unexpected error occurred' }
    }
  }

  const register = async (data: { username: string; email: string; password: string }) => {
    try {
      const { user: authUser, error } = await FriksiAuth.signUp({
        email: data.email,
        password: data.password,
        username: data.username
      })

      if (error) {
        return { error: error.message }
      }

      if (authUser) {
        const profile = await FriksiAuth.getCurrentUserProfile()
        setUser(profile)
      }

      return {}
    } catch (error) {
      return { error: 'An unexpected error occurred' }
    }
  }

  const logout = async () => {
    try {
      await FriksiAuth.signOut()
      setUser(null)
    } catch (error) {
      console.error('Logout error:', error)
    }
  }

  const resetPassword = async (email: string) => {
    try {
      const { error } = await FriksiAuth.resetPassword(email)

      if (error) {
        return { error: error.message }
      }

      return {}
    } catch (error) {
      return { error: 'An unexpected error occurred' }
    }
  }

  return (
    <AuthContext.Provider value={{
      user,
      loading,
      login,
      register,
      logout,
      resetPassword
    }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
