/**
 * @generated SignedSource<<403ea5b2d1c10f98238488b06acaa6fa>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ConcreteRequest } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type BaseApplicationQuery$variables = {
  faceId?: string | null | undefined;
  folderId?: string | null | undefined;
};
export type BaseApplicationQuery$data = {
  readonly faces: {
    readonly nodes: ReadonlyArray<{
      readonly id: string;
      readonly " $fragmentSpreads": FragmentRefs<"FaceFragment">;
    } | null | undefined> | null | undefined;
  };
  readonly folders: {
    readonly nodes: ReadonlyArray<{
      readonly id: string;
      readonly name: string;
      readonly photoCount: number;
    } | null | undefined> | null | undefined;
  };
  readonly photos: ReadonlyArray<{
    readonly id: string;
    readonly " $fragmentSpreads": FragmentRefs<"PhotoCollection_photos" | "PhotoFragment">;
  }>;
};
export type BaseApplicationQuery = {
  response: BaseApplicationQuery$data;
  variables: BaseApplicationQuery$variables;
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
  "name": "photoCount",
  "storageKey": null
},
v3 = {
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
        (v1/*:: as any*/),
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "name",
          "storageKey": null
        },
        (v2/*:: as any*/)
      ],
      "storageKey": null
    }
  ],
  "storageKey": null
},
v4 = [
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
];
return {
  "fragment": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "BaseApplicationQuery",
    "selections": [
      (v3/*:: as any*/),
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
              (v1/*:: as any*/),
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
      },
      {
        "alias": null,
        "args": (v4/*:: as any*/),
        "concreteType": "Photo",
        "kind": "LinkedField",
        "name": "photos",
        "plural": true,
        "selections": [
          (v1/*:: as any*/),
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
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Operation",
    "name": "BaseApplicationQuery",
    "selections": [
      (v3/*:: as any*/),
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
              (v1/*:: as any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "thumbnailUrl",
                "storageKey": null
              },
              (v2/*:: as any*/)
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v4/*:: as any*/),
        "concreteType": "Photo",
        "kind": "LinkedField",
        "name": "photos",
        "plural": true,
        "selections": [
          (v1/*:: as any*/),
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
    "cacheID": "d82e985b26a182556d14e8d2da61aa5e",
    "id": null,
    "metadata": {},
    "name": "BaseApplicationQuery",
    "operationKind": "query",
    "text": "query BaseApplicationQuery(\n  $faceId: ID\n  $folderId: ID\n) {\n  folders {\n    nodes {\n      id\n      name\n      photoCount\n    }\n  }\n  faces {\n    nodes {\n      id\n      ...FaceFragment\n    }\n  }\n  photos(faceId: $faceId, folderId: $folderId) {\n    id\n    ...PhotoCollection_photos\n    ...PhotoFragment\n  }\n}\n\nfragment FaceFragment on Face {\n  id\n  thumbnailUrl\n  photoCount\n}\n\nfragment PhotoCollection_photos on Photo {\n  id\n  ...PhotoFragment\n}\n\nfragment PhotoFragment on Photo {\n  id\n  isPurchased\n  previewUrl\n  takenAt\n  caption\n}\n"
  }
};
})();

(node as any).hash = "5abe182d52d393c092a4bd4eac2bf9b4";

export default node;
