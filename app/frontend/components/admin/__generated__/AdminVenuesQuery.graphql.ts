/**
 * @generated SignedSource<<446d27f070ab0b3b32f02cab02c7c1c2>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ConcreteRequest } from 'relay-runtime';
export type AdminVenuesQuery$variables = Record<PropertyKey, never>;
export type AdminVenuesQuery$data = {
  readonly events: {
    readonly nodes: ReadonlyArray<{
      readonly id: string;
      readonly name: string | null | undefined;
      readonly venue: {
        readonly id: string;
      } | null | undefined;
    } | null | undefined>;
  };
  readonly venues: {
    readonly nodes: ReadonlyArray<{
      readonly address: string | null | undefined;
      readonly city: string | null | undefined;
      readonly id: string;
      readonly name: string | null | undefined;
    } | null | undefined>;
    readonly totalCount: number;
  };
};
export type AdminVenuesQuery = {
  response: AdminVenuesQuery$data;
  variables: AdminVenuesQuery$variables;
};

const node: ConcreteRequest = (function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "totalCount",
  "storageKey": null
},
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "concreteType": "Venue",
  "kind": "LinkedField",
  "name": "nodes",
  "plural": true,
  "selections": [
    (v1/*:: as any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "city",
      "storageKey": null
    },
    (v2/*:: as any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "address",
      "storageKey": null
    }
  ],
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "concreteType": "Event",
  "kind": "LinkedField",
  "name": "nodes",
  "plural": true,
  "selections": [
    (v1/*:: as any*/),
    (v2/*:: as any*/),
    {
      "alias": null,
      "args": null,
      "concreteType": "Venue",
      "kind": "LinkedField",
      "name": "venue",
      "plural": false,
      "selections": [
        (v1/*:: as any*/)
      ],
      "storageKey": null
    }
  ],
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "AdminVenuesQuery",
    "selections": [
      {
        "kind": "RequiredField",
        "field": {
          "alias": null,
          "args": null,
          "concreteType": "VenueConnection",
          "kind": "LinkedField",
          "name": "venues",
          "plural": false,
          "selections": [
            (v0/*:: as any*/),
            {
              "kind": "RequiredField",
              "field": (v3/*:: as any*/),
              "action": "THROW"
            }
          ],
          "storageKey": null
        },
        "action": "THROW"
      },
      {
        "kind": "RequiredField",
        "field": {
          "alias": null,
          "args": null,
          "concreteType": "EventConnection",
          "kind": "LinkedField",
          "name": "events",
          "plural": false,
          "selections": [
            {
              "kind": "RequiredField",
              "field": (v4/*:: as any*/),
              "action": "THROW"
            }
          ],
          "storageKey": null
        },
        "action": "THROW"
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "AdminVenuesQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "VenueConnection",
        "kind": "LinkedField",
        "name": "venues",
        "plural": false,
        "selections": [
          (v0/*:: as any*/),
          (v3/*:: as any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "EventConnection",
        "kind": "LinkedField",
        "name": "events",
        "plural": false,
        "selections": [
          (v4/*:: as any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "80be2286ebab9aa578e4992b005de059",
    "id": null,
    "metadata": {},
    "name": "AdminVenuesQuery",
    "operationKind": "query",
    "text": "query AdminVenuesQuery {\n  venues {\n    totalCount\n    nodes {\n      id\n      city\n      name\n      address\n    }\n  }\n  events {\n    nodes {\n      id\n      name\n      venue {\n        id\n      }\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "a9b2e05a30934428ba7c97f8b4a922cf";

export default node;
