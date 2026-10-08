import {Environment, FetchFunction, Network, RecordSource, Store} from 'relay-runtime';
import {csrfToken} from './csrf';

const fetchQuery: FetchFunction = async (request, variables) => {
    const response = await fetch('/graphql', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken(),
        },
        body: JSON.stringify({
            query: request.text,
            variables,
        }),
    });
    // The request id matches the Rails log line, so a reported error can be found.
    const reference = response.headers.get('X-Request-Id');
    const failed = (detail: string) =>
        new Error(`GraphQL request failed: ${detail}${reference ? ` (reference ${reference})` : ''}`);

    let payload;
    try {
        payload = await response.json();
    } catch {
        throw failed(`HTTP ${response.status}`);
    }
    if (!response.ok && !payload?.data) {
        throw failed(payload?.errors?.[0]?.message ?? `HTTP ${response.status}`);
    }
    return payload;
};

export const relayEnvironment = new Environment({
    network: Network.create(fetchQuery),
    store: new Store(new RecordSource()),
});