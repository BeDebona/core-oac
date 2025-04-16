-- ====================================================
-- Sistema OAC - Ordem dos Advogados de Central City
-- Cliente: Interface com o jogador e comunicação com o servidor
-- ====================================================

-- Inicialização e dependências
local QBCore = exports['qb-core']:GetCoreObject()

-- Variáveis locais
local painelAberto = false
local callbacks = {}
local callbackIndex = 0
local notificacoes = {}

-- Configurações
local Config = {
    Debug = false,
    TeclaAtalho = 56, -- F9
    TempoTimeoutCallback = 10000, -- 10 segundos
    MaxNotificacoes = 10
}

-- Sistema de logs
local function LogInfo(mensagem)
    if Config.Debug then
        print("[OAC:INFO] " .. mensagem)
    end
end

local function LogErro(mensagem)
    print("[OAC:ERRO] " .. mensagem)
end

-- Funções auxiliares
local function GerarCallbackId()
    callbackIndex = callbackIndex + 1
    return tostring(GetGameTimer()) .. "_" .. callbackIndex
end

-- Gerenciamento de callbacks
local function RegistrarCallback(eventName, callbackFn)
    local callbackId = GerarCallbackId()
    
    if not callbacks[eventName] then
        callbacks[eventName] = {}
    end
    
    callbacks[eventName][callbackId] = callbackFn
    
    -- Retornar ID para possível remoção posterior
    return callbackId
end

local function RemoverCallback(eventName, callbackId)
    if callbacks[eventName] and callbacks[eventName][callbackId] then
        callbacks[eventName][callbackId] = nil
        return true
    end
    
    return false
end

-- Gerenciamento de notificações
local function AdicionarNotificacao(notificacao)
    table.insert(notificacoes, 1, notificacao)
    
    -- Limitar número de notificações
    if #notificacoes > Config.MaxNotificacoes then
        table.remove(notificacoes, #notificacoes)
    end
    
    -- Enviar para a NUI
    if painelAberto then
        SendNUIMessage({
            action = "updateNotifications",
            notifications = notificacoes
        })
    end
end

-- Funções de interface
local function AbrirPainel()
    if painelAberto then
        return
    end
    
    painelAberto = true
    
    -- Desativar controles do jogo
    DisableControlAction(0, 1, true) -- LookLeftRight
    DisableControlAction(0, 2, true) -- LookUpDown
    DisableControlAction(0, 142, true) -- MeleeAttackAlternate
    DisableControlAction(0, 18, true) -- Enter
    DisableControlAction(0, 322, true) -- ESC
    DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
    
    -- Abrir NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        notifications = notificacoes
    })
    
    LogInfo("Painel OAC aberto")
end

local function FecharPainel()
    if not painelAberto then
        return
    end
    
    painelAberto = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "close"
    })
    
    -- Reativar controles do jogo
    EnableAllControlActions(0)
    
    LogInfo("Painel OAC fechado")
end

-- Eventos do servidor
RegisterNetEvent('oac:openPanel')
AddEventHandler('oac:openPanel', function()
    AbrirPainel()
end)

RegisterNetEvent('oac:closePanel')
AddEventHandler('oac:closePanel', function()
    FecharPainel()
end)

RegisterNetEvent('oac:callback')
AddEventHandler('oac:callback', function(eventName, data)
    if callbacks[eventName] then
        for callbackId, callback in pairs(callbacks[eventName]) do
            callback(data)
            RemoverCallback(eventName, callbackId)
        end
    end
end)

RegisterNetEvent('oac:notification')
AddEventHandler('oac:notification', function(notificacao)
    AdicionarNotificacao({
        id = GerarCallbackId(),
        type = notificacao.type or "info",
        title = notificacao.title or "Notificação",
        message = notificacao.message or "",
        icon = notificacao.icon or "info",
        timestamp = os.date("%H:%M")
    })
    
    -- Reproduzir som de notificação
    PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
end)

-- Callbacks NUI
RegisterNUICallback('exit', function(data, cb)
    FecharPainel()
    TriggerServerEvent('oac:exit')
    cb({success = true})
end)

RegisterNUICallback('registerOab', function(data, cb)
    TriggerServerEvent('oac:registerOab', data)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('registerOab', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['registerOab'] and callbacks['registerOab'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('registerOab', callbackId)
        end
    end)
end)

RegisterNUICallback('getPlayerInfo', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:getPlayerInfo', function(playerInfo)
        cb(playerInfo or {success = false, error = "Erro ao obter informações do jogador"})
    end, data)
end)

RegisterNUICallback('createPassport', function(data, cb)
    TriggerServerEvent('oac:createPassport', data)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('createPassport', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['createPassport'] and callbacks['createPassport'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('createPassport', callbackId)
        end
    end)
end)

RegisterNUICallback('approvePassport', function(data, cb)
    TriggerServerEvent('oac:approvePassport', data)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('approvePassport', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['approvePassport'] and callbacks['approvePassport'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('approvePassport', callbackId)
        end
    end)
end)

RegisterNUICallback('rejectPassport', function(data, cb)
    TriggerServerEvent('oac:rejectPassport', data)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('rejectPassport', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['rejectPassport'] and callbacks['rejectPassport'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('rejectPassport', callbackId)
        end
    end)
end)

RegisterNUICallback('getPassaportes', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:getPassaportes', function(passaportes)
        cb(passaportes or {passaportes = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

RegisterNUICallback('getLeis', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:getLeis', function(leis)
        cb(leis or {})
    end)
end)

RegisterNUICallback('getDocumentos', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:getDocumentos', function(documentos)
        cb(documentos or {documentos = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

RegisterNUICallback('getProcessos', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:getProcessos', function(processos)
        cb(processos or {processos = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

RegisterNUICallback('updateProfile', function(data, cb)
    TriggerServerEvent('oac:updateProfile', data)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('updateProfile', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['updateProfile'] and callbacks['updateProfile'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('updateProfile', callbackId)
        end
    end)
end)

RegisterNUICallback('clearNotifications', function(data, cb)
    notificacoes = {}
    cb({success = true})
end)

RegisterNUICallback('markNotificationAsRead', function(data, cb)
    if data.id then
        for i, notificacao in ipairs(notificacoes) do
            if notificacao.id == data.id then
                notificacoes[i].read = true
                break
            end
        end
    end
    
    cb({success = true})
end)

-- Comando para abrir o painel
RegisterCommand('forum', function()
    TriggerEvent('oac:openPanel')
end, false)

-- Thread principal
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Tecla para abrir o painel (F9)
        if IsControlJustPressed(0, Config.TeclaAtalho) then
            TriggerEvent('oac:openPanel')
        end
        
        -- Desativar controles do jogo quando o painel estiver aberto
        if painelAberto then
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 18, true) -- Enter
            DisableControlAction(0, 322, true) -- ESC
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
        end
    end
end)

-- Inicialização
Citizen.CreateThread(function()
    -- Adicionar notificação de boas-vindas
    AdicionarNotificacao({
        id = GerarCallbackId(),
        type = "info",
        title = "Sistema OAC",
        message = "Bem-vindo ao Sistema da Ordem dos Advogados de Central City",
        icon = "info",
        timestamp = os.date("%H:%M")
    })
    
    LogInfo("Cliente OAC iniciado com sucesso!")
end)
