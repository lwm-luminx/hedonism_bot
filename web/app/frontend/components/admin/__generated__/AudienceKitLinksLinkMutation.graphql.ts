/**
 * @generated SignedSource<<f95bdda276ec7cf9e6df9a7030e953f8>>
 * @relayHash 6b79a74d51cee6cfb03136cac90a3da8
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

// @relayRequestID 6b79a74d51cee6cfb03136cac90a3da8

import { ConcreteRequest } from 'relay-runtime';
export type AudienceKitLinksLinkMutation$variables = {
  audienceId: string;
  eventId?: string | null | undefined;
  folderId: string;
  venueId?: string | null | undefined;
};
export type AudienceKitLinksLinkMutation$data = {
  readonly linkAlbumToAudienceKit: {
    readonly link: {
      readonly audienceId: string;
    };
  } | null | undefined;
};
export type AudienceKitLinksLinkMutation = {
  response: AudienceKitLinksLinkMutation$data;
  variables: AudienceKitLinksLinkMutation$variables;
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
  "name": "eventId"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "folderId"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "venueId"
},
v4 = [
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
        "name": "eventId",
        "variableName": "eventId"
      },
      {
        "kind": "Variable",
        "name": "folderId",
        "variableName": "folderId"
      },
      {
        "kind": "Variable",
        "name": "venueId",
        "variableName": "venueId"
      }
    ],
    "concreteType": "LinkAlbumToAudienceKitPayload",
    "kind": "LinkedField",
    "name": "linkAlbumToAudienceKit",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "AlbumEvent",
        "kind": "LinkedField",
        "name": "link",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "audienceId",
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
      (v1/*:: as any*/),
      (v2/*:: as any*/),
      (v3/*:: as any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "AudienceKitLinksLinkMutation",
    "selections": (v4/*:: as any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v2/*:: as any*/),
      (v0/*:: as any*/),
      (v1/*:: as any*/),
      (v3/*:: as any*/)
    ],
    "kind": "Operation",
    "name": "AudienceKitLinksLinkMutation",
    "selections": (v4/*:: as any*/)
  },
  "params": {
    "cacheID": "6b79a74d51cee6cfb03136cac90a3da8",
    "id": "6b79a74d51cee6cfb03136cac90a3da8",
    "metadata": {},
    "name": "AudienceKitLinksLinkMutation",
    "operationKind": "mutation",
    "text": "mutation AudienceKitLinksLinkMutation(\n  $folderId: ID!\n  $audienceId: ID!\n  $eventId: ID\n  $venueId: ID\n) {\n  linkAlbumToAudienceKit(folderId: $folderId, audienceId: $audienceId, eventId: $eventId, venueId: $venueId) {\n    link {\n      audienceId\n    }\n  }\n}\n"
  }
};
})();

(node as any).hash = "556c750ee307f124e57ed4fdc011a033";

export default node;
