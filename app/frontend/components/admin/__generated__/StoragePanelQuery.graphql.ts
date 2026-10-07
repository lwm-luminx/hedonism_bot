/**
 * @generated SignedSource<<b15e1577393515b7e73ec596c2eb6309>>
 * @relayHash 21fb4b16473dddf250678aa669b61fd6
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID 21fb4b16473dddf250678aa669b61fd6

import { ConcreteRequest } from 'relay-runtime';
export type StorageTransition = "ARCHIVING" | "RESTORING" | "%future added value";
export type StoragePanelQuery$variables = Record<PropertyKey, never>;
export type StoragePanelQuery$data = {
  readonly photographer: {
    readonly storage: {
      readonly albums: ReadonlyArray<{
        readonly albumId: string;
        readonly archivedBytes: any;
        readonly bytes: any;
        readonly name: string;
        readonly originalBytes: any;
        readonly photoCount: number;
        readonly transition: StorageTransition | null | undefined;
      }>;
      readonly archiveAvailable: boolean;
      readonly archivedBytes: any;
      readonly hotBytes: any;
      readonly totalBytes: any;
    };
  };
};
export type StoragePanelQuery = {
  response: StoragePanelQuery$data;
  variables: StoragePanelQuery$variables;
};

const node: ConcreteRequest = (function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "archivedBytes",
  "storageKey": null
},
v1 = {
  "alias": null,
  "args": null,
  "concreteType": "StorageUsage",
  "kind": "LinkedField",
  "name": "storage",
  "plural": false,
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "totalBytes",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "hotBytes",
      "storageKey": null
    },
    (v0/*:: as any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "archiveAvailable",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "AlbumStorage",
      "kind": "LinkedField",
      "name": "albums",
      "plural": true,
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
          "name": "name",
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "photoCount",
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "bytes",
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "originalBytes",
          "storageKey": null
        },
        (v0/*:: as any*/),
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
};
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "StoragePanelQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Photographer",
        "kind": "LinkedField",
        "name": "photographer",
        "plural": false,
        "selections": [
          (v1/*:: as any*/)
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
    "name": "StoragePanelQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Photographer",
        "kind": "LinkedField",
        "name": "photographer",
        "plural": false,
        "selections": [
          (v1/*:: as any*/),
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "id",
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "21fb4b16473dddf250678aa669b61fd6",
    "id": "21fb4b16473dddf250678aa669b61fd6",
    "metadata": {},
    "name": "StoragePanelQuery",
    "operationKind": "query",
    "text": "query StoragePanelQuery {\n  photographer {\n    storage {\n      totalBytes\n      hotBytes\n      archivedBytes\n      archiveAvailable\n      albums {\n        albumId\n        name\n        photoCount\n        bytes\n        originalBytes\n        archivedBytes\n        transition\n      }\n    }\n    id\n  }\n}\n"
  }
};
})();

(node as any).hash = "f296f8946ef022bb435f8d12932259b1";

export default node;
