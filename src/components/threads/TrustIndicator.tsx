'use client'

import { Tooltip, Badge, Group, Progress, Stack, Text } from '@mantine/core'
import { IconShieldCheck, IconAlertTriangle, IconRobot } from '@tabler/icons-react'

interface TrustIndicatorProps {
  trustScore: number
  botFlags: number
  isBot: boolean
  level: number
  showDetails?: boolean
}

export function TrustIndicator({
  trustScore,
  botFlags,
  isBot,
  level,
  showDetails = false,
}: TrustIndicatorProps) {
  // Calculate trust level and color
  const getTrustLevel = (score: number) => {
    if (score >= 80) return { label: 'Trusted', color: '#00AA00' }
    if (score >= 50) return { label: 'Neutral', color: '#FF8C00' }
    return { label: 'Suspicious', color: '#FF4444' }
  }

  const trust = getTrustLevel(trustScore)

  // Bot detection indicators
  const botIndicators = [
    { flag: 1, label: 'Rapid posting' },
    { flag: 2, label: 'Repetitive content' },
    { flag: 4, label: 'Link spamming' },
    { flag: 8, label: 'Vote manipulation' },
    { flag: 16, label: 'Account anomalies' },
  ]

  const activeBotFlags = botIndicators.filter(ind => botFlags & ind.flag)

  if (!showDetails) {
    // Compact display for inline use
    return (
      <Tooltip
        label={
          <Stack gap={4}>
            <Text size="sm" fw={600}>
              Trust Score: {trustScore}%
            </Text>
            {activeBotFlags.length > 0 && (
              <Text size="xs" c="dimmed">
                Bot flags: {activeBotFlags.map(f => f.label).join(', ')}
              </Text>
            )}
          </Stack>
        }
        withArrow
      >
        <Badge
          size="sm"
          variant="light"
          color={isBot ? 'red' : trustScore >= 80 ? 'green' : trustScore >= 50 ? 'orange' : 'red'}
          leftSection={
            isBot ? (
              <IconRobot size={12} />
            ) : trustScore >= 80 ? (
              <IconShieldCheck size={12} />
            ) : trustScore < 50 ? (
              <IconAlertTriangle size={12} />
            ) : null
          }
        >
          {isBot ? 'Bot' : trust.label}
        </Badge>
      </Tooltip>
    )
  }

  // Detailed display for profile pages
  return (
    <Stack gap="sm">
      <Group justify="space-between">
        <Group gap="xs">
          {isBot ? (
            <IconRobot size={20} color="#FF4444" />
          ) : trustScore >= 80 ? (
            <IconShieldCheck size={20} color="#00AA00" />
          ) : trustScore < 50 ? (
            <IconAlertTriangle size={20} color="#FF4444" />
          ) : null}
          <Text fw={600}>Trust Score</Text>
        </Group>
        <Badge color={isBot ? 'red' : trust.color === '#00AA00' ? 'green' : trust.color === '#FF8C00' ? 'orange' : 'red'}>
          {trustScore}%
        </Badge>
      </Group>

      <Progress
        value={trustScore}
        color={trustScore >= 80 ? 'green' : trustScore >= 50 ? 'orange' : 'red'}
        size="lg"
        radius="md"
      />

      {activeBotFlags.length > 0 && (
        <Stack gap={4}>
          <Text size="sm" c="dimmed" fw={600}>
            Detected Issues:
          </Text>
          {activeBotFlags.map(flag => (
            <Group key={flag.flag} gap={4}>
              <IconAlertTriangle size={12} color="#FF8C00" />
              <Text size="xs" c="dimmed">
                {flag.label}
              </Text>
            </Group>
          ))}
        </Stack>
      )}

      <Group gap="xs">
        <Badge size="xs" variant="light" color="blue">
          Level {level}
        </Badge>
        {isBot && (
          <Badge size="xs" variant="filled" color="red">
            Flagged as Bot
          </Badge>
        )}
      </Group>
    </Stack>
  )
}