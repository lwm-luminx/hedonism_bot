/**
 * @generated SignedSource<<517ac3170d14b1142b88af06ba711313>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ConcreteRequest } from 'relay-runtime';
export type AdminEventQuery$variables = Record<PropertyKey, never>;
export type AdminEventQuery$data = {
  readonly events: {
    readonly nodes: ReadonlyArray<{
      readonly date: any | null | undefined;
      readonly id: string;
      readonly name: string | null | undefined;
      readonly venue: {
        readonly id: string;
      } | null | undefined;
    } | null | undefined> | null | undefined;
    readonly totalCount: number;
  } | null | undefined;
  readonly photos: {
    readonly nodes: ReadonlyArray<{
      readonly event: {
        readonly id: string;
      } | null | undefined;
      readonly id: string;
    } | null | undefined> | null | undefined;
  };
  readonly venues: {
    readonly nodes: ReadonlyArray<{
      readonly city: string | null | undefined;
      readonly id: string;
      readonly name: string | null | undefined;
    } | null | undefined> | null | undefined;
    readonly totalCount: number;
  } | null | undefined;
};
export type AdminEventQuery = {
  response: AdminEventQuery$data;
  variables: AdminEventQuery$variables;
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
v3 = [
  (v1/*:: as any*/)
],
v4 = [
  {
    "alias": null,
    "args": null,
    "concreteType": "EventConnection",
    "kind": "LinkedField",
    "name": "events",
    "plural": false,
    "selections": [
      (v0/*:: as any*/),
      {
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
            "kind": "ScalarField",
            "name": "date",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "Venue",
            "kind": "LinkedField",
            "name": "venue",
            "plural": false,
            "selections": (v3/*:: as any*/),
            "storageKey": null
          }
        ],
        "storageKey": null
      }
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
      (v0/*:: as any*/),
      {
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
      }
    ],
    "storageKey": null
  },
  {
    "alias": null,
    "args": null,
    "concreteType": "PhotoConnection",
    "kind": "LinkedField",
    "name": "photos",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Photo",
        "kind": "LinkedField",
        "name": "nodes",
        "plural": true,
        "selections": [
          (v1/*:: as any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Event",
            "kind": "LinkedField",
            "name": "event",
            "plural": false,
            "selections": (v3/*:: as any*/),
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ],
    "storageKey": null
  }
];
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "AdminEventQuery",
    "selections": (v4/*:: as any*/),
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "AdminEventQuery",
    "selections": (v4/*:: as any*/)
  },
  "params": {
    "cacheID": "db6c9fb0538b7e25436189b5d7377045",
    "id": null,
    "metadata": {},
    "name": "AdminEventQuery",
    "operationKind": "query",
    "text": "query AdminEventQuery {\n  events {\n    totalCount\n    nodes {\n      id\n      name\n      date\n      venue {\n        id\n      }\n    }\n  }\n  venues {\n    totalCount\n    nodes {\n      id\n      name\n      city\n    }\n  }\n  photos {\n    nodes {\n      id\n      event {\n        id\n      }\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "1686d372bf334caf7c3e66b1f593deab";

export default node;
