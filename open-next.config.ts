import { defineCloudflareConfig } from "@opennextjs/cloudflare";

// OpenNext Cloudflare configuration
export default defineCloudflareConfig({
  // Optional: Configure incremental cache with R2 if needed
  // incrementalCache: r2IncrementalCache,

  // Custom configuration options can be added here
  // For now, using default configuration which works well
  // with standard Next.js applications
});