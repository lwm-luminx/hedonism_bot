import * as React from "react";
import {ScrollArea as ScrollAreaPrimitive} from "radix-ui";
import {cva} from "class-variance-authority";
import {clsx} from "clsx";

const scrollAreaVariants = cva("scroll-area-base", {
    variants: {
        direction: {vertical: "scroll-area-vertical", horizontal: "scroll-area-horizontal" }
    }
});

export function ScrollArea({
                        className,
                        children,
                        ...props
                    }: React.ComponentProps<typeof ScrollAreaPrimitive.Root>) {

    return (
        <ScrollAreaPrimitive.Root
            data-slot="scroll-area"
            className={clsx("relative", className)}
            {...props}
        >
            <ScrollAreaPrimitive.Viewport data-slot="scroll-area-viewport" className="scroll-area-viewport">
                {children}
            </ScrollAreaPrimitive.Viewport>

            <ScrollBar/>

            <ScrollAreaPrimitive.Corner/>
        </ScrollAreaPrimitive.Root>
    );
}

function ScrollBar({
                       className,
                       orientation = "vertical",
                       ...props
                   }: React.ComponentProps<typeof ScrollAreaPrimitive.ScrollAreaScrollbar>) {

    return (
        <ScrollAreaPrimitive.ScrollAreaScrollbar
            data-slot="scroll-area-scrollbar"
            orientation={orientation}
            className={clsx(className, scrollAreaVariants({direction: orientation}))}
            {...props}>

            <ScrollAreaPrimitive.ScrollAreaThumb data-slot="scroll-area-thumb" className="scroll-area-thumb" />
        </ScrollAreaPrimitive.ScrollAreaScrollbar>
    );
}
