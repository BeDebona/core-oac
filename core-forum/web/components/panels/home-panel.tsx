import type React from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { BarChart, FileText, Users, Calendar, Clock, ArrowUpRight, ArrowDownRight } from "lucide-react"
import { UserCard } from "@/components/user-card"

interface HomePanelProps {
  userData: {
    name: string
    oab: string
    role: string
    level: string
    avatar: string
  }
}

export const HomePanel = ({ userData }: HomePanelProps) => {
  return (
    <div className="flex h-full flex-col gap-4 overflow-auto">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-semibold tracking-tight">Bem-vindo, {userData.name}!</h2>
        <div className="flex items-center gap-2">
          <Badge variant="outline" className="text-xs">
            <Clock className="mr-1 h-3 w-3" />
            {new Date().toLocaleDateString("pt-BR", {
              weekday: "long",
              year: "numeric",
              month: "long",
              day: "numeric",
            })}
          </Badge>
        </div>
      </div>



      <Tabs defaultValue="atividades" className="flex-1">
        <TabsList>
          <TabsTrigger value="atividades">Atividades Recentes</TabsTrigger>

        </TabsList>
        <TabsContent value="atividades" className="mt-4 flex-1">
          <Card className="h-[calc(100%-1rem)]">
            <CardHeader>
              <CardTitle>Atividades Recentes</CardTitle>
            </CardHeader>
            <CardContent className="h-[calc(100%-5rem)] overflow-auto">
              <div className="space-y-4">
                <ActivityItem
                  icon={<FileText className="h-4 w-4" />}
                  title="Passaporte aprovado"
                  description="Você aprovou o passaporte de João Silva"
                  timestamp="Há 10 minutos"
                />
                <ActivityItem
                  icon={<FileText className="h-4 w-4" />}
                  title="Novo processo registrado"
                  description="Processo #1234 foi registrado no sistema"
                  timestamp="Há 2 horas"
                />
                <ActivityItem
                  icon={<Calendar className="h-4 w-4" />}
                  title="Audiência agendada"
                  description="Audiência do caso #5678 marcada para 15/05/2023"
                  timestamp="Há 5 horas"
                />
                <ActivityItem
                  icon={<FileText className="h-4 w-4" />}
                  title="Documento assinado"
                  description="Você assinou o documento #9012"
                  timestamp="Ontem"
                />
                <ActivityItem
                  icon={<Users className="h-4 w-4" />}
                  title="Novo cliente"
                  description="Maria Oliveira foi registrada como cliente"
                  timestamp="Há 2 dias"
                />
                <ActivityItem
                  icon={<FileText className="h-4 w-4" />}
                  title="Passaporte rejeitado"
                  description="Você rejeitou o passaporte de Carlos Pereira"
                  timestamp="Há 3 dias"
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="estatisticas" className="mt-4 flex-1">
          <Card className="h-[calc(100%-1rem)]">
            <CardHeader>
              <CardTitle>Estatísticas</CardTitle>
            </CardHeader>
            <CardContent className="h-[calc(100%-5rem)]">
              <div className="flex h-full items-center justify-center">
                <div className="flex flex-col items-center gap-4 text-center">
                  <BarChart className="h-16 w-16 text-muted-foreground" />
                  <p className="text-muted-foreground">Estatísticas detalhadas estarão disponíveis em breve.</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="md:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle>Prisões Recentes</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-center justify-between rounded-lg border p-3">
                  <div>
                    <p className="font-medium">Caso #1234</p>
                    <p className="text-sm text-muted-foreground">Assalto a mão armada - 100 meses</p>
                  </div>
                </div>
                <div className="flex items-center justify-between rounded-lg border p-3">
                  <div>
                    <p className="font-medium">Caso #5678</p>
                    <p className="text-sm text-muted-foreground">Furto - 30 meses</p>
                  </div>
                </div>
                <div className="flex items-center justify-between rounded-lg border p-3">
                  <div>
                    <p className="font-medium">Caso #9012</p>
                    <p className="text-sm text-muted-foreground">Direção perigosa - 20 meses</p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
        <div className="md:order-first lg:order-none">
          <UserCard userData={userData} />
        </div>
      </div>
    </div>
  )
}

interface ActivityItemProps {
  icon: React.ReactNode
  title: string
  description: string
  timestamp: string
}

const ActivityItem = ({ icon, title, description, timestamp }: ActivityItemProps) => {
  return (
    <div className="flex items-start gap-4 rounded-lg border p-3">
      <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-primary">{icon}</div>
      <div className="flex-1">
        <p className="font-medium">{title}</p>
        <p className="text-sm text-muted-foreground">{description}</p>
      </div>
      <div className="text-xs text-muted-foreground">{timestamp}</div>
    </div>
  )
}
