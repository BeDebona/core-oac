"use client"

import type React from "react"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Calendar } from "@/components/ui/calendar"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { CalendarIcon, Clock } from "lucide-react"
import { format } from "date-fns"
import { ptBR } from "date-fns/locale"

interface NewEventModalProps {
  isOpen: boolean
  onClose: () => void
  onAddEvent: (event: any) => void
  selectedDate: Date | null
}

export function NewEventModal({ isOpen, onClose, onAddEvent, selectedDate }: NewEventModalProps) {
  const [date, setDate] = useState<Date | undefined>(selectedDate || undefined)
  const [formData, setFormData] = useState({
    title: "",
    description: "",
    time: "",
    location: "",
    participants: "",
    type: "audiencia" as "audiencia" | "reuniao" | "prazo",
  })

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSelectChange = (name: string, value: string) => {
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()

    if (!date || !formData.title || !formData.time || !formData.location || !formData.type) {
      return
    }

    const dateString = date.toISOString().split("T")[0]

    const newEvent = {
      title: formData.title,
      description: formData.description,
      date: dateString,
      time: formData.time,
      location: formData.location,
      participants: formData.participants
        .split(",")
        .map((p) => p.trim())
        .filter((p) => p),
      type: formData.type,
    }

    onAddEvent(newEvent)

    // Reset form
    setFormData({
      title: "",
      description: "",
      time: "",
      location: "",
      participants: "",
      type: "audiencia",
    })
    setDate(undefined)
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Novo Evento</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="title">Título do Evento</Label>
            <Input
              id="title"
              name="title"
              value={formData.title}
              onChange={handleInputChange}
              placeholder="Ex: Audiência - Caso #1234"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Descrição</Label>
            <Textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              placeholder="Detalhes do evento"
              rows={3}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Data</Label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button variant="outline" className="w-full justify-start text-left font-normal">
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {date ? format(date, "PPP", { locale: ptBR }) : "Selecione uma data"}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0">
                  <Calendar mode="single" selected={date} onSelect={setDate} initialFocus />
                </PopoverContent>
              </Popover>
            </div>

            <div className="space-y-2">
              <Label htmlFor="time">Horário</Label>
              <div className="flex items-center">
                <Clock className="mr-2 h-4 w-4 text-muted-foreground" />
                <Input id="time" name="time" type="time" value={formData.time} onChange={handleInputChange} required />
              </div>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="location">Local</Label>
            <Input
              id="location"
              name="location"
              value={formData.location}
              onChange={handleInputChange}
              placeholder="Ex: Sala 3 - Fórum Central"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="participants">Participantes</Label>
            <Input
              id="participants"
              name="participants"
              value={formData.participants}
              onChange={handleInputChange}
              placeholder="Nomes separados por vírgula"
            />
            <p className="text-xs text-muted-foreground">Deixe em branco se não houver participantes específicos</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="type">Tipo de Evento</Label>
            <Select value={formData.type} onValueChange={(value) => handleSelectChange("type", value)}>
              <SelectTrigger id="type">
                <SelectValue placeholder="Selecione o tipo" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="audiencia">Audiência</SelectItem>
                <SelectItem value="reuniao">Reunião</SelectItem>
                <SelectItem value="prazo">Prazo</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit">Adicionar Evento</Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
