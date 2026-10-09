import os
from contextlib import contextmanager
from contextvars import ContextVar

from gql import Client, gql
from gql.transport.aiohttp import AIOHTTPTransport

GRAPHQL_URL = os.environ.get("GRAPHQL_URL", "http://localhost:5000/graphql")
API_KEY = os.environ.get("API_KEY", "")
_updates = ContextVar("worker_updates", default=None)


@contextmanager
def capture_updates():
    updates = []
    marker = _updates.set(updates)
    try:
        yield updates
    finally:
        _updates.reset(marker)


class WorkerClient:
    def __init__(self, client):
        self.client = client

    def execute(self, request):
        updates = _updates.get()
        if updates is not None and any(
            getattr(getattr(definition, "operation", None), "value", None) == "mutation"
            for definition in request.document.definitions
        ):
            updates.append(dict(request.variable_values))
            return {}
        return self.client.execute(request)

def graph_client():
    # Select your transport with a defined url endpoint
    graph_transport = AIOHTTPTransport(url=GRAPHQL_URL,
                                       timeout=300,
                                       headers={"Authorization": f"Bearer {API_KEY}"})

    # Create a GraphQL client using the defined transport
    return WorkerClient(Client(transport=graph_transport, execute_timeout=300))


def get_photo_url(photo_id):

    # Provide a GraphQL query
    query = gql(
        """
        query FacialRecognitionPhoto($photoId: ID!) {
          node(id: $photoId) {
            id
            ... on Photo {
              facialRecognitionUrl
            }
          }
        }
    """
    )

    query.variable_values = {"photoId": photo_id}

    result = graph_client().execute(query)
    return result['node']['facialRecognitionUrl']
