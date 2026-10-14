/**
 * @generated SignedSource<<cc1f84752bf61cd9368d1dfdd22abfd9>>
 * @lightSyntaxTransform
 */

/* tslint:disable */
/* eslint-disable */
// @ts-nocheck

import { ReaderFragment } from 'relay-runtime';
import { FragmentRefs } from "relay-runtime";
export type PhotoPromiseFragment$data = {
  readonly files: {
    readonly nodes: ReadonlyArray<{
      readonly id: string;
    } | null | undefined> | null | undefined;
  };
  readonly id: string;
  readonly " $fragmentType": "PhotoPromiseFragment";
};
export type PhotoPromiseFragment$key = {
  readonly " $data"?: PhotoPromiseFragment$data;
  readonly " $fragmentSpreads": FragmentRefs<"PhotoPromiseFragment">;
};

const node: ReaderFragment = (function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
};
return {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "PhotoPromiseFragment",
  "selections": [
    (v0/*:: as any*/),
    {
      "alias": null,
      "args": null,
      "concreteType": "PhotoPromiseFileConnection",
      "kind": "LinkedField",
      "name": "files",
      "plural": false,
      "selections": [
        {
          "alias": null,
          "args": null,
          "concreteType": "PhotoPromiseFile",
          "kind": "LinkedField",
          "name": "nodes",
          "plural": true,
          "selections": [
            (v0/*:: as any*/)
          ],
          "storageKey": null
        }
      ],
      "storageKey": null
    }
  ],
  "type": "PhotoPromise",
  "abstractKey": null
};
})();

(node as any).hash = "98c5ca0756c18b2307b55fa340206bb3";

export default node;
