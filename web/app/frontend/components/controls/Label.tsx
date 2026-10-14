import * as React from "react";
import {Label as LabelPrimitive} from "radix-ui";
import {clsx} from "clsx";


export function Label({
                   className,
                   ...props
               }: React.ComponentProps<typeof LabelPrimitive.Root>) {

    return <LabelPrimitive.Root data-slot="label" className={clsx("label-base", className)} {...props} />
}
