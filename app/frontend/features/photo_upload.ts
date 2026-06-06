import {createSlice, PayloadAction} from '@reduxjs/toolkit';
import {FileRejection} from "react-dropzone";

const RAW_FORMAT_EXTENSIONS = ['.arw'];

interface UploadPhoto {
    id: string | null,
    title: string,
    rawPhoto: File | null
    processedPhotos: File[]
}

interface UploadState {
    acceptedFiles: Record<string, UploadPhoto>;
    rejectedFiles: FileRejection[];
}

const INITIAL_STATE: UploadState = {
    acceptedFiles: {},
    rejectedFiles: []
}

function stripExtension(filename: string) {
    return filename.substring(0, filename.lastIndexOf('.')) || filename;
}

function getExtension(filename: string) {
    const extension = filename.substring(filename.lastIndexOf('.')) || filename;
    return extension.toLowerCase();
}

const photoUploadSlice = createSlice({
    name: 'photoUpload',
    initialState: INITIAL_STATE,
    reducers: {
      addFile: (state, action : PayloadAction<File>) => {
          if (RAW_FORMAT_EXTENSIONS.includes(getExtension(action.payload.name))) {
              const basename = stripExtension(action.payload.name);

              if (state.acceptedFiles[basename]) {
                state.acceptedFiles[basename] = {
                    ...state.acceptedFiles[basename],
                    rawPhoto: action.payload
                }
              }
              else {
                  state.acceptedFiles[basename] = {
                      id: null,
                      title: basename,
                      rawPhoto: action.payload,
                      processedPhotos: []
                  }
              }
          } else {
              const basename = stripExtension(action.payload.name);

              if (state.acceptedFiles[basename]) {
                  state.acceptedFiles[basename].processedPhotos = [
                      ...state.acceptedFiles[basename].processedPhotos,
                      action.payload
                  ]
              }
              else {
                  state.acceptedFiles[basename] = {
                      id: null,
                      title: basename,
                      rawPhoto: null,
                      processedPhotos: [
                          action.payload
                      ]
                  }
              }
          }
      }
    }
})

export { }

export default photoUploadSlice;