import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"

interface UserCardProps {
  userData: {
    name: string
    oab: string
    role: string
    level: string
    avatar: string
  }
}

export const UserCard = ({ userData }: UserCardProps) => {
  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-center">OAC Digital</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col items-center">
          <Avatar className="h-24 w-24">
            <AvatarImage src={userData.avatar || "/placeholder.svg"} alt={userData.name} />
            <AvatarFallback>{userData.name.charAt(0)}</AvatarFallback>
          </Avatar>
          <div className="mt-4 w-full space-y-2">
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">OAB:</span>
              <span className="text-sm font-medium">{userData.oab}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">NOME:</span>
              <span className="text-sm font-medium">{userData.name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">CARGO:</span>
              <span className="text-sm font-medium">{userData.role}</span>
            </div>
            <div className="mt-4 flex justify-between">
              <span className="text-sm text-muted-foreground">STATUS:</span>
              <Badge variant="outline" className="bg-success/10 text-success">
                ONLINE
              </Badge>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-muted-foreground">NÍVEL:</span>
              <span className="text-sm font-medium">{userData.level}</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
