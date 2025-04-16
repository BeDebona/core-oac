"use client"

import type React from "react"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import Image from "next/image"

interface OabRegistrationModalProps {
  isOpen: boolean
  oabNumber: string
  onRegister: (name: string) => void
}

export function OabRegistrationModal({ isOpen, oabNumber, onRegister }: OabRegistrationModalProps) {
  const [name, setName] = useState("")

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (name.trim()) {
      onRegister(name)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={() => {}}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <div className="mx-auto mb-4 flex justify-center">
            <Image src="https://host-trig.vercel.app/files/Logo_Branca.png" alt="OAC Logo" width={180} height={180} />
          </div>
          <DialogTitle className="text-center text-xl">Bem-vindo à Ordem dos Advogados de Central City</DialogTitle>
          <DialogDescription className="text-center">
            Este é seu primeiro acesso. Por favor, registre-se para continuar.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-2">
            <Label htmlFor="name">Seu Nome Completo</Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Digite seu nome completo"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="oab">Seu Número OAC (Gerado Automaticamente)</Label>
            <Input id="oab" value={oabNumber} readOnly className="bg-muted" />
            <p className="text-xs text-muted-foreground">
              Este número é único e será usado para identificá-lo no sistema.
            </p>
          </div>

          <Button type="submit" className="w-full">
            Registrar e Continuar
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  )
}
