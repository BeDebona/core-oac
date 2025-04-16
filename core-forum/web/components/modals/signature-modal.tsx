"use client"

import type React from "react"

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
  const [ctx, setCtx] = useState<CanvasRenderingContext2D | null>(null)

  useEffect(() => {
    if (isOpen && canvasRef.current) {
      const canvas = canvasRef.current
      const context = canvas.getContext("2d")

      if (context) {
        // Set canvas dimensions
        canvas.width = canvas.offsetWidth
        canvas.height = canvas.offsetHeight

        // Set drawing style
        context.lineWidth = 2
        context.lineCap = "round"
        context.strokeStyle = "#000000"

        setCtx(context)
      }
    }
  }, [isOpen])

  const startDrawing = (e: React.MouseEvent | React.TouchEvent) => {
    if (!ctx) return

    setIsDrawing(true)
    ctx.beginPath()

    // Get coordinates
    const { offsetX, offsetY } = getCoordinates(e)
    ctx.moveTo(offsetX, offsetY)
  }

  const draw = (e: React.MouseEvent | React.TouchEvent) => {
    if (!isDrawing || !ctx) return

    // Get coordinates
    const { offsetX, offsetY } = getCoordinates(e)
    ctx.lineTo(offsetX, offsetY)
    ctx.stroke()
  }

  const stopDrawing = () => {
    if (!ctx) return

    setIsDrawing(false)
    ctx.closePath()
  }

  const getCoordinates = (e: React.MouseEvent | React.TouchEvent) => {
    if (!canvasRef.current) {
      return { offsetX: 0, offsetY: 0 }
    }

    const canvas = canvasRef.current
    const rect = canvas.getBoundingClientRect()

    if ("touches" in e) {
      // Touch event
      const touch = e.touches[0]
      return {
        offsetX: touch.clientX - rect.left,
        offsetY: touch.clientY - rect.top,
      }
    } else {
      // Mouse event
      return {
        offsetX: e.clientX - rect.left,
        offsetY: e.clientY - rect.top,
      }
    }
  }

  const clearCanvas = () => {
    if (!ctx || !canvasRef.current) return

    ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height)
  }

  const saveSignature = () => {
    if (!canvasRef.current) return

    const signatureData = canvasRef.current.toDataURL("image/png")
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
