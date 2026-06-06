import {configureStore } from '@reduxjs/toolkit';
import uploadPhotoReducer from '../features/photo_upload';

export default configureStore({
    reducer: {
        uploadPhoto: uploadPhotoReducer
    }
});