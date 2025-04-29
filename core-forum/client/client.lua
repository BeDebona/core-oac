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
    QBCore.Functions.TriggerCallback('oac:getDocumentos', function(resultado)
        cb(resultado or {documentos = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

RegisterNUICallback('getDocumento', function(data, cb)
    if not data or not data.id then
        cb({success = false, error = "ID do documento não fornecido"})
        return
    end
    
    QBCore.Functions.TriggerCallback('oac:getDocumento', function(resultado)
        cb(resultado or {success = false, error = "Erro ao obter documento"})
    end, data.id)
end)

RegisterNUICallback('createDocumento', function(data, cb)
    if not data then
        cb({success = false, error = "Dados inválidos"})
        return
    end
    
    TriggerServerEvent('oac:createDocumento', data)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('createDocumento', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['createDocumento'] and callbacks['createDocumento'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('createDocumento', callbackId)
        end
    end)
end)

RegisterNUICallback('updateDocumento', function(data, cb)
    if not data or not data.id then
        cb({success = false, error = "ID do documento não fornecido"})
        return
    end
    
    TriggerServerEvent('oac:updateDocumento', data.id, data.documento)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('updateDocumento', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['updateDocumento'] and callbacks['updateDocumento'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('updateDocumento', callbackId)
        end
    end)
end)

RegisterNUICallback('deleteDocumento', function(data, cb)
    if not data or not data.id then
        cb({success = false, error = "ID do documento não fornecido"})
        return
    end
    
    TriggerServerEvent('oac:deleteDocumento', data.id)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('deleteDocumento', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['deleteDocumento'] and callbacks['deleteDocumento'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('deleteDocumento', callbackId)
        end
    end)
end)

RegisterNUICallback('signDocumento', function(data, cb)
    if not data or not data.id or not data.assinatura then
        cb({success = false, error = "Dados de assinatura inválidos"})
        return
    end
    
    TriggerServerEvent('oac:signDocumento', data.id, data.assinatura)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('signDocumento', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['signDocumento'] and callbacks['signDocumento'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('signDocumento', callbackId)
        end
    end)
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

RegisterCommand("documentos", function()
    TriggerEvent('oac:openPanel')
    -- Enviar mensagem para NUI abrir diretamente a aba de documentos
    if painelAberto then
        SendNUIMessage({
            action = "openTab",
            tab = "documentos"
        })
    end
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

-- ====================================================
-- Funções para gerenciamento de documentos (Cliente)
-- ====================================================

-- Função para pegar a lista de documentos com filtros
function GetDocumentos(pagina, porPagina, filtros, callback)
    QBCore.Functions.TriggerCallback('oac:getDocumentos', function(resultado)
        callback(resultado)
    end, {
        pagina = pagina or 1,
        porPagina = porPagina or 10,
        filtros = filtros or {}
    })
end

-- Função para pegar um documento específico
function GetDocumento(id, callback)
    QBCore.Functions.TriggerCallback('oac:getDocumento', function(resultado)
        callback(resultado)
    end, id)
end

-- Função para criar documento
function CriarDocumento(dados, callback)
    local callbackId = RegistrarCallback('createDocumento', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:createDocumento', dados)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['createDocumento'] and callbacks['createDocumento'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('createDocumento', callbackId)
        end
    end)
end

-- Função para atualizar documento
function AtualizarDocumento(id, dados, callback)
    local callbackId = RegistrarCallback('updateDocumento', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:updateDocumento', id, dados)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['updateDocumento'] and callbacks['updateDocumento'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('updateDocumento', callbackId)
        end
    end)
end

-- Função para excluir documento
function ExcluirDocumento(id, callback)
    local callbackId = RegistrarCallback('deleteDocumento', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:deleteDocumento', id)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['deleteDocumento'] and callbacks['deleteDocumento'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('deleteDocumento', callbackId)
        end
    end)
end

-- Função para assinar documento
function AssinarDocumento(id, assinatura, callback)
    local callbackId = RegistrarCallback('signDocumento', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:signDocumento', id, assinatura)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['signDocumento'] and callbacks['signDocumento'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('signDocumento', callbackId)
        end
    end)
end

-- Exportar funções para outros scripts
exports('GetDocumentos', GetDocumentos)
exports('GetDocumento', GetDocumento)
exports('CriarDocumento', CriarDocumento)
exports('AtualizarDocumento', AtualizarDocumento)
exports('ExcluirDocumento', ExcluirDocumento)
exports('AssinarDocumento', AssinarDocumento)

-- ====================================================
-- Sistema de Consultas - Integração com o servidor
-- ====================================================

-- Callbacks NUI para consultas
RegisterNUICallback('consultarDocumentos', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:consultarDocumentos', function(resultado)
        cb(resultado or {success = false, documentos = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

RegisterNUICallback('consultarDocumento', function(data, cb)
    if not data or not data.id then
        cb({success = false, error = "ID do documento não fornecido"})
        return
    end
    
    QBCore.Functions.TriggerCallback('oac:consultarDocumento', function(resultado)
        cb(resultado or {success = false, error = "Erro ao obter documento"})
    end, data.id)
end)

RegisterNUICallback('consultaAvancada', function(data, cb)
    if not data or not data.query or data.query == "" then
        cb({success = false, error = "Consulta inválida"})
        return
    end
    
    QBCore.Functions.TriggerCallback('oac:consultaAvancada', function(resultado)
        cb(resultado or {success = false, documentos = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

RegisterNUICallback('consultarDocumentosPorIdentidade', function(data, cb)
    if not data or not data.identidade then
        cb({success = false, error = "Identidade não fornecida"})
        return
    end
    
    QBCore.Functions.TriggerCallback('oac:consultarDocumentosPorIdentidade', function(resultado)
        cb(resultado or {success = false, documentos = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

RegisterNUICallback('consultarEstatisticasDocumentos', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:consultarEstatisticasDocumentos', function(resultado)
        cb(resultado or {success = false, estatisticas = {}})
    end)
end)

-- Comando específico para consultas
RegisterCommand("pesquisardoc", function(source, args)
    -- Verificar se foi fornecido pelo menos um argumento
    if not args[1] then
        TriggerEvent('QBCore:Notify', 'Uso: /pesquisardoc [termo1] [termo2] ...', 'error')
        return
    end
    
    -- Construir consulta a partir dos argumentos
    local query = table.concat(args, " ")
    
    -- Abrir painel se não estiver aberto
    if not painelAberto then
        TriggerEvent('oac:openPanel')
        
        -- Dar um pequeno delay para garantir que o painel está aberto antes de enviar a pesquisa
        Citizen.SetTimeout(500, function()
            if painelAberto then
                -- Enviar consulta para a NUI
                SendNUIMessage({
                    action = "executarConsulta",
                    query = query
                })
            end
        end)
    else
        -- Enviar consulta para a NUI diretamente
        SendNUIMessage({
            action = "executarConsulta",
            query = query
        })
    end
end)

-- ====================================================
-- Funções exportadas para consultas
-- ====================================================

-- Função para realizar consulta direta no banco de dados
function ConsultarDocumentos(filtros, pagina, porPagina, callback)
    QBCore.Functions.TriggerCallback('oac:consultarDocumentos', function(resultado)
        callback(resultado)
    end, {
        filtros = filtros or {},
        pagina = pagina or 1,
        porPagina = porPagina or 10
    })
end

-- Função para consultar documento específico
function ConsultarDocumento(id, callback)
    QBCore.Functions.TriggerCallback('oac:consultarDocumento', function(resultado)
        callback(resultado)
    end, id)
end

-- Função para realizar consulta avançada
function ConsultaAvancada(query, pagina, porPagina, callback)
    QBCore.Functions.TriggerCallback('oac:consultaAvancada', function(resultado)
        callback(resultado)
    end, {
        query = query,
        pagina = pagina or 1,
        porPagina = porPagina or 10
    })
end

-- Função para consultar documentos por identidade
function ConsultarDocumentosPorIdentidade(identidade, pagina, porPagina, callback)
    QBCore.Functions.TriggerCallback('oac:consultarDocumentosPorIdentidade', function(resultado)
        callback(resultado)
    end, {
        identidade = identidade,
        pagina = pagina or 1,
        porPagina = porPagina or 10
    })
end

-- Função para consultar estatísticas de documentos
function ConsultarEstatisticasDocumentos(callback)
    QBCore.Functions.TriggerCallback('oac:consultarEstatisticasDocumentos', function(resultado)
        callback(resultado)
    end)
end

-- Exportar funções para outros scripts
exports('ConsultarDocumentos', ConsultarDocumentos)
exports('ConsultarDocumento', ConsultarDocumento)
exports('ConsultaAvancada', ConsultaAvancada)
exports('ConsultarDocumentosPorIdentidade', ConsultarDocumentosPorIdentidade)
exports('ConsultarEstatisticasDocumentos', ConsultarEstatisticasDocumentos)

-- ====================================================
-- Sistema de Passaportes e Registro - Integração com o servidor
-- ====================================================

-- Callbacks NUI para passaportes
RegisterNUICallback('consultarPassaportes', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:consultarPassaportes', function(resultado)
        cb(resultado or {success = false, passaportes = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

-- Callback específico para passaportes pendentes (alta ordem)
RegisterNUICallback('consultarPassaportesPendentes', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:consultarPassaportesPendentes', function(resultado)
        cb(resultado or {success = false, passaportes = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

-- Callback para estatísticas de passaportes
RegisterNUICallback('consultarEstatisticasPassaportes', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:consultarEstatisticasPassaportes', function(resultado)
        cb(resultado or {success = false, estatisticas = {}})
    end)
end)

-- Função para verificar passaportes pendentes para alta ordem
local function VerificarPassaportesPendentes()
    -- Verificar se o jogador tem permissão de alta ordem
    QBCore.Functions.TriggerCallback('oac:consultarPassaportesPendentes', function(resultado)
        if resultado.success and resultado.total > 0 then
            -- Adicionar notificação se houver passaportes pendentes
            AdicionarNotificacao({
                id = GerarCallbackId(),
                type = "info",
                title = "Passaportes Pendentes",
                message = "Há " .. resultado.total .. " solicitação(ões) de passaporte aguardando aprovação",
                icon = "passport",
                timestamp = os.date("%H:%M")
            })
            
            -- Reproduzir som de notificação
            PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
        end
    end, {pagina = 1, porPagina = 1}) -- Apenas para contar
end

-- Comando para listar passaportes pendentes
RegisterCommand("passaportes_pendentes", function()
    QBCore.Functions.TriggerCallback('oac:consultarPassaportesPendentes', function(resultado)
        if resultado.success then
            if resultado.total > 0 then
                TriggerEvent('QBCore:Notify', 'Há ' .. resultado.total .. ' passaportes pendentes', 'info')
                
                -- Abrir painel se não estiver aberto
                if not painelAberto then
                    TriggerEvent('oac:openPanel')
                    
                    -- Enviar mensagem para NUI abrir a aba de passaportes
                    Citizen.SetTimeout(500, function()
                        if painelAberto then
                            SendNUIMessage({
                                action = "openTab",
                                tab = "passaportes_pendentes"
                            })
                        end
                    end)
                else
                    -- Se já estiver aberto, apenas mudar para a aba
                    SendNUIMessage({
                        action = "openTab",
                        tab = "passaportes_pendentes"
                    })
                end
            else
                TriggerEvent('QBCore:Notify', 'Não há passaportes pendentes', 'info')
            end
        else
            TriggerEvent('QBCore:Notify', resultado.error or 'Erro ao consultar passaportes pendentes', 'error')
        end
    end, {pagina = 1, porPagina = 1})
end)

-- ====================================================
-- Funções exportadas para passaportes
-- ====================================================

-- Função para consultar passaportes
function ConsultarPassaportes(filtros, pagina, porPagina, callback)
    QBCore.Functions.TriggerCallback('oac:consultarPassaportes', function(resultado)
        callback(resultado)
    end, {
        filtros = filtros or {},
        pagina = pagina or 1,
        porPagina = porPagina or 10
    })
end

-- Função para consultar passaportes pendentes (alta ordem)
function ConsultarPassaportesPendentes(pagina, porPagina, callback)
    QBCore.Functions.TriggerCallback('oac:consultarPassaportesPendentes', function(resultado)
        callback(resultado)
    end, {
        pagina = pagina or 1,
        porPagina = porPagina or 10
    })
end

-- Função para criar solicitação de passaporte
function CriarSolicitacaoPassaporte(dados, callback)
    local callbackId = RegistrarCallback('createPassport', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:createPassport', dados)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['createPassport'] and callbacks['createPassport'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('createPassport', callbackId)
        end
    end)
end

-- Função para aprovar passaporte (alta ordem)
function AprovarPassaporte(id, callback)
    local callbackId = RegistrarCallback('approvePassport', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:approvePassport', {id = id})
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['approvePassport'] and callbacks['approvePassport'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('approvePassport', callbackId)
        end
    end)
end

-- Função para rejeitar passaporte (alta ordem)
function RejeitarPassaporte(id, motivo, callback)
    local callbackId = RegistrarCallback('rejectPassport', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:rejectPassport', {id = id, motivo = motivo})
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['rejectPassport'] and callbacks['rejectPassport'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('rejectPassport', callbackId)
        end
    end)
end

-- Função para consultar estatísticas de passaportes
function ConsultarEstatisticasPassaportes(callback)
    QBCore.Functions.TriggerCallback('oac:consultarEstatisticasPassaportes', function(resultado)
        callback(resultado)
    end)
end

-- Exportar funções para outros scripts
exports('ConsultarPassaportes', ConsultarPassaportes)
exports('ConsultarPassaportesPendentes', ConsultarPassaportesPendentes)
exports('CriarSolicitacaoPassaporte', CriarSolicitacaoPassaporte)
exports('AprovarPassaporte', AprovarPassaporte)
exports('RejeitarPassaporte', RejeitarPassaporte)
exports('ConsultarEstatisticasPassaportes', ConsultarEstatisticasPassaportes)

-- ====================================================
-- Inicialização e verificações periódicas
-- ====================================================

-- Verificar periodicamente passaportes pendentes para alta ordem
Citizen.CreateThread(function()
    -- Aguardar um pouco para o jogador conectar completamente
    Citizen.Wait(10000)
    
    -- Verificar permissão e verificar passaportes pendentes
    QBCore.Functions.GetPlayerData(function(PlayerData)
        local jobName = PlayerData.job.name
        local jobGrade = PlayerData.job.grade.level
        
        -- Verificar se é juiz, admin ou tem nível alto em advogado
        if jobName == "judge" or 
           jobName == "prosecutor" or 
           (jobName == "lawyer" and jobGrade >= 3) or
           PlayerData.permission == "admin" or 
           PlayerData.permission == "god" then
            
            -- Verificar passaportes pendentes na inicialização
            VerificarPassaportesPendentes()
            
            -- Verificar passaportes pendentes periodicamente
            Citizen.CreateThread(function()
                while true do
                    Citizen.Wait(10 * 60 * 1000) -- Verificar a cada 10 minutos
                    VerificarPassaportesPendentes()
                end
            end)
        end
    end)
end)

-- ====================================================
-- Sistema de Alta Ordem e Calendário - Integração com o servidor
-- ====================================================

-- Callbacks NUI para Calendário
RegisterNUICallback('consultarEventosCalendario', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:consultarEventosCalendario', function(resultado)
        cb(resultado or {success = false, eventos = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

RegisterNUICallback('consultarEventosProximos', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:consultarEventosProximos', function(resultado)
        cb(resultado or {success = false, eventos = {}, total = 0})
    end)
end)

RegisterNUICallback('createCalendarEvent', function(data, cb)
    TriggerServerEvent('oac:createCalendarEvent', data)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('createCalendarEvent', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['createCalendarEvent'] and callbacks['createCalendarEvent'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('createCalendarEvent', callbackId)
        end
    end)
end)

RegisterNUICallback('updateCalendarEvent', function(data, cb)
    TriggerServerEvent('oac:updateCalendarEvent', data)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('updateCalendarEvent', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['updateCalendarEvent'] and callbacks['updateCalendarEvent'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('updateCalendarEvent', callbackId)
        end
    end)
end)

-- Callbacks NUI para Alta Ordem
RegisterNUICallback('consultarDecisoesAltaOrdem', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:consultarDecisoesAltaOrdem', function(resultado)
        cb(resultado or {success = false, decisoes = {}, total = 0, pagina = 1, totalPaginas = 0})
    end, data)
end)

RegisterNUICallback('consultarDecisoesRecentes', function(data, cb)
    QBCore.Functions.TriggerCallback('oac:consultarDecisoesRecentes', function(resultado)
        cb(resultado or {success = false, decisoes = {}, total = 0})
    end)
end)

RegisterNUICallback('createAltaOrdemDecisao', function(data, cb)
    TriggerServerEvent('oac:createAltaOrdemDecisao', data)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('createAltaOrdemDecisao', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['createAltaOrdemDecisao'] and callbacks['createAltaOrdemDecisao'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('createAltaOrdemDecisao', callbackId)
        end
    end)
end)

RegisterNUICallback('updateAltaOrdemDecisao', function(data, cb)
    TriggerServerEvent('oac:updateAltaOrdemDecisao', data)
    
    -- Registrar callback temporário para receber resposta
    local callbackId = RegistrarCallback('updateAltaOrdemDecisao', function(response)
        cb(response)
    end)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['updateAltaOrdemDecisao'] and callbacks['updateAltaOrdemDecisao'][callbackId] then
            cb({success = false, error = "Timeout"})
            RemoverCallback('updateAltaOrdemDecisao', callbackId)
        end
    end)
end)

-- Comandos para Alta Ordem e Calendário
RegisterCommand("calendario", function()
    TriggerEvent('oac:openPanel')
    -- Enviar mensagem para NUI abrir diretamente a aba de calendário
    if painelAberto then
        SendNUIMessage({
            action = "openTab",
            tab = "calendario"
        })
    end
end)

RegisterCommand("alta_ordem", function()
    TriggerEvent('oac:openPanel')
    -- Enviar mensagem para NUI abrir diretamente a aba de alta ordem
    if painelAberto then
        SendNUIMessage({
            action = "openTab",
            tab = "alta_ordem"
        })
    end
end)

-- ====================================================
-- Funções exportadas para Calendário e Alta Ordem
-- ====================================================

-- Função para consultar eventos do calendário
function ConsultarEventosCalendario(filtros, pagina, porPagina, callback)
    QBCore.Functions.TriggerCallback('oac:consultarEventosCalendario', function(resultado)
        callback(resultado)
    end, {
        filtros = filtros or {},
        pagina = pagina or 1,
        porPagina = porPagina or 10
    })
end

-- Função para consultar próximos eventos
function ConsultarEventosProximos(callback)
    QBCore.Functions.TriggerCallback('oac:consultarEventosProximos', function(resultado)
        callback(resultado)
    end)
end

-- Função para criar evento no calendário
function CriarEventoCalendario(dados, callback)
    local callbackId = RegistrarCallback('createCalendarEvent', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:createCalendarEvent', dados)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['createCalendarEvent'] and callbacks['createCalendarEvent'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('createCalendarEvent', callbackId)
        end
    end)
end

-- Função para atualizar evento no calendário
function AtualizarEventoCalendario(id, dados, callback)
    dados.id = id
    
    local callbackId = RegistrarCallback('updateCalendarEvent', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:updateCalendarEvent', dados)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['updateCalendarEvent'] and callbacks['updateCalendarEvent'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('updateCalendarEvent', callbackId)
        end
    end)
end

-- Função para consultar decisões da alta ordem
function ConsultarDecisoesAltaOrdem(filtros, pagina, porPagina, callback)
    QBCore.Functions.TriggerCallback('oac:consultarDecisoesAltaOrdem', function(resultado)
        callback(resultado)
    end, {
        filtros = filtros or {},
        pagina = pagina or 1,
        porPagina = porPagina or 10
    })
end

-- Função para consultar decisões recentes da alta ordem
function ConsultarDecisoesRecentes(callback)
    QBCore.Functions.TriggerCallback('oac:consultarDecisoesRecentes', function(resultado)
        callback(resultado)
    end)
end

-- Função para criar decisão da alta ordem
function CriarDecisaoAltaOrdem(dados, callback)
    local callbackId = RegistrarCallback('createAltaOrdemDecisao', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:createAltaOrdemDecisao', dados)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['createAltaOrdemDecisao'] and callbacks['createAltaOrdemDecisao'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('createAltaOrdemDecisao', callbackId)
        end
    end)
end

-- Função para atualizar decisão da alta ordem
function AtualizarDecisaoAltaOrdem(id, dados, callback)
    dados.id = id
    
    local callbackId = RegistrarCallback('updateAltaOrdemDecisao', function(response)
        callback(response)
    end)
    
    TriggerServerEvent('oac:updateAltaOrdemDecisao', dados)
    
    -- Timeout para evitar que o callback fique pendurado
    SetTimeout(Config.TempoTimeoutCallback, function()
        if callbacks['updateAltaOrdemDecisao'] and callbacks['updateAltaOrdemDecisao'][callbackId] then
            callback({success = false, error = "Timeout"})
            RemoverCallback('updateAltaOrdemDecisao', callbackId)
        end
    end)
end

-- Exportar funções para outros scripts
exports('ConsultarEventosCalendario', ConsultarEventosCalendario)
exports('ConsultarEventosProximos', ConsultarEventosProximos)
exports('CriarEventoCalendario', CriarEventoCalendario)
exports('AtualizarEventoCalendario', AtualizarEventoCalendario)
exports('ConsultarDecisoesAltaOrdem', ConsultarDecisoesAltaOrdem)
exports('ConsultarDecisoesRecentes', ConsultarDecisoesRecentes)
exports('CriarDecisaoAltaOrdem', CriarDecisaoAltaOrdem)
exports('AtualizarDecisaoAltaOrdem', AtualizarDecisaoAltaOrdem)

-- ====================================================
-- Verificação de eventos do calendário
-- ====================================================

-- Função para verificar eventos próximos
local function VerificarEventosProximos()
    QBCore.Functions.TriggerCallback('oac:consultarEventosProximos', function(resultado)
        if resultado.success and #resultado.eventos > 0 then
            -- Verificar se há eventos nas próximas 24 horas
            local temEventoProximo = false
            local eventoProximo = nil
            
            local tempoAtual = os.time()
            for _, evento in ipairs(resultado.eventos) do
                local tempoEvento = os.time({
                    year = tonumber(string.sub(evento.dataInicio, 1, 4)),
                    month = tonumber(string.sub(evento.dataInicio, 6, 7)),
                    day = tonumber(string.sub(evento.dataInicio, 9, 10)),
                    hour = tonumber(string.sub(evento.dataInicio, 12, 13)),
                    min = tonumber(string.sub(evento.dataInicio, 15, 16))
                })
                
                local diferencaTempo = tempoEvento - tempoAtual
                
                -- Se o evento ocorrer nas próximas 24 horas
                if diferencaTempo > 0 and diferencaTempo < (24 * 60 * 60) then
                    temEventoProximo = true
                    eventoProximo = evento
                    break
                end
            end
            
            -- Notificar sobre evento próximo
            if temEventoProximo and eventoProximo then
                -- Formatar hora do evento
                local horaEvento = string.sub(eventoProximo.dataInicio, 12, 16)
                
                AdicionarNotificacao({
                    id = GerarCallbackId(),
                    type = "warning",
                    title = "Evento em breve",
                    message = eventoProximo.titulo .. " às " .. horaEvento,
                    icon = "calendar",
                    timestamp = os.date("%H:%M")
                })
                
                -- Reproduzir som de notificação
                PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
            end
        end
    end)
end

-- Verificar eventos próximos periodicamente
Citizen.CreateThread(function()
    -- Aguardar um pouco para o jogador conectar completamente
    Citizen.Wait(15000)
    
    -- Verificar permissão
    QBCore.Functions.GetPlayerData(function(PlayerData)
        local jobName = PlayerData.job.name
        local jobGrade = PlayerData.job.grade.level
        
        -- Verificar se tem permissão para o fórum (qualquer cargo jurídico)
        if jobName == "judge" or 
           jobName == "prosecutor" or 
           jobName == "lawyer" or
           PlayerData.permission == "admin" or 
           PlayerData.permission == "god" then
            
            -- Verificar eventos próximos na inicialização
            VerificarEventosProximos()
            
            -- Verificar eventos próximos a cada 30 minutos
            Citizen.CreateThread(function()
                while true do
                    Citizen.Wait(30 * 60 * 1000)
                    VerificarEventosProximos()
                end
            end)
        end
    end)
end)

-- Receptor de sincronização do servidor
RegisterNetEvent('oac:syncData')
AddEventHandler('oac:syncData', function(data)
    -- Armazenar dados recebidos
    local eventosRecentes = data.eventos
    local decisoesRecentes = data.decisoes
    local timestamp = data.timestamp
    
    -- Atualizar interface se estiver aberta
    if painelAberto then
        SendNUIMessage({
            action = "updateSyncData",
            eventos = eventosRecentes,
            decisoes = decisoesRecentes,
            timestamp = timestamp
        })
    end
    
    -- Verificar e notificar sobre eventos muito próximos (1 hora ou menos)
    local tempoAtual = os.time()
    for _, evento in ipairs(eventosRecentes) do
        local tempoEvento = os.time({
            year = tonumber(string.sub(evento.dataInicio, 1, 4)),
            month = tonumber(string.sub(evento.dataInicio, 6, 7)),
            day = tonumber(string.sub(evento.dataInicio, 9, 10)),
            hour = tonumber(string.sub(evento.dataInicio, 12, 13)),
            min = tonumber(string.sub(evento.dataInicio, 15, 16))
        })
        
        local diferencaTempo = tempoEvento - tempoAtual
        
        -- Se o evento ocorrer na próxima hora
        if diferencaTempo > 0 and diferencaTempo <= 3600 then
            AdicionarNotificacao({
                id = GerarCallbackId(),
                type = "warning",
                title = "Evento em breve",
                message = evento.titulo .. " às " .. string.sub(evento.dataInicio, 12, 16),
                icon = "calendar-alert",
                timestamp = os.date("%H:%M")
            })
        end
    end
    
    -- Adicionar notificação se houver novas decisões da alta ordem
    if #decisoesRecentes > 0 then
        local ultimaDecisao = decisoesRecentes[1]
        -- Verificar se é uma decisão recente (nas últimas 24 horas)
        local tempoDecisao = os.time({
            year = tonumber(string.sub(ultimaDecisao.dataEfetiva or "2023-01-01", 1, 4)),
            month = tonumber(string.sub(ultimaDecisao.dataEfetiva or "2023-01-01", 6, 7)),
            day = tonumber(string.sub(ultimaDecisao.dataEfetiva or "2023-01-01", 9, 10))
        })
        
        if (tempoAtual - tempoDecisao) < (24 * 60 * 60) then
            AdicionarNotificacao({
                id = GerarCallbackId(),
                type = "info",
                title = "Nova Decisão da Alta Ordem",
                message = ultimaDecisao.titulo,
                icon = "gavel",
                timestamp = os.date("%H:%M")
            })
        end
    end
    
    LogInfo("Dados sincronizados com o servidor: " .. #eventosRecentes .. " eventos, " .. #decisoesRecentes .. " decisões")
end)
