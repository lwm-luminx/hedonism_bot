/**
 * @generated SignedSource<<c266737c29e24347147d922a77f6786e>>
 * @relayHash 8a244bdd73d043c00734e032b4ad17aa
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID 8a244bdd73d043c00734e032b4ad17aa

import { ConcreteRequest } from 'relay-runtime';
export type AudienceKitLinksCatalogQuery$variables = {
  query?: string | null | undefined;
};
export type AudienceKitLinksCatalogQuery$data = {
  readonly audienceKitCatalog: ReadonlyArray<{
    readonly events: ReadonlyArray<{
      readonly id: string;
      readonly isCanceled: boolean;
      readonly name: string;
      readonly startAt: any | null | undefined;
      readonly venueId: string | null | undefined;
    }>;
    readonly id: string;
    readonly name: string;
    readonly venues: ReadonlyArray<{
      readonly address: string | null | undefined;
      readonly id: string;
      readonly locale: string | null | undefined;
      readonly name: string;
    }>;
  }>;
};
export type AudienceKitLinksCatalogQuery = {
  response: AudienceKitLinksCatalogQuery$data;
  variables: AudienceKitLinksCatalogQuery$variables;
};

const node: ConcreteRequest = (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "query"
  }
],
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
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "query",
        "variableName": "query"
      }
    ],
    "concreteType": "AudienceKitAudience",
    "kind": "LinkedField",
    "name": "audienceKitCatalog",
    "plural": true,
    "selections": [
      (v1/*:: as any*/),
      (v2/*:: as any*/),
      {
        "alias": null,
        "args": null,
        "concreteType": "AudienceKitEvent",
        "kind": "LinkedField",
        "name": "events",
        "plural": true,
        "selections": [
          (v1/*:: as any*/),
          (v2/*:: as any*/),
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "startAt",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "venueId",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "isCanceled",
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "AudienceKitVenue",
        "kind": "LinkedField",
        "name": "venues",
        "plural": true,
        "selections": [
          (v1/*:: as any*/),
          (v2/*:: as any*/),
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "address",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "locale",
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
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "AudienceKitLinksCatalogQuery",
    "selections": (v3/*:: as any*/),
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Operation",
    "name": "AudienceKitLinksCatalogQuery",
    "selections": (v3/*:: as any*/)
  },
  "params": {
    "cacheID": "8a244bdd73d043c00734e032b4ad17aa",
    "id": "8a244bdd73d043c00734e032b4ad17aa",
    "metadata": {},
    "name": "AudienceKitLinksCatalogQuery",
    "operationKind": "query",
    "text": "query AudienceKitLinksCatalogQuery(\n  $query: String\n) {\n  audienceKitCatalog(query: $query) {\n    id\n    name\n    events {\n      id\n      name\n      startAt\n      venueId\n      isCanceled\n    }\n    venues {\n      id\n      name\n      address\n      locale\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "8369dda4dd99f76db707042073a00527";

export default node;
