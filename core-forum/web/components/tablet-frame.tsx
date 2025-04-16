import type { ReactNode } from "react"

interface TabletFrameProps {
  children: ReactNode
}

export function TabletFrame({ children }: TabletFrameProps) {
  return (
    <div className="relative mx-auto w-full max-w-[1200px] h-[90vh] max-h-[900px]">
      {/* Tablet Frame */}
      <div className="relative h-full w-full rounded-[40px] bg-black p-8 sm:p-2 ">
        {/* Tablet Bezel */}
        <div className="relative h-full w-full rounded-[30px] border-4 sm:border-8 border-gray-800 bg-black shadow-inner">
          {/* Screen Content */}
          <div className="h-full w-full overflow-hidden rounded-[22px]">{children}</div>
        </div>
      </div>
    </div>
  )
}
