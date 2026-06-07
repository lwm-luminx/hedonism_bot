/**
 * @generated SignedSource<<b749704ef59b93ceb54cf2ce40234391>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ReaderFragment } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type PhotoFragment$data = {
  readonly caption: string | null | undefined;
  readonly id: string;
  readonly isPurchased: boolean;
  readonly previewUrl: string | null | undefined;
  readonly takenAt: any;
  readonly " $fragmentType": "PhotoFragment";
};
export type PhotoFragment$key = {
  readonly " $data"?: PhotoFragment$data;
  readonly " $fragmentSpreads": FragmentRefs<"PhotoFragment">;
};

const node: ReaderFragment = {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "PhotoFragment",
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
      "name": "isPurchased",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "previewUrl",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "takenAt",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "caption",
      "storageKey": null
    }
  ],
  "type": "Photo",
  "abstractKey": null
};

(node as any).hash = "9280cae34188e3f1488961f732e0be3d";

export default node;
