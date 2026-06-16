/**
 * @generated SignedSource<<e0ec4d4efd59870ceeb75f1ae9c18b36>>
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
  "args": [
    {
      "kind": "Variable",
      "name": "faceId",
      "variableName": "faceId"
    }
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
        "args": (v4/*:: as any*/),
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
        "args": (v4/*:: as any*/),
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
      }
    ]
  },
  "params": {
    "cacheID": "20e32aebea510fb3626c5fb9ed03aaca",
    "id": null,
    "metadata": {},
    "name": "BaseApplicationQuery",
    "operationKind": "query",
    "text": "query BaseApplicationQuery(\n  $faceId: ID\n  $folderId: ID\n) {\n  folders(faceId: $faceId) {\n    nodes {\n      id\n      name\n      photoCount\n    }\n  }\n  faces(folderId: $folderId) {\n    ...FaceFragment_faces\n  }\n}\n\nfragment FaceFragment_face on Face {\n  id\n  thumbnailUrl\n  photoCount\n}\n\nfragment FaceFragment_faces on FaceConnection {\n  nodes {\n    id\n    ...FaceFragment_face\n  }\n}\n"
  }
};
})();

(node as any).hash = "a3c5b9baeafe0aee4750629a7a8f07a9";

export default node;
