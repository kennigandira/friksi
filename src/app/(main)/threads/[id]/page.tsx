import { Metadata } from 'next'
import { notFound } from 'next/navigation'
import { ThreadDetail } from '@/components/threads/ThreadDetail'
import { VotePanel } from '@/components/threads/VotePanel'
import { CommentSection } from '@/components/threads/CommentSection'
import { ThreadHelpers } from '@/lib/database/helpers/threads'

interface ThreadDetailPageProps {
  params: {
    id: string
  }
}

export async function generateMetadata({
  params,
}: ThreadDetailPageProps): Promise<Metadata> {
  const { thread } = await ThreadHelpers.getThread(params.id, {
    useServerClient: true,
  })

  if (!thread) {
    return {
      title: 'Thread Not Found',
      description: 'The requested thread could not be found.',
    }
  }

  return {
    title: thread.title,
    description: thread.content?.substring(0, 160) || 'Join the discussion on Friksi',
    openGraph: {
      title: thread.title,
      description: thread.content?.substring(0, 160) || 'Join the discussion on Friksi',
      type: 'article',
      publishedTime: thread.created_at,
      modifiedTime: thread.updated_at,
    },
  }
}

export default async function ThreadDetailPage({ params }: ThreadDetailPageProps) {
  // Fetch thread data server-side with view increment
  const { thread, error } = await ThreadHelpers.getThread(params.id, {
    incrementViews: true,
    useServerClient: true,
  })

  if (error || !thread) {
    notFound()
  }

  return (
    <div className="container mx-auto px-4 py-6 max-w-7xl">
      <div className="grid grid-cols-12 gap-6">
        <div className="col-span-12 md:col-span-1">
          <div className="sticky top-20">
            <VotePanel
              contentId={thread.id}
              contentType="thread"
              initialUpvotes={thread.upvotes}
              initialDownvotes={thread.downvotes}
            />
          </div>
        </div>

        <div className="col-span-12 md:col-span-8">
          <ThreadDetail thread={thread} />
          <CommentSection threadId={thread.id} />
        </div>

        <div className="col-span-12 md:col-span-3">
          {/* Sidebar - stats coming soon */}
        </div>
      </div>
    </div>
  )
}