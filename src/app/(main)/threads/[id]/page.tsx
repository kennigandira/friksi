'use client'

import { Container, Grid } from '@mantine/core'
import { ThreadDetail } from '@/components/threads/ThreadDetail'
import { VotePanel } from '@/components/threads/VotePanel'
import { CommentSection } from '@/components/threads/CommentSection'

interface ThreadDetailPageProps {
  params: {
    id: string
  }
}

export default function ThreadDetailPage({ params }: ThreadDetailPageProps) {
  return (
    <Container size="xl">
      <Grid>
        <Grid.Col span={{ base: 12, md: 8 }}>
          <ThreadDetail threadId={params.id} />
          <CommentSection threadId={params.id} />
        </Grid.Col>

        <Grid.Col span={{ base: 12, md: 4 }}>
          <VotePanel contentId={params.id} contentType="thread" />
        </Grid.Col>
      </Grid>
    </Container>
  )
}
