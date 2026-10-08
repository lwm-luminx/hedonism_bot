import {
  ArrowLeft,
  CalendarDays,
  HardDrive,
  Image,
  LayoutDashboard,
  LogOut,
  MapPin,
} from "lucide-react";
import { NavLink, Outlet, useNavigate } from "react-router";
import { Suspense } from "react";
import { Spinner } from "../controls/Spinner";
import { AuthGate, signOut } from "./AuthPage";

export function AdminPage() {
  const navigate = useNavigate();
  return (
    <AuthGate>
      <div
        className="flex min-h-screen flex-col"
        style={{
          background: "var(--background)",
          fontFamily: "'Inter', sans-serif",
        }}
      >
        {/* Header */}
        <header
          className="flex shrink-0 items-center gap-4 border-b px-6 py-3.5"
          style={{ borderColor: "var(--border)", background: "var(--card)" }}
        >
          <button
            onClick={() => navigate("/")}
            className="flex items-center gap-1.5 transition-opacity hover:opacity-70"
            style={{ color: "var(--muted-foreground)", fontSize: "0.875rem" }}
          >
            <ArrowLeft className="h-4 w-4" />
            Back to gallery
          </button>
          <div className="h-4 w-px" style={{ background: "var(--border)" }} />
          <span
            style={{
              fontFamily: "'Playfair Display', serif",
              color: "var(--foreground)",
              fontSize: "1.125rem",
            }}
          >
            Admin
          </span>
          <button
            onClick={signOut}
            className="ml-auto flex items-center gap-1.5 transition-opacity hover:opacity-70"
            style={{ color: "var(--muted-foreground)", fontSize: "0.875rem" }}
          >
            <LogOut className="h-4 w-4" />
            Sign out
          </button>
        </header>

        <div
          className="flex flex-1 overflow-hidden"
          style={{ height: "calc(100vh - 57px)" }}
        >
          {/* Sidebar nav */}
          <nav
            className="flex w-44 shrink-0 flex-col gap-0.5 border-r px-3 pt-4"
            style={{
              borderColor: "var(--border)",
              background: "var(--sidebar)",
            }}
          >
            <NavLink to="/admin" className="admin-nav" end>
              <LayoutDashboard />
              Overview
            </NavLink>
            <NavLink to="/admin/venues" className="admin-nav">
              <MapPin />
              Venues
            </NavLink>
            <NavLink to="/admin/events" className="admin-nav">
              <CalendarDays />
              Events
            </NavLink>
            <NavLink to="/admin/photos" className="admin-nav">
              <Image />
              Photos
            </NavLink>
            <NavLink to="/admin/storage" className="admin-nav">
              <HardDrive />
              Storage
            </NavLink>
          </nav>

          {/* Panel */}
          <main className="flex-1 overflow-auto">
            <Suspense fallback={<Spinner />}>
              <Outlet />
            </Suspense>
          </main>
        </div>
      </div>
    </AuthGate>
  );
}
