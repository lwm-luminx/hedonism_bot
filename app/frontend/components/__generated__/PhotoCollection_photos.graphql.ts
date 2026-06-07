/**
 * @generated SignedSource<<1297298a28f510b226eba615379f2fef>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ReaderFragment } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type PhotoCollection_photos$data = ReadonlyArray<{
  readonly id: string;
  readonly " $fragmentSpreads": FragmentRefs<"PhotoFragment">;
  readonly " $fragmentType": "PhotoCollection_photos";
}>;
export type PhotoCollection_photos$key = ReadonlyArray<{
  readonly " $data"?: PhotoCollection_photos$data;
  readonly " $fragmentSpreads": FragmentRefs<"PhotoCollection_photos">;
}>;

const node: ReaderFragment = {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": {
    "plural": true
  },
  "name": "PhotoCollection_photos",
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
      "name": "PhotoFragment"
    }
  ],
  "type": "Photo",
  "abstractKey": null
};

(node as any).hash = "b0fd704b42a6c2b93ce13c361b2fa77f";

export default node;
