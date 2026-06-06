import React from 'react';
import {Card, Inset, Text} from "@radix-ui/themes";

export interface CardProps {
    rawPhoto: File;
    processedPhotos: File[];
    title: string;
    description?: string;
}

export const PhotoUpload: React.FC<CardProps> = ({ title, description, rawPhoto, processedPhotos }) => {
    return <Card style={{width: '18rem'}}>
        <Inset clip="padding-box" side="top" pb="current">
            <img
                src={URL.createObjectURL(processedPhotos[0])}
                alt="Bold typography"
                style={{
                    display: "block",
                    objectFit: "cover",
                    width: "100%",
                    height: 140,
                    backgroundColor: "var(--gray-5)",
                }}
            />
        </Inset>
        <Text as="p" size="3">
            {title} - {description}
        </Text>
    </Card>
}