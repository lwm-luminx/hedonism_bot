/**
 * @generated SignedSource<<f5cdd34f4623b5f3d795e0419af1f4e7>>
 * @relayHash fc08d0b853f62ccf088fe346d93c0b4f
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID fc08d0b853f62ccf088fe346d93c0b4f

import { ConcreteRequest } from 'relay-runtime';
export type AdminOverviewQuery$variables = Record<PropertyKey, never>;
export type AdminOverviewQuery$data = {
  readonly events: {
    readonly totalCount: number;
  } | null | undefined;
  readonly photos: {
    readonly nodes: ReadonlyArray<{
      readonly isPurchased: boolean;
    } | null | undefined> | null | undefined;
    readonly totalCount: number;
  };
  readonly venues: {
    readonly totalCount: number;
  } | null | undefined;
};
export type AdminOverviewQuery = {
  response: AdminOverviewQuery$data;
  variables: AdminOverviewQuery$variables;
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
  "name": "isPurchased",
  "storageKey": null
},
v2 = [
  (v0/*:: as any*/)
],
v3 = {
  "alias": null,
  "args": null,
  "concreteType": "EventConnection",
  "kind": "LinkedField",
  "name": "events",
  "plural": false,
  "selections": (v2/*:: as any*/),
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "concreteType": "VenueConnection",
  "kind": "LinkedField",
  "name": "venues",
  "plural": false,
  "selections": (v2/*:: as any*/),
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "AdminOverviewQuery",
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
          {
            "alias": null,
            "args": null,
            "concreteType": "Photo",
            "kind": "LinkedField",
            "name": "nodes",
            "plural": true,
            "selections": [
              (v1/*:: as any*/)
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      (v3/*:: as any*/),
      (v4/*:: as any*/)
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "AdminOverviewQuery",
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
                "kind": "ScalarField",
                "name": "id",
                "storageKey": null
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      (v3/*:: as any*/),
      (v4/*:: as any*/)
    ]
  },
  "params": {
    "cacheID": "fc08d0b853f62ccf088fe346d93c0b4f",
    "id": "fc08d0b853f62ccf088fe346d93c0b4f",
    "metadata": {},
    "name": "AdminOverviewQuery",
    "operationKind": "query",
    "text": "query AdminOverviewQuery {\n  photos {\n    totalCount\n    nodes {\n      isPurchased\n      id\n    }\n  }\n  events {\n    totalCount\n  }\n  venues {\n    totalCount\n  }\n}\n"
  }
};
})();

(node as any).hash = "43267a71d090788fa4517159bed07100";

export default node;
