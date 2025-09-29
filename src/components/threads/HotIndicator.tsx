'use client'

import { Badge, MantineColor } from '@mantine/core'
import { IconFlame, IconTrendingUp, IconBolt } from '@tabler/icons-react'
import classes from './HotIndicator.module.css'

export type HotLevel = 'extremely-hot' | 'trending' | 'rising' | 'normal'

interface HotIndicatorProps {
  score: number
  compact?: boolean
}

export function HotIndicator({ score, compact = false }: HotIndicatorProps) {
  const getHotLevel = (score: number): HotLevel => {
    if (score > 100) return 'extremely-hot'
    if (score > 50) return 'trending'
    if (score > 20) return 'rising'
    return 'normal'
  }

  const level = getHotLevel(score)

  if (level === 'normal') return null

  const config = {
    'extremely-hot': {
      icon: IconFlame,
      label: compact ? '🔥' : 'HOT',
      color: 'orange' as MantineColor,
      gradient: { from: '#FF6B6B', to: '#FF8C00', deg: 135 },
      className: classes.pulseAnimation,
    },
    trending: {
      icon: IconBolt,
      label: compact ? '⚡' : 'Trending',
      color: 'yellow' as MantineColor,
      gradient: { from: '#FFD700', to: '#FFA500', deg: 135 },
      className: classes.glowAnimation,
    },
    rising: {
      icon: IconTrendingUp,
      label: compact ? '📈' : 'Rising',
      color: 'blue' as MantineColor,
      gradient: undefined,
      className: '',
    },
  }

  const { icon: Icon, label, color, gradient, className } = config[level]

  if (compact) {
    return <span className={className}>{label}</span>
  }

  return (
    <Badge
      variant={gradient ? 'gradient' : 'light'}
      gradient={gradient}
      color={gradient ? undefined : color}
      leftSection={<Icon size={14} />}
      className={className}
      size="sm"
    >
      {label}
    </Badge>
  )
}