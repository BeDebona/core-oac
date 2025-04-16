"use client"

import { Bell, LogOut } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import Image from "next/image"

interface HeaderProps {
  userData: {
    name: string
    oab: string
    role: string
    level: string
    avatar: string
  }
  onExit: () => void
}

export const Header = ({ userData, onExit }: HeaderProps) => {
  return (
    <header className="border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="relative flex h-14 sm:h-16 items-center px-2 sm:px-4">
        {/* LOGO da OAC à esquerda */}
        <div className="flex items-center gap-2 sm:gap-3">
          <div className="relative h-10 w-10 sm:h-16 sm:w-16">
            <Image
              src="https://host-trig.vercel.app/files/OAC%20-%20Branco.png"
              alt="OAC Logo"
              fill
              className="object-contain"
            />
          </div>
        </div>

        {/* TEXTO centralizado */}
        <div className="absolute left-1/2 -translate-x-1/2 flex items-center">
          <h1 className="text-sm font-semibold sm:text-lg tracking-tight hidden xs:block">
            Ordem dos Advogados de Central City
          </h1>
          <h1 className="text-sm font-semibold tracking-tight xs:hidden">OAC</h1>
        </div>

        {/* ÍCONES à direita */}
        <div className="ml-auto flex items-center gap-2 sm:gap-4">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="relative">
              <Bell className="h-4 w-4 sm:h-5 sm:w-5" />
              <span className="absolute -right-1 -top-1 flex h-4 w-4 sm:h-5 sm:w-5 items-center justify-center rounded-full bg-cyan-500 text-[10px] font-semibold text-black sm:text-xs">
                3
              </span>
            </Button>

            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-60 sm:w-80">
              <DropdownMenuLabel>Notificações</DropdownMenuLabel>
              <DropdownMenuSeparator />
              <div className="max-h-60 sm:max-h-80 overflow-auto">
                <NotificationItem
                  title="Novo passaporte pendente"
                  description="Passaporte de João Silva aguardando aprovação"
                  time="Agora"
                  unread
                />
                <NotificationItem
                  title="Audiência marcada"
                  description="Audiência do caso #1234 marcada para amanhã às 14h"
                  time="1h atrás"
                  unread
                />
                <NotificationItem
                  title="Documento assinado"
                  description="Maria Oliveira assinou o documento #5678"
                  time="3h atrás"
                  unread
                />
                <NotificationItem
                  title="Novo processo"
                  description="Processo #9012 foi registrado no sistema"
                  time="Ontem"
                />
                <NotificationItem
                  title="Atualização do sistema"
                  description="O sistema foi atualizado para a versão 2.1.0"
                  time="2 dias atrás"
                />
              </div>
              <DropdownMenuSeparator />
              <DropdownMenuItem className="cursor-pointer justify-center text-center">
                Ver todas as notificações
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <div className="relative h-6 w-6 sm:h-14 sm:w-14">
            <Image
              src="https://host-trig.vercel.app/files/Logo_Branca.png"
              alt="Central City"
              fill
              className="object-contain"
            />
          </div>

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" className="relative h-8 w-8 rounded-full">
                <Avatar className="h-7 w-7 sm:h-8 sm:w-8">
                  <AvatarImage src={userData.avatar || "/placeholder.svg"} alt={userData.name} />
                  <AvatarFallback>{userData.name.charAt(0)}</AvatarFallback>
                </Avatar>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel className="font-normal">
                <div className="flex flex-col space-y-1">
                  <p className="text-sm font-medium leading-none">{userData.name}</p>
                  <p className="text-xs leading-none text-muted-foreground">
                    {userData.oab} - {userData.role}
                  </p>
                </div>
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem className="text-destructive" onClick={onExit}>
                <LogOut className="mr-2 h-4 w-4" />
                <span>Sair</span>
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

    </header>
  )
}

interface NotificationItemProps {
  title: string
  description: string
  time: string
  unread?: boolean
}

const NotificationItem = ({ title, description, time, unread }: NotificationItemProps) => {
  return (
    <div className={`flex cursor-pointer flex-col gap-1 px-4 py-2 hover:bg-muted/50 ${unread ? "bg-muted/30" : ""}`}>
      <div className="flex items-center justify-between">
        <h4 className="text-sm font-medium">{title}</h4>
        <span className="text-xs text-muted-foreground">{time}</span>
      </div>
      <p className="text-xs text-muted-foreground">{description}</p>
      {unread && (
        <div className="mt-1 flex items-center">
          <Badge variant="default" className="h-1.5 w-1.5 rounded-full p-0" />
          <span className="ml-1.5 text-xs text-primary">Não lida</span>
        </div>
      )}
    </div>
  )
}
