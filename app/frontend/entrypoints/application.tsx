import React from 'react';
import {createRoot} from 'react-dom/client';
import {BrowserRouter} from 'react-router';
import {Theme} from "@radix-ui/themes";
import App from "../components/App";
import {RelayEnvironmentProvider} from "react-relay";
import {relayEnvironment} from '../services/RelayEnvironment';

console.log('Vite ⚡️ Rails')

const container = document.getElementById('root');
const root = createRoot(container!);

root.render(
    <React.StrictMode>
        <RelayEnvironmentProvider environment={relayEnvironment}>
            <BrowserRouter>
                <Theme accentColor="bronze"
                       grayColor="gray"
                       panelBackground="solid"
                       scaling="100%"
                       radius="full">
                    <App/>
                </Theme>
            </BrowserRouter>
        </RelayEnvironmentProvider>
    </React.StrictMode>
);