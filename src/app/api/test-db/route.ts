import { NextResponse } from 'next/server'
import { createServerSupabaseClient } from '@/lib/database/lib/server'

export async function GET() {
  try {
    console.log('[test-db] Starting test...')

    const supabase = createServerSupabaseClient()
    console.log('[test-db] Created Supabase client')

    const { data, error } = await supabase
      .from('threads')
      .select('id, title')
      .limit(1)

    console.log('[test-db] Query result:', { data, error })

    if (error) {
      return NextResponse.json({
        success: false,
        error: error.message,
        details: error
      }, { status: 500 })
    }

    return NextResponse.json({
      success: true,
      data,
      message: 'Database connection successful'
    })
  } catch (error) {
    console.error('[test-db] Caught error:', error)
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      details: error
    }, { status: 500 })
  }
}