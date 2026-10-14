import * as React from "react";
import {Separator as SeparatorPrimitive} from "radix-ui";
import {clsx} from "clsx";

export function Separator({
                       className,
                       orientation = "horizontal",
                       decorative = true,
                       ...props
                   }: React.ComponentProps<typeof SeparatorPrimitive.Root>) {
    return (
        <SeparatorPrimitive.Root
            data-slot="separator-root"
            decorative={decorative}
            orientation={orientation}
            className={clsx("separator", className)}
            {...props}
        />
    );
}

