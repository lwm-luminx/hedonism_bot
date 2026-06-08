import React from 'react';
import {Button, Card, Flex, Inset, Progress, Text} from "@radix-ui/themes";
import {X} from 'lucide-react';

export interface CardProps {
    rawPhoto: File;
    processedPhotos: File[];
    title: string;
    description?: string;
    progress?: number;
    onRemove?: () => void;
}

export const PhotoUpload: React.FC<CardProps> = ({
                                                     title,
                                                     description,
                                                     rawPhoto,
                                                     processedPhotos,
                                                     progress,
                                                     onRemove
                                                 }) => {
    return <Card style={{width: '18rem'}}>
        <Flex justify="between" align="center" mb="2">
            <Text as="p" size="3" truncate>{title}</Text>
            {onRemove && (
                <Button variant="ghost" color="red" onClick={onRemove}>
                    <X size={16}/>
                </Button>
            )}
        </Flex>
        <Inset clip="padding-box" side="top" pb="current">
            <img
                src={URL.createObjectURL(processedPhotos[0] || rawPhoto)}
                alt={title}
                style={{
                    display: "block",
                    objectFit: "cover",
                    width: "100%",
                    height: 140,
                    backgroundColor: "var(--gray-5)",
                }}
            />
        </Inset>
        {progress !== undefined && (
            <Progress value={progress}/>
        )}
        <Text as="p" size="1" color="gray">
            {description}
        </Text>
    </Card>
}