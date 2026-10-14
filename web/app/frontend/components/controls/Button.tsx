import * as React from "react";
import {Slot} from "radix-ui";
import {cva, type VariantProps} from "class-variance-authority";

const buttonVariants = cva("button-base", {
    variants: {
        variant: {
            default: "button-default",
            destructive: "button-destructive",
            outline: "button-outline",
            secondary: "button-secondary",
            ghost: "button-ghost",
            link: "button-link",
        },
        size: {
            default: "h-9 px-4 py-2 has-[>svg]:px-3",
            sm: "h-8 rounded-md gap-1.5 px-3 has-[>svg]:px-2.5",
            lg: "h-10 rounded-md px-6 has-[>svg]:px-4",
            icon: "size-9 rounded-md",
        },
    },
    defaultVariants: {
        variant: "default",
        size: "default",
    },
});

interface ButtonProps extends
    React.ComponentProps<"button">,
    VariantProps<typeof buttonVariants> {

    asChild?: boolean;
}

export function Button({
                    className,
                    variant,
                    size,
                    asChild = false,
                    ...props
                }: ButtonProps) {
    const Comp = asChild ? Slot.Root : "button";

    return <Comp data-slot="button" className={buttonVariants({variant, size, className})} {...props} />
}
