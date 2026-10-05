import os

from gql import Client, gql
from gql.transport.aiohttp import AIOHTTPTransport

GRAPHQL_URL = os.environ.get("GRAPHQL_URL", "http://localhost:5000/graphql")
API_KEY = os.environ.get("API_KEY", "")

def graph_client():
    # Select your transport with a defined url endpoint
    graph_transport = AIOHTTPTransport(url=GRAPHQL_URL,
                                       timeout=300,
                                       headers={"Authorization": f"Bearer {API_KEY}"})

    # Create a GraphQL client using the defined transport
    return Client(transport=graph_transport, execute_timeout=300)


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
