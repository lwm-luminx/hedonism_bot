import { RelayEnvironmentProvider } from "react-relay";
import { relayEnvironment } from "../services/RelayEnvironment";
import { BrowserRouter, Route, Routes } from "react-router";
import GalleryPage from "./pages/GalleryPage";
import { UploadPage } from "./pages/UploadPage";
import React from "react";
import { AdminPage } from "./pages/AdminPage";
import { AdminOverview } from "./admin/AdminOverview";
import { VenuesPanel } from "./admin/VenuesPanel";
import { EventsPanel } from "./admin/EventsPanel";
import { AdminPhotosPanel } from "./admin/AdminPhotosPanel";
import { CreatePhotoPromise } from "./pages/CreatePhotoPromise";

export default function App() {
  return (
    <RelayEnvironmentProvider environment={relayEnvironment}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<GalleryPage />} />
          <Route path="/upload" element={<CreatePhotoPromise />}>
            <Route path=":promiseId" element={<UploadPage />} />
          </Route>
          <Route path="admin" element={<AdminPage />}>
            <Route index element={<AdminOverview />} />
            <Route path="venues" element={<VenuesPanel />} />
            <Route path="events" element={<EventsPanel />} />
            <Route path="photos" element={<AdminPhotosPanel />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </RelayEnvironmentProvider>
  );
}
