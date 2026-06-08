/**
 * @generated SignedSource<<eaeee3b598302cf32526d925674877af>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ConcreteRequest } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type BaseApplicationQuery$variables = Record<PropertyKey, never>;
export type BaseApplicationQuery$data = {
  readonly folders: {
    readonly nodes: ReadonlyArray<{
      readonly id: string;
      readonly name: string;
    } | null | undefined> | null | undefined;
  };
  readonly photos: ReadonlyArray<{
    readonly id: string;
    readonly " $fragmentSpreads": FragmentRefs<"PhotoCollection_photos" | "PhotoFragment">;
  }>;
  readonly " $fragmentSpreads": FragmentRefs<"FaceFragment_faces">;
};
export type BaseApplicationQuery = {
  response: BaseApplicationQuery$data;
  variables: BaseApplicationQuery$variables;
};

const node: ConcreteRequest = (function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v1 = {
  "alias": null,
  "args": null,
  "concreteType": "FolderConnection",
  "kind": "LinkedField",
  "name": "folders",
  "plural": false,
  "selections": [
    {
      "alias": null,
      "args": null,
      "concreteType": "Folder",
      "kind": "LinkedField",
      "name": "nodes",
      "plural": true,
      "selections": [
        (v0/*:: as any*/),
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "name",
          "storageKey": null
        }
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
    "name": "BaseApplicationQuery",
    "selections": [
      (v1/*:: as any*/),
      {
        "args": null,
        "kind": "FragmentSpread",
        "name": "FaceFragment_faces"
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "Photo",
        "kind": "LinkedField",
        "name": "photos",
        "plural": true,
        "selections": [
          (v0/*:: as any*/),
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "PhotoCollection_photos"
          },
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "PhotoFragment"
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
    "name": "BaseApplicationQuery",
    "selections": [
      (v1/*:: as any*/),
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
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "Photo",
        "kind": "LinkedField",
        "name": "photos",
        "plural": true,
        "selections": [
          (v0/*:: as any*/),
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
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "44a0d496c03ef6fd47161e9a2c2ae88d",
    "id": null,
    "metadata": {},
    "name": "BaseApplicationQuery",
    "operationKind": "query",
    "text": "query BaseApplicationQuery {\n  folders {\n    nodes {\n      id\n      name\n    }\n  }\n  ...FaceFragment_faces\n  photos {\n    id\n    ...PhotoCollection_photos\n    ...PhotoFragment\n  }\n}\n\nfragment FaceFragment_face on Face {\n  id\n  thumbnailUrl\n  photoCount\n}\n\nfragment FaceFragment_faces on Query {\n  faces {\n    nodes {\n      id\n      ...FaceFragment_face\n    }\n  }\n}\n\nfragment PhotoCollection_photos on Photo {\n  id\n  ...PhotoFragment\n}\n\nfragment PhotoFragment on Photo {\n  id\n  isPurchased\n  previewUrl\n  takenAt\n  caption\n}\n"
  }
};
})();

(node as any).hash = "6e64a263e84e75c1233b298397d32dcf";

export default node;
