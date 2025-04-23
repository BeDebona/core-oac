"use client"

import { useState, useEffect } from "react"
import { Sidebar } from "@/components/sidebar"
import { Header } from "@/components/header"
import { HomePanel } from "@/components/panels/home-panel"
import { PassportPanel } from "@/components/panels/passport-panel"
import { RegistroGeralPanel } from "@/components/panels/registro-geral-panel"
import { ConsultaPanel } from "@/components/panels/consulta-panel"
import { AltaOrdemPanel } from "@/components/panels/alta-ordem-panel"
import { DocumentosPanel } from "@/components/panels/documentos-panel"
import { CalendarioPanel } from "@/components/panels/calendario-panel"
import { ConfiguracoesPanel } from "@/components/panels/configuracoes-panel"
import { useToast } from "@/components/ui/use-toast"
import { Loader2 } from "lucide-react"
import { sendToBackend } from "@/lib/api"

export type Panel =
  | "home"
  | "passaporte"
  | "registro-geral"
  | "consulta"
  | "alta-ordem"
  | "documentos"
  | "calendario"
  | "mensagens"
  | "configuracoes"

interface DashboardProps {
  registeredOab?: string
  onExit: () => void
}

export const Dashboard = ({ registeredOab, onExit }: DashboardProps) => {
  const [activePanel, setActivePanel] = useState<Panel>("home")
  const [loading, setLoading] = useState(true)
  const [userData, setUserData] = useState({
    name: "Carregando...",
    oab: "000-000000",
    role: "Advogado",
    level: "SÊNIOR",
    avatar: "https://host-trig.vercel.app/files/1000_F_808373133_lrCrFLLTXF0A2WQK7QKMCNAzKCjX7kvb.png",
  })

  const { toast } = useToast()

  useEffect(() => {
    // Carregar dados do usuário do localStorage e do back-end
    const loadUserData = async () => {
      try {
        const storedName = localStorage.getItem("user_name")
        const storedOab = localStorage.getItem("oab_number") || registeredOab

        // Buscar dados do usuário do back-end
        const backendData = await sendToBackend("getPlayerInfo", { oab: storedOab })

        // Mesclar dados do back-end com dados locais
        setUserData({
          name: backendData.name || storedName || "Trig",
          oab: backendData.oab || storedOab || "123-456789",
          role: backendData.role || "Advogado",
          level: backendData.level || "SÊNIOR",
          avatar: backendData.avatar || "https://host-trig.vercel.app/files/1000_F_808373133_lrCrFLLTXF0A2WQK7QKMCNAzKCjX7kvb.png",
        })

        setLoading(false)

        toast({
          title: "Bem-vindo ao Sistema OAC",
          description: `Você está conectado como ${backendData.name || storedName || "Trig"}`,
        })
      } catch (error) {
        console.error("Erro ao carregar dados do usuário:", error)

        // Fallback para dados locais em caso de erro
        const storedName = localStorage.getItem("user_name")
        const storedOab = localStorage.getItem("oab_number") || registeredOab

        setUserData({
          name: storedName || "Trig",
          oab: storedOab || "123-456789",
          role: "Advogado",
          level: "SÊNIOR",
          avatar: "https://host-trig.vercel.app/files/1000_F_808373133_lrCrFLLTXF0A2WQK7QKMCNAzKCjX7kvb.png",
        })

        setLoading(false)

        toast({
          title: "Bem-vindo ao Sistema OAC",
          description: `Você está conectado como ${storedName || "Trig"}`,
        })
      }
    }

    loadUserData()
  }, [toast, registeredOab])

  const handleExit = () => {
    onExit()
  }

  if (loading) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-4">
          <Loader2 className="h-12 w-12 animate-spin text-primary" />
          <h2 className="text-xl font-semibold">Carregando Sistema OAC...</h2>
        </div>
      </div>
    )
  }

  return (
    <div className="flex h-full flex-col overflow-hidden bg-background">
      <Header userData={userData} onExit={handleExit} />
      <div className="flex flex-1 overflow-hidden">
        <Sidebar activePanel={activePanel} setActivePanel={setActivePanel} />
        <main className="flex-1 overflow-hidden p-2 sm:p-4">
          <div className="glass-panel h-full overflow-hidden p-2 sm:p-4">
            {activePanel === "home" && <HomePanel userData={userData} />}
            {activePanel === "passaporte" && <PassportPanel />}
            {activePanel === "registro-geral" && <RegistroGeralPanel />}
            {activePanel === "consulta" && <ConsultaPanel />}
            {activePanel === "alta-ordem" && <AltaOrdemPanel />}
            {activePanel === "documentos" && <DocumentosPanel />}
            {activePanel === "calendario" && <CalendarioPanel />}
            {activePanel === "configuracoes" && <ConfiguracoesPanel userData={userData} />}
          </div>
        </main>
      </div>
    </div>
  )
}
