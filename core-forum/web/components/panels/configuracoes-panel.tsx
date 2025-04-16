"use client"

import type React from "react"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { useToast } from "@/components/ui/use-toast"
import { Save, Upload, User, Settings } from "lucide-react"
import { sendToBackend } from "@/lib/api"

interface ConfiguracoesPanelProps {
  userData: {
    name: string
    oab: string
    role: string
    level: string
    avatar: string
  }
}

export const ConfiguracoesPanel = ({ userData }: ConfiguracoesPanelProps) => {
  const [profileData, setProfileData] = useState({
    name: userData.name,
    email: "advogado@oac.cc",
    phone: "(11) 98765-4321",
  })
  const [isSubmitting, setIsSubmitting] = useState(false)
  const { toast } = useToast()

  const handleProfileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setProfileData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSaveProfile = async () => {
    try {
      setIsSubmitting(true)
      // Enviar dados para o back-end
      await sendToBackend("updateProfile", {
        name: profileData.name,
        email: profileData.email,
        phone: profileData.phone,
        oab: userData.oab,
      })

      toast({
        title: "Perfil Atualizado",
        description: "Suas informações foram atualizadas com sucesso.",
        variant: "default",
      })
    } catch (error) {
      console.error("Erro ao atualizar perfil:", error)
      toast({
        title: "Erro",
        description: "Ocorreu um erro ao atualizar o perfil. Tente novamente.",
        variant: "destructive",
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="flex h-full flex-col gap-4 overflow-auto">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-semibold tracking-tight">Configurações</h2>
      </div>

      <Tabs defaultValue="perfil" className="flex-1">
        <TabsList>
          <TabsTrigger value="perfil">
            <User className="mr-2 h-4 w-4" />
            Perfil
          </TabsTrigger>
          <TabsTrigger value="sistema">
            <Settings className="mr-2 h-4 w-4" />
            Sistema
          </TabsTrigger>
        </TabsList>
        <TabsContent value="perfil" className="mt-4 flex-1">
          <Card className="flex-1">
            <CardHeader>
              <CardTitle>Informações do Perfil</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="name">Nome Completo</Label>
                    <Input id="name" name="name" value={profileData.name} onChange={handleProfileChange} />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="email">E-mail</Label>
                    <Input
                      id="email"
                      name="email"
                      type="email"
                      value={profileData.email}
                      onChange={handleProfileChange}
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="phone">Telefone</Label>
                    <Input id="phone" name="phone" value={profileData.phone} onChange={handleProfileChange} />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="oab">Número OAB</Label>
                    <Input id="oab" name="oab" value={userData.oab} disabled />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="role">Cargo</Label>
                    <Input id="role" name="role" value={userData.role} disabled />
                  </div>
                </div>

                <div className="flex flex-col items-center justify-start space-y-4">
                  <div className="text-center">
                    <Label className="mb-2 block">Foto de Perfil</Label>
                    <Avatar className="h-32 w-32">
                      <AvatarImage src={userData.avatar || "/placeholder.svg"} alt={userData.name} />
                      <AvatarFallback>{userData.name.charAt(0)}</AvatarFallback>
                    </Avatar>
                  </div>

                  <Button variant="outline">
                    <Upload className="mr-2 h-4 w-4" />
                    Alterar Foto
                  </Button>

                  <div className="mt-8 w-full rounded-lg border bg-card p-4">
                    <h3 className="mb-2 font-semibold">Informações Adicionais</h3>
                    <div className="space-y-2 text-sm">
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Nível:</span>
                        <span>{userData.level}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Status:</span>
                        <span className="text-success">ATIVO</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Membro desde:</span>
                        <span>01/01/2023</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="mt-6 flex justify-end">
                <Button onClick={handleSaveProfile} disabled={isSubmitting}>
                  {isSubmitting ? (
                    <>
                      <span className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></span>
                      Salvando...
                    </>
                  ) : (
                    <>
                      <Save className="mr-2 h-4 w-4" />
                      Salvar Alterações
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="sistema" className="mt-4 flex-1">
          <Card className="flex-1">
            <CardHeader>
              <CardTitle>Configurações do Sistema</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                <div>
                  <h3 className="mb-4 text-lg font-medium">Sobre o Sistema</h3>
                  <div className="rounded-lg border p-4">
                    <p className="mb-2">
                      <span className="font-medium">Versão:</span> 1.0.0
                    </p>
                    <p className="mb-2">
                      <span className="font-medium">Última atualização:</span> 16/05/2025
                    </p>
                    <p className="mb-2">
                      <span className="font-medium">Desenvolvido por:</span> Equipe Core Devs
                    </p>
                    <p>
                      <span className="font-medium">Contato:</span> suporte@oac.cc
                    </p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
