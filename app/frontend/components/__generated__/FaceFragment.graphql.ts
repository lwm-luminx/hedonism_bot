/**
 * @generated SignedSource<<afced0df48c11ae9d6e39cc54a3a9455>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ReaderFragment } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type FaceFragment$data = {
  readonly id: string;
  readonly photoCount: number;
  readonly thumbnailUrl: string | null | undefined;
  readonly " $fragmentType": "FaceFragment";
};
export type FaceFragment$key = {
  readonly " $data"?: FaceFragment$data;
  readonly " $fragmentSpreads": FragmentRefs<"FaceFragment">;
};

const node: ReaderFragment = {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "FaceFragment",
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
      "name": "thumbnailUrl",
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
  "type": "Face",
  "abstractKey": null
};

(node as any).hash = "760e7ea98a238c0c43c5d84c23d5f65c";

export default node;
