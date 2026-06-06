import React from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router';
import {Theme} from "@radix-ui/themes";
import App from "../components/App";

// To see this message, add the following to the `<head>` section in your
// views/layouts/application.html.haml
//
//    <%= vite_client_tag %>
//    <%= vite_javascript_tag 'application' %>
console.log('Vite ⚡️ Rails')

// If using a TypeScript entrypoint file:
//     <%= vite_typescript_tag 'application' %>
//
// If you want to use .jsx or .tsx, add the extension:
//     <%= vite_javascript_tag 'application.jsx' %>

// console.log('Visit the guide for more information: ', 'https://vite-ruby.netlify.app/guide/rails')

// Example: Load Rails libraries in Vite.
//
// import * as Turbo from '@hotwired/turbo'
// Turbo.start()
//
// import ActiveStorage from '@rails/activestorage'
// ActiveStorage.start()
//
// // Import all channels.
// const channels = import.meta.glob('./**/*_channel.js', { eager: true })

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'

const container = document.getElementById('root');
const root = createRoot(container!);

root.render(
    <React.StrictMode>
        <BrowserRouter>
            <Theme accentColor="bronze"
                      grayColor="gray"
                      panelBackground="solid"
                      scaling="100%"
                      radius="full">
                <App />
            </Theme>
        </BrowserRouter>
    </React.StrictMode>
);