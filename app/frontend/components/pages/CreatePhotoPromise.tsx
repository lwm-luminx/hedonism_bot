import { graphql, useMutation } from "react-relay";
import type { CreatePhotoPromiseMutation } from "./__generated__/CreatePhotoPromiseMutation.graphql";
import { Suspense, useEffect } from "react";
import { useNavigate } from "react-router";

const CREATE_PHOTO_PROMISE_MUTATION = graphql`
  mutation CreatePhotoPromiseMutation {
    createPhotoPromise {
      promise {
        id
      }
    }
  }
`;

export function CreatePhotoPromise() {
  const navigate = useNavigate();
  const [commitMutation, isMutationInFlight] =
    useMutation<CreatePhotoPromiseMutation>(CREATE_PHOTO_PROMISE_MUTATION);

  useEffect(() => {
    commitMutation({
      variables: {},
      onCompleted: (response, _errors) => {
        if (response.createPhotoPromise) {
          const promiseId = response.createPhotoPromise.promise.id;
          navigate(`/upload/${promiseId}`);
        }
      },
    });
  }, []);

  return <Suspense />;
}
