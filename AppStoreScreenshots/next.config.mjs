/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: false,
  distDir: ".build/next",
  // Next 16.3+ otherwise writes AGENTS.md / CLAUDE.md into every scaffolded
  // project on first `dev`, leaving a dirty tree before anything is edited.
  agentRules: false,
};

export default nextConfig;
