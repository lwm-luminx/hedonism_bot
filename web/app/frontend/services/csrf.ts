// Rails renders the session's CSRF token into <meta name="csrf-token"> (csrf_meta_tags).
export function csrfToken(): string {
  return (
    document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
      ?.content ?? ""
  );
}
