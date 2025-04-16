"use client"

import type React from "react"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Badge } from "@/components/ui/badge"
import { FileText, Upload, Check, Pen, FileSignature, X, Clock } from "lucide-react"
import { useToast } from "@/components/ui/use-toast"
import { SignatureModal } from "@/components/modals/signature-modal"

export const DocumentosPanel = () => {
  const [formData, setFormData] = useState({
    type: "",
    name: "",
    identity: "",
    description: "",
  })
  const [signature, setSignature] = useState<string | null>(null)
  const [showSignature, setShowSignature] = useState(false)
  const [evidenceFiles, setEvidenceFiles] = useState<{ name: string; size: string }[]>([])
  const { toast } = useToast()

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSelectChange = (name: string, value: string) => {
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()

    if (!formData.type || !formData.name || !formData.identity || !formData.description) {
      toast({
        title: "Erro",
        description: "Por favor, preencha todos os campos obrigatórios.",
        variant: "destructive",
      })
      return
    }

    if (!signature) {
      toast({
        title: "Erro",
        description: "Por favor, assine o documento antes de enviar.",
        variant: "destructive",
      })
      return
    }

    // Aqui você enviaria os dados para o servidor
    console.log("Enviando documento:", {
      ...formData,
      evidence: evidenceFiles,
      signature,
    })

    toast({
      title: "Sucesso",
      description: "Documento criado com sucesso!",
      variant: "default",
    })

    // Resetar o formulário
    setFormData({
      type: "",
      name: "",
      identity: "",
      description: "",
    })
    setSignature(null)
    setEvidenceFiles([])
  }

  const handleSignatureCapture = (signatureData: string) => {
    setSignature(signatureData)
    setShowSignature(false)
    toast({
      title: "Assinatura Salva",
      description: "Sua assinatura foi salva com sucesso.",
      variant: "default",
    })
  }

  const handleFileUpload = () => {
    // Simulando upload de arquivo
    const mockFile = {
      name: `Evidência_${Date.now()}.jpg`,
      size: "1.2 MB",
    }
    setEvidenceFiles((prev) => [...prev, mockFile])
  }

  const removeFile = (index: number) => {
    setEvidenceFiles((prev) => prev.filter((_, i) => i !== index))
  }

  // Dados mockados para demonstração
  const recentDocuments = [
    {
      id: "DOC-001",
      type: "Petição",
      name: "João Silva",
      description: "Petição inicial para processo de furto",
      status: "Em andamento",
      date: "10/05/2023",
    },
    {
      id: "DOC-002",
      type: "Auto de Defesa",
      name: "Maria Oliveira",
      description: "Defesa contra acusação de direção perigosa",
      status: "Concluído",
      date: "05/05/2023",
    },
    {
      id: "DOC-003",
      type: "Mandado",
      name: "Carlos Pereira",
      description: "Mandado de busca e apreensão",
      status: "Pendente",
      date: "12/05/2023",
    },
  ]

  return (
    <div className="flex h-full flex-col gap-4 overflow-auto">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-semibold tracking-tight">Documentos Jurídicos</h2>
      </div>

      <Tabs defaultValue="criar" className="flex-1">
        <TabsList>
          <TabsTrigger value="criar">Criar Documento</TabsTrigger>
          <TabsTrigger value="recentes">Documentos Recentes</TabsTrigger>
        </TabsList>
        <TabsContent value="criar" className="mt-4 flex-1">
          <Card className="flex-1">
            <CardHeader>
              <CardTitle>Criação de Documento Jurídico</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                  <div className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="type">Topo de Documento</Label>
                      <Select value={formData.type} onValueChange={(value) => handleSelectChange("type", value)}>
                        <SelectTrigger id="type">
                          <SelectValue placeholder="Selecione o tipo" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="peticao">Petição</SelectItem>
                          <SelectItem value="defesa">Auto de Defesa</SelectItem>
                          <SelectItem value="mandado">Mandado</SelectItem>
                          <SelectItem value="processo">Processo</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="name">Nome do Réu/Envolvido</Label>
                      <Input
                        id="name"
                        name="name"
                        value={formData.name}
                        onChange={handleInputChange}
                        placeholder="Digite o nome completo"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="identity">RG</Label>
                      <Input
                        id="identity"
                        name="identity"
                        value={formData.identity}
                        onChange={handleInputChange}
                        placeholder="Digite o número do documento"
                      />
                    </div>
                  </div>

                  <div className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="description">Descrição/Acusação</Label>
                      <Textarea
                        id="description"
                        name="description"
                        value={formData.description}
                        onChange={handleInputChange}
                        placeholder="Descreva os detalhes do caso"
                        rows={5}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label>Anexar provas</Label>
                      <div className="rounded-lg border border-dashed border-border p-4">
                        <div className="flex flex-col items-center gap-2">
                          <Upload className="h-8 w-8 text-muted-foreground" />
                          <p className="text-sm text-muted-foreground">Arraste arquivos ou clique para fazer upload</p>
                          <Button type="button" variant="outline" size="sm" onClick={handleFileUpload}>
                            Selecionar Arquivos
                          </Button>
                        </div>

                        {evidenceFiles.length > 0 && (
                          <div className="mt-4 space-y-2">
                            <p className="text-sm font-medium">Arquivos anexados:</p>
                            {evidenceFiles.map((file, index) => (
                              <div
                                key={index}
                                className="flex items-center justify-between rounded-lg bg-muted/50 p-2 text-sm"
                              >
                                <div className="flex items-center gap-2">
                                  <FileText className="h-4 w-4 text-primary" />
                                  <span>{file.name}</span>
                                  <span className="text-xs text-muted-foreground">({file.size})</span>
                                </div>
                                <Button type="button" variant="ghost" size="icon" onClick={() => removeFile(index)}>
                                  <X className="h-4 w-4" />
                                </Button>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-4">
                  <div className="flex-1">
                    {signature ? (
                      <div className="flex items-center gap-2 rounded-lg border p-2">
                        <img
                          src={signature || "/placeholder.svg"}
                          alt="Assinatura"
                          className="h-12 max-w-[200px] object-contain"
                        />
                        <Button type="button" variant="ghost" size="icon" onClick={() => setSignature(null)}>
                          <X className="h-4 w-4" />
                        </Button>
                      </div>
                    ) : (
                      <Button type="button" variant="outline" onClick={() => setShowSignature(true)}>
                        <Pen className="mr-2 h-4 w-4" />
                        Assinar Documento
                      </Button>
                    )}
                  </div>
                  <Button type="submit">
                    <Check className="mr-2 h-4 w-4" />
                    Enviar Documento
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="recentes" className="mt-4 flex-1">
          <Card className="flex-1">
            <CardHeader>
              <CardTitle>Documentos Recentes</CardTitle>
            </CardHeader>
            <CardContent className="h-[calc(100%-5rem)] overflow-auto">
              <div className="space-y-4">
                {recentDocuments.map((doc) => (
                  <div key={doc.id} className="flex items-start justify-between rounded-lg border p-4">
                    <div className="flex items-start gap-4">
                      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary">
                        <FileSignature className="h-5 w-5" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="font-semibold">{doc.id}</h3>
                          <Badge
                            variant={
                              doc.status === "Concluído"
                                ? "secondary"
                                : doc.status === "Em andamento"
                                  ? "default"
                                  : "outline"
                            }
                          >
                            {doc.status}
                          </Badge>
                        </div>
                        <p className="mt-1 text-sm">
                          <span className="font-medium">{doc.type}:</span> {doc.name}
                        </p>
                        <p className="text-sm text-muted-foreground">{doc.description}</p>
                        <div className="mt-2 flex items-center gap-1 text-xs text-muted-foreground">
                          <Clock className="h-3 w-3" />
                          <span>{doc.date}</span>
                        </div>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Button variant="outline" size="icon">
                        <FileText className="h-4 w-4" />
                      </Button>
                      {doc.status === "Pendente" && (
                        <>
                          <Button variant="destructive" size="icon">
                            <X className="h-4 w-4" />
                          </Button>
                          <Button variant="default" size="icon">
                            <Check className="h-4 w-4" />
                          </Button>
                        </>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <SignatureModal isOpen={showSignature} onClose={() => setShowSignature(false)} onSave={handleSignatureCapture} />
    </div>
  )
}
