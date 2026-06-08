import * as React from "react";
import {ScrollArea as ScrollAreaPrimitive} from "radix-ui";
import {cva} from "class-variance-authority";

const scrollAreaVariants = cva("flex touch-none p-px transition-colors select-none",
    {
        variants:
            {
                direction: {
                    vertical: "h-full w-2.5 border-l border-l-transparent",
                    horizontal: "h-2.5 flex-col border-t border-t-transparent",
                }
            }
    });

function ScrollArea({
                        className,
                        children,
                        ...props
                    }: React.ComponentProps<typeof ScrollAreaPrimitive.Root>) {
    return (
        <ScrollAreaPrimitive.Root
            data-slot="scroll-area"
            className={"relative" + (className ? ` ${className}` : '')}
            {...props}
        >
            <ScrollAreaPrimitive.Viewport
                data-slot="scroll-area-viewport"
                className="focus-visible:ring-ring/50 size-full rounded-[inherit] transition-[color,box-shadow] outline-none focus-visible:ring-[3px] focus-visible:outline-1"
            >
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
            className={scrollAreaVariants({className})}
            {...props}
        >
            <ScrollAreaPrimitive.ScrollAreaThumb
                data-slot="scroll-area-thumb"
                className="bg-border relative flex-1 rounded-full"
            />
        </ScrollAreaPrimitive.ScrollAreaScrollbar>
    );
}

export {ScrollArea, ScrollBar};
