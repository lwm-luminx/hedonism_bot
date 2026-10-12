/**
 * @generated SignedSource<<273a8f7dba6ae1fa0a5737115376a54d>>
 * @relayHash cdc39673a687ce9c8747d951db797b3c
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID cdc39673a687ce9c8747d951db797b3c

import { ConcreteRequest } from 'relay-runtime';
export type PhotoPurchaseQuery$variables = {
  photoId: string;
};
export type PhotoPurchaseQuery$data = {
  readonly node: {
    readonly alternateDescription?: string;
    readonly id: string;
    readonly previewUrl?: string | null | undefined;
    readonly takenAt?: any;
  } | null | undefined;
};
export type PhotoPurchaseQuery = {
  response: PhotoPurchaseQuery$data;
  variables: PhotoPurchaseQuery$variables;
};

const node: ConcreteRequest = (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "photoId"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "photoId"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v3 = {
  "kind": "InlineFragment",
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "alternateDescription",
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
    }
  ],
  "type": "PhotoTake",
  "abstractKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "PhotoPurchaseQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*:: as any*/),
        "concreteType": null,
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          (v2/*:: as any*/),
          (v3/*:: as any*/)
        ],
        "storageKey": null
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Operation",
    "name": "PhotoPurchaseQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*:: as any*/),
        "concreteType": null,
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "__typename",
            "storageKey": null
          },
          (v2/*:: as any*/),
          (v3/*:: as any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "cdc39673a687ce9c8747d951db797b3c",
    "id": "cdc39673a687ce9c8747d951db797b3c",
    "metadata": {},
    "name": "PhotoPurchaseQuery",
    "operationKind": "query",
    "text": "query PhotoPurchaseQuery(\n  $photoId: ID!\n) {\n  node(id: $photoId) {\n    __typename\n    id\n    ... on PhotoTake {\n      id\n      alternateDescription\n      previewUrl\n      takenAt\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "faddbb024471fb1063fe0585a1b4cd5c";

export default node;
