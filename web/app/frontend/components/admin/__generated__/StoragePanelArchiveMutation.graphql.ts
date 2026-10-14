/**
 * @generated SignedSource<<41cd6c03cc07eb95decfa42a752151ff>>
 * @relayHash cc8d50971ccfd5f2b83e7e7ccfa71ac1
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID cc8d50971ccfd5f2b83e7e7ccfa71ac1

import { ConcreteRequest } from 'relay-runtime';
export type StorageTransition = "ARCHIVING" | "RESTORING" | "%future added value";
export type StoragePanelArchiveMutation$variables = {
  id: string;
};
export type StoragePanelArchiveMutation$data = {
  readonly archiveAlbum: {
    readonly album: {
      readonly albumId: string;
      readonly transition: StorageTransition | null | undefined;
    };
  } | null | undefined;
};
export type StoragePanelArchiveMutation = {
  response: StoragePanelArchiveMutation$data;
  variables: StoragePanelArchiveMutation$variables;
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
    "concreteType": "ArchiveAlbumPayload",
    "kind": "LinkedField",
    "name": "archiveAlbum",
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
    "name": "StoragePanelArchiveMutation",
    "selections": (v1/*:: as any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Operation",
    "name": "StoragePanelArchiveMutation",
    "selections": (v1/*:: as any*/)
  },
  "params": {
    "cacheID": "cc8d50971ccfd5f2b83e7e7ccfa71ac1",
    "id": "cc8d50971ccfd5f2b83e7e7ccfa71ac1",
    "metadata": {},
    "name": "StoragePanelArchiveMutation",
    "operationKind": "mutation",
    "text": "mutation StoragePanelArchiveMutation(\n  $id: ID!\n) {\n  archiveAlbum(id: $id) {\n    album {\n      albumId\n      transition\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "93ef4afc20b0c35db57172373ad44495";

export default node;
