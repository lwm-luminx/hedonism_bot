import { commitMutation, graphql } from "react-relay";
import type { GraphQLTaggedNode, MutationParameters } from "relay-runtime";
// Not re-exported from the package index, but it's the MD5 helper Active Storage's own direct uploads use.
// @ts-expect-error untyped module
import { FileChecksum } from "@rails/activestorage/src/file_checksum";
import { relayEnvironment } from "./RelayEnvironment";
import type { photoUploadAttachMutation } from "./__generated__/photoUploadAttachMutation.graphql";
import type { photoUploadFinishMutation } from "./__generated__/photoUploadFinishMutation.graphql";

// The same flow as the Mac uploader (HedonismClient.swift): register the files with the promise to get
// signed storage URLs, PUT each file straight to storage, then tell the server whether it landed.

const ATTACH_MUTATION = graphql`
  mutation photoUploadAttachMutation($id: ID!, $files: [PhotoPromiseFileInput!]!) {
    attachPhotoPromiseFiles(id: $id, files: $files) {
      files {
        id
        uploadUrl
        uploadHeaders
      }
    }
  }
`;

const FINISH_MUTATION = graphql`
  mutation photoUploadFinishMutation($id: ID!, $status: PhotoPromiseFileStatus!) {
    updatePhotoPromiseFileUpdate(id: $id, status: $status) {
      file {
        status
      }
    }
  }
`;

// Browsers often report an empty type for camera RAW files; the server keys RAW handling off this type.
const CONTENT_TYPES_BY_EXTENSION: Record<string, string> = {
  ".arw": "image/x-sony-arw",
  ".hif": "image/heif",
  ".heif": "image/heif",
  ".heic": "image/heic",
};

export function contentTypeFor(file: File): string {
  const extension = file.name.substring(file.name.lastIndexOf(".")).toLowerCase();
  return CONTENT_TYPES_BY_EXTENSION[extension] ?? (file.type || "application/octet-stream");
}

function run<T extends MutationParameters>(mutation: GraphQLTaggedNode, variables: T["variables"]) {
  return new Promise<T["response"]>((resolve, reject) => {
    commitMutation<T>(relayEnvironment, {
      mutation,
      variables,
      onCompleted: (response, errors) => {
        if (errors?.length) reject(new Error(errors.map((e) => e.message).join(", ")));
        else resolve(response);
      },
      onError: reject,
    });
  });
}

function md5Base64(file: File) {
  return new Promise<string>((resolve, reject) => {
    FileChecksum.create(file, (error: string | undefined, checksum: string) =>
      error ? reject(new Error(error)) : resolve(checksum),
    );
  });
}

async function sha256Base64(file: File) {
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", await file.arrayBuffer()));
  let binary = "";
  for (const byte of digest) binary += String.fromCharCode(byte);
  return btoa(binary);
}

function put(file: File, url: string, headers: Record<string, string>, onProgress: (loaded: number) => void) {
  return new Promise<void>((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open("PUT", url, true);
    for (const [name, value] of Object.entries(headers)) xhr.setRequestHeader(name, value);
    xhr.upload.addEventListener("progress", (event) => onProgress(event.loaded));
    xhr.onload = () =>
      xhr.status >= 200 && xhr.status < 300
        ? resolve()
        : reject(new Error(`Storage rejected ${file.name} (HTTP ${xhr.status})`));
    xhr.onerror = () => reject(new Error(`Couldn't reach storage for ${file.name}`));
    xhr.send(file);
  });
}

/** Uploads one take (a RAW and its processed versions) into the promise, reporting progress 0–100. */
export async function uploadTake(promiseId: string, files: File[], onProgress: (percent: number) => void) {
  const inputs = await Promise.all(
    files.map(async (file) => ({
      originalFilename: file.name,
      contentType: contentTypeFor(file),
      fileSizeBytes: file.size,
      imageHash: await sha256Base64(file),
      checksum: await md5Base64(file),
    })),
  );

  const attached = await run<photoUploadAttachMutation>(ATTACH_MUTATION, { id: promiseId, files: inputs });
  const pending = attached.attachPhotoPromiseFiles?.files ?? [];
  if (pending.length !== files.length) throw new Error("The server didn't accept every file");

  const total = files.reduce((sum, file) => sum + file.size, 0) || 1;
  const loaded = files.map(() => 0);

  // Each file is finished whether or not its PUT worked, so the server never waits on an abandoned upload.
  const results = await Promise.allSettled(
    pending.map(async (upload, index) => {
      try {
        await put(files[index], upload.uploadUrl, (upload.uploadHeaders ?? {}) as Record<string, string>, (bytes) => {
          loaded[index] = bytes;
          onProgress(Math.round((loaded.reduce((a, b) => a + b, 0) / total) * 100));
        });
      } catch (error) {
        await run<photoUploadFinishMutation>(FINISH_MUTATION, { id: upload.id, status: "FAILED" }).catch(() => {});
        throw error;
      }
      await run<photoUploadFinishMutation>(FINISH_MUTATION, { id: upload.id, status: "SUCCESS" });
    }),
  );

  const failure = results.find((result): result is PromiseRejectedResult => result.status === "rejected");
  if (failure) throw failure.reason instanceof Error ? failure.reason : new Error(String(failure.reason));
}
