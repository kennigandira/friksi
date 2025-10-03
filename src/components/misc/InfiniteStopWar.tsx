'use client'

import { useEffect, useRef, useState } from 'react'

const Texts = () => (
  <div className="h-screen flex items-center justify-center text-6xl font-bold text-[18vw] odd:bg-bravepink odd:text-herogreen even:bg-herogreen even:text-bravepink">
    STOP WAR STOP WAR STOP WAR STOP WAR STOP WAR STOP WAR STOP WAR STOP WAR STOP
    WAR STOP WAR STOP WAR STOP WAR STOP WAR
  </div>
)

export default function InfiniteStopWar() {
  const [pages, setPages] = useState(1)
  const loaderRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    const observer = new IntersectionObserver(
      entries => {
        const entry = entries[0]
        if (entry?.isIntersecting) {
          setPages(prevPages => prevPages + 1)
        }
      },
      { threshold: 1 }
    )

    const currentLoader = loaderRef.current
    if (currentLoader) {
      observer.observe(currentLoader)
    }
    return () => {
      if (currentLoader) {
        observer.unobserve(currentLoader)
      }
    }
  }, [])

  return (
    <div>
      {Array.from({ length: pages }, (_, i) => (
        <Texts key={i} />
      ))}
      <div ref={loaderRef} className="h-10" />
    </div>
  )
}
