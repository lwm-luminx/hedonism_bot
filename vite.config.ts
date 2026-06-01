import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import tailwindcss from "@tailwindcss/vite";
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [
    tailwindcss(),
    RubyPlugin(),
    react()
  ],
})
