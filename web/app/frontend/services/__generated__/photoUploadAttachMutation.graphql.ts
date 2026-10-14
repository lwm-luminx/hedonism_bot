/**
 * @generated SignedSource<<5eb290a071bcaeda3ae8b3668de0a257>>
 * @relayHash 7251989edfa2dfaaf02a9ea96f773216
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID 7251989edfa2dfaaf02a9ea96f773216

import { ConcreteRequest } from 'relay-runtime';
export type PhotoPromiseFileInput = {
  checksum?: string | null | undefined;
  contentType: string;
  fileSizeBytes: number;
  imageHash: any;
  originalFilename: string;
};
export type photoUploadAttachMutation$variables = {
  files: ReadonlyArray<PhotoPromiseFileInput>;
  id: string;
};
export type photoUploadAttachMutation$data = {
  readonly attachPhotoPromiseFiles: {
    readonly files: ReadonlyArray<{
      readonly id: string;
      readonly uploadHeaders: any;
      readonly uploadUrl: string;
    }>;
  } | null | undefined;
};
export type photoUploadAttachMutation = {
  response: photoUploadAttachMutation$data;
  variables: photoUploadAttachMutation$variables;
};

const node: ConcreteRequest = (function(){
var v0 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "files"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "id"
},
v2 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "files",
        "variableName": "files"
      },
      {
        "kind": "Variable",
        "name": "id",
        "variableName": "id"
      }
    ],
    "concreteType": "AttachPhotoPromiseFilesPayload",
    "kind": "LinkedField",
    "name": "attachPhotoPromiseFiles",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "PhotoPromiseFile",
        "kind": "LinkedField",
        "name": "files",
        "plural": true,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "id",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "uploadUrl",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "uploadHeaders",
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
    "argumentDefinitions": [
      (v0/*:: as any*/),
      (v1/*:: as any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "photoUploadAttachMutation",
    "selections": (v2/*:: as any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v1/*:: as any*/),
      (v0/*:: as any*/)
    ],
    "kind": "Operation",
    "name": "photoUploadAttachMutation",
    "selections": (v2/*:: as any*/)
  },
  "params": {
    "cacheID": "7251989edfa2dfaaf02a9ea96f773216",
    "id": "7251989edfa2dfaaf02a9ea96f773216",
    "metadata": {},
    "name": "photoUploadAttachMutation",
    "operationKind": "mutation",
    "text": "mutation photoUploadAttachMutation(\n  $id: ID!\n  $files: [PhotoPromiseFileInput!]!\n) {\n  attachPhotoPromiseFiles(id: $id, files: $files) {\n    files {\n      id\n      uploadUrl\n      uploadHeaders\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "20f416b6118a5502e0012f2ba2b47c61";

export default node;
