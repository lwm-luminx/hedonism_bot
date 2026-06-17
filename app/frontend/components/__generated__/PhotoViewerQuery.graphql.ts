/**
 * @generated SignedSource<<4812deafafe0805925e4ce76be349cf0>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ConcreteRequest } from 'relay-runtime';
export type PhotoViewerQuery$variables = {
  id: string;
};
export type PhotoViewerQuery$data = {
  readonly node: {
    readonly alternateDescription?: string;
    readonly id?: string;
    readonly isPurchased?: boolean;
    readonly previewUrl?: string | null | undefined;
    readonly takenAt?: any;
  } | null | undefined;
};
export type PhotoViewerQuery = {
  response: PhotoViewerQuery$data;
  variables: PhotoViewerQuery$variables;
};

const node: ConcreteRequest = (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "id"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "id"
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
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "previewUrl",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "alternateDescription",
  "storageKey": null
},
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "isPurchased",
  "storageKey": null
},
v6 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "takenAt",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "PhotoViewerQuery",
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
            "kind": "InlineFragment",
            "selections": [
              {
                "kind": "RequiredField",
                "field": (v2/*:: as any*/),
                "action": "THROW"
              },
              (v3/*:: as any*/),
              (v4/*:: as any*/),
              (v5/*:: as any*/),
              (v6/*:: as any*/)
            ],
            "type": "Photo",
            "abstractKey": null
          }
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
    "name": "PhotoViewerQuery",
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
          {
            "kind": "InlineFragment",
            "selections": [
              (v3/*:: as any*/),
              (v4/*:: as any*/),
              (v5/*:: as any*/),
              (v6/*:: as any*/)
            ],
            "type": "Photo",
            "abstractKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "9070abfef7d604370378709c3eb37b8d",
    "id": null,
    "metadata": {},
    "name": "PhotoViewerQuery",
    "operationKind": "query",
    "text": "query PhotoViewerQuery(\n  $id: ID!\n) {\n  node(id: $id) {\n    __typename\n    ... on Photo {\n      id\n      previewUrl\n      alternateDescription\n      isPurchased\n      takenAt\n    }\n    id\n  }\n}\n"
  }
};
})();

(node as any).hash = "3cac21238634f94fe51d994c3950329b";

export default node;
