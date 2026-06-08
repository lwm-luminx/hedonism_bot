import {Environment, FetchFunction, Network, RecordSource, Store} from 'relay-runtime';

const fetchQuery: FetchFunction = async (request, variables) => {
    const response = await fetch('http://localhost:5000/graphql', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
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