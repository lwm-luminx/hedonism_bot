/**
 * @generated SignedSource<<0f9aa722e0529c9f6dae6ad1ea37ec5e>>
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
    readonly " $fragmentSpreads": FragmentRefs<"FaceFragment_faces">;
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
  "kind": "Variable",
  "name": "faceId",
  "variableName": "faceId"
},
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
  "name": "photoCount",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": [
    (v1/*:: as any*/)
  ],
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
        (v2/*:: as any*/),
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "name",
          "storageKey": null
        },
        (v3/*:: as any*/)
      ],
      "storageKey": null
    }
  ],
  "storageKey": null
},
v5 = {
  "kind": "Variable",
  "name": "folderId",
  "variableName": "folderId"
},
v6 = [
  (v5/*:: as any*/)
],
v7 = [
  (v1/*:: as any*/),
  (v5/*:: as any*/)
];
return {
  "fragment": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "BaseApplicationQuery",
    "selections": [
      (v4/*:: as any*/),
      {
        "alias": null,
        "args": (v6/*:: as any*/),
        "concreteType": "FaceConnection",
        "kind": "LinkedField",
        "name": "faces",
        "plural": false,
        "selections": [
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "FaceFragment_faces"
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v7/*:: as any*/),
        "concreteType": "Photo",
        "kind": "LinkedField",
        "name": "photos",
        "plural": true,
        "selections": [
          (v2/*:: as any*/),
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
      (v4/*:: as any*/),
      {
        "alias": null,
        "args": (v6/*:: as any*/),
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
              (v2/*:: as any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "thumbnailUrl",
                "storageKey": null
              },
              (v3/*:: as any*/)
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v7/*:: as any*/),
        "concreteType": "Photo",
        "kind": "LinkedField",
        "name": "photos",
        "plural": true,
        "selections": [
          (v2/*:: as any*/),
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
    "cacheID": "7733aa4b79324d511806c9ea18d25cfc",
    "id": null,
    "metadata": {},
    "name": "BaseApplicationQuery",
    "operationKind": "query",
    "text": "query BaseApplicationQuery(\n  $faceId: ID\n  $folderId: ID\n) {\n  folders(faceId: $faceId) {\n    nodes {\n      id\n      name\n      photoCount\n    }\n  }\n  faces(folderId: $folderId) {\n    ...FaceFragment_faces\n  }\n  photos(faceId: $faceId, folderId: $folderId) {\n    id\n    ...PhotoCollection_photos\n    ...PhotoFragment\n  }\n}\n\nfragment FaceFragment_face on Face {\n  id\n  thumbnailUrl\n  photoCount\n}\n\nfragment FaceFragment_faces on FaceConnection {\n  nodes {\n    id\n    ...FaceFragment_face\n  }\n}\n\nfragment PhotoCollection_photos on Photo {\n  id\n  ...PhotoFragment\n}\n\nfragment PhotoFragment on Photo {\n  id\n  isPurchased\n  previewUrl\n  takenAt\n  caption\n}\n"
  }
};
})();

(node as any).hash = "74faf1365f7bd0a67ea1b21e98abfc72";

export default node;
