import React, {
  Component,
  createContext,
  ErrorInfo,
  ReactNode,
  Suspense,
  useContext,
} from "react";
import { reportError } from "../services/errorReporting";
import { Spinner } from "./controls/Spinner";

// Bumped on each retry. Pass it as useLazyLoadQuery's fetchKey so a retry
// refetches instead of rethrowing Relay's cached error.
const RetryKeyContext = createContext(0);

export function useRetryKey() {
  return useContext(RetryKeyContext);
}

interface ErrorBoundaryProps {
  children: ReactNode;
  message?: string;
}

interface ErrorBoundaryState {
  error: Error | null;
  attempt: number;
}

// Catches a failed query (or any render error) below it and shows a retry
// instead of unmounting the whole page.
export class ErrorBoundary extends Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  state: ErrorBoundaryState = { error: null, attempt: 0 };

  static getDerivedStateFromError(error: Error) {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error(error);
    reportError(error, {
      kind: "boundary",
      component_stack: info.componentStack ?? undefined,
    });
  }

  retry = () => {
    this.setState(({ attempt }) => ({ error: null, attempt: attempt + 1 }));
  };

  render() {
    if (this.state.error) {
      return (
        <div
          role="alert"
          className="flex flex-col items-center gap-2 p-6 text-center text-sm"
          style={{ color: "var(--muted-foreground)" }}
        >
          <span>{this.props.message ?? "Something went wrong loading this."}</span>
          <button
            onClick={this.retry}
            className="rounded px-3 py-1.5"
            style={{
              background: "var(--secondary)",
              color: "var(--foreground)",
              border: "1px solid var(--border)",
              borderRadius: "var(--radius-sm)",
            }}
          >
            Try again
          </button>
        </div>
      );
    }

    return (
      <RetryKeyContext.Provider value={this.state.attempt}>
        <React.Fragment key={this.state.attempt}>
          {this.props.children}
        </React.Fragment>
      </RetryKeyContext.Provider>
    );
  }
}

// A section that loads data: spinner while loading, retry on error.
export function QueryBoundary({ children, message }: ErrorBoundaryProps) {
  return (
    <ErrorBoundary message={message}>
      <Suspense fallback={<Spinner />}>{children}</Suspense>
    </ErrorBoundary>
  );
}
