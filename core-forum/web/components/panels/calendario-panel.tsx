"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { CalendarIcon, ChevronLeft, ChevronRight, Clock, Users, MapPin, Plus } from "lucide-react"
import { cn } from "@/lib/utils"
import { NewEventModal } from "@/components/modals/new-event-modal"

type CalendarEvent = {
  id: string
  title: string
  description: string
  date: string
  time: string
  location: string
  participants: string[]
  type: "audiencia" | "reuniao" | "prazo"
}

export const CalendarioPanel = () => {
  const [currentDate, setCurrentDate] = useState(new Date())
  const [selectedDate, setSelectedDate] = useState<Date | null>(null)
  const [showNewEventModal, setShowNewEventModal] = useState(false)
  const [events, setEvents] = useState<CalendarEvent[]>([
    {
      id: "1",
      title: "Audiência - Caso #1234",
      description: "Audiência de instrução e julgamento",
      date: "2023-05-15",
      time: "14:00",
      location: "Sala 3 - Fórum Central",
      participants: ["João Silva", "Dr. Juiz Dredd", "Promotor"],
      type: "audiencia",
    },
    {
      id: "2",
      title: "Reunião com cliente",
      description: "Preparação para audiência",
      date: "2023-05-15",
      time: "10:00",
      location: "Escritório OAC",
      participants: ["Maria Oliveira"],
      type: "reuniao",
    },
    {
      id: "3",
      title: "Prazo final - Recurso",
      description: "Prazo final para apresentação de recurso",
      date: "2023-05-20",
      time: "18:00",
      location: "Online",
      participants: [],
      type: "prazo",
    },
  ])

  const handleAddEvent = (newEvent: Omit<CalendarEvent, "id">) => {
    const event = {
      ...newEvent,
      id: Date.now().toString(),
    }
    setEvents([...events, event])
    setShowNewEventModal(false)
  }

  const getDaysInMonth = (year: number, month: number) => {
    return new Date(year, month + 1, 0).getDate()
  }

  const getFirstDayOfMonth = (year: number, month: number) => {
    return new Date(year, month, 1).getDay()
  }

  const renderCalendar = () => {
    const year = currentDate.getFullYear()
    const month = currentDate.getMonth()
    const daysInMonth = getDaysInMonth(year, month)
    const firstDayOfMonth = getFirstDayOfMonth(year, month)
    const days = []

    // Add empty cells for days before the first day of the month
    for (let i = 0; i < firstDayOfMonth; i++) {
      days.push(<div key={`empty-${i}`} className="h-12"></div>)
    }

    // Add days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day)
      const dateString = date.toISOString().split("T")[0]
      const hasEvents = events.some((event) => event.date === dateString)
      const isSelected =
        selectedDate &&
        date.getDate() === selectedDate.getDate() &&
        date.getMonth() === selectedDate.getMonth() &&
        date.getFullYear() === selectedDate.getFullYear()
      const isToday =
        date.getDate() === new Date().getDate() &&
        date.getMonth() === new Date().getMonth() &&
        date.getFullYear() === new Date().getFullYear()

      days.push(
        <div
          key={day}
          className={cn(
            "flex h-12 cursor-pointer flex-col items-center justify-center rounded-md p-1 transition-colors",
            isSelected ? "bg-primary text-primary-foreground" : isToday ? "border border-primary" : "hover:bg-muted",
          )}
          onClick={() => setSelectedDate(date)}
        >
          <span>{day}</span>
          {hasEvents && <div className="mt-1 h-1 w-1 rounded-full bg-primary"></div>}
        </div>,
      )
    }

    return days
  }

  const getMonthName = (month: number) => {
    const monthNames = [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro",
    ]
    return monthNames[month]
  }

  const prevMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1))
  }

  const nextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1))
  }

  const getEventsForSelectedDate = () => {
    if (!selectedDate) return []

    const dateString = selectedDate.toISOString().split("T")[0]
    return events.filter((event) => event.date === dateString)
  }

  const selectedEvents = getEventsForSelectedDate()

  return (
    <div className="flex h-full flex-col gap-4 overflow-auto">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-semibold tracking-tight">Calendário</h2>
        <Button onClick={() => setShowNewEventModal(true)}>
          <Plus className="mr-2 h-4 w-4" />
          Novo Evento
        </Button>
      </div>

      <div className="grid flex-1 grid-cols-1 gap-4 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <Card className="h-full">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-base sm:text-lg">
                {getMonthName(currentDate.getMonth())} {currentDate.getFullYear()}
              </CardTitle>
              <div className="flex items-center gap-2">
                <Button variant="outline" size="icon" onClick={prevMonth} className="h-7 w-7 sm:h-8 sm:w-8">
                  <ChevronLeft className="h-4 w-4" />
                </Button>
                <Button variant="outline" size="icon" onClick={nextMonth} className="h-7 w-7 sm:h-8 sm:w-8">
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-7 gap-1 text-center text-xs sm:text-sm">
                <div className="font-medium">Dom</div>
                <div className="font-medium">Seg</div>
                <div className="font-medium">Ter</div>
                <div className="font-medium">Qua</div>
                <div className="font-medium">Qui</div>
                <div className="font-medium">Sex</div>
                <div className="font-medium">Sáb</div>
              </div>
              <div className="mt-2 grid grid-cols-7 gap-1">{renderCalendar()}</div>
            </CardContent>
          </Card>
        </div>

        <div>
          <Card className="h-full">
            <CardHeader>
              <CardTitle className="text-base sm:text-lg">
                {selectedDate
                  ? selectedDate.toLocaleDateString("pt-BR", {
                      weekday: "long",
                      day: "numeric",
                      month: "long",
                    })
                  : "Eventos"}
              </CardTitle>
            </CardHeader>
            <CardContent className="h-[calc(100%-5rem)] overflow-auto">
              {selectedDate ? (
                selectedEvents.length > 0 ? (
                  <div className="space-y-4">
                    {selectedEvents.map((event) => (
                      <div key={event.id} className="rounded-lg border p-3">
                        <div className="flex items-start justify-between">
                          <h3 className="font-semibold">{event.title}</h3>
                          <Badge
                            variant={
                              event.type === "audiencia"
                                ? "default"
                                : event.type === "reuniao"
                                  ? "secondary"
                                  : "outline"
                            }
                          >
                            {event.type === "audiencia" ? "Audiência" : event.type === "reuniao" ? "Reunião" : "Prazo"}
                          </Badge>
                        </div>
                        <p className="mt-1 text-sm text-muted-foreground">{event.description}</p>
                        <div className="mt-3 space-y-1 text-sm">
                          <div className="flex items-center gap-2">
                            <Clock className="h-4 w-4 text-muted-foreground" />
                            <span>{event.time}</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <MapPin className="h-4 w-4 text-muted-foreground" />
                            <span>{event.location}</span>
                          </div>
                          {event.participants.length > 0 && (
                            <div className="flex items-center gap-2">
                              <Users className="h-4 w-4 text-muted-foreground" />
                              <span>{event.participants.join(", ")}</span>
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="flex h-full flex-col items-center justify-center">
                    <CalendarIcon className="mb-4 h-12 w-12 text-muted-foreground" />
                    <p className="text-center text-muted-foreground">Nenhum evento para esta data.</p>
                    <Button variant="outline" className="mt-4" onClick={() => setShowNewEventModal(true)}>
                      <Plus className="mr-2 h-4 w-4" />
                      Adicionar Evento
                    </Button>
                  </div>
                )
              ) : (
                <div className="flex h-full flex-col items-center justify-center">
                  <CalendarIcon className="mb-4 h-12 w-12 text-muted-foreground" />
                  <p className="text-center text-muted-foreground">Selecione uma data para ver os eventos.</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      <NewEventModal
        isOpen={showNewEventModal}
        onClose={() => setShowNewEventModal(false)}
        onAddEvent={handleAddEvent}
        selectedDate={selectedDate}
      />
    </div>
  )
}
