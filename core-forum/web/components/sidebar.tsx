"use client"

import type React from "react"
import { useState, useEffect } from "react"
import { Home, BookOpen, FileText, Search, Shield, FileSignature, Calendar, Settings, Menu, X, ChevronRight } from "lucide-react"
import type { Panel } from "@/components/dashboard"
import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

interface SidebarProps {
  activePanel: Panel
  setActivePanel: (panel: Panel) => void
}

export const Sidebar = ({ activePanel, setActivePanel }: SidebarProps) => {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [isCollapsed, setIsCollapsed] = useState(false)

  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth < 768) {
        setIsCollapsed(false)
      }
    }

    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  const toggleSidebar = () => {
    setSidebarOpen(!sidebarOpen)
  }

  const handlePanelChange = (panel: Panel) => {
    setActivePanel(panel)
    if (window.innerWidth < 768) {
      setSidebarOpen(false)
    }
  }

  return (
    <>
      <Button 
        variant="ghost" 
        size="icon" 
        className="fixed left-2 top-2 z-50 md:hidden hover:bg-accent" 
        onClick={toggleSidebar}
      >
        {sidebarOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
      </Button>

      <aside
        className={cn(
          "fixed md:relative z-40 h-full transition-all duration-300 ease-in-out",
          sidebarOpen ? "translate-x-0" : "hidden md:block",
          isCollapsed ? "w-20" : "w-64",
          "border-r border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60"
        )}
      >
        <div className="flex h-full flex-col">
          <div className="flex items-center justify-between p-4 h-16">
            <h2 className={cn(
              "font-semibold tracking-tight transition-all duration-300",
              isCollapsed ? "opacity-0 w-0" : "opacity-100"
            )}>
              Sistema OAC
            </h2>
            <Button
              variant="ghost"
              size="icon"
              className="hidden md:flex"
              onClick={() => setIsCollapsed(!isCollapsed)}
            >
              <ChevronRight className={cn(
                "h-4 w-4 transition-transform duration-300",
                isCollapsed ? "rotate-180" : ""
              )} />
            </Button>
          </div>

          <div className={cn(
            "flex-1 py-2",
            isCollapsed ? "overflow-visible" : "overflow-auto"
          )}>
            <nav className="grid gap-1 px-2">
              <SidebarItem
                icon={<Home className="h-4 w-4" />}
                label="Home"
                panel="home"
                active={activePanel === "home"}
                onClick={() => handlePanelChange("home")}
                isCollapsed={isCollapsed}
              />
              <SidebarItem
                icon={<BookOpen className="h-4 w-4" />}
                label="Passaporte"
                panel="passaporte"
                active={activePanel === "passaporte"}
                onClick={() => handlePanelChange("passaporte")}
                isCollapsed={isCollapsed}
              />
              <SidebarItem
                icon={<FileText className="h-4 w-4" />}
                label="Registro-Geral"
                panel="registro-geral"
                active={activePanel === "registro-geral"}
                onClick={() => handlePanelChange("registro-geral")}
                isCollapsed={isCollapsed}
              />
              <SidebarItem
                icon={<Search className="h-4 w-4" />}
                label="Consulta"
                panel="consulta"
                active={activePanel === "consulta"}
                onClick={() => handlePanelChange("consulta")}
                isCollapsed={isCollapsed}
              />
              <SidebarItem
                icon={<Shield className="h-4 w-4" />}
                label="Alta Ordem"
                panel="alta-ordem"
                active={activePanel === "alta-ordem"}
                onClick={() => handlePanelChange("alta-ordem")}
                isCollapsed={isCollapsed}
              />
              <SidebarItem
                icon={<FileSignature className="h-4 w-4" />}
                label="Documentos"
                panel="documentos"
                active={activePanel === "documentos"}
                onClick={() => handlePanelChange("documentos")}
                isCollapsed={isCollapsed}
              />
              <SidebarItem
                icon={<Calendar className="h-4 w-4" />}
                label="Calendário"
                panel="calendario"
                active={activePanel === "calendario"}
                onClick={() => handlePanelChange("calendario")}
                isCollapsed={isCollapsed}
              />
              <SidebarItem
                icon={<Settings className="h-4 w-4" />}
                label="Configurações"
                panel="configuracoes"
                active={activePanel === "configuracoes"}
                onClick={() => handlePanelChange("configuracoes")}
                isCollapsed={isCollapsed}
              />
            </nav>
          </div>

          {!isCollapsed && (
            <div className="mt-auto p-4">
              <div className="rounded-lg bg-muted p-3 text-xs text-muted-foreground">
                <p className="font-medium">Sistema OAC v1.0</p>
                <p className="mt-1">© 2025 Central City/Core Devs</p>
              </div>
            </div>
          )}
        </div>
      </aside>

      {sidebarOpen && (
        <div 
          className="fixed inset-0 z-30 bg-black/50 md:hidden backdrop-blur-sm" 
          onClick={toggleSidebar} 
        />
      )}
    </>
  )
}

interface SidebarItemProps {
  icon: React.ReactNode
  label: string
  panel: Panel
  active: boolean
  onClick: () => void
  isCollapsed: boolean
}

const SidebarItem = ({ icon, label, active, onClick, isCollapsed }: SidebarItemProps) => {
  return (
    <button
      className={cn(
        "flex items-center gap-2 w-full rounded-lg px-3 h-9 text-sm transition-colors duration-200",
        "hover:bg-accent hover:text-accent-foreground",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
        active ? "bg-accent text-accent-foreground" : "text-muted-foreground",
        isCollapsed ? "justify-center" : "justify-start"
      )}
      onClick={onClick}
    >
      {icon}
      <span className={cn(
        "font-medium transition-all duration-300 whitespace-nowrap",
        isCollapsed ? "w-0 opacity-0" : "opacity-100"
      )}>
        {label}
      </span>
    </button>
  )
}