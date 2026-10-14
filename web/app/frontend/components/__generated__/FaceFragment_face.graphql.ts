/**
 * @generated SignedSource<<ae0f0ef46ac5e56d90bd4c01e4085066>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ReaderFragment } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type FaceFragment_face$data = {
  readonly id: string;
  readonly photoCount: number;
  readonly thumbnailUrl: string | null | undefined;
  readonly " $fragmentType": "FaceFragment_face";
};
export type FaceFragment_face$key = {
  readonly " $data"?: FaceFragment_face$data;
  readonly " $fragmentSpreads": FragmentRefs<"FaceFragment_face">;
};

const node: ReaderFragment = {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "FaceFragment_face",
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

(node as any).hash = "2dd24075f5c4f18a694c39fee8811f32";

export default node;
