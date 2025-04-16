import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function generateRandomOab() {
  // Gera um número OAB aleatório no formato XXX-XXXXXX
  const prefix = Math.floor(Math.random() * 900) + 100 // 100-999
  const suffix = Math.floor(Math.random() * 900000) + 100000 // 100000-999999

  return `${prefix}-${suffix}`
}
