/**
 * @generated SignedSource<<7639470899d996f23d314afabb467f66>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ConcreteRequest } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type FacesQuery$variables = Record<PropertyKey, never>;
export type FacesQuery$data = {
  readonly faces: {
    readonly nodes: ReadonlyArray<{
      readonly id: string;
      readonly " $fragmentSpreads": FragmentRefs<"FaceFragment">;
    } | null | undefined> | null | undefined;
  };
};
export type FacesQuery = {
  response: FacesQuery$data;
  variables: FacesQuery$variables;
};

const node: ConcreteRequest = (function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "FacesQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "FaceConnection",
        "kind": "LinkedField",
        "name": "faces",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "Face",
            "kind": "LinkedField",
            "name": "nodes",
            "plural": true,
            "selections": [
              (v0/*:: as any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "FaceFragment"
              }
            ],
            "storageKey": null
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
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "FacesQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "FaceConnection",
        "kind": "LinkedField",
        "name": "faces",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "Face",
            "kind": "LinkedField",
            "name": "nodes",
            "plural": true,
            "selections": [
              (v0/*:: as any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "thumbnailUrl",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "photoCount",
                "storageKey": null
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "7b9b762582c6e98217242b030ded3be5",
    "id": null,
    "metadata": {},
    "name": "FacesQuery",
    "operationKind": "query",
    "text": "query FacesQuery {\n  faces {\n    nodes {\n      id\n      ...FaceFragment\n    }\n  }\n}\n\nfragment FaceFragment on Face {\n  id\n  thumbnailUrl\n  photoCount\n}\n"
  }
};
})();

(node as any).hash = "a65bc5bad72364e0827b6698f2cd65bc";

export default node;
