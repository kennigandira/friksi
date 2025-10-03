/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      // Add patterns when needed, example:
      // {
      //   protocol: 'https',
      //   hostname: '**.supabase.co',
      //   pathname: '/storage/v1/object/public/**',
      // },
    ],
  },
  // PWA configuration
  async headers() {
    return [
      {
        source: '/manifest.json',
        headers: [
          {
            key: 'Content-Type',
            value: 'application/json',
          },
        ],
      },
    ]
  },
}

module.exports = nextConfig