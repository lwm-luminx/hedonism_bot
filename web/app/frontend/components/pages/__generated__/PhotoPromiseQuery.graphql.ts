/**
 * @generated SignedSource<<6503a472100d2f328d02b0eba397d992>>
 * @relayHash c46ede6766eebe7045080a40e80a14ee
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID c46ede6766eebe7045080a40e80a14ee

import { ConcreteRequest } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type PhotoPromiseQuery$variables = {
  id: string;
};
export type PhotoPromiseQuery$data = {
  readonly node: {
    readonly photoPromise: {
      readonly " $fragmentSpreads": FragmentRefs<"PhotoPromiseFragment">;
    } | null | undefined;
  } | null | undefined;
};
export type PhotoPromiseQuery = {
  response: PhotoPromiseQuery$data;
  variables: PhotoPromiseQuery$variables;
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
    "kind": "Variable",
    "name": "id",
    "variableName": "id"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "PhotoPromiseQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*:: as any*/),
        "concreteType": null,
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          {
            "fragment": {
              "kind": "InlineFragment",
              "selections": [
                {
                  "args": null,
                  "kind": "FragmentSpread",
                  "name": "PhotoPromiseFragment"
                }
              ],
              "type": "PhotoPromise",
              "abstractKey": null
            },
            "kind": "AliasedInlineFragmentSpread",
            "name": "photoPromise"
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
    "name": "PhotoPromiseQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*:: as any*/),
        "concreteType": null,
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "__typename",
            "storageKey": null
          },
          (v2/*:: as any*/),
          {
            "kind": "InlineFragment",
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "PhotoPromiseFileConnection",
                "kind": "LinkedField",
                "name": "files",
                "plural": false,
                "selections": [
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "PhotoPromiseFile",
                    "kind": "LinkedField",
                    "name": "nodes",
                    "plural": true,
                    "selections": [
                      (v2/*:: as any*/)
                    ],
                    "storageKey": null
                  }
                ],
                "storageKey": null
              }
            ],
            "type": "PhotoPromise",
            "abstractKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "c46ede6766eebe7045080a40e80a14ee",
    "id": "c46ede6766eebe7045080a40e80a14ee",
    "metadata": {},
    "name": "PhotoPromiseQuery",
    "operationKind": "query",
    "text": "query PhotoPromiseQuery(\n  $id: ID!\n) {\n  node(id: $id) {\n    __typename\n    ...PhotoPromiseFragment\n    id\n  }\n}\n\nfragment PhotoPromiseFragment on PhotoPromise {\n  id\n  files {\n    nodes {\n      id\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "fc6cce3716d4101780919309b0037fec";

export default node;
