import {defineConfig} from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import tailwindcss from "@tailwindcss/vite";
import react from '@vitejs/plugin-react';
import relay from 'vite-plugin-relay';

export default defineConfig({
    plugins: [
        RubyPlugin(),
        react(),
        tailwindcss(),
        relay
    ],
})
