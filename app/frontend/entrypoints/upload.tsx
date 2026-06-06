import React from 'react';
import { createRoot } from 'react-dom/client';
import { MultiUploader } from '../components/MultiUploader';
import {Theme} from "@radix-ui/themes";
import {Provider} from "react-redux";
import store from '../services/upload_store';

const container = document.getElementById('root');
const root = createRoot(container!);

root.render(
    <React.StrictMode>
        <Provider store={store}>
            <Theme>
                <MultiUploader />
            </Theme>
        </Provider>
    </React.StrictMode>
);