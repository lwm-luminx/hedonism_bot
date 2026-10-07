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
    return await response.json();
};

export const relayEnvironment = new Environment({
    network: Network.create(fetchQuery),
    store: new Store(new RecordSource()),
});