import React, { Component } from 'react';
import Dropzone, { DropzoneState, FileRejection } from 'react-dropzone'

import { PhotoUpload } from './PhotoUpload';
import {Button} from "./Button";
import {Container, Grid} from "@radix-ui/themes";
import {Row} from "@radix-ui/themes/components/table";

interface UploadPhoto {
    id: string | null,
    title: string,
    rawPhoto: File
    processedPhotos: File[]
}

interface UploadState {
    acceptedFiles: Record<string, UploadPhoto>;
    rejectedFiles: FileRejection[];
    uploadProgress: Record<string, number>;
    uploading: Record<string, boolean>;
}

interface MultiUploaderProps {
    uploadPath?: string
}

const RAW_FORMAT_EXTENSIONS = ['.arw'];

export class MultiUploader extends Component<MultiUploaderProps, UploadState> {
    constructor(props: MultiUploaderProps) {
        super(props);
        this.state = {
            acceptedFiles: {},
            rejectedFiles: [],
            uploadProgress: {},
            uploading: {},
        };
    }

    static defaultProps = {
        uploadPath: '/upload',
    };

    static stripExtension(filename: string) {
        return filename.substring(0, filename.lastIndexOf('.')) || filename;
    }

    static getExtension(filename: string) {
        const extension = filename.substring(filename.lastIndexOf('.')) || filename;
        return extension.toLowerCase();
    }

    // 3. Define the type-safe handleDrop callback
    handleDrop = (acceptedFiles: File[], fileRejections: FileRejection[]) => {
        const rawPhotos = acceptedFiles.filter(file => RAW_FORMAT_EXTENSIONS.includes(MultiUploader.getExtension(file.name)));
        const processedPhotos = new Set(acceptedFiles).difference(new Set(rawPhotos));

        const newAcceptedFiles = {...this.state.acceptedFiles};

        for (const rawPhoto of rawPhotos) {
            const basename = MultiUploader.stripExtension(rawPhoto.name);

            newAcceptedFiles[basename] = {
                id: null,
                title: rawPhoto.name,
                rawPhoto,
                processedPhotos: [],
            }
        }

        for (const processedPhoto of processedPhotos) {
            const basename = MultiUploader.stripExtension(processedPhoto.name);

            if (basename in newAcceptedFiles) {
                newAcceptedFiles[basename].processedPhotos.push(processedPhoto);
            }
            else {
                console.error(`Processed photo ${processedPhoto.name} does not have a corresponding raw photo (${processedPhoto.type})`);
            }
        }

        this.setState({
            acceptedFiles: newAcceptedFiles,
            rejectedFiles: [...this.state.rejectedFiles, ...fileRejections],
        });
    };

    removeFile = (basename: string) => {
        const newAcceptedFiles = {...this.state.acceptedFiles};
        delete newAcceptedFiles[basename];
        this.setState({ acceptedFiles: newAcceptedFiles });
    }

    upload = async() => {
        const uploadPath = this.props.uploadPath ?? MultiUploader.defaultProps.uploadPath;

        this.setState({ uploading: Object.fromEntries(Object.keys(this.state.acceptedFiles).map(k => [k, true])) });

        for (const [_name, file] of Object.entries(this.state.acceptedFiles)) {

            const formData = new FormData();
            formData.append('raw_image', file.rawPhoto);
            for (const [index, processedPhoto] of file.processedPhotos.entries()) {
                formData.append('processed_image[]', processedPhoto);
            }

            await fetch(uploadPath, {
                method: 'POST',
                body: formData
            });
        }
    }

    render() {
        if (Object.keys(this.state.acceptedFiles).length == 0) {
            return <div className="container">
                <Dropzone onDrop={this.handleDrop} accept={{ 'image/*': ['.arw'], 'image/heif': ['.heif', '.heic', '.hif'], 'image/png': ['.png'], 'image/jpeg': ['.jpg', '.jpeg']}}>
                    {({ getRootProps, getInputProps, isDragActive }: DropzoneState) => (
                        <div
                            {...getRootProps()}
                            style={{
                                border: '2px dashed #0087F7',
                                borderRadius: '5px',
                                padding: '40px',
                                textAlign: 'center',
                                backgroundColor: isDragActive ? '#ecf0f1' : '#f9f9f9',
                                cursor: 'pointer',
                            }}
                        >
                            <input {...getInputProps()} />
                            {isDragActive ? (
                                <p>Drop the files here ...</p>
                            ) : (
                                <p>Drop some photos here</p>
                            )}
                        </div>
                    )}
                </Dropzone>
            </div>
        }

        return <Container className="py-4">
                <Grid columns="4" gap="4">
                    {Object.entries(this.state.acceptedFiles).map(([name, file]) => (
                        <PhotoUpload
                            key={name}
                            title={file.title}
                            rawPhoto={file.rawPhoto}
                            processedPhotos={file.processedPhotos}
                            progress={this.state.uploadProgress[name]}
                            onRemove={this.state.uploading[name] ? undefined : () => this.removeFile(name)}
                        />
                    ))}
                </Grid>

                <Row>
                    <ul>
                        {this.state.rejectedFiles.map(({ file, errors }) => (
                            <li key={file.name}>
                                {file.name} - {errors[0].message}
                            </li>
                        ))}
                    </ul>
                </Row>
                <Button onClick={this.upload}>Upload</Button>
            </Container>;
    }
}