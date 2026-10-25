/**
 * @generated SignedSource<<15f7cdf9644a887e0ed7b59264af5ce3>>
 * @relayHash c4e1b4fc54bc259ca9c0288042d91b46
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID c4e1b4fc54bc259ca9c0288042d91b46

import { ConcreteRequest } from 'relay-runtime';
export type AudienceKitLinksUnlinkMutation$variables = {
  audienceId: string;
  folderId: string;
};
export type AudienceKitLinksUnlinkMutation$data = {
  readonly unlinkAlbumFromAudienceKit: {
    readonly folder: {
      readonly id: string;
    };
  } | null | undefined;
};
export type AudienceKitLinksUnlinkMutation = {
  response: AudienceKitLinksUnlinkMutation$data;
  variables: AudienceKitLinksUnlinkMutation$variables;
};

const node: ConcreteRequest = (function(){
var v0 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "audienceId"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "folderId"
},
v2 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "audienceId",
        "variableName": "audienceId"
      },
      {
        "kind": "Variable",
        "name": "folderId",
        "variableName": "folderId"
      }
    ],
    "concreteType": "UnlinkAlbumFromAudienceKitPayload",
    "kind": "LinkedField",
    "name": "unlinkAlbumFromAudienceKit",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Folder",
        "kind": "LinkedField",
        "name": "folder",
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
    "argumentDefinitions": [
      (v0/*:: as any*/),
      (v1/*:: as any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "AudienceKitLinksUnlinkMutation",
    "selections": (v2/*:: as any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v1/*:: as any*/),
      (v0/*:: as any*/)
    ],
    "kind": "Operation",
    "name": "AudienceKitLinksUnlinkMutation",
    "selections": (v2/*:: as any*/)
  },
  "params": {
    "cacheID": "c4e1b4fc54bc259ca9c0288042d91b46",
    "id": "c4e1b4fc54bc259ca9c0288042d91b46",
    "metadata": {},
    "name": "AudienceKitLinksUnlinkMutation",
    "operationKind": "mutation",
    "text": "mutation AudienceKitLinksUnlinkMutation(\n  $folderId: ID!\n  $audienceId: ID!\n) {\n  unlinkAlbumFromAudienceKit(folderId: $folderId, audienceId: $audienceId) {\n    folder {\n      id\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "d2b3e2f9e8ad09189aa31acd81cfba61";

export default node;
