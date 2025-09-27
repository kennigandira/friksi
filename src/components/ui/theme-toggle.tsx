'use client'

import { ActionIcon, Tooltip, useMantineColorScheme } from '@mantine/core'
import { IconSun, IconMoon } from '@tabler/icons-react'
import { useEffect } from 'react'

interface ThemeToggleProps {
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
  variant?: 'subtle' | 'filled' | 'outline' | 'light' | 'default' | 'transparent'
}

export function ThemeToggle({ size = 'lg', variant = 'subtle' }: ThemeToggleProps) {
  const { colorScheme, toggleColorScheme, setColorScheme } = useMantineColorScheme()

  useEffect(() => {
    const root = document.documentElement

    if (colorScheme === 'dark') {
      root.classList.add('dark')
    } else {
      root.classList.remove('dark')
    }
  }, [colorScheme])

  useEffect(() => {
    const storedTheme = localStorage.getItem('theme') as 'light' | 'dark' | null

    if (storedTheme) {
      setColorScheme(storedTheme)
    } else if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
      setColorScheme('dark')
    }
  }, [setColorScheme])

  const handleToggle = () => {
    toggleColorScheme()
    const newTheme = colorScheme === 'dark' ? 'light' : 'dark'
    localStorage.setItem('theme', newTheme)
  }

  return (
    <Tooltip label={`Switch to ${colorScheme === 'dark' ? 'light' : 'dark'} mode`}>
      <ActionIcon
        variant={variant}
        onClick={handleToggle}
        size={size}
        aria-label={`Switch to ${colorScheme === 'dark' ? 'light' : 'dark'} mode`}
      >
        {colorScheme === 'dark' ? (
          <IconSun size={18} stroke={1.5} />
        ) : (
          <IconMoon size={18} stroke={1.5} />
        )}
      </ActionIcon>
    </Tooltip>
  )
}