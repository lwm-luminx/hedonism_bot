import * as React from "react";
import {Slot} from "radix-ui";
import {cva, type VariantProps} from "class-variance-authority";

const badgeVariants = cva("badge-base", {
    variants: {
        variant: {
            default: "badge-default",
            secondary: "badge-secondary",
            destructive: "badge-destructive",
            outline: "badge-outline",
        },
    },
    defaultVariants: {variant: "default"},
});

interface BadgeProps extends React.ComponentProps<"span">, VariantProps<typeof badgeVariants>
{
    asChild?: boolean
}

export function Badge({
                   className,
                   variant,
                   asChild = false,
                   ...props} : BadgeProps) {

    const Comp = asChild ? Slot.Root : "span";

    return (
        <Comp
            data-slot="badge"
            className={badgeVariants({variant, className})}
            {...props}
        />
    );
}

