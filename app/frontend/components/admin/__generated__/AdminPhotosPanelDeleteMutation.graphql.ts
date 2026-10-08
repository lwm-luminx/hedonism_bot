/**
 * @generated SignedSource<<7e19006c02fb3f8a57c112a3e9ee6d2f>>
 * @relayHash bd2bf7339b4ba29fa042fb6ef6a14ea7
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID bd2bf7339b4ba29fa042fb6ef6a14ea7

import { ConcreteRequest } from 'relay-runtime';
export type AdminPhotosPanelDeleteMutation$variables = {
  ids: ReadonlyArray<string>;
};
export type AdminPhotosPanelDeleteMutation$data = {
  readonly deletePhotos: {
    readonly deletedIds: ReadonlyArray<string>;
  } | null | undefined;
};
export type AdminPhotosPanelDeleteMutation = {
  response: AdminPhotosPanelDeleteMutation$data;
  variables: AdminPhotosPanelDeleteMutation$variables;
};

const node: ConcreteRequest = (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "ids"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "ids",
    "variableName": "ids"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "deletedIds",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*:: as any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "AdminPhotosPanelDeleteMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*:: as any*/),
        "concreteType": "DeletePhotosPayload",
        "kind": "LinkedField",
        "name": "deletePhotos",
        "plural": false,
        "selections": [
          (v2/*:: as any*/)
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
    "name": "AdminPhotosPanelDeleteMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*:: as any*/),
        "concreteType": "DeletePhotosPayload",
        "kind": "LinkedField",
        "name": "deletePhotos",
        "plural": false,
        "selections": [
          (v2/*:: as any*/),
          {
            "alias": null,
            "args": null,
            "filters": null,
            "handle": "deleteRecord",
            "key": "",
            "kind": "ScalarHandle",
            "name": "deletedIds"
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "bd2bf7339b4ba29fa042fb6ef6a14ea7",
    "id": "bd2bf7339b4ba29fa042fb6ef6a14ea7",
    "metadata": {},
    "name": "AdminPhotosPanelDeleteMutation",
    "operationKind": "mutation",
    "text": "mutation AdminPhotosPanelDeleteMutation(\n  $ids: [ID!]!\n) {\n  deletePhotos(ids: $ids) {\n    deletedIds\n  }\n}\n"
  }
};
})();

(node as any).hash = "606baa9ecef1c3111ed6b77c2ac5f4f8";

export default node;
