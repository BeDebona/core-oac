"use client"

import { useRef, useState, useEffect } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Eraser, Save, X } from "lucide-react"

interface SignatureModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (signatureData: string) => void
}

export const SignatureModal = ({ isOpen, onClose, onSave }: SignatureModalProps) => {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [isDrawing, setIsDrawing] = useState(false)

  const setupCanvas = () => {
    const canvas = canvasRef.current
    if (!canvas) return

    // Define tamanho fixo para o canvas
    const width = canvas.clientWidth
    const height = canvas.clientHeight

    canvas.width = width
    canvas.height = height

    const context = canvas.getContext("2d")
    if (context) {
      context.lineWidth = 2
      context.lineCap = "round"
      context.strokeStyle = "#000"
    }
  }

  useEffect(() => {
    if (isOpen) {
      // Espera o dialog abrir completamente antes de configurar o canvas
      requestAnimationFrame(() => {
        setupCanvas()
      })
    }
  }, [isOpen])

  const getCtx = () => {
    return canvasRef.current?.getContext("2d") ?? null
  }

  const startDrawing = (e: React.MouseEvent | React.TouchEvent) => {
    const ctx = getCtx()
    if (!ctx) return

    setIsDrawing(true)
    ctx.beginPath()

    const { offsetX, offsetY } = getCoordinates(e)
    ctx.moveTo(offsetX, offsetY)
  }

  const draw = (e: React.MouseEvent | React.TouchEvent) => {
    if (!isDrawing) return
    const ctx = getCtx()
    if (!ctx) return

    const { offsetX, offsetY } = getCoordinates(e)
    ctx.lineTo(offsetX, offsetY)
    ctx.stroke()
  }

  const stopDrawing = () => {
    const ctx = getCtx()
    if (!ctx) return

    setIsDrawing(false)
    ctx.closePath()
  }

  const getCoordinates = (e: React.MouseEvent | React.TouchEvent) => {
    const canvas = canvasRef.current
    if (!canvas) return { offsetX: 0, offsetY: 0 }

    const rect = canvas.getBoundingClientRect()

    if ("touches" in e) {
      const touch = e.touches[0]
      return {
        offsetX: touch.clientX - rect.left,
        offsetY: touch.clientY - rect.top,
      }
    } else {
      return {
        offsetX: e.clientX - rect.left,
        offsetY: e.clientY - rect.top,
      }
    }
  }

  const clearCanvas = () => {
    const canvas = canvasRef.current
    const ctx = getCtx()
    if (!canvas || !ctx) return

    ctx.clearRect(0, 0, canvas.width, canvas.height)
  }

  const saveSignature = () => {
    const canvas = canvasRef.current
    if (!canvas) return

    const signatureData = canvas.toDataURL("image/png")
    onSave(signatureData)
  }

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Assinatura Digital</DialogTitle>
        </DialogHeader>
        <div className="rounded-lg bg-white p-2">
          <canvas
            ref={canvasRef}
            className="h-40 w-full cursor-crosshair rounded border border-gray-300"
            style={{ display: "block" }}
            onMouseDown={startDrawing}
            onMouseMove={draw}
            onMouseUp={stopDrawing}
            onMouseLeave={stopDrawing}
            onTouchStart={startDrawing}
            onTouchMove={draw}
            onTouchEnd={stopDrawing}
          />
        </div>
        <div className="flex justify-between">
          <Button variant="outline" onClick={clearCanvas}>
            <Eraser className="mr-2 h-4 w-4" />
            Limpar
          </Button>
          <div className="flex gap-2">
            <Button variant="outline" onClick={onClose}>
              <X className="mr-2 h-4 w-4" />
              Cancelar
            </Button>
            <Button onClick={saveSignature}>
              <Save className="mr-2 h-4 w-4" />
              Salvar
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
