import {useState} from "react";
import {Check, CreditCard, Download, Lock} from "lucide-react";
import {Dialog, DialogContent, DialogTitle} from "./Dialog";
import {Button} from "./Button";
import {Input} from "./Input";
import {Label} from "./Label";
import {Separator} from "./Separator";
import {ImageWithFallback} from "./ImageWithFallback";
import {graphql, useLazyLoadQuery} from "react-relay";
import {PhotoPurchaseQuery} from "./__generated__/PhotoPurchaseQuery.graphql";

interface PurchaseModalProps {
    photoId: string | null;
    open: boolean;
    onClose: () => void;
    onPurchaseComplete: (photoId: string) => void;
}

const PHOTO_PURCHASE_QUERY = graphql`
query PhotoPurchaseQuery($photoId: ID!) {
    photo(id: $photoId) {
        id
        alternateDescription
        previewUrl
        takenAt
    }
}
`

type Step = "review" | "payment" | "success";

export function PurchaseModal({photoId, open, onClose, onPurchaseComplete}: PurchaseModalProps) {
    if (!photoId) return null;

    const data = useLazyLoadQuery<PhotoPurchaseQuery>(PHOTO_PURCHASE_QUERY, {photoId});

    const [step, setStep] = useState<Step>("review");
    const [processing, setProcessing] = useState(false);
    const [cardNumber, setCardNumber] = useState("");
    const [expiry, setExpiry] = useState("");
    const [cvc, setCvc] = useState("");
    const [name, setName] = useState("");

    const handleClose = () => {
        onClose();
        setTimeout(() => {
            setStep("review");
            setProcessing(false);
            setCardNumber("");
            setExpiry("");
            setCvc("");
            setName("");
        }, 300);
    };

    const handlePay = async () => {
        setProcessing(true);
        await new Promise((r) => setTimeout(r, 1800));
        setProcessing(false);
        setStep("success");
        if (data.photo) onPurchaseComplete(data.photo.id);
    };

    const formatCard = (val: string) =>
        val
            .replace(/\D/g, "")
            .slice(0, 16)
            .replace(/(.{4})/g, "$1 ")
            .trim();

    const formatExpiry = (val: string) => {
        const digits = val.replace(/\D/g, "").slice(0, 4);
        if (digits.length >= 3) return `${digits.slice(0, 2)} / ${digits.slice(2)}`;
        return digits;
    };


    return (
        <Dialog open={open} onOpenChange={handleClose}>
            <DialogContent
                className="max-w-md border"
                style={{
                    background: "var(--card)",
                    borderColor: "var(--border)",
                    borderRadius: "var(--radius)",
                    padding: 0,
                    overflow: "hidden",
                }}
            >
                {/* Header */}
                <div className="px-6 pt-5 pb-4 border-b" style={{borderColor: "var(--border)"}}>
                    <DialogTitle
                        style={{
                            fontFamily: "'Playfair Display', serif",
                            color: "var(--foreground)",
                            fontSize: "1.25rem",
                        }}
                    >
                        {step === "success" ? "Purchase Complete" : step === "payment" ? "Secure Checkout" : "Purchase Photo"}
                    </DialogTitle>
                    <p className="text-xs mt-1"
                       style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}>
                        {data.photo!.takenAt}
                    </p>
                </div>

                {step === "review" && (
                    <div className="p-6 flex flex-col gap-5">
                        <div className="flex gap-4">
                            <div
                                className="w-24 h-24 overflow-hidden shrink-0"
                                style={{borderRadius: "var(--radius-sm)", border: "1px solid var(--border)"}}
                            >
                                <ImageWithFallback
                                    src={data.photo!.previewUrl!}
                                    alt={data.photo!.alternateDescription}
                                    className="w-full h-full object-cover"
                                />
                            </div>
                            <div className="flex flex-col justify-center gap-1">
                                <p style={{
                                    fontFamily: "'Inter', sans-serif",
                                    color: "var(--foreground)",
                                    fontSize: "0.9375rem"
                                }}>
                                    {data.photo!.alternateDescription}
                                </p>
                                <p className="text-xs"
                                   style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}>
                                    Original high-resolution file
                                </p>
                                <p className="text-xs"
                                   style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}>
                                    Instant download · Unlimited use
                                </p>
                            </div>
                        </div>
                        <Separator style={{background: "var(--border)"}}/>
                        <div className="flex justify-between items-center">
              <span style={{fontFamily: "'Inter', sans-serif", color: "var(--foreground)", fontSize: "0.9375rem"}}>
                Total
              </span>
                            <span
                                style={{
                                    fontFamily: "'Playfair Display', serif",
                                    color: "var(--primary)",
                                    fontSize: "1.375rem",
                                }}
                            >
                $1
              </span>
                        </div>
                        <Button
                            className="w-full"
                            style={{
                                background: "var(--primary)",
                                color: "var(--primary-foreground)",
                                fontFamily: "'Inter', sans-serif",
                                borderRadius: "var(--radius-sm)",
                            }}
                            onClick={() => setStep("payment")}
                        >
                            <CreditCard className="w-4 h-4 mr-2"/>
                            Continue to Payment
                        </Button>
                    </div>
                )}

                {step === "payment" && (
                    <div className="p-6 flex flex-col gap-4">
                        <div className="flex flex-col gap-3">
                            <div>
                                <Label
                                    htmlFor="name"
                                    className="text-xs mb-1.5 block"
                                    style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}
                                >
                                    Cardholder Name
                                </Label>
                                <Input
                                    id="name"
                                    placeholder="Jane Smith"
                                    value={name}
                                    onChange={(e) => setName(e.target.value)}
                                    style={{
                                        background: "var(--input-background)",
                                        border: "1px solid var(--border)",
                                        color: "var(--foreground)",
                                        borderRadius: "var(--radius-sm)",
                                        fontFamily: "'Inter', sans-serif",
                                    }}
                                />
                            </div>
                            <div>
                                <Label
                                    htmlFor="card"
                                    className="text-xs mb-1.5 block"
                                    style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}
                                >
                                    Card Number
                                </Label>
                                <Input
                                    id="card"
                                    placeholder="4242 4242 4242 4242"
                                    value={cardNumber}
                                    onChange={(e) => setCardNumber(formatCard(e.target.value))}
                                    style={{
                                        background: "var(--input-background)",
                                        border: "1px solid var(--border)",
                                        color: "var(--foreground)",
                                        borderRadius: "var(--radius-sm)",
                                        fontFamily: "'DM Mono', monospace",
                                    }}
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                                <div>
                                    <Label
                                        htmlFor="expiry"
                                        className="text-xs mb-1.5 block"
                                        style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}
                                    >
                                        Expiry
                                    </Label>
                                    <Input
                                        id="expiry"
                                        placeholder="MM / YY"
                                        value={expiry}
                                        onChange={(e) => setExpiry(formatExpiry(e.target.value))}
                                        style={{
                                            background: "var(--input-background)",
                                            border: "1px solid var(--border)",
                                            color: "var(--foreground)",
                                            borderRadius: "var(--radius-sm)",
                                            fontFamily: "'DM Mono', monospace",
                                        }}
                                    />
                                </div>
                                <div>
                                    <Label
                                        htmlFor="cvc"
                                        className="text-xs mb-1.5 block"
                                        style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}
                                    >
                                        CVC
                                    </Label>
                                    <Input
                                        id="cvc"
                                        placeholder="123"
                                        value={cvc}
                                        onChange={(e) => setCvc(e.target.value.replace(/\D/g, "").slice(0, 3))}
                                        style={{
                                            background: "var(--input-background)",
                                            border: "1px solid var(--border)",
                                            color: "var(--foreground)",
                                            borderRadius: "var(--radius-sm)",
                                            fontFamily: "'DM Mono', monospace",
                                        }}
                                    />
                                </div>
                            </div>
                        </div>
                        <Separator style={{background: "var(--border)"}}/>
                        <div className="flex justify-between items-center">
              <span style={{fontFamily: "'Inter', sans-serif", color: "var(--foreground)", fontSize: "0.9375rem"}}>
                Total
              </span>
                            <span style={{
                                fontFamily: "'Playfair Display', serif",
                                color: "var(--primary)",
                                fontSize: "1.375rem"
                            }}>
                $1
              </span>
                        </div>
                        <Button
                            className="w-full"
                            disabled={processing || !name || cardNumber.replace(/\s/g, "").length < 16 || expiry.length < 7 || cvc.length < 3}
                            style={{
                                background: "var(--primary)",
                                color: "var(--primary-foreground)",
                                fontFamily: "'Inter', sans-serif",
                                borderRadius: "var(--radius-sm)",
                                opacity: processing ? 0.7 : 1,
                            }}
                            onClick={handlePay}
                        >
                            {processing ? (
                                <span className="flex items-center gap-2">
                  <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/>
                  </svg>
                  Processing…
                </span>
                            ) : (
                                <>
                                    <Lock className="w-4 h-4 mr-2"/>
                                    Pay $1
                                </>
                            )}
                        </Button>
                        <p
                            className="text-center text-xs"
                            style={{color: "var(--muted-foreground)", fontFamily: "'DM Mono', monospace"}}
                        >
                            <Lock className="w-3 h-3 inline mr-1"/>
                            Secured by Stripe · No data stored
                        </p>
                    </div>
                )}

                {step === "success" && (
                    <div className="p-6 flex flex-col items-center gap-5 text-center">
                        <div
                            className="w-14 h-14 rounded-full flex items-center justify-center"
                            style={{background: "rgba(201,169,110,0.15)"}}
                        >
                            <Check className="w-7 h-7" style={{color: "var(--primary)"}}/>
                        </div>
                        <div>
                            <p
                                style={{
                                    fontFamily: "'Playfair Display', serif",
                                    color: "var(--foreground)",
                                    fontSize: "1.125rem",
                                    marginBottom: "0.375rem",
                                }}
                            >
                                Thank you for your purchase
                            </p>
                            <p className="text-sm"
                               style={{color: "var(--muted-foreground)", fontFamily: "'Inter', sans-serif"}}>
                                Your original high-resolution photo is ready to download.
                            </p>
                        </div>
                        <Button
                            className="w-full"
                            style={{
                                background: "var(--primary)",
                                color: "var(--primary-foreground)",
                                fontFamily: "'Inter', sans-serif",
                                borderRadius: "var(--radius-sm)",
                            }}
                            onClick={handleClose}
                        >
                            <Download className="w-4 h-4 mr-2"/>
                            Download Original
                        </Button>
                        <button
                            className="text-sm underline underline-offset-2 transition-opacity hover:opacity-70"
                            style={{color: "var(--muted-foreground)", fontFamily: "'Inter', sans-serif"}}
                            onClick={handleClose}
                        >
                            Close
                        </button>
                    </div>
                )}
            </DialogContent>
        </Dialog>
    );
}
