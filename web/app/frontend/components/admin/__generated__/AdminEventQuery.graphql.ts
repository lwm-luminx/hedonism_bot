/**
 * @generated SignedSource<<2764c8270c9b64173319dcbcbf1d6645>>
 * @relayHash 400ffbd7df7147d6412864951a56b9b3
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID 400ffbd7df7147d6412864951a56b9b3

import { ConcreteRequest } from 'relay-runtime';
export type AdminEventQuery$variables = Record<PropertyKey, never>;
export type AdminEventQuery$data = {
  readonly folders: {
    readonly nodes: ReadonlyArray<{
      readonly audienceKitLinks: ReadonlyArray<{
        readonly audienceId: string;
        readonly audienceName: string | null | undefined;
        readonly eventName: string | null | undefined;
        readonly eventStartAt: any | null | undefined;
        readonly venueName: string | null | undefined;
      }>;
      readonly id: string;
      readonly name: string;
      readonly photoCount: number;
    } | null | undefined> | null | undefined;
    readonly totalCount: number;
  };
};
export type AdminEventQuery = {
  response: AdminEventQuery$data;
  variables: AdminEventQuery$variables;
};

const node: ConcreteRequest = (function(){
var v0 = [
  {
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
        "kind": "ScalarField",
        "name": "totalCount",
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "Folder",
        "kind": "LinkedField",
        "name": "nodes",
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
            "concreteType": "AlbumEvent",
            "kind": "LinkedField",
            "name": "audienceKitLinks",
            "plural": true,
            "selections": [
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "audienceId",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "audienceName",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "venueName",
                "storageKey": null
              },
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
                "name": "eventStartAt",
                "storageKey": null
              }
            ],
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
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "AdminEventQuery",
    "selections": (v0/*:: as any*/),
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "AdminEventQuery",
    "selections": (v0/*:: as any*/)
  },
  "params": {
    "cacheID": "400ffbd7df7147d6412864951a56b9b3",
    "id": "400ffbd7df7147d6412864951a56b9b3",
    "metadata": {},
    "name": "AdminEventQuery",
    "operationKind": "query",
    "text": "query AdminEventQuery {\n  folders {\n    totalCount\n    nodes {\n      id\n      name\n      photoCount\n      audienceKitLinks {\n        audienceId\n        audienceName\n        venueName\n        eventName\n        eventStartAt\n      }\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "ee0769e09216ca4f232c6cda4053aab3";

export default node;
