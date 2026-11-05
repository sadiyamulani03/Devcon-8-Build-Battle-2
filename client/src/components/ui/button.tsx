"use client";

import * as React from "react";
import { cn } from "./ui/utils";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "default" | "destructive" | "outline" | "secondary" | "ghost";
  size?: "default" | "sm";
}

export function Button({ className, variant = "default", size = "default", ...props }: ButtonProps) {
  const variants = {
    default: "bg-navy-900 text-white hover:bg-navy-800",
    destructive: "bg-green-600 text-white hover:bg-green-700",
    outline: "border border-slate-200 bg-white hover:bg-slate-50",
    secondary: "bg-slate-200 text-slate-900 hover:bg-slate-300",
    ghost: "text-slate-600 hover:bg-slate-100",
  };
  const sizes = {
    default: "h-10 px-4 py-2",
    sm: "h-8 px-3 text-sm",
  };
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center rounded-md font-medium transition-colors",
        variants[variant],
        sizes[size],
        "disabled:opacity-50 disabled:pointer-events-none",
        className
      )}
      {...props}
    />
  );
}
