import {defineConfig} from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import tailwindcss from "@tailwindcss/vite";
import react from '@vitejs/plugin-react';
import relay from 'vite-plugin-relay';

export default defineConfig({
    server: process.env.AUDIENCEKIT_DEV_PROXY === '1' ? {
        allowedHosts: ['hedonism.local.audiencekit.com'],
        origin: 'https://hedonism.local.audiencekit.com',
        ws: { protocol: 'wss', clientPort: 443 },
    } : undefined,
    plugins: [
        RubyPlugin(),
        react(),
        tailwindcss(),
        relay
    ],
    assetsInclude: ['**/*.svg']
})
