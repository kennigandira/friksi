# Cloudflare Pages Deployment Guide

This guide covers deploying the Friksi platform to Cloudflare Pages using the OpenNext adapter.

## Prerequisites

- Node.js 18+ installed
- pnpm package manager
- Cloudflare account
- All environment variables from `.env.local`

## Local Development

### 1. Install Dependencies

```bash
pnpm install
```

### 2. Configure Environment Variables

Copy your environment variables from `.env.local` to `.dev.vars`:

```bash
cp .env.local .dev.vars
```

Update the `NEXT_PUBLIC_APP_URL` in `.dev.vars` to:
```
NEXT_PUBLIC_APP_URL=http://localhost:8788
```

### 3. Build and Preview Locally

```bash
# Build for Cloudflare
pnpm build:cf

# Preview locally (builds and starts local server)
pnpm preview:cf
```

The preview server will run at `http://localhost:8788`

## Production Deployment

### Method 1: CLI Deployment (Quick)

1. **Login to Cloudflare**
   ```bash
   npx wrangler login
   ```

2. **Deploy to Cloudflare Pages**
   ```bash
   pnpm deploy:cf
   ```

3. **First-time deployment**: You'll be prompted to:
   - Create a new project or select existing
   - Choose production branch (usually `main`)
   - Confirm deployment

### Method 2: GitHub Integration (Recommended)

1. **Push code to GitHub**
   ```bash
   git add .
   git commit -m "Add Cloudflare deployment configuration"
   git push origin main
   ```

2. **Connect to Cloudflare Pages Dashboard**
   - Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
   - Navigate to "Workers & Pages"
   - Click "Create application" → "Pages"
   - Connect to Git → Select your GitHub repository

3. **Configure Build Settings**
   - **Framework preset**: None (manual configuration)
   - **Build command**: `pnpm build:cf`
   - **Build output directory**: `.open-next/assets`
   - **Root directory**: `/` (leave blank)
   - **Environment variables**: Add all from `.env.local`

4. **Environment Variables Setup**
   Add these essential variables in Cloudflare Pages settings:
   ```
   NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-key
   NEXT_PUBLIC_APP_URL=https://your-domain.pages.dev
   NODE_VERSION=18
   ```

5. **Deploy**
   - Click "Save and Deploy"
   - Wait for build to complete (~2-5 minutes)

## Custom Domain Setup

1. **Add Custom Domain**
   - Go to your Pages project → "Custom domains"
   - Click "Set up a custom domain"
   - Enter your domain (e.g., `friksi.com`)

2. **DNS Configuration**
   - If using Cloudflare DNS: Automatic setup
   - External DNS: Add CNAME record pointing to `your-project.pages.dev`

3. **SSL Certificate**
   - Automatically provisioned by Cloudflare
   - Usually active within minutes

## Environment Variables Reference

### Required Variables
- `NEXT_PUBLIC_SUPABASE_URL` - Your Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Supabase anonymous key
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key (server-side)
- `NEXT_PUBLIC_APP_URL` - Your application URL

### Optional Variables
See `.env.example` for complete list of configuration options

## Deployment Commands

```bash
# Build for Cloudflare
pnpm build:cf

# Preview locally
pnpm preview:cf

# Deploy to production
pnpm deploy:cf

# Regular Next.js development (not Cloudflare)
pnpm dev
```

## Troubleshooting

### Build Failures

1. **Node Version Issues**
   - Ensure `NODE_VERSION=18` is set in environment variables
   - Check `.node-version` file exists with content: `18`

2. **Memory Issues**
   - Worker size limit: 3MB (free) / 10MB (paid)
   - If hitting limits, consider:
     - Optimizing imports
     - Code splitting
     - Upgrading to paid plan

3. **Environment Variables Not Working**
   - Verify all variables are added in Cloudflare dashboard
   - Check for typos in variable names
   - Ensure `.dev.vars` is used for local development

### Runtime Issues

1. **404 Errors**
   - Check build output includes all routes
   - Verify `wrangler.jsonc` configuration

2. **API/Database Connection Issues**
   - Verify Supabase keys are correct
   - Check CORS settings in Supabase
   - Ensure service role key is only used server-side

3. **Real-time Features Not Working**
   - Verify WebSocket support (automatic in Cloudflare)
   - Check Supabase real-time is enabled
   - Verify channel names match

## Monitoring & Analytics

### Cloudflare Analytics
- Available in Pages dashboard
- Shows requests, bandwidth, visitor analytics
- Web Vitals metrics included

### Error Tracking
- View logs in Cloudflare dashboard → "Functions" tab
- Use `wrangler tail` for real-time logs:
  ```bash
  npx wrangler pages deployment tail
  ```

## Rollback Procedures

### Quick Rollback
1. Go to Pages project → "Deployments"
2. Find previous working deployment
3. Click "..." menu → "Rollback to this deployment"

### DNS Rollback (if using external service)
- Point DNS back to previous hosting provider
- Keep Cloudflare deployment for testing

## Performance Optimization

### Caching Strategy
- Static assets cached automatically
- Configure cache headers in `next.config.js` if needed
- Use Cloudflare Page Rules for advanced caching

### Edge Locations
- Content served from 300+ global locations
- Automatic geo-routing for best performance
- No configuration needed

## Cost Considerations

### Free Tier Limits
- 500 builds per month
- Unlimited requests
- Unlimited bandwidth
- 100,000 Workers requests per day

### When to Upgrade
- Need builds > 500/month
- Worker size > 3MB
- Need concurrent builds
- Want build prioritization

## Migration from Vercel

### Key Differences
- No serverless functions (use Supabase for backend)
- Better pricing for high traffic
- More edge locations globally
- Built-in DDoS protection

### Migration Checklist
- [x] Install OpenNext adapter
- [x] Configure wrangler.jsonc
- [x] Set up environment variables
- [x] Test local build
- [x] Deploy to Cloudflare Pages
- [ ] Update DNS (when ready)
- [ ] Monitor for 24-48 hours
- [ ] Decommission Vercel deployment

## Support & Resources

- [OpenNext Documentation](https://opennext.js.org/cloudflare)
- [Cloudflare Pages Docs](https://developers.cloudflare.com/pages/)
- [Wrangler CLI Docs](https://developers.cloudflare.com/workers/wrangler/)
- [Cloudflare Discord](https://discord.cloudflare.com)

## Next Steps

1. **Test Preview Deployment**: Deploy to a preview branch first
2. **Configure Domain**: Set up your custom domain
3. **Enable Analytics**: Set up Cloudflare Web Analytics
4. **Set Up Monitoring**: Configure alerts for errors
5. **Optimize Performance**: Review Core Web Vitals in dashboard