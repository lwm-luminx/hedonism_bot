/**
 * @generated SignedSource<<db45f1959b6de45a44108930a8452494>>
 * @relayHash 312a23103b278a989c02bc47c212c922
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID 312a23103b278a989c02bc47c212c922

import { ConcreteRequest } from 'relay-runtime';
export type EventsPanelDeleteMutation$variables = {
  id: string;
};
export type EventsPanelDeleteMutation$data = {
  readonly deleteAlbum: {
    readonly deletedId: string;
  } | null | undefined;
};
export type EventsPanelDeleteMutation = {
  response: EventsPanelDeleteMutation$data;
  variables: EventsPanelDeleteMutation$variables;
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
    "concreteType": "DeleteAlbumPayload",
    "kind": "LinkedField",
    "name": "deleteAlbum",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "deletedId",
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
    "name": "EventsPanelDeleteMutation",
    "selections": (v1/*:: as any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Operation",
    "name": "EventsPanelDeleteMutation",
    "selections": (v1/*:: as any*/)
  },
  "params": {
    "cacheID": "312a23103b278a989c02bc47c212c922",
    "id": "312a23103b278a989c02bc47c212c922",
    "metadata": {},
    "name": "EventsPanelDeleteMutation",
    "operationKind": "mutation",
    "text": "mutation EventsPanelDeleteMutation(\n  $id: ID!\n) {\n  deleteAlbum(id: $id) {\n    deletedId\n  }\n}\n"
  }
};
})();

(node as any).hash = "4a2c2ad08d20bb0dcd1c80b9743ff2d4";

export default node;
