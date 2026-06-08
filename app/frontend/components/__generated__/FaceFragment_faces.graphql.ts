/**
 * @generated SignedSource<<a3ebf3ca1b0a6f454190c0b5603ad2a9>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ReaderFragment } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type FaceFragment_faces$data = {
  readonly nodes: ReadonlyArray<{
    readonly id: string;
    readonly " $fragmentSpreads": FragmentRefs<"FaceFragment_face">;
  } | null | undefined> | null | undefined;
  readonly " $fragmentType": "FaceFragment_faces";
};
export type FaceFragment_faces$key = {
  readonly " $data"?: FaceFragment_faces$data;
  readonly " $fragmentSpreads": FragmentRefs<"FaceFragment_faces">;
};

const node: ReaderFragment = {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "FaceFragment_faces",
  "selections": [
    {
      "alias": null,
      "args": null,
      "concreteType": "Face",
      "kind": "LinkedField",
      "name": "nodes",
      "plural": true,
      "selections": [
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "id",
          "storageKey": null
        },
        {
          "args": null,
          "kind": "FragmentSpread",
          "name": "FaceFragment_face"
        }
      ],
      "storageKey": null
    }
  ],
  "type": "FaceConnection",
  "abstractKey": null
};

(node as any).hash = "056b86a222041cb00bd2e5ba3b55ff70";

export default node;
