"use client"

import { useState, useEffect } from "react"
import { TabletFrame } from "@/components/tablet-frame"
import { Dashboard } from "@/components/dashboard"
import { OabRegistrationModal } from "@/components/modals/oab-registration-modal"
import { generateRandomOab } from "@/lib/utils"
import { sendToBackend, registerCallback } from "@/lib/api"

export default function Home() {
  const [isFirstUse, setIsFirstUse] = useState(false)
  const [oabNumber, setOabNumber] = useState("")
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    // Verificar se é a primeira utilização
    const storedOab = localStorage.getItem("oab_number")

    if (!storedOab) {
      setIsFirstUse(true)
      const newOab = generateRandomOab()
      setOabNumber(newOab)
      setIsLoading(false)
    } else {
      setOabNumber(storedOab)
      setIsLoading(false)
    }

    // Registrar callbacks para eventos do back-end
    const unregisterNotification = registerCallback("notification", (data) => {
      console.log("Notificação recebida:", data)
      // Aqui você pode mostrar uma notificação usando o componente toast
    })

    const unregisterSystemUpdate = registerCallback("systemUpdate", (data) => {
      console.log("Atualização do sistema:", data)
      // Aqui você pode mostrar uma mensagem de atualização do sistema
    })

    // Limpar callbacks ao desmontar o componente
    return () => {
      unregisterNotification()
      unregisterSystemUpdate()
    }
  }, [])

  const handleRegisterOab = async (name: string) => {
    try {
      // Enviar dados para o back-end
      await sendToBackend("registerOab", { name, oab: oabNumber })

      // Salvar OAB no localStorage
      localStorage.setItem("oab_number", oabNumber)
      localStorage.setItem("user_name", name)
      setIsFirstUse(false)
    } catch (error) {
      console.error("Erro ao registrar OAB:", error)
      // Continuar mesmo com erro para desenvolvimento local
      localStorage.setItem("oab_number", oabNumber)
      localStorage.setItem("user_name", name)
      setIsFirstUse(false)
    }
  }

  const handleExit = async () => {
    try {
      await sendToBackend("exit")
    } catch (error) {
      console.error("Erro ao sair:", error)
    }
  }

  if (isLoading) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-gradient-to-b from-gray-900 to-black p-1 sm:p-4">
        <div className="text-center">
          <div className="animate-spin h-12 w-12 border-4 border-primary border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-white text-lg">Carregando...</p>
        </div>
      </main>
    )
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-gradient-to-b from-gray-900 to-black p-1 sm:p-4">
      <TabletFrame>
        <Dashboard registeredOab={oabNumber} onExit={handleExit} />
      </TabletFrame>

      <OabRegistrationModal isOpen={isFirstUse} oabNumber={oabNumber} onRegister={handleRegisterOab} />
    </main>
  )
}
