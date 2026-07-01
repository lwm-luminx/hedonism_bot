/**
 * @generated SignedSource<<e1f2f0fafafd890196a7fc62df981544>>
 * @relayHash e84548eb7d458efbe12d060121b7b3f3
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID e84548eb7d458efbe12d060121b7b3f3

import { ConcreteRequest } from 'relay-runtime';
export type CreatePhotoPromiseMutation$variables = Record<PropertyKey, never>;
export type CreatePhotoPromiseMutation$data = {
  readonly createPhotoPromise: {
    readonly promise: {
      readonly id: string;
    };
  } | null | undefined;
};
export type CreatePhotoPromiseMutation = {
  response: CreatePhotoPromiseMutation$data;
  variables: CreatePhotoPromiseMutation$variables;
};

const node: ConcreteRequest = (function(){
var v0 = [
  {
    "alias": null,
    "args": null,
    "concreteType": "CreatePhotoPromisePayload",
    "kind": "LinkedField",
    "name": "createPhotoPromise",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "PhotoPromise",
        "kind": "LinkedField",
        "name": "promise",
        "plural": false,
        "selections": [
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
    ],
    "storageKey": null
  }
];
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "CreatePhotoPromiseMutation",
    "selections": (v0/*:: as any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "CreatePhotoPromiseMutation",
    "selections": (v0/*:: as any*/)
  },
  "params": {
    "cacheID": "e84548eb7d458efbe12d060121b7b3f3",
    "id": "e84548eb7d458efbe12d060121b7b3f3",
    "metadata": {},
    "name": "CreatePhotoPromiseMutation",
    "operationKind": "mutation",
    "text": "mutation CreatePhotoPromiseMutation {\n  createPhotoPromise {\n    promise {\n      id\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "6737e46685817aeb48758d28655201d8";

export default node;
