"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Check, X, ArrowLeft, Eye, Loader2 } from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { useToast } from "@/components/ui/use-toast"
import { sendToBackend } from "@/lib/api"

interface Passport {
  id: string
  name: string
  identity: string
  birthdate: string
  photo: string
  orgao: string
  status: "pendente" | "aprovado" | "rejeitado"
  createdAt: string
}

export const AltaOrdemPanel = () => {
  const [selectedPassport, setSelectedPassport] = useState<Passport | null>(null)
  const [pendingPassports, setPendingPassports] = useState<Passport[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const { toast } = useToast()

  useEffect(() => {
    // Carregar passaportes pendentes do back-end
    const loadPassports = async () => {
      try {
        setIsLoading(true)
        const response = await sendToBackend("getPassaportes")

        // Converter formato do back-end para o formato do front-end
        const formattedPassports = response
          .map((passport: any) => ({
            id: passport.id,
            name: passport.nome,
            identity: passport.identidade,
            birthdate: passport.dataNascimento,
            orgao: passport.orgao,
            photo: passport.foto,
            status: passport.status,
            createdAt: passport.createdAt || new Date().toISOString(),
          }))
          .filter((p: Passport) => p.status === "pendente")

        setPendingPassports(formattedPassports)
      } catch (error) {
        console.error("Erro ao carregar passaportes:", error)
        toast({
          title: "Erro",
          description: "Não foi possível carregar os passaportes pendentes.",
          variant: "destructive",
        })
      } finally {
        setIsLoading(false)
      }
    }

    loadPassports()
  }, [toast])

  const handleApprove = async () => {
    if (!selectedPassport) return

    try {
      setIsSubmitting(true)
      // Enviar aprovação para o back-end
      await sendToBackend("approvePassport", { id: selectedPassport.id })

      toast({
        title: "Passaporte Aprovado",
        description: `O passaporte de ${selectedPassport.name} foi aprovado com sucesso.`,
        variant: "default",
      })

      // Atualizar lista de passaportes pendentes
      setPendingPassports((prev) => prev.filter((p) => p.id !== selectedPassport.id))
      setSelectedPassport(null)
    } catch (error) {
      console.error("Erro ao aprovar passaporte:", error)
      toast({
        title: "Erro",
        description: "Ocorreu um erro ao aprovar o passaporte. Tente novamente.",
        variant: "destructive",
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleReject = async () => {
    if (!selectedPassport) return

    try {
      setIsSubmitting(true)
      // Enviar rejeição para o back-end
      await sendToBackend("rejectPassport", { id: selectedPassport.id })

      toast({
        title: "Passaporte Rejeitado",
        description: `O passaporte de ${selectedPassport.name} foi rejeitado.`,
        variant: "destructive",
      })

      // Atualizar lista de passaportes pendentes
      setPendingPassports((prev) => prev.filter((p) => p.id !== selectedPassport.id))
      setSelectedPassport(null)
    } catch (error) {
      console.error("Erro ao rejeitar passaporte:", error)
      toast({
        title: "Erro",
        description: "Ocorreu um erro ao rejeitar o passaporte. Tente novamente.",
        variant: "destructive",
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="flex h-full flex-col gap-4 overflow-auto">
      <div className="flex items-center justify-between">
        <h2 className="text-xl sm:text-2xl font-semibold tracking-tight">
          {selectedPassport ? "Detalhes do Passaporte" : "Aprovação de Passaportes"}
        </h2>
        {selectedPassport && (
          <Button variant="outline" size="sm" onClick={() => setSelectedPassport(null)}>
            <ArrowLeft className="mr-2 h-4 w-4" />
            Voltar
          </Button>
        )}
      </div>

      {isLoading ? (
        <div className="flex flex-1 items-center justify-center">
          <div className="flex flex-col items-center gap-4">
            <Loader2 className="h-12 w-12 animate-spin text-primary" />
            <p className="text-muted-foreground">Carregando passaportes...</p>
          </div>
        </div>
      ) : selectedPassport ? (
        <Card className="flex-1">
          <CardHeader>
            <CardTitle>Passaporte #{selectedPassport.id}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
              <div className="space-y-4">
                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">Nome Completo</h3>
                  <p className="text-lg font-semibold">{selectedPassport.name}</p>
                </div>

                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">Identidade (RG)</h3>
                  <p className="text-lg font-semibold">{selectedPassport.identity}</p>
                </div>

                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">Data de Nascimento:</h3>
                  <p className="text-lg font-semibold">
                    {new Date(selectedPassport.birthdate).toLocaleDateString("pt-BR")}
                  </p>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">Orgão Espedidor:</h3>
                  <p className="text-lg font-semibold">{selectedPassport.orgao}</p>
                </div>

                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">Data de Solicitação</h3>
                  <p className="text-lg font-semibold">
                    {new Date(selectedPassport.createdAt).toLocaleDateString("pt-BR", {
                      day: "2-digit",
                      month: "2-digit",
                      year: "numeric",
                      hour: "2-digit",
                      minute: "2-digit",
                    })}
                  </p>
                </div>

                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">Status</h3>
                  <Badge
                    variant={
                      selectedPassport.status === "aprovado"
                        ? "default"
                        : selectedPassport.status === "rejeitado"
                          ? "destructive"
                          : "outline"
                    }
                    className="mt-1"
                  >
                    {selectedPassport.status.toUpperCase()}
                  </Badge>
                </div>
              </div>

              <div className="flex flex-col items-center justify-center space-y-4">
                <div className="text-center">
                  <h3 className="mb-2 text-sm font-medium text-muted-foreground">Foto do Cidadão</h3>
                  <div className="overflow-hidden rounded-lg border">
                    <img
                      src={selectedPassport.photo || "/placeholder.svg"}
                      alt={`Foto de ${selectedPassport.name}`}
                      className="h-48 w-48 object-cover"
                    />
                  </div>
                </div>

                <div className="mt-6 flex w-full justify-center gap-4">
                  <Button variant="destructive" onClick={handleReject} className="w-32" disabled={isSubmitting}>
                    {isSubmitting ? (
                      <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></span>
                    ) : (
                      <X className="mr-2 h-4 w-4" />
                    )}
                    REJEITAR
                  </Button>
                  <Button onClick={handleApprove} className="w-32" disabled={isSubmitting}>
                    {isSubmitting ? (
                      <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></span>
                    ) : (
                      <Check className="mr-2 h-4 w-4" />
                    )}
                    APROVAR
                  </Button>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      ) : (
        <Card className="flex-1">
          <CardHeader>
            <CardTitle>Passaportes Pendentes</CardTitle>
          </CardHeader>
          <CardContent className="h-[calc(100%-5rem)] overflow-auto">
            {pendingPassports.length > 0 ? (
              <div className="space-y-4">
                {pendingPassports.map((passport) => (
                  <div key={passport.id} className="flex items-center justify-between rounded-lg border p-4">
                    <div className="flex items-center gap-4">
                      <Avatar>
                        <AvatarImage src={passport.photo || "/placeholder.svg"} alt={passport.name} />
                        <AvatarFallback>{passport.name.charAt(0)}</AvatarFallback>
                      </Avatar>
                      <div>
                        <h3 className="font-semibold">{passport.name}</h3>
                        <p className="text-sm text-muted-foreground">
                          Passaporte #{passport.id} - {passport.identity}
                        </p>
                      </div>
                    </div>
                    <Button variant="outline" size="sm" onClick={() => setSelectedPassport(passport)}>
                      <Eye className="mr-2 h-4 w-4" />
                      VER
                    </Button>
                  </div>
                ))}
              </div>
            ) : (
              <div className="flex h-full flex-col items-center justify-center">
                <Check className="mb-4 h-12 w-12 text-muted-foreground" />
                <p className="text-center text-muted-foreground">Não há passaportes pendentes de aprovação.</p>
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  )
}
