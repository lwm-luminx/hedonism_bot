/**
 * @generated SignedSource<<ce37b133ec9efdedf80cae90557505e4>>
 * @relayHash b3bb1664a6df453c603d474663920457
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID b3bb1664a6df453c603d474663920457

import { ConcreteRequest } from 'relay-runtime';
export type AdminEventQuery$variables = Record<PropertyKey, never>;
export type AdminEventQuery$data = {
  readonly folders: {
    readonly nodes: ReadonlyArray<{
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
    "cacheID": "b3bb1664a6df453c603d474663920457",
    "id": "b3bb1664a6df453c603d474663920457",
    "metadata": {},
    "name": "AdminEventQuery",
    "operationKind": "query",
    "text": "query AdminEventQuery {\n  folders {\n    totalCount\n    nodes {\n      id\n      name\n      photoCount\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "34ae59b0248c5ff2494b7778696cdaca";

export default node;
