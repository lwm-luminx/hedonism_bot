/**
 * @generated SignedSource<<70a538517e221daa14901ec1a5c5348f>>
 * @relayHash 9a799d9216bf40c31339232ddb6099e1
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID 9a799d9216bf40c31339232ddb6099e1

import { ConcreteRequest } from 'relay-runtime';
export type PhotoPromiseFileStatus = "FAILED" | "PENDING" | "SUCCESS" | "%future added value";
export type photoUploadFinishMutation$variables = {
  id: string;
  status: PhotoPromiseFileStatus;
};
export type photoUploadFinishMutation$data = {
  readonly updatePhotoPromiseFileUpdate: {
    readonly file: {
      readonly status: PhotoPromiseFileStatus;
    };
  } | null | undefined;
};
export type photoUploadFinishMutation = {
  response: photoUploadFinishMutation$data;
  variables: photoUploadFinishMutation$variables;
};

const node: ConcreteRequest = (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "id"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "status"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "id"
  },
  {
    "kind": "Variable",
    "name": "status",
    "variableName": "status"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "status",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "photoUploadFinishMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*:: as any*/),
        "concreteType": "UpdatePhotoPromiseFileUpdatePayload",
        "kind": "LinkedField",
        "name": "updatePhotoPromiseFileUpdate",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "PhotoPromiseFile",
            "kind": "LinkedField",
            "name": "file",
            "plural": false,
            "selections": [
              (v2/*:: as any*/)
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ],
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Operation",
    "name": "photoUploadFinishMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*:: as any*/),
        "concreteType": "UpdatePhotoPromiseFileUpdatePayload",
        "kind": "LinkedField",
        "name": "updatePhotoPromiseFileUpdate",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "PhotoPromiseFile",
            "kind": "LinkedField",
            "name": "file",
            "plural": false,
            "selections": [
              (v2/*:: as any*/),
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
    ]
  },
  "params": {
    "cacheID": "9a799d9216bf40c31339232ddb6099e1",
    "id": "9a799d9216bf40c31339232ddb6099e1",
    "metadata": {},
    "name": "photoUploadFinishMutation",
    "operationKind": "mutation",
    "text": "mutation photoUploadFinishMutation(\n  $id: ID!\n  $status: PhotoPromiseFileStatus!\n) {\n  updatePhotoPromiseFileUpdate(id: $id, status: $status) {\n    file {\n      status\n      id\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "53d9e7818743609b3583fc3f50bd220e";

export default node;
