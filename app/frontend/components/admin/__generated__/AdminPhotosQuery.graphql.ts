/**
 * @generated SignedSource<<c35653721321bc3692020d11a0a5f432>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ConcreteRequest } from 'relay-runtime';
export type AdminPhotosQuery$variables = Record<PropertyKey, never>;
export type AdminPhotosQuery$data = {
  readonly events: {
    readonly nodes: ReadonlyArray<{
      readonly id: string;
      readonly name: string | null | undefined;
      readonly venue: {
        readonly id: string;
      } | null | undefined;
    } | null | undefined>;
    readonly totalCount: number;
  };
  readonly photos: {
    readonly nodes: ReadonlyArray<{
      readonly event: {
        readonly id: string;
        readonly name: string | null | undefined;
        readonly venue: {
          readonly id: string;
          readonly name: string | null | undefined;
        } | null | undefined;
      } | null | undefined;
      readonly id: string;
      readonly name: string;
      readonly previewUrl: string | null | undefined;
      readonly price: number | null | undefined;
      readonly takenAt: any;
    } | null | undefined>;
    readonly totalCount: number;
  };
  readonly venues: {
    readonly nodes: ReadonlyArray<{
      readonly city: string | null | undefined;
      readonly id: string;
      readonly name: string | null | undefined;
    } | null | undefined>;
  };
};
export type AdminPhotosQuery = {
  response: AdminPhotosQuery$data;
  variables: AdminPhotosQuery$variables;
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
  "concreteType": "Photo",
  "kind": "LinkedField",
  "name": "nodes",
  "plural": true,
  "selections": [
    (v1/*:: as any*/),
    (v2/*:: as any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "price",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "previewUrl",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "takenAt",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "Event",
      "kind": "LinkedField",
      "name": "event",
      "plural": false,
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
            (v1/*:: as any*/),
            (v2/*:: as any*/)
          ],
          "storageKey": null
        }
      ],
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
},
v5 = {
  "alias": null,
  "args": null,
  "concreteType": "Venue",
  "kind": "LinkedField",
  "name": "nodes",
  "plural": true,
  "selections": [
    (v1/*:: as any*/),
    (v2/*:: as any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "city",
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
    "name": "AdminPhotosQuery",
    "selections": [
      {
        "kind": "RequiredField",
        "field": {
          "alias": null,
          "args": null,
          "concreteType": "PhotoConnection",
          "kind": "LinkedField",
          "name": "photos",
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
            (v0/*:: as any*/),
            {
              "kind": "RequiredField",
              "field": (v4/*:: as any*/),
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
          "concreteType": "VenueConnection",
          "kind": "LinkedField",
          "name": "venues",
          "plural": false,
          "selections": [
            {
              "kind": "RequiredField",
              "field": (v5/*:: as any*/),
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
    "name": "AdminPhotosQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "PhotoConnection",
        "kind": "LinkedField",
        "name": "photos",
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
          (v0/*:: as any*/),
          (v4/*:: as any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "VenueConnection",
        "kind": "LinkedField",
        "name": "venues",
        "plural": false,
        "selections": [
          (v5/*:: as any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "564a29a528c2a72fdc91977951591017",
    "id": null,
    "metadata": {},
    "name": "AdminPhotosQuery",
    "operationKind": "query",
    "text": "query AdminPhotosQuery {\n  photos {\n    totalCount\n    nodes {\n      id\n      name\n      price\n      previewUrl\n      takenAt\n      event {\n        id\n        name\n        venue {\n          id\n          name\n        }\n      }\n    }\n  }\n  events {\n    totalCount\n    nodes {\n      id\n      name\n      venue {\n        id\n      }\n    }\n  }\n  venues {\n    nodes {\n      id\n      name\n      city\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "4c6d93d975ccfdcc9b0aac257f89a75d";

export default node;
