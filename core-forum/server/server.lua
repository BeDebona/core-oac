-- ====================================================
-- Sistema OAC - Ordem dos Advogados de Central City
-- Servidor: Gerenciamento de dados e lógica de negócios
-- ====================================================

-- Inicialização e dependências
local QBCore = exports['qb-core']:GetCoreObject()
local MySQL = exports['oxmysql']:GetModule("MySQL")

-- Variáveis globais
local Cache = {
    Passaportes = {},
    Documentos = {},
    Leis = {},
    Usuarios = {},
    Processos = {}
}

-- Configurações
local Config = {
    Debug = false,
    MaxPassaportesPorPagina = 20,
    MaxDocumentosPorPagina = 20,
    MaxProcessosPorPagina = 20,
    TempoExpiracaoPassaporte = 30, -- dias
    NiveisPermissao = {
        Estagiario = 0,
        Advogado = 1,
        Promotor = 2,
        Juiz = 3,
        Diretor = 4
    }
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

local function LogAcao(source, acao, dados)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    local identifier = Player.PlayerData.citizenid
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    -- Converter tabela para string JSON
    local dadosJson = "null"
    if dados then
        dadosJson = json.encode(dados)
    end
    
    -- Salvar log no banco de dados
    MySQL.Async.execute('INSERT INTO oac_logs (identifier, nome, acao, dados, timestamp) VALUES (?, ?, ?, ?, ?)',
        {identifier, playerName, acao, dadosJson, timestamp})
    
    LogInfo(string.format("Ação: %s | Usuário: %s | ID: %s", acao, playerName, identifier))
end

-- Funções auxiliares
local function GerarId()
    return os.time() .. math.random(1000, 9999)
end

local function FormatarData(data)
    if not data then return nil end
    
    -- Se for timestamp, converter para string
    if type(data) == "number" then
        return os.date("%Y-%m-%d", data)
    end
    
    -- Se já for string no formato correto, retornar
    if string.match(data, "%d%d%d%d%-%d%d%-%d%d") then
        return data
    end
    
    -- Tentar converter de outros formatos (DD/MM/AAAA)
    local dia, mes, ano = string.match(data, "(%d+)/(%d+)/(%d+)")
    if dia and mes and ano then
        return string.format("%04d-%02d-%02d", ano, mes, dia)
    end
    
    return nil
end

local function ValidarCPF(cpf)
    -- Remover caracteres não numéricos
    cpf = string.gsub(cpf, "[^0-9]", "")
    
    -- Verificar tamanho
    if string.len(cpf) ~= 11 then
        return false
    end
    
    -- Verificar se todos os dígitos são iguais
    local igual = true
    for i = 2, 11 do
        if string.sub(cpf, i, i) ~= string.sub(cpf, 1, 1) then
            igual = false
            break
        end
    end
    if igual then
        return false
    end
    
    -- Validação dos dígitos verificadores
    local soma = 0
    for i = 1, 9 do
        soma = soma + tonumber(string.sub(cpf, i, i)) * (11 - i)
    end
    local resto = soma % 11
    local dv1 = resto < 2 and 0 or 11 - resto
    
    if tonumber(string.sub(cpf, 10, 10)) ~= dv1 then
        return false
    end
    
    soma = 0
    for i = 1, 10 do
        soma = soma + tonumber(string.sub(cpf, i, i)) * (12 - i)
    end
    resto = soma % 11
    local dv2 = resto < 2 and 0 or 11 - resto
    
    if tonumber(string.sub(cpf, 11, 11)) ~= dv2 then
        return false
    end
    
    return true
end

-- Verificação de permissões
local function ObterNivelPermissao(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return -1 end
    
    -- Verificar se é administrador do servidor
    if Player.Functions.GetPermission() == "admin" or Player.Functions.GetPermission() == "god" then
        return Config.NiveisPermissao.Diretor
    end
    
    -- Verificar cargo
    local jobName = Player.PlayerData.job.name
    local jobGrade = Player.PlayerData.job.grade.level
    
    if jobName == "judge" then
        return Config.NiveisPermissao.Juiz
    elseif jobName == "prosecutor" then
        return Config.NiveisPermissao.Promotor
    elseif jobName == "lawyer" then
        -- Verificar nível dentro da profissão
        if jobGrade >= 3 then
            return Config.NiveisPermissao.Diretor
        elseif jobGrade >= 2 then
            return Config.NiveisPermissao.Advogado
        else
            return Config.NiveisPermissao.Estagiario
        end
    end
    
    -- Verificar permissões específicas
    if Player.Functions.HasPermission("oac.diretor") then
        return Config.NiveisPermissao.Diretor
    elseif Player.Functions.HasPermission("oac.juiz") then
        return Config.NiveisPermissao.Juiz
    elseif Player.Functions.HasPermission("oac.promotor") then
        return Config.NiveisPermissao.Promotor
    elseif Player.Functions.HasPermission("oac.advogado") then
        return Config.NiveisPermissao.Advogado
    elseif Player.Functions.HasPermission("oac.estagiario") then
        return Config.NiveisPermissao.Estagiario
    end
    
    return -1
end

local function TemPermissao(source, nivelMinimo)
    local nivelPermissao = ObterNivelPermissao(source)
    return nivelPermissao >= nivelMinimo
end

local function VerificarPermissaoForum(source)
    return TemPermissao(source, Config.NiveisPermissao.Estagiario)
end

local function VerificarPermissaoAltaOrdem(source)
    return TemPermissao(source, Config.NiveisPermissao.Juiz)
end

-- Funções de carregamento de dados
local function CarregarLeis()
    LogInfo("Carregando leis do banco de dados...")
    
    local result = MySQL.Sync.fetchAll("SELECT * FROM oac_leis ORDER BY categoria, id")
    
    if result and #result > 0 then
        Cache.Leis = {}
        
        for _, v in ipairs(result) do
            table.insert(Cache.Leis, {
                id = v.id,
                categoria = v.categoria,
                titulo = v.titulo,
                conteudo = v.conteudo
            })
        end
        
        LogInfo("Carregadas " .. #Cache.Leis .. " leis.")
    else
        -- Inserir leis padrão se não existirem
        if #Cache.Leis == 0 then
            Cache.Leis = {
                {id = 1, categoria = "Código Penal", titulo = "Artigo 1 - Furto", conteudo = "Pena: 30 meses de prisão e multa de $5,000"},
                {id = 2, categoria = "Código Penal", titulo = "Artigo 2 - Roubo", conteudo = "Pena: 45 meses de prisão e multa de $10,000"},
                {id = 3, categoria = "Código Penal", titulo = "Artigo 3 - Assalto a Mão Armada", conteudo = "Pena: 100 meses de prisão e multa de $15,000"}
            }
            
            -- Salvar no banco de dados
            for _, lei in ipairs(Cache.Leis) do
                MySQL.Async.execute('INSERT INTO oac_leis (id, categoria, titulo, conteudo) VALUES (?, ?, ?, ?)',
                    {lei.id, lei.categoria, lei.titulo, lei.conteudo})
            end
            
            LogInfo("Inseridas " .. #Cache.Leis .. " leis padrão.")
        end
    end
end

local function CarregarPassaportes()
    LogInfo("Carregando passaportes do banco de dados...")
    
    local result = MySQL.Sync.fetchAll("SELECT * FROM oac_passaportes ORDER BY created_at DESC")
    
    Cache.Passaportes = {}
    
    if result and #result > 0 then
        for _, v in ipairs(result) do
            table.insert(Cache.Passaportes, {
                id = v.id,
                nome = v.nome,
                identidade = v.identidade,
                dataNascimento = v.data_nascimento,
                foto = v.foto,
                status = v.status,
                createdAt = v.created_at,
                updatedAt = v.updated_at,
                aprovadoPor = v.aprovado_por,
                rejeitadoPor = v.rejeitado_por,
                motivoRejeicao = v.motivo_rejeicao
            })
        end
        
        LogInfo("Carregados " .. #Cache.Passaportes .. " passaportes.")
    end
end

local function CarregarDocumentos()
    LogInfo("Carregando documentos do banco de dados...")
    
    local result = MySQL.Sync.fetchAll("SELECT * FROM oac_documentos ORDER BY created_at DESC")
    
    Cache.Documentos = {}
    
    if result and #result > 0 then
        for _, v in ipairs(result) do
            table.insert(Cache.Documentos, {
                id = v.id,
                tipo = v.tipo,
                nome = v.nome,
                identidade = v.identidade,
                descricao = v.descricao,
                evidencias = json.decode(v.evidencias),
                status = v.status,
                createdAt = v.created_at,
                updatedAt = v.updated_at,
                criadoPor = v.criado_por,
                assinatura = v.assinatura
            })
        end
        
        LogInfo("Carregados " .. #Cache.Documentos .. " documentos.")
    end
end

local function CarregarUsuarios()
    LogInfo("Carregando usuários do banco de dados...")
    
    local result = MySQL.Sync.fetchAll("SELECT * FROM oac_usuarios")
    
    Cache.Usuarios = {}
    
    if result and #result > 0 then
        for _, v in ipairs(result) do
            Cache.Usuarios[v.oab] = {
                id = v.id,
                nome = v.nome,
                oab = v.oab,
                cargo = v.cargo,
                nivel = v.nivel,
                avatar = v.avatar,
                email = v.email,
                telefone = v.telefone,
                ultimoAcesso = v.ultimo_acesso
            }
        end
        
        LogInfo("Carregados " .. #result .. " usuários.")
    end
end

local function CarregarProcessos()
    LogInfo("Carregando processos do banco de dados...")
    
    local result = MySQL.Sync.fetchAll("SELECT * FROM oac_processos ORDER BY created_at DESC")
    
    Cache.Processos = {}
    
    if result and #result > 0 then
        for _, v in ipairs(result) do
            table.insert(Cache.Processos, {
                id = v.id,
                numero = v.numero,
                titulo = v.titulo,
                descricao = v.descricao,
                reu = v.reu,
                identidadeReu = v.identidade_reu,
                advogado = v.advogado,
                promotor = v.promotor,
                juiz = v.juiz,
                status = v.status,
                dataAudiencia = v.data_audiencia,
                documentos = json.decode(v.documentos),
                createdAt = v.created_at,
                updatedAt = v.updated_at
            })
        end
        
        LogInfo("Carregados " .. #Cache.Processos .. " processos.")
    end
end

-- Funções de atualização de dados
local function AtualizarPassaporte(id, dados)
    -- Atualizar no cache
    for i, passaporte in ipairs(Cache.Passaportes) do
        if passaporte.id == id then
            for k, v in pairs(dados) do
                Cache.Passaportes[i][k] = v
            end
            Cache.Passaportes[i].updatedAt = os.date("%Y-%m-%d %H:%M:%S")
            break
        end
    end
    
    -- Preparar campos para atualização no banco de dados
    local campos = {}
    local valores = {}
    
    for k, v in pairs(dados) do
        -- Converter camelCase para snake_case
        local campo = k:gsub("([A-Z])", function(c) return "_" .. c:lower() end)
        table.insert(campos, campo .. " = ?")
        table.insert(valores, v)
    end
    
    table.insert(campos, "updated_at = ?")
    table.insert(valores, os.date("%Y-%m-%d %H:%M:%S"))
    
    -- Adicionar ID no final dos valores
    table.insert(valores, id)
    
    -- Executar query
    MySQL.Async.execute('UPDATE oac_passaportes SET ' .. table.concat(campos, ", ") .. ' WHERE id = ?', valores)
end

local function AtualizarDocumento(id, dados)
    -- Atualizar no cache
    for i, documento in ipairs(Cache.Documentos) do
        if documento.id == id then
            for k, v in pairs(dados) do
                Cache.Documentos[i][k] = v
            end
            Cache.Documentos[i].updatedAt = os.date("%Y-%m-%d %H:%M:%S")
            break
        end
    end
    
    -- Preparar campos para atualização no banco de dados
    local campos = {}
    local valores = {}
    
    for k, v in pairs(dados) do
        -- Converter camelCase para snake_case e tratar campos especiais
        local campo = k:gsub("([A-Z])", function(c) return "_" .. c:lower() end)
        
        if k == "evidencias" then
            table.insert(campos, "evidencias = ?")
            table.insert(valores, json.encode(v))
        else
            table.insert(campos, campo .. " = ?")
            table.insert(valores, v)
        end
    end
    
    table.insert(campos, "updated_at = ?")
    table.insert(valores, os.date("%Y-%m-%d %H:%M:%S"))
    
    -- Adicionar ID no final dos valores
    table.insert(valores, id)
    
    -- Executar query
    MySQL.Async.execute('UPDATE oac_documentos SET ' .. table.concat(campos, ", ") .. ' WHERE id = ?', valores)
end

local function AtualizarUsuario(oab, dados)
    -- Atualizar no cache
    if Cache.Usuarios[oab] then
        for k, v in pairs(dados) do
            Cache.Usuarios[oab][k] = v
        end
        Cache.Usuarios[oab].ultimoAcesso = os.date("%Y-%m-%d %H:%M:%S")
    end
    
    -- Preparar campos para atualização no banco de dados
    local campos = {}
    local valores = {}
    
    for k, v in pairs(dados) do
        -- Converter camelCase para snake_case
        local campo = k:gsub("([A-Z])", function(c) return "_" .. c:lower() end)
        table.insert(campos, campo .. " = ?")
        table.insert(valores, v)
    end
    
    table.insert(campos, "ultimo_acesso = ?")
    table.insert(valores, os.date("%Y-%m-%d %H:%M:%S"))
    
    -- Adicionar OAB no final dos valores
    table.insert(valores, oab)
    
    -- Executar query
    MySQL.Async.execute('UPDATE oac_usuarios SET ' .. table.concat(campos, ", ") .. ' WHERE oab = ?', valores)
end

-- Funções de notificação
local function NotificarJuizes(mensagem)
    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        
        if Player and (Player.PlayerData.job.name == "judge" or TemPermissao(playerId, Config.NiveisPermissao.Juiz)) then
            TriggerClientEvent('QBCore:Notify', playerId, mensagem, 'info')
            TriggerClientEvent('oac:notification', playerId, {
                type = "info",
                title = "Nova Solicitação",
                message = mensagem,
                icon = "gavel"
            })
        end
    end
end

local function NotificarAdvogados(mensagem)
    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        
        if Player and (Player.PlayerData.job.name == "lawyer" or TemPermissao(playerId, Config.NiveisPermissao.Advogado)) then
            TriggerClientEvent('QBCore:Notify', playerId, mensagem, 'info')
            TriggerClientEvent('oac:notification', playerId, {
                type = "info",
                title = "Notificação OAC",
                message = mensagem,
                icon = "briefcase"
            })
        end
    end
end

-- Callbacks
QBCore.Functions.CreateCallback('oac:getPlayerInfo', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        cb(nil)
        return
    end
    
    local oab = data.oab
    
    -- Se não foi fornecido um OAB, verificar se o jogador já tem um registrado
    if not oab or oab == "" then
        -- Buscar por citizenid
        local citizenid = Player.PlayerData.citizenid
        
        for registeredOab, usuario in pairs(Cache.Usuarios) do
            if usuario.id == citizenid then
                oab = registeredOab
                break
            end
        end
        
        -- Se ainda não tiver OAB, gerar um novo
        if not oab or oab == "" then
            -- Gerar OAB no formato XXX-XXXXXX
            local prefix = math.random(100, 999)
            local suffix = math.random(100000, 999999)
            oab = prefix .. "-" .. suffix
        end
    end
    
    -- Verificar se o usuário já existe
    local usuarioExistente = Cache.Usuarios[oab]
    
    if usuarioExistente then
        -- Atualizar último acesso
        AtualizarUsuario(oab, {ultimoAcesso = os.date("%Y-%m-%d %H:%M:%S")})
        cb(usuarioExistente)
        return
    end
    
    -- Criar novo usuário
    local nivelPermissao = ObterNivelPermissao(source)
    local nivel = "INICIANTE"
    
    if nivelPermissao >= Config.NiveisPermissao.Juiz then
        nivel = "ALTA ORDEM"
    elseif nivelPermissao >= Config.NiveisPermissao.Advogado then
        nivel = "SÊNIOR"
    end
    
    local playerInfo = {
        id = Player.PlayerData.citizenid,
        nome = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        oab = oab,
        cargo = Player.PlayerData.job.label,
        nivel = nivel,
        avatar = "https://i.imgur.com/default.png", -- Em um sistema real, isso seria a foto do personagem
        email = Player.PlayerData.charinfo.email or Player.PlayerData.charinfo.firstname:lower() .. "@oac.cc",
        telefone = Player.PlayerData.charinfo.phone or "000-0000",
        ultimoAcesso = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    cb(playerInfo)
end)

QBCore.Functions.CreateCallback('oac:getLeis', function(source, cb)
    if not VerificarPermissaoForum(source) then
        cb({})
        return
    end
    
    cb(Cache.Leis)
end)

QBCore.Functions.CreateCallback('oac:getPassaportes', function(source, cb, data)
    if not VerificarPermissaoForum(source) then
        cb({})
        return
    end
    
    local pagina = data and data.pagina or 1
    local porPagina = data and data.porPagina or Config.MaxPassaportesPorPagina
    local filtro = data and data.filtro or nil
    
    -- Aplicar filtros se necessário
    local passaportesFiltrados = {}
    
    if filtro then
        for _, passaporte in ipairs(Cache.Passaportes) do
            local corresponde = true
            
            if filtro.status and passaporte.status ~= filtro.status then
                corresponde = false
            end
            
            if filtro.nome and not string.find(string.lower(passaporte.nome), string.lower(filtro.nome)) then
                corresponde = false
            end
            
            if filtro.identidade and not string.find(passaporte.identidade, filtro.identidade) then
                corresponde = false
            end
            
            if corresponde then
                table.insert(passaportesFiltrados, passaporte)
            end
        end
    else
        passaportesFiltrados = Cache.Passaportes
    end
    
    -- Calcular paginação
    local inicio = (pagina - 1) * porPagina + 1
    local fim = math.min(inicio + porPagina - 1, #passaportesFiltrados)
    
    local resultado = {
        passaportes = {},
        total = #passaportesFiltrados,
        pagina = pagina,
        totalPaginas = math.ceil(#passaportesFiltrados / porPagina)
    }
    
    for i = inicio, fim do
        table.insert(resultado.passaportes, passaportesFiltrados[i])
    end
    
    cb(resultado)
end)

QBCore.Functions.CreateCallback('oac:getDocumentos', function(source, cb, data)
    if not VerificarPermissaoForum(source) then
        cb({})
        return
    end
    
    local pagina = data and data.pagina or 1
    local porPagina = data and data.porPagina or Config.MaxDocumentosPorPagina
    local filtro = data and data.filtro or nil
    
    -- Aplicar filtros se necessário
    local documentosFiltrados = {}
    
    if filtro then
        for _, documento in ipairs(Cache.Documentos) do
            local corresponde = true
            
            if filtro.tipo and documento.tipo ~= filtro.tipo then
                corresponde = false
            end
            
            if filtro.status and documento.status ~= filtro.status then
                corresponde = false
            end
            
            if filtro.nome and not string.find(string.lower(documento.nome), string.lower(filtro.nome)) then
                corresponde = false
            end
            
            if corresponde then
                table.insert(documentosFiltrados, documento)
            end
        end
    else
        documentosFiltrados = Cache.Documentos
    end
    
    -- Calcular paginação
    local inicio = (pagina - 1) * porPagina + 1
    local fim = math.min(inicio + porPagina - 1, #documentosFiltrados)
    
    local resultado = {
        documentos = {},
        total = #documentosFiltrados,
        pagina = pagina,
        totalPaginas = math.ceil(#documentosFiltrados / porPagina)
    }
    
    for i = inicio, fim do
        table.insert(resultado.documentos, documentosFiltrados[i])
    end
    
    cb(resultado)
end)

QBCore.Functions.CreateCallback('oac:getProcessos', function(source, cb, data)
    if not VerificarPermissaoForum(source) then
        cb({})
        return
    end
    
    local pagina = data and data.pagina or 1
    local porPagina = data and data.porPagina or Config.MaxProcessosPorPagina
    local filtro = data and data.filtro or nil
    
    -- Aplicar filtros se necessário
    local processosFiltrados = {}
    
    if filtro then
        for _, processo in ipairs(Cache.Processos) do
            local corresponde = true
            
            if filtro.status and processo.status ~= filtro.status then
                corresponde = false
            end
            
            if filtro.reu and not string.find(string.lower(processo.reu), string.lower(filtro.reu)) then
                corresponde = false
            end
            
            if filtro.numero and not string.find(processo.numero, filtro.numero) then
                corresponde = false
            end
            
            if corresponde then
                table.insert(processosFiltrados, processo)
            end
        end
    else
        processosFiltrados = Cache.Processos
    end
    
    -- Calcular paginação
    local inicio = (pagina - 1) * porPagina + 1
    local fim = math.min(inicio + porPagina - 1, #processosFiltrados)
    
    local resultado = {
        processos = {},
        total = #processosFiltrados,
        pagina = pagina,
        totalPaginas = math.ceil(#processosFiltrados / porPagina)
    }
    
    for i = inicio, fim do
        table.insert(resultado.processos, processosFiltrados[i])
    end
    
    cb(resultado)
end)

-- Eventos
RegisterNetEvent('oac:registerOab')
AddEventHandler('oac:registerOab', function(data)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', source, 'Erro ao obter informações do jogador!', 'error')
        return
    end
    
    -- Validar dados
    if not data.name or not data.oab then
        TriggerClientEvent('QBCore:Notify', source, 'Dados incompletos!', 'error')
        return
    end
    
    -- Verificar se o OAB já existe
    if Cache.Usuarios[data.oab] then
        TriggerClientEvent('QBCore:Notify', source, 'Este número OAB já está registrado!', 'error')
        return
    end
    
    -- Determinar nível com base nas permissões
    local nivelPermissao = ObterNivelPermissao(source)
    local nivel = "INICIANTE"
    
    if nivelPermissao >= Config.NiveisPermissao.Juiz then
        nivel = "ALTA ORDEM"
    elseif nivelPermissao >= Config.NiveisPermissao.Advogado then
        nivel = "SÊNIOR"
    end
    
    -- Criar novo usuário
    local novoUsuario = {
        id = Player.PlayerData.citizenid,
        nome = data.name,
        oab = data.oab,
        cargo = Player.PlayerData.job.label,
        nivel = nivel,
        avatar = "https://host-trig.vercel.app/files/Logo_Branca.png",
        email = Player.PlayerData.charinfo.email or data.name:lower():gsub("%s+", ".") .. "@oac.cc",
        telefone = Player.PlayerData.charinfo.phone or "000-0000",
        ultimoAcesso = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    -- Salvar no banco de dados
    MySQL.Async.execute('INSERT INTO oac_usuarios (id, nome, oab, cargo, nivel, avatar, email, telefone, ultimo_acesso) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {novoUsuario.id, novoUsuario.nome, novoUsuario.oab, novoUsuario.cargo, novoUsuario.nivel, novoUsuario.avatar, novoUsuario.email, novoUsuario.telefone, novoUsuario.ultimoAcesso})
    
    -- Adicionar à lista em memória
    Cache.Usuarios[data.oab] = novoUsuario
    
    -- Registrar log
    LogAcao(source, "registro_oab", {oab = data.oab, nome = data.name})
    
    -- Notificar cliente
    TriggerClientEvent('QBCore:Notify', source, 'Registro OAC concluído com sucesso!', 'success')
    
    -- Enviar resposta ao cliente
    TriggerClientEvent('oac:callback', source, 'registerOab', {success = true})
end)

RegisterNetEvent('oac:createPassport')
AddEventHandler('oac:createPassport', function(data)
    local source = source
    
    if not VerificarPermissaoForum(source) then
        TriggerClientEvent('QBCore:Notify', source, 'Você não tem permissão para isso!', 'error')
        TriggerClientEvent('oac:callback', source, 'createPassport', {success = false, error = "Sem permissão"})
        return
    end
    
    -- Validar dados
    if not data.nome or not data.identidade or not data.dataNascimento or not data.foto then
        TriggerClientEvent('QBCore:Notify', source, 'Dados incompletos!', 'error')
        TriggerClientEvent('oac:callback', source, 'createPassport', {success = false, error = "Dados incompletos"})
        return
    end
    
    -- Validar CPF/RG
    if not ValidarCPF(data.identidade) then
        TriggerClientEvent('QBCore:Notify', source, 'CPF/RG inválido!', 'error')
        TriggerClientEvent('oac:callback', source, 'createPassport', {success = false, error = "CPF/RG inválido"})
        return
    end
    
    -- Formatar data de nascimento
    local dataNascimento = FormatarData(data.dataNascimento)
    if not dataNascimento then
        TriggerClientEvent('QBCore:Notify', source, 'Data de nascimento inválida!', 'error')
        TriggerClientEvent('oac:callback', source, 'createPassport', {success = false, error = "Data inválida"})
        return
    end
    
    -- Gerar ID único
    local id = GerarId()
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    -- Obter informações do criador
    local Player = QBCore.Functions.GetPlayer(source)
    local criadorNome = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    local criadorId = Player.PlayerData.citizenid
    
    -- Criar novo passaporte
    local novoPassaporte = {
        id = id,
        nome = data.nome,
        identidade = data.identidade,
        dataNascimento = dataNascimento,
        foto = data.foto,
        status = "pendente",
        createdAt = timestamp,
        updatedAt = timestamp,
        criadoPor = criadorId,
        criadoPorNome = criadorNome
    }
    
    -- Salvar no banco de dados
    MySQL.Async.execute('INSERT INTO oac_passaportes (id, nome, identidade, data_nascimento, foto, status, created_at, updated_at, criado_por, criado_por_nome) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {id, data.nome, data.identidade, dataNascimento, data.foto, "pendente", timestamp, timestamp, criadorId, criadorNome})
    
    -- Adicionar à lista em memória
    table.insert(Cache.Passaportes, 1, novoPassaporte)
    
    -- Registrar log
    LogAcao(source, "criar_passaporte", {id = id, nome = data.nome, identidade = data.identidade})
    
    -- Notificar cliente
    TriggerClientEvent('QBCore:Notify', source, 'Solicitação de passaporte enviada com sucesso!', 'success')
    
    -- Enviar resposta ao cliente
    TriggerClientEvent('oac:callback', source, 'createPassport', {success = true, id = id})
    
    -- Notificar juízes sobre nova solicitação
    NotificarJuizes('Nova solicitação de passaporte pendente de aprovação!')
end)

RegisterNetEvent('oac:approvePassport')
AddEventHandler('oac:approvePassport', function(data)
    local source = source
    
    if not VerificarPermissaoAltaOrdem(source) then
        TriggerClientEvent('QBCore:Notify', source, 'Você não tem permissão para isso!', 'error')
        TriggerClientEvent('oac:callback', source, 'approvePassport', {success = false, error = "Sem permissão"})
        return
    end
    
    -- Encontrar passaporte
    local passaporte = nil
    local index = 0
    
    for i, p in ipairs(Cache.Passaportes) do
        if p.id == data.id then
            passaporte = p
            index = i
            break
        end
    end
    
    if not passaporte then
        TriggerClientEvent('QBCore:Notify', source, 'Passaporte não encontrado!', 'error')
        TriggerClientEvent('oac:callback', source, 'approvePassport', {success = false, error = "Passaporte não encontrado"})
        return
    end
    
    -- Verificar se já foi aprovado ou rejeitado
    if passaporte.status ~= "pendente" then
        TriggerClientEvent('QBCore:Notify', source, 'Este passaporte já foi ' .. passaporte.status .. '!', 'error')
        TriggerClientEvent('oac:callback', source, 'approvePassport', {success = false, error = "Passaporte já processado"})
        return
    end
    
    -- Obter informações do aprovador
    local Player = QBCore.Functions.GetPlayer(source)
    local aprovadorNome = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    local aprovadorId = Player.PlayerData.citizenid
    
    -- Atualizar status
    local dadosAtualizacao = {
        status = "aprovado",
        aprovadoPor = aprovadorId,
        aprovadoPorNome = aprovadorNome,
        dataAprovacao = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    AtualizarPassaporte(data.id, dadosAtualizacao)
    
    -- Registrar log
    LogAcao(source, "aprovar_passaporte", {id = data.id, nome = passaporte.nome})
    
    -- Notificar cliente
    TriggerClientEvent('QBCore:Notify', source, 'Passaporte aprovado com sucesso!', 'success')
    
    -- Enviar resposta ao cliente
    TriggerClientEvent('oac:callback', source, 'approvePassport', {success = true})
    
    -- Adicionar item ao inventário do cidadão
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(passaporte.identidade)
    if targetPlayer then
        targetPlayer.Functions.AddItem('passaporte', 1, false, {
            nome = passaporte.nome,
            identidade = passaporte.identidade,
            dataNascimento = passaporte.dataNascimento,
            foto = passaporte.foto,
            dataEmissao = os.date("%Y-%m-%d"),
            dataValidade = os.date("%Y-%m-%d", os.time() + Config.TempoExpiracaoPassaporte * 24 * 60 * 60)
        })
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'Seu passaporte foi aprovado!', 'success')
    end
end)

RegisterNetEvent('oac:rejectPassport')
AddEventHandler('oac:rejectPassport', function(data)
    local source = source
    
    if not VerificarPermissaoAltaOrdem(source) then
        TriggerClientEvent('QBCore:Notify', source, 'Você não tem permissão para isso!', 'error')
        TriggerClientEvent('oac:callback', source, 'rejectPassport', {success = false, error = "Sem permissão"})
        return
    end
    
    -- Encontrar passaporte
    local passaporte = nil
    local index = 0
    
    for i, p in ipairs(Cache.Passaportes) do
        if p.id == data.id then
            passaporte = p
            index = i
            break
        end
    end
    
    if not passaporte then
        TriggerClientEvent('QBCore:Notify', source, 'Passaporte não encontrado!', 'error')
        TriggerClientEvent('oac:callback', source, 'rejectPassport', {success = false, error = "Passaporte não encontrado"})
        return
    end
    
    -- Verificar se já foi aprovado ou rejeitado
    if passaporte.status ~= "pendente" then
        TriggerClientEvent('QBCore:Notify', source, 'Este passaporte já foi ' .. passaporte.status .. '!', 'error')
        TriggerClientEvent('oac:callback', source, 'rejectPassport', {success = false, error = "Passaporte já processado"})
        return
    end
    
    -- Obter informações do rejeitador
    local Player = QBCore.Functions.GetPlayer(source)
    local rejeitadorNome = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    local rejeitadorId = Player.PlayerData.citizenid
    
    -- Atualizar status
    local dadosAtualizacao = {
        status = "rejeitado",
        rejeitadoPor = rejeitadorId,
        rejeitadoPorNome = rejeitadorNome,
        dataRejeicao = os.date("%Y-%m-%d %H:%M:%S"),
        motivoRejeicao = data.motivo or "Não especificado"
    }
    
    AtualizarPassaporte(data.id, dadosAtualizacao)
    
    -- Registrar log
    LogAcao(source, "rejeitar_passaporte", {id = data.id, nome = passaporte.nome, motivo = data.motivo})
    
    -- Notificar cliente
    TriggerClientEvent('QBCore:Notify', source, 'Passaporte rejeitado!', 'success')
    
    -- Enviar resposta ao cliente
    TriggerClientEvent('oac:callback', source, 'rejectPassport', {success = true})
    
    -- Notificar o cidadão
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(passaporte.identidade)
    if targetPlayer then
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'Seu passaporte foi rejeitado!', 'error')
    end
end)

RegisterNetEvent('oac:updateProfile')
AddEventHandler('oac:updateProfile', function(data)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', source, 'Erro ao obter informações do jogador!', 'error')
        return
    end
    
    -- Validar dados
    if not data.oab then
        TriggerClientEvent('QBCore:Notify', source, 'Dados incompletos!', 'error')
        return
    end
    
    -- Verificar se o OAB existe
    if not Cache.Usuarios[data.oab] then
        TriggerClientEvent('QBCore:Notify', source, 'Usuário não encontrado!', 'error')
        return
    end
    
    -- Verificar se o usuário tem permissão para atualizar este perfil
    local usuarioAtual = Cache.Usuarios[data.oab]
    if usuarioAtual.id ~= Player.PlayerData.citizenid and not TemPermissao(source, Config.NiveisPermissao.Diretor) then
        TriggerClientEvent('QBCore:Notify', source, 'Você não tem permissão para atualizar este perfil!', 'error')
        return
    end
    
    -- Preparar dados para atualização
    local dadosAtualizacao = {}
    
    if data.name and data.name ~= "" then
        dadosAtualizacao.nome = data.name
    end
    
    if data.email and data.email ~= "" then
        dadosAtualizacao.email = data.email
    end
    
    if data.phone and data.phone ~= "" then
        dadosAtualizacao.telefone = data.phone
    end
    
    if data.avatar and data.avatar ~= "" then
        dadosAtualizacao.avatar = data.avatar
    end
    
    -- Atualizar perfil
    AtualizarUsuario(data.oab, dadosAtualizacao)
    
    -- Registrar log
    LogAcao(source, "atualizar_perfil", {oab = data.oab, dados = dadosAtualizacao})
    
    -- Notificar cliente
    TriggerClientEvent('QBCore:Notify', source, 'Perfil atualizado com sucesso!', 'success')
    
    -- Enviar resposta ao cliente
    TriggerClientEvent('oac:callback', source, 'updateProfile', {success = true})
end)

RegisterNetEvent('oac:exit')
AddEventHandler('oac:exit', function()
    local source = source
    TriggerClientEvent('oac:closePanel', source)
end)

-- Comando para abrir o painel
QBCore.Commands.Add('forum', 'Abrir painel do Fórum', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if VerificarPermissaoForum(source) then
        TriggerClientEvent('oac:openPanel', source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'Você não tem permissão para acessar o painel do Fórum!', 'error')
    end
end)

-- Inicialização
Citizen.CreateThread(function()
    -- Criar tabelas no banco de dados se não existirem
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS oac_passaportes (
            id VARCHAR(50) PRIMARY KEY,
            nome VARCHAR(255) NOT NULL,
            identidade VARCHAR(50) NOT NULL,
            data_nascimento DATE NOT NULL,
            foto TEXT NOT NULL,
            status VARCHAR(50) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            criado_por VARCHAR(50),
            criado_por_nome VARCHAR(255),
            aprovado_por VARCHAR(50),
            aprovado_por_nome VARCHAR(255),
            data_aprovacao TIMESTAMP NULL,
            rejeitado_por VARCHAR(50),
            rejeitado_por_nome VARCHAR(255),
            data_rejeicao TIMESTAMP NULL,
            motivo_rejeicao TEXT
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS oac_documentos (
            id VARCHAR(50) PRIMARY KEY,
            tipo VARCHAR(50) NOT NULL,
            nome VARCHAR(255) NOT NULL,
            identidade VARCHAR(50) NOT NULL,
            descricao TEXT NOT NULL,
            evidencias TEXT NOT NULL,
            status VARCHAR(50) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            criado_por VARCHAR(50),
            criado_por_nome VARCHAR(255),
            assinatura TEXT
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS oac_leis (
            id INT AUTO_INCREMENT PRIMARY KEY,
            categoria VARCHAR(100) NOT NULL,
            titulo VARCHAR(255) NOT NULL,
            conteudo TEXT NOT NULL
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS oac_usuarios (
            id VARCHAR(50) NOT NULL,
            nome VARCHAR(255) NOT NULL,
            oab VARCHAR(50) PRIMARY KEY,
            cargo VARCHAR(50) NOT NULL,
            nivel VARCHAR(50) NOT NULL,
            avatar TEXT NOT NULL,
            email VARCHAR(255),
            telefone VARCHAR(50),
            ultimo_acesso TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS oac_processos (
            id VARCHAR(50) PRIMARY KEY,
            numero VARCHAR(50) NOT NULL,
            titulo VARCHAR(255) NOT NULL,
            descricao TEXT NOT NULL,
            reu VARCHAR(255) NOT NULL,
            identidade_reu VARCHAR(50) NOT NULL,
            advogado VARCHAR(50),
            promotor VARCHAR(50),
            juiz VARCHAR(50),
            status VARCHAR(50) NOT NULL,
            data_audiencia TIMESTAMP NULL,
            documentos TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS oac_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL,
            nome VARCHAR(255) NOT NULL,
            acao VARCHAR(100) NOT NULL,
            dados TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    -- Carregar dados
    CarregarLeis()
    CarregarPassaportes()
    CarregarDocumentos()
    CarregarUsuarios()
    CarregarProcessos()
    
    LogInfo("Sistema OAC iniciado com sucesso!")
end)
