/**
 * @generated SignedSource<<608ffcee4f09a5cfd0aeccee5045062b>>
 * @relayHash 6b353e8b7503eedfa6ac9059a6548ced
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID 6b353e8b7503eedfa6ac9059a6548ced

import { ConcreteRequest } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type PhotosViewQuery$variables = {
  faceId?: string | null | undefined;
  folderId?: string | null | undefined;
};
export type PhotosViewQuery$data = {
  readonly photos: {
    readonly nodes: ReadonlyArray<{
      readonly id: string;
      readonly " $fragmentSpreads": FragmentRefs<"PhotoFragment">;
    } | null | undefined> | null | undefined;
  };
};
export type PhotosViewQuery = {
  response: PhotosViewQuery$data;
  variables: PhotosViewQuery$variables;
};

const node: ConcreteRequest = (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "faceId"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "folderId"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "faceId",
    "variableName": "faceId"
  },
  {
    "kind": "Variable",
    "name": "folderId",
    "variableName": "folderId"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "PhotosViewQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*:: as any*/),
        "concreteType": "PhotoTakeConnection",
        "kind": "LinkedField",
        "name": "photos",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "PhotoTake",
            "kind": "LinkedField",
            "name": "nodes",
            "plural": true,
            "selections": [
              (v2/*:: as any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "PhotoFragment"
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
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Operation",
    "name": "PhotosViewQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*:: as any*/),
        "concreteType": "PhotoTakeConnection",
        "kind": "LinkedField",
        "name": "photos",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "PhotoTake",
            "kind": "LinkedField",
            "name": "nodes",
            "plural": true,
            "selections": [
              (v2/*:: as any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "eventName",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "isPurchased",
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
                "kind": "ScalarField",
                "name": "caption",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "alternateDescription",
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
    "cacheID": "6b353e8b7503eedfa6ac9059a6548ced",
    "id": "6b353e8b7503eedfa6ac9059a6548ced",
    "metadata": {},
    "name": "PhotosViewQuery",
    "operationKind": "query",
    "text": "query PhotosViewQuery(\n  $faceId: ID\n  $folderId: ID\n) {\n  photos(faceId: $faceId, folderId: $folderId) {\n    nodes {\n      id\n      ...PhotoFragment\n    }\n  }\n}\n\nfragment PhotoFragment on PhotoTake {\n  id\n  eventName\n  isPurchased\n  previewUrl\n  takenAt\n  caption\n  alternateDescription\n}\n"
  }
};
})();

(node as any).hash = "6752380a456f5e05ce5abba7f3be1523";

export default node;
