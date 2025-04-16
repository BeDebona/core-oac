"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Badge } from "@/components/ui/badge"
import { Search, FileText, Scale, User, Calendar } from "lucide-react"

export const ConsultaPanel = () => {
  const [searchQuery, setSearchQuery] = useState("")
  const [searchResults, setSearchResults] = useState<any[]>([])
  const [isSearching, setIsSearching] = useState(false)

  const handleSearch = () => {
    if (searchQuery.length < 3) return

    setIsSearching(true)

    // Simulando uma busca com delay
    setTimeout(() => {
      // Dados mockados para demonstração
      const results = [
        {
          type: "law",
          title: "ASSALTO A MÃO ARMADA",
          description: "Pena: 100 meses de prisão e multa de $15,000",
          id: "1",
        },
        {
          type: "law",
          title: "FURTO",
          description: "Pena: 30 meses de prisão e multa de $5,000",
          id: "2",
        },
        {
          type: "case",
          title: "PROCESSO #1234",
          description: "Réu: João Silva - Acusação: Assalto a mão armada",
          status: "Em andamento",
          id: "3",
        },
        {
          type: "person",
          title: "MARIA OLIVEIRA",
          description: "CPF: 123.456.789-00 - Passaporte: Aprovado",
          id: "4",
        },
      ].filter(
        (item) =>
          item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
          item.description.toLowerCase().includes(searchQuery.toLowerCase()),
      )

      setSearchResults(results)
      setIsSearching(false)
    }, 1000)
  }

  return (
    <div className="flex h-full flex-col gap-4 overflow-auto">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-semibold tracking-tight">Consulta</h2>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          placeholder="Buscar por CPF, nome, número do processo ou lei..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleSearch()}
          className="pl-10 pr-20"
        />
        <Button
          className="absolute right-1 top-1/2 h-8 -translate-y-1/2"
          onClick={handleSearch}
          disabled={searchQuery.length < 3 || isSearching}
        >
          {isSearching ? "Buscando..." : "Buscar"}
        </Button>
      </div>

      <Tabs defaultValue="resultados" className="flex-1">
        <TabsList>
          <TabsTrigger value="resultados">Resultados</TabsTrigger>
          <TabsTrigger value="leis">Leis</TabsTrigger>
          <TabsTrigger value="processos">Processos</TabsTrigger>
          <TabsTrigger value="pessoas">Pessoas</TabsTrigger>
        </TabsList>
        <TabsContent value="resultados" className="mt-4 flex-1">
          <Card className="h-[calc(100%-1rem)]">
            <CardHeader>
              <CardTitle>Resultados da Busca</CardTitle>
            </CardHeader>
            <CardContent className="h-[calc(100%-5rem)] overflow-auto">
              {searchResults.length > 0 ? (
                <div className="space-y-4">
                  {searchResults.map((result) => (
                    <SearchResultItem key={result.id} result={result} />
                  ))}
                </div>
              ) : (
                <div className="flex h-full flex-col items-center justify-center">
                  <Search className="mb-4 h-12 w-12 text-muted-foreground" />
                  <p className="text-center text-muted-foreground">
                    {searchQuery.length > 0
                      ? "Nenhum resultado encontrado. Tente outros termos."
                      : "Digite algo para pesquisar..."}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="leis" className="mt-4 flex-1">
          <Card className="h-[calc(100%-1rem)]">
            <CardHeader>
              <CardTitle>Código Penal</CardTitle>
            </CardHeader>
            <CardContent className="h-[calc(100%-5rem)] overflow-auto">
              <div className="space-y-4">
                <LawItem title="ASSALTO A MÃO ARMADA" description="Pena: 100 meses de prisão e multa de $15,000" />
                <LawItem title="FURTO" description="Pena: 30 meses de prisão e multa de $5,000" />
                <LawItem title="ROUBO" description="Pena: 45 meses de prisão e multa de $10,000" />
                <LawItem title="DIREÇÃO PERIGOSA" description="Pena: 20 meses de prisão e multa de $3,000" />
                <LawItem title="POSSE DE DROGAS" description="Pena: 15 meses de prisão e multa de $2,000" />
                <LawItem title="TRÁFICO DE DROGAS" description="Pena: 60 meses de prisão e multa de $12,000" />
              </div>
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="processos" className="mt-4 flex-1">
          <Card className="h-[calc(100%-1rem)]">
            <CardHeader>
              <CardTitle>Processos Recentes</CardTitle>
            </CardHeader>
            <CardContent className="h-[calc(100%-5rem)] overflow-auto">
              <div className="space-y-4">
                <ProcessItem
                  number="1234"
                  defendant="João Silva"
                  charge="Assalto a mão armada"
                  status="Em andamento"
                  date="15/05/2023"
                />
                <ProcessItem
                  number="5678"
                  defendant="Maria Oliveira"
                  charge="Furto"
                  status="Concluído"
                  date="10/04/2023"
                />
                <ProcessItem
                  number="9012"
                  defendant="Carlos Pereira"
                  charge="Direção perigosa"
                  status="Agendado"
                  date="20/05/2023"
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="pessoas" className="mt-4 flex-1">
          <Card className="h-[calc(100%-1rem)]">
            <CardHeader>
              <CardTitle>Pessoas Registradas</CardTitle>
            </CardHeader>
            <CardContent className="h-[calc(100%-5rem)] overflow-auto">
              <div className="space-y-4">
                <PersonItem name="João Silva" id="123.456.789-00" status="Passaporte aprovado" />
                <PersonItem name="Maria Oliveira" id="987.654.321-00" status="Passaporte aprovado" />
                <PersonItem name="Carlos Pereira" id="111.222.333-44" status="Passaporte pendente" />
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}

interface SearchResultItemProps {
  result: {
    type: string
    title: string
    description: string
    status?: string
    id: string
  }
}

const SearchResultItem = ({ result }: SearchResultItemProps) => {
  const getIcon = () => {
    switch (result.type) {
      case "law":
        return <Scale className="h-5 w-5" />
      case "case":
        return <FileText className="h-5 w-5" />
      case "person":
        return <User className="h-5 w-5" />
      default:
        return <Search className="h-5 w-5" />
    }
  }

  return (
    <div className="flex items-start gap-4 rounded-lg border p-4">
      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary">
        {getIcon()}
      </div>
      <div className="flex-1">
        <div className="flex items-center justify-between">
          <h3 className="font-semibold">{result.title}</h3>
          {result.status && <Badge variant="outline">{result.status}</Badge>}
        </div>
        <p className="mt-1 text-sm text-muted-foreground">{result.description}</p>
        <Button variant="link" className="mt-2 h-auto p-0 text-primary">
          Ver detalhes
        </Button>
      </div>
    </div>
  )
}

interface LawItemProps {
  title: string
  description: string
}

const LawItem = ({ title, description }: LawItemProps) => {
  return (
    <div className="rounded-lg border p-4">
      <div className="flex items-center gap-2">
        <Scale className="h-5 w-5 text-primary" />
        <h3 className="font-semibold">{title}</h3>
      </div>
      <p className="mt-2 text-sm text-muted-foreground">{description}</p>
    </div>
  )
}

interface ProcessItemProps {
  number: string
  defendant: string
  charge: string
  status: string
  date: string
}

const ProcessItem = ({ number, defendant, charge, status, date }: ProcessItemProps) => {
  return (
    <div className="rounded-lg border p-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <FileText className="h-5 w-5 text-primary" />
          <h3 className="font-semibold">PROCESSO #{number}</h3>
        </div>
        <Badge variant={status === "Em andamento" ? "default" : status === "Concluído" ? "secondary" : "outline"}>
          {status}
        </Badge>
      </div>
      <div className="mt-2 grid grid-cols-2 gap-2 text-sm">
        <div>
          <span className="text-muted-foreground">Réu:</span> <span>{defendant}</span>
        </div>
        <div>
          <span className="text-muted-foreground">Acusação:</span> <span>{charge}</span>
        </div>
        <div className="col-span-2 flex items-center gap-1">
          <Calendar className="h-4 w-4 text-muted-foreground" />
          <span className="text-muted-foreground">{date}</span>
        </div>
      </div>
    </div>
  )
}

interface PersonItemProps {
  name: string
  id: string
  status: string
}

const PersonItem = ({ name, id, status }: PersonItemProps) => {
  return (
    <div className="rounded-lg border p-4">
      <div className="flex items-center gap-2">
        <User className="h-5 w-5 text-primary" />
        <h3 className="font-semibold">{name}</h3>
      </div>
      <div className="mt-2 grid grid-cols-2 gap-2 text-sm">
        <div>
          <span className="text-muted-foreground">CPF/RG:</span> <span>{id}</span>
        </div>
        <div>
          <span className="text-muted-foreground">Status:</span> <span>{status}</span>
        </div>
      </div>
    </div>
  )
}
