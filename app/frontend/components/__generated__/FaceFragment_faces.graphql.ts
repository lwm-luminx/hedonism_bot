/**
 * @generated SignedSource<<50a48fe232c01d1177285e8b9f347fbc>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ReaderFragment } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type FaceFragment_faces$data = {
  readonly faces: {
    readonly nodes: ReadonlyArray<{
      readonly id: string;
      readonly " $fragmentSpreads": FragmentRefs<"FaceFragment_face">;
    } | null | undefined> | null | undefined;
  };
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
      "concreteType": "FaceConnection",
      "kind": "LinkedField",
      "name": "faces",
      "plural": false,
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
      "storageKey": null
    }
  ],
  "type": "Query",
  "abstractKey": null
};

(node as any).hash = "834ea23b1a449ff9e2e6b65e03a376ee";

export default node;
