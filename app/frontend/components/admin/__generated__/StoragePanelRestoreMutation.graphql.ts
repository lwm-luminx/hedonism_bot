/**
 * @generated SignedSource<<51518799db2e2b9daa60ec20d72db332>>
 * @relayHash bc5a6686a60762177df862d07e44ac02
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID bc5a6686a60762177df862d07e44ac02

import { ConcreteRequest } from 'relay-runtime';
export type StorageTransition = "ARCHIVING" | "RESTORING" | "%future added value";
export type StoragePanelRestoreMutation$variables = {
  id: string;
};
export type StoragePanelRestoreMutation$data = {
  readonly restoreAlbum: {
    readonly album: {
      readonly albumId: string;
      readonly transition: StorageTransition | null | undefined;
    };
  } | null | undefined;
};
export type StoragePanelRestoreMutation = {
  response: StoragePanelRestoreMutation$data;
  variables: StoragePanelRestoreMutation$variables;
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
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "id",
        "variableName": "id"
      }
    ],
    "concreteType": "RestoreAlbumPayload",
    "kind": "LinkedField",
    "name": "restoreAlbum",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "AlbumStorage",
        "kind": "LinkedField",
        "name": "album",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "albumId",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "transition",
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
    "name": "StoragePanelRestoreMutation",
    "selections": (v1/*:: as any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Operation",
    "name": "StoragePanelRestoreMutation",
    "selections": (v1/*:: as any*/)
  },
  "params": {
    "cacheID": "bc5a6686a60762177df862d07e44ac02",
    "id": "bc5a6686a60762177df862d07e44ac02",
    "metadata": {},
    "name": "StoragePanelRestoreMutation",
    "operationKind": "mutation",
    "text": "mutation StoragePanelRestoreMutation(\n  $id: ID!\n) {\n  restoreAlbum(id: $id) {\n    album {\n      albumId\n      transition\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "5b504c2da29cf8e45c927aed4611f0d7";

export default node;
