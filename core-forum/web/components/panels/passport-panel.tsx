"use client"

import type React from "react"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Camera, Check, X } from "lucide-react"
import { useToast } from "@/components/ui/use-toast"
import { CameraModal } from "@/components/modals/camera-modal"
import { sendToBackend } from "@/lib/api"

export const PassportPanel = () => {
  const [formData, setFormData] = useState({
    name: "",
    identity: "",
    birthdate: "",
    orgao: "",
  })
  const [photo, setPhoto] = useState<string | null>(null)
  const [showCamera, setShowCamera] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const { toast } = useToast()

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!formData.name || !formData.identity || !formData.birthdate || !photo) {
      toast({
        title: "Erro",
        description: "Por favor, preencha todos os campos e tire uma foto.",
        variant: "destructive",
      })
      return
    }

    setIsSubmitting(true)

    try {
      // Enviar dados para o back-end
      const response = await sendToBackend("createPassport", {
        nome: formData.name,
        identidade: formData.identity,
        dataNascimento: formData.birthdate,
        foto: photo,
      })

      toast({
        title: "Sucesso",
        description: `Solicitação de passaporte #${response.id} enviada com sucesso!`,
        variant: "default",
      })

  
      setFormData({
        name: "",
        identity: "",
        birthdate: "",
        orgao: "",
      })
      setPhoto(null)
    } catch (error) {
      console.error("Erro ao enviar solicitação de passaporte:", error)
      toast({
        title: "Erro",
        description: "Ocorreu um erro ao enviar a solicitação. Tente novamente.",
        variant: "destructive",
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  const handlePhotoCapture = (photoData: string) => {
    setPhoto(photoData)
    setShowCamera(false)
  }

  return (
    <div className="flex h-full flex-col gap-4 overflow-auto">
      <div className="flex items-center justify-between">
        <h2 className="text-xl sm:text-2xl font-semibold tracking-tight">Processo de Criação de Passaporte</h2>
      </div>

      <Card className="flex-1">
        <CardHeader>
          <CardTitle>Formulário de Solicitação</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Nome Completo:</Label>
                  <Input
                    id="name"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    placeholder="Digite o nome completo."
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="identity">Identidade (RG):</Label>
                  <Input
                    id="identity"
                    name="identity"
                    value={formData.identity}
                    onChange={handleInputChange}
                    placeholder="Digite o número do documento."
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="birthdate">Data de Nascimento:</Label>
                  <Input
                    id="birthdate"
                    name="birthdate"
                    type="date"
                    value={formData.birthdate}
                    onChange={handleInputChange}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="birthdate">Nome do Orgão Espedidor:</Label>
                  <Input
                    id="orgao"
                    name="orgao"
                    value={formData.orgao}
                    onChange={handleInputChange}
                    placeholder="Digite o nome de quem esta auxiliando."
                  />
                </div>
              </div>
              

              <div className="space-y-4">
                <Label>FOTO DO CIDADÃO</Label>
                <div className="flex h-48 flex-col items-center justify-center rounded-lg border border-dashed border-border bg-muted/30">
                  {photo ? (
                    <div className="relative h-full w-full">
                      <img
                        src={photo || "/placeholder.svg"}
                        alt="Foto do cidadão"
                        className="h-full w-full rounded-lg object-cover"
                      />
                      <div className="absolute bottom-2 right-2 flex gap-2">
                        <Button type="button" size="icon" variant="destructive" onClick={() => setPhoto(null)}>
                          <X className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <Button type="button" variant="outline" onClick={() => setShowCamera(true)}>
                      <Camera className="mr-2 h-4 w-4" />
                      TIRAR FOTO
                    </Button>
                  )}
                </div>

                <div className="rounded-lg border bg-card p-4">
                  <h3 className="mb-2 font-semibold">Requisitos da foto:</h3>
                  <ul className="space-y-1 text-sm text-muted-foreground">
                    <li>• Fundo neutro e bem iluminado</li>
                    <li>• Rosto centralizado e visível</li>
                    <li>• Sem óculos escuros ou chapéus</li>
                    <li>• Expressão neutra</li>
                  </ul>
                </div>
              </div>
            </div>

            <div className="flex justify-end">
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? (
                  <>
                    <span className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></span>
                    ENVIANDO...
                  </>
                ) : (
                  <>
                    <Check className="mr-2 h-4 w-4" />
                    ENVIAR SOLICITAÇÃO
                  </>
                )}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <CameraModal isOpen={showCamera} onClose={() => setShowCamera(false)} onCapture={handlePhotoCapture} />
    </div>
  )
}
