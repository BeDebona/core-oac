// Funções para comunicação com o back-end (FiveM/GTA RP)

declare function GetParentResourceName(): string

/**
 * Verifica se o código está sendo executado no ambiente FiveM
 */
export const isFiveMEnvironment = (): boolean => {
  return typeof window !== "undefined" && "invokeNative" in window
}

/**
 * Obtém o nome do recurso pai
 */
export const getResourceName = (): string => {
  if (isFiveMEnvironment() && typeof GetParentResourceName === "function") {
    return GetParentResourceName()
  }
  return "oac-forum"
}

/**
 * Envia uma solicitação para o back-end
 */
export const sendToBackend = async (eventName: string, data: Record<string, any> = {}): Promise<any> => {
  if (!isFiveMEnvironment()) {
    console.log(`Simulando envio para o back-end: ${eventName}`, data)
    return mockResponse(eventName, data)
  }

  try {
    const response = await fetch(`https://${getResourceName()}/${eventName}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: JSON.stringify(data),
    })

    return await response.json()
  } catch (error) {
    console.error(`Erro ao enviar ${eventName} para o back-end:`, error)
    throw error
  }
}

/**
 * Registra um callback para eventos do back-end
 */
export const registerCallback = (eventName: string, callback: (data: any) => void): (() => void) => {
  if (!isFiveMEnvironment()) {
    console.log(`Simulando registro de callback para: ${eventName}`)
    return () => {}
  }

  // Registra o callback no objeto window para que o back-end possa chamá-lo
  const callbackName = `__oac_callback_${eventName}`
  ;(window as any)[callbackName] = callback

  // Notifica o back-end sobre o registro do callback
  sendToBackend("registerCallback", { eventName, callbackName })

  // Retorna uma função para remover o callback
  return () => {
    delete (window as any)[callbackName]
    sendToBackend("unregisterCallback", { eventName, callbackName })
  }
}

/**
 * Simula respostas do back-end para desenvolvimento local
 */
const mockResponse = (eventName: string, data: Record<string, any>): Promise<any> => {
  // Simula um atraso de rede
  return new Promise((resolve) => {
    setTimeout(() => {
      switch (eventName) {
        case "getPlayerInfo":
          resolve({
            name: "Trig",
            oab: data.oab || "123-456789",
            role: "Advogado",
            level: "SÊNIOR",
            avatar: "/assets/",
          })
          break
        case "createPassport":
          resolve({ success: true, id: Math.floor(Math.random() * 1000).toString() })
          break
        case "approvePassport":
          resolve({ success: true })
          break
        case "rejectPassport":
          resolve({ success: true })
          break
        case "getLeis":
          resolve([
            {
              id: 1,
              categoria: "Código Penal",
              titulo: "Artigo 1 - Furto",
              conteudo: "Pena: 30 meses de prisão e multa de $5,000",
            },
            {
              id: 2,
              categoria: "Código Penal",
              titulo: "Artigo 2 - Roubo",
              conteudo: "Pena: 45 meses de prisão e multa de $10,000",
            },
            {
              id: 3,
              categoria: "Código Penal",
              titulo: "Artigo 3 - Assalto a Mão Armada",
              conteudo: "Pena: 100 meses de prisão e multa de $15,000",
            },
          ])
          break
        case "getPassaportes":
          resolve([
            {
              id: "101",
              nome: "João Silva",
              identidade: "123.456.789-00",
              dataNascimento: "1990-05-15",
              foto: "/assets/",
              orgao: "Juiz TrigX1",
              status: "pendente",
            },
            {
              id: "102",
              nome: "Maria Oliveira",
              identidade: "987.654.321-00",
              dataNascimento: "1985-10-20",
              foto: "/assets/",
              orgao: "Juiz TrigX1",
              status: "aprovado",
            },
          ])
          break
        case "exit":
          resolve({ success: true })
          break
        default:
          resolve({ success: false, error: "Evento não reconhecido" })
      }
    }, 300)
  })
}
