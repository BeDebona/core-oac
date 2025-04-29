-- ====================================================
-- Sistema OAC - Ordem dos Advogados de Central City
-- Servidor: Gerenciamento de dados e lógica de negócios
-- Adaptado para Creative Framework
-- ====================================================

-- Inicialização e dependências para Creative Framework
-- Nenhuma necessidade de importar objetos como no QBCore

-- Variáveis globais
local Cache = {
    Passaportes = {},
    Documentos = {},
    Leis = {},
    Usuarios = {},
    Processos = {},
    Calendario = {},
    AltaOrdem = {}
}

-- Configurações
local Config = {
    Debug = true,
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
    local identity = vRP.userIdentity(vRP.getUserId(source))
    if not identity then return end
    
    local playerName = identity.name .. " " .. identity.name2
    local registrado = identity.registration
    
    local query = "INSERT INTO oac_logs (player_name, registration, acao, dados, data) VALUES (?, ?, ?, ?, NOW())"
    exports.oxmysql:execute(query, {
        playerName,
        registrado,
        acao,
        json.encode(dados)
    })
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

-- Verificação de permissões para o Creative Framework
local function ObterNivelPermissao(source)
    local user_id = vRP.getUserId(source)
    if not user_id then return -1 end
    
    -- Verificar se é administrador do servidor
    if vRP.hasPermission(user_id, "admin.permissao") then
        return Config.NiveisPermissao.Diretor
    end
    
    -- Verificar cargos no Creative Framework
    -- Juiz
    if vRP.hasPermission(user_id, "juiz.permissao") then
        return Config.NiveisPermissao.Juiz
    end
    
    -- Promotor
    if vRP.hasPermission(user_id, "promotor.permissao") then
        return Config.NiveisPermissao.Promotor
    end
    
    -- Advogado
    -- Verificamos diferentes níveis de advogado
    if vRP.hasPermission(user_id, "advogado.diretor") then
        return Config.NiveisPermissao.Diretor
    elseif vRP.hasPermission(user_id, "advogado.permissao") then
        return Config.NiveisPermissao.Advogado
    elseif vRP.hasPermission(user_id, "advogado.estagiario") then
        return Config.NiveisPermissao.Estagiario
    end
    
    -- Verificar permissões específicas da OAC
    if vRP.hasPermission(user_id, "oac.diretor") then
        return Config.NiveisPermissao.Diretor
    elseif vRP.hasPermission(user_id, "oac.juiz") then
        return Config.NiveisPermissao.Juiz
    elseif vRP.hasPermission(user_id, "oac.promotor") then
        return Config.NiveisPermissao.Promotor
    elseif vRP.hasPermission(user_id, "oac.advogado") then
        return Config.NiveisPermissao.Advogado
    elseif vRP.hasPermission(user_id, "oac.estagiario") then
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
    
    local result = exports.oxmysql:executeSync("SELECT * FROM oac_leis ORDER BY categoria, id")
    
    if result and #result > 0 then
        Cache.Leis = result
        LogInfo("Leis carregadas: " .. #result)
    else
        LogInfo("Nenhuma lei encontrada no banco de dados.")
    end
end

local function CarregarPassaportes()
    LogInfo("Carregando passaportes do banco de dados...")
    
    local result = exports.oxmysql:executeSync("SELECT * FROM oac_passaportes ORDER BY created_at DESC LIMIT 100")
    
    if result and #result > 0 then
        Cache.Passaportes = result
        LogInfo("Passaportes carregados: " .. #result)
    else
        LogInfo("Nenhum passaporte encontrado no banco de dados.")
    end
end

local function CarregarDocumentos()
    LogInfo("Carregando documentos do banco de dados...")
    
    local result = exports.oxmysql:executeSync("SELECT * FROM oac_documentos ORDER BY updated_at DESC LIMIT 100")
    
    if result and #result > 0 then
        Cache.Documentos = result
        LogInfo("Documentos carregados: " .. #result)
    else
        LogInfo("Nenhum documento encontrado no banco de dados.")
    end
end

local function CarregarUsuarios()
    LogInfo("Carregando usuários do banco de dados...")
    
    local result = exports.oxmysql:executeSync("SELECT * FROM oac_usuarios ORDER BY nome")
    
    if result and #result > 0 then
        Cache.Usuarios = result
        LogInfo("Usuários carregados: " .. #result)
    else
        LogInfo("Nenhum usuário encontrado no banco de dados.")
    end
end

local function CarregarProcessos()
    LogInfo("Carregando processos do banco de dados...")
    
    local result = exports.oxmysql:executeSync("SELECT * FROM oac_processos ORDER BY updated_at DESC LIMIT 100")
    
    if result and #result > 0 then
        Cache.Processos = result
        LogInfo("Processos carregados: " .. #result)
    else
        LogInfo("Nenhum processo encontrado no banco de dados.")
    end
end

local function CarregarEventosCalendario()
    LogInfo("Carregando eventos do calendário...")
    
    local result = exports.oxmysql:executeSync("SELECT * FROM oac_calendario ORDER BY data_inicio DESC LIMIT 100")
    
    if result and #result > 0 then
        Cache.Calendario = result
        LogInfo("Eventos do calendário carregados: " .. #result)
    else
        LogInfo("Nenhum evento de calendário encontrado no banco de dados.")
    end
end

local function CarregarDecisoesAltaOrdem()
    LogInfo("Carregando decisões da alta ordem...")
    
    local result = exports.oxmysql:executeSync("SELECT * FROM oac_alta_ordem ORDER BY updated_at DESC LIMIT 100")
    
    if result and #result > 0 then
        Cache.AltaOrdem = result
        LogInfo("Decisões da alta ordem carregadas: " .. #result)
    else
        LogInfo("Nenhuma decisão da alta ordem encontrada no banco de dados.")
    end
end

-- Inicialização do banco de dados
local function InicializarBancoDados()
    LogInfo("Inicializando banco de dados...")
    
    -- Criar tabelas no banco de dados
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS oac_leis (
            id INT AUTO_INCREMENT PRIMARY KEY,
            categoria VARCHAR(50) NOT NULL,
            titulo VARCHAR(255) NOT NULL,
            conteudo TEXT NOT NULL
        )
    ]])
    
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS oac_passaportes (
            id VARCHAR(50) PRIMARY KEY,
            nome VARCHAR(255) NOT NULL,
            identidade VARCHAR(50) NOT NULL UNIQUE,
            data_nascimento DATE NOT NULL,
            foto TEXT,
            status VARCHAR(20) DEFAULT 'pendente',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
    
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS oac_documentos (
            id VARCHAR(50) PRIMARY KEY,
            tipo VARCHAR(50) NOT NULL,
            status VARCHAR(20) DEFAULT 'rascunho',
            titulo VARCHAR(255) NOT NULL,
            conteudo TEXT,
            envolvidos TEXT,
            autor_id VARCHAR(50) NOT NULL,
            autor_nome VARCHAR(255) NOT NULL,
            anexos TEXT,
            assinatura TEXT,
            referencias TEXT,
            metadata TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS oac_usuarios (
            id VARCHAR(50) NOT NULL,
            nome VARCHAR(255) NOT NULL,
            oab VARCHAR(50) PRIMARY KEY,
            cargo VARCHAR(50),
            nivel VARCHAR(20) DEFAULT 'INICIANTE',
            avatar TEXT,
            email VARCHAR(100),
            telefone VARCHAR(20),
            ultimo_acesso TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS oac_processos (
            id VARCHAR(50) PRIMARY KEY,
            numero VARCHAR(50) UNIQUE,
            titulo VARCHAR(255) NOT NULL,
            descricao TEXT,
            reu VARCHAR(255),
            identidade_reu VARCHAR(50),
            advogado VARCHAR(50),
            promotor VARCHAR(50),
            juiz VARCHAR(50),
            status VARCHAR(20) DEFAULT 'aberto',
            data_audiencia TIMESTAMP,
            documentos TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS oac_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_name VARCHAR(255) NOT NULL,
            registration VARCHAR(50) NOT NULL,
            acao VARCHAR(50) NOT NULL,
            dados TEXT,
            data TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    -- Criar tabela para eventos do calendário
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS oac_calendario (
            id VARCHAR(50) PRIMARY KEY,
            titulo VARCHAR(255) NOT NULL,
            descricao TEXT,
            tipo VARCHAR(50) NOT NULL, -- audiencia, reuniao, evento
            data_inicio TIMESTAMP NOT NULL,
            data_fim TIMESTAMP NOT NULL,
            local VARCHAR(255),
            criado_por VARCHAR(50) NOT NULL,
            criado_por_nome VARCHAR(255) NOT NULL,
            participantes TEXT,
            status VARCHAR(50) NOT NULL DEFAULT 'agendado', -- agendado, concluido, cancelado
            notas TEXT,
            documentos_relacionados TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    -- Criar tabela para alta ordem
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS oac_alta_ordem (
            id VARCHAR(50) PRIMARY KEY,
            tipo VARCHAR(50) NOT NULL, -- decisao, sentenca, decreto
            titulo VARCHAR(255) NOT NULL,
            conteudo TEXT NOT NULL,
            autor_id VARCHAR(50) NOT NULL,
            autor_nome VARCHAR(255) NOT NULL,
            data_efetiva TIMESTAMP,
            status VARCHAR(50) NOT NULL DEFAULT 'ativo', -- ativo, arquivado, revogado
            referencias TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end

-- Função para tarefas automáticas
local function AgendarTarefasAutomaticas()
    -- Esta função é chamada durante a inicialização e configura tarefas periódicas
    
    -- Sincronizar dados com clientes a cada 10 minutos
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(10 * 60 * 1000)
            SincronizarDadosComClientes()
        end
    end)
    
    -- Limpar cache a cada 2 horas
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(2 * 60 * 60 * 1000)
            LogInfo("Limpando cache...")
            
            -- Recarregar dados do banco de dados
            CarregarLeis()
            CarregarPassaportes()
            CarregarDocumentos()
            CarregarUsuarios()
            CarregarProcessos()
            CarregarEventosCalendario()
            CarregarDecisoesAltaOrdem()
            
            LogInfo("Cache limpo e recarregado.")
        end
    end)
end

-- Função para sincronizar dados com clientes
local function SincronizarDadosComClientes()
    LogInfo("Sincronizando dados com clientes...")
    
    -- Obter dados recentes para sincronização
    local eventosRecentes = {}
    local decisoesRecentes = {}
    
    -- Buscar eventos próximos
    local dataAtual = os.date("%Y-%m-%d %H:%M:%S")
    local result = exports.oxmysql:executeSync([[
        SELECT * FROM oac_calendario 
        WHERE data_inicio > ? AND status = 'agendado' 
        ORDER BY data_inicio ASC LIMIT 5
    ]], {dataAtual})
    
    if result and #result > 0 then
        eventosRecentes = result
    end
    
    -- Buscar decisões recentes da alta ordem
    result = exports.oxmysql:executeSync([[
        SELECT * FROM oac_alta_ordem 
        WHERE status = 'ativo' 
        ORDER BY created_at DESC LIMIT 5
    ]])
    
    if result and #result > 0 then
        decisoesRecentes = result
    end
    
    -- Enviar dados para todos os clientes que têm permissão
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        if VerificarPermissaoForum(tonumber(playerId)) then
            TriggerClientEvent('oac:syncData', tonumber(playerId), {
                eventos = eventosRecentes,
                decisoes = decisoesRecentes,
                timestamp = os.time()
            })
        end
    end
    
    LogInfo("Dados sincronizados com " .. #players .. " clientes.")
end

-- ====================================================
-- Sistema de Consultas - Sincronização com MySQL
-- ====================================================

-- Função para buscar documentos diretamente no banco de dados (sem cache)
local function BuscarDocumentosBD(filtros, pagina, porPagina)
    -- Inicializar parâmetros e valores para consulta SQL
    local where = {}
    local params = {}
    local sql = "SELECT * FROM oac_documentos WHERE 1=1"
    
    -- Adicionar filtros à consulta
    if filtros then
        if filtros.tipo then
            table.insert(where, "tipo = ?")
            table.insert(params, filtros.tipo)
        end
        
        if filtros.status then
            table.insert(where, "status = ?")
            table.insert(params, filtros.status)
        end
        
        if filtros.autor_id then
            table.insert(where, "autor_id = ?")
            table.insert(params, filtros.autor_id)
        end
        
        if filtros.texto then
            table.insert(where, "(titulo LIKE ? OR conteudo LIKE ?)")
            table.insert(params, "%" .. filtros.texto .. "%")
            table.insert(params, "%" .. filtros.texto .. "%")
        end
        
        if filtros.data_inicio then
            table.insert(where, "created_at >= ?")
            table.insert(params, filtros.data_inicio)
        end
        
        if filtros.data_fim then
            table.insert(where, "created_at <= ?")
            table.insert(params, filtros.data_fim)
        end
        
        -- Filtro para documentos que mencionam uma identidade específica
        if filtros.identidade then
            table.insert(where, "(envolvidos LIKE ? OR conteudo LIKE ?)")
            table.insert(params, "%" .. filtros.identidade .. "%")
            table.insert(params, "%" .. filtros.identidade .. "%")
        end
    end
    
    -- Montar cláusula WHERE
    if #where > 0 then
        sql = sql .. " AND " .. table.concat(where, " AND ")
    end
    
    -- Contar total de resultados (para paginação)
    local countSql = "SELECT COUNT(*) as total FROM oac_documentos WHERE 1=1"
    if #where > 0 then
        countSql = countSql .. " AND " .. table.concat(where, " AND ")
    end
    
    local countResult = exports.oxmysql:executeSync(countSql, params)
    local total = countResult[1].total
    
    -- Adicionar ordenação e paginação
    sql = sql .. " ORDER BY updated_at DESC"
    
    -- Calcular offset para paginação
    local offset = (pagina - 1) * porPagina
    sql = sql .. string.format(" LIMIT %d, %d", offset, porPagina)
    
    -- Executar consulta
    local result = exports.oxmysql:executeSync(sql, params)
    
    -- Calcular total de páginas
    local totalPaginas = math.ceil(total / porPagina)
    
    return {
        documentos = result or {},
        total = total,
        pagina = pagina,
        porPagina = porPagina,
        totalPaginas = totalPaginas
    }
end

-- Função para buscar passaportes diretamente no banco de dados (sem cache)
local function BuscarPassaportesBD(filtros, pagina, porPagina)
    -- Inicializar parâmetros e valores para consulta SQL
    local where = {}
    local params = {}
    local sql = "SELECT * FROM oac_passaportes WHERE 1=1"
    
    -- Adicionar filtros à consulta
    if filtros then
        if filtros.status then
            table.insert(where, "status = ?")
            table.insert(params, filtros.status)
        end
        
        if filtros.nome then
            table.insert(where, "nome LIKE ?")
            table.insert(params, "%" .. filtros.nome .. "%")
        end
        
        if filtros.identidade then
            table.insert(where, "identidade = ?")
            table.insert(params, filtros.identidade)
        end
        
        if filtros.data_inicio then
            table.insert(where, "created_at >= ?")
            table.insert(params, filtros.data_inicio)
        end
        
        if filtros.data_fim then
            table.insert(where, "created_at <= ?")
            table.insert(params, filtros.data_fim)
        end
    end
    
    -- Montar cláusula WHERE
    if #where > 0 then
        sql = sql .. " AND " .. table.concat(where, " AND ")
    end
    
    -- Contar total de resultados (para paginação)
    local countSql = "SELECT COUNT(*) as total FROM oac_passaportes WHERE 1=1"
    if #where > 0 then
        countSql = countSql .. " AND " .. table.concat(where, " AND ")
    end
    
    local countResult = exports.oxmysql:executeSync(countSql, params)
    local total = countResult[1].total
    
    -- Adicionar ordenação e paginação
    sql = sql .. " ORDER BY created_at DESC"
    
    -- Calcular offset para paginação
    local offset = (pagina - 1) * porPagina
    sql = sql .. string.format(" LIMIT %d, %d", offset, porPagina)
    
    -- Executar consulta
    local result = exports.oxmysql:executeSync(sql, params)
    
    -- Calcular total de páginas
    local totalPaginas = math.ceil(total / porPagina)
    
    return {
        passaportes = result or {},
        total = total,
        pagina = pagina,
        porPagina = porPagina,
        totalPaginas = totalPaginas
    }
end

-- Função para buscar eventos do calendário no banco de dados
local function BuscarEventosBD(filtros, pagina, porPagina)
    -- Inicializar parâmetros e valores para consulta SQL
    local where = {}
    local params = {}
    local sql = "SELECT * FROM oac_calendario WHERE 1=1"
    
    -- Adicionar filtros à consulta
    if filtros then
        if filtros.tipo then
            table.insert(where, "tipo = ?")
            table.insert(params, filtros.tipo)
        end
        
        if filtros.status then
            table.insert(where, "status = ?")
            table.insert(params, filtros.status)
        end
        
        if filtros.titulo then
            table.insert(where, "titulo LIKE ?")
            table.insert(params, "%" .. filtros.titulo .. "%")
        end
        
        if filtros.data_inicio then
            table.insert(where, "data_inicio >= ?")
            table.insert(params, filtros.data_inicio)
        end
        
        if filtros.data_fim then
            table.insert(where, "data_fim <= ?")
            table.insert(params, filtros.data_fim)
        end
        
        if filtros.participante then
            table.insert(where, "participantes LIKE ?")
            table.insert(params, "%" .. filtros.participante .. "%")
        end
    end
    
    -- Montar cláusula WHERE
    if #where > 0 then
        sql = sql .. " AND " .. table.concat(where, " AND ")
    end
    
    -- Contar total de resultados (para paginação)
    local countSql = "SELECT COUNT(*) as total FROM oac_calendario WHERE 1=1"
    if #where > 0 then
        countSql = countSql .. " AND " .. table.concat(where, " AND ")
    end
    
    local countResult = exports.oxmysql:executeSync(countSql, params)
    local total = countResult[1].total
    
    -- Adicionar ordenação e paginação
    sql = sql .. " ORDER BY data_inicio ASC"
    
    -- Calcular offset para paginação
    local offset = (pagina - 1) * porPagina
    sql = sql .. string.format(" LIMIT %d, %d", offset, porPagina)
    
    -- Executar consulta
    local result = exports.oxmysql:executeSync(sql, params)
    
    -- Calcular total de páginas
    local totalPaginas = math.ceil(total / porPagina)
    
    return {
        eventos = result or {},
        total = total,
        pagina = pagina,
        porPagina = porPagina,
        totalPaginas = totalPaginas
    }
end

-- Função para buscar decisões da alta ordem no banco de dados
local function BuscarDecisoesAltaOrdemBD(filtros, pagina, porPagina)
    -- Inicializar parâmetros e valores para consulta SQL
    local where = {}
    local params = {}
    local sql = "SELECT * FROM oac_alta_ordem WHERE 1=1"
    
    -- Adicionar filtros à consulta
    if filtros then
        if filtros.tipo then
            table.insert(where, "tipo = ?")
            table.insert(params, filtros.tipo)
        end
        
        if filtros.status then
            table.insert(where, "status = ?")
            table.insert(params, filtros.status)
        end
        
        if filtros.titulo then
            table.insert(where, "titulo LIKE ?")
            table.insert(params, "%" .. filtros.titulo .. "%")
        end
        
        if filtros.texto then
            table.insert(where, "(titulo LIKE ? OR conteudo LIKE ?)")
            table.insert(params, "%" .. filtros.texto .. "%")
            table.insert(params, "%" .. filtros.texto .. "%")
        end
        
        if filtros.autor_id then
            table.insert(where, "autor_id = ?")
            table.insert(params, filtros.autor_id)
        end
        
        if filtros.data_inicio then
            table.insert(where, "created_at >= ?")
            table.insert(params, filtros.data_inicio)
        end
        
        if filtros.data_fim then
            table.insert(where, "created_at <= ?")
            table.insert(params, filtros.data_fim)
        end
    end
    
    -- Montar cláusula WHERE
    if #where > 0 then
        sql = sql .. " AND " .. table.concat(where, " AND ")
    end
    
    -- Contar total de resultados (para paginação)
    local countSql = "SELECT COUNT(*) as total FROM oac_alta_ordem WHERE 1=1"
    if #where > 0 then
        countSql = countSql .. " AND " .. table.concat(where, " AND ")
    end
    
    local countResult = exports.oxmysql:executeSync(countSql, params)
    local total = countResult[1].total
    
    -- Adicionar ordenação e paginação
    sql = sql .. " ORDER BY updated_at DESC"
    
    -- Calcular offset para paginação
    local offset = (pagina - 1) * porPagina
    sql = sql .. string.format(" LIMIT %d, %d", offset, porPagina)
    
    -- Executar consulta
    local result = exports.oxmysql:executeSync(sql, params)
    
    -- Calcular total de páginas
    local totalPaginas = math.ceil(total / porPagina)
    
    return {
        decisoes = result or {},
        total = total,
        pagina = pagina,
        porPagina = porPagina,
        totalPaginas = totalPaginas
    }
end

-- ====================================================
-- Callbacks para Creative Framework - Sistema de documentos
-- ====================================================

-- Função para registrar callbacks no Creative Framework
local function RegisterCreativeCallback(name, callback)
    RegisterServerEvent(name)
    AddEventHandler(name, function(...)
        local source = source
        local args = {...}
        
        -- O último argumento é uma função de callback
        local cbFunction = args[#args]
        table.remove(args, #args)
        
        -- Executar callback com argumento adicional para resposta
        local result = callback(source, table.unpack(args))
        
        -- Enviar resultado de volta ao cliente
        cbFunction(result)
    end)
end

-- Callback para consultar documentos
RegisterCreativeCallback("oac:consultarDocumentos", function(source, data)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    -- Parâmetros de paginação e filtros
    local pagina = data and data.pagina or 1
    local porPagina = data and data.porPagina or 10
    local filtros = data and data.filtros or {}
    
    -- Registrar log da consulta
    LogAcao(source, "consultar_documentos", {
        filtros = filtros,
        pagina = pagina
    })
    
    -- Buscar do banco de dados
    local resultado = BuscarDocumentosBD(filtros, pagina, porPagina)
    
    return {
        success = true,
        documentos = resultado.documentos,
        total = resultado.total,
        pagina = resultado.pagina,
        totalPaginas = resultado.totalPaginas
    }
end)

-- Callback para consultar um documento específico
RegisterCreativeCallback("oac:consultarDocumento", function(source, id)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    if not id then
        return {success = false, error = "ID não fornecido"}
    end
    
    -- Registrar log da consulta
    LogAcao(source, "consultar_documento", {
        id = id
    })
    
    -- Buscar do banco de dados
    local result = exports.oxmysql:executeSync("SELECT * FROM oac_documentos WHERE id = ?", {id})
    
    if result and #result > 0 then
        return {success = true, documento = result[1]}
    else
        return {success = false, error = "Documento não encontrado"}
    end
end)

-- Callback para consulta avançada de documentos
RegisterCreativeCallback("oac:consultaAvancada", function(source, data)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    if not data or not data.query or data.query == "" then
        return {success = false, error = "Consulta inválida"}
    end
    
    -- Parâmetros de paginação
    local pagina = data.pagina or 1
    local porPagina = data.porPagina or 10
    
    -- Registrar log da consulta
    LogAcao(source, "consulta_avancada", {
        query = data.query,
        pagina = pagina
    })
    
    -- Preparar filtros para a consulta
    local filtros = {
        texto = data.query
    }
    
    -- Buscar do banco de dados
    local resultado = BuscarDocumentosBD(filtros, pagina, porPagina)
    
    return {
        success = true,
        documentos = resultado.documentos,
        total = resultado.total,
        pagina = resultado.pagina,
        totalPaginas = resultado.totalPaginas
    }
end)

-- Callback para consultar documentos por identidade
RegisterCreativeCallback("oac:consultarDocumentosPorIdentidade", function(source, data)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    if not data or not data.identidade then
        return {success = false, error = "Identidade não fornecida"}
    end
    
    -- Parâmetros de paginação
    local pagina = data.pagina or 1
    local porPagina = data.porPagina or 10
    
    -- Registrar log da consulta
    LogAcao(source, "consultar_documentos_por_identidade", {
        identidade = data.identidade,
        pagina = pagina
    })
    
    -- Preparar filtros para a consulta
    local filtros = {
        identidade = data.identidade
    }
    
    -- Buscar do banco de dados
    local resultado = BuscarDocumentosBD(filtros, pagina, porPagina)
    
    return {
        success = true,
        documentos = resultado.documentos,
        total = resultado.total,
        pagina = resultado.pagina,
        totalPaginas = resultado.totalPaginas
    }
end)

-- Callback para consultar estatísticas de documentos
RegisterCreativeCallback("oac:consultarEstatisticasDocumentos", function(source)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    -- Registrar log da consulta
    LogAcao(source, "consultar_estatisticas_documentos", {})
    
    -- Buscar estatísticas do banco de dados
    local result = exports.oxmysql:executeSync([[
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN status = 'rascunho' THEN 1 ELSE 0 END) as rascunhos,
            SUM(CASE WHEN status = 'pendente' THEN 1 ELSE 0 END) as pendentes,
            SUM(CASE WHEN status = 'assinado' THEN 1 ELSE 0 END) as assinados,
            SUM(CASE WHEN status = 'arquivado' THEN 1 ELSE 0 END) as arquivados,
            COUNT(DISTINCT autor_id) as autores,
            DATE_FORMAT(MAX(created_at), '%Y-%m-%d') as ultimo_criado,
            DATE_FORMAT(MAX(updated_at), '%Y-%m-%d') as ultimo_atualizado
        FROM oac_documentos
    ]])
    
    -- Obter estatísticas por tipo de documento
    local tiposResult = exports.oxmysql:executeSync([[
        SELECT 
            tipo,
            COUNT(*) as total
        FROM oac_documentos
        GROUP BY tipo
        ORDER BY total DESC
    ]])
    
    local estatisticas = {
        geral = result[1],
        porTipo = tiposResult
    }
    
    return {
        success = true,
        estatisticas = estatisticas
    }
end)

-- Callback para consultar passaportes
RegisterCreativeCallback("oac:consultarPassaportes", function(source, data)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    -- Parâmetros de paginação e filtros
    local pagina = data and data.pagina or 1
    local porPagina = data and data.porPagina or 10
    local filtros = data and data.filtros or {}
    
    -- Registrar log da consulta
    LogAcao(source, "consultar_passaportes", {
        filtros = filtros,
        pagina = pagina
    })
    
    -- Buscar do banco de dados
    local resultado = BuscarPassaportesBD(filtros, pagina, porPagina)
    
    return {
        success = true,
        passaportes = resultado.passaportes,
        total = resultado.total,
        pagina = resultado.pagina,
        totalPaginas = resultado.totalPaginas
    }
end)

-- Callback para consultar passaportes pendentes (alta ordem)
RegisterCreativeCallback("oac:consultarPassaportesPendentes", function(source, data)
    if not VerificarPermissaoAltaOrdem(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    -- Parâmetros de paginação
    local pagina = data and data.pagina or 1
    local porPagina = data and data.porPagina or 10
    
    -- Registrar log da consulta
    LogAcao(source, "consultar_passaportes_pendentes", {
        pagina = pagina
    })
    
    -- Preparar filtros para a consulta
    local filtros = {
        status = "pendente"
    }
    
    -- Buscar do banco de dados
    local resultado = BuscarPassaportesBD(filtros, pagina, porPagina)
    
    return {
        success = true,
        passaportes = resultado.passaportes,
        total = resultado.total,
        pagina = resultado.pagina,
        totalPaginas = resultado.totalPaginas
    }
end)

-- Callback para estatísticas de passaportes
RegisterCreativeCallback("oac:consultarEstatisticasPassaportes", function(source)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    -- Registrar log da consulta
    LogAcao(source, "consultar_estatisticas_passaportes", {})
    
    -- Buscar estatísticas do banco de dados
    local result = exports.oxmysql:executeSync([[
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN status = 'pendente' THEN 1 ELSE 0 END) as pendentes,
            SUM(CASE WHEN status = 'aprovado' THEN 1 ELSE 0 END) as aprovados,
            SUM(CASE WHEN status = 'rejeitado' THEN 1 ELSE 0 END) as rejeitados,
            DATE_FORMAT(MAX(created_at), '%Y-%m-%d') as ultimo_criado,
            DATE_FORMAT(MAX(updated_at), '%Y-%m-%d') as ultimo_atualizado
        FROM oac_passaportes
    ]])
    
    return {
        success = true,
        estatisticas = result[1]
    }
end)

-- Callback para obter informações do jogador
RegisterCreativeCallback("oac:getPlayerInfo", function(source, data)
    local user_id = vRP.getUserId(source)
    if not user_id then 
        return {success = false, error = "Usuário não encontrado"}
    end
    
    -- Obter identidade do jogador
    local identity = vRP.userIdentity(user_id)
    if not identity then
        return {success = false, error = "Identidade não encontrada"}
    end
    
    -- Verificar permissões
    local nivelPermissao = ObterNivelPermissao(source)
    local permissoes = {
        forum = VerificarPermissaoForum(source),
        altaOrdem = VerificarPermissaoAltaOrdem(source),
        nivel = nivelPermissao
    }
    
    -- Formatar nome completo
    local nomeCompleto = identity.name .. " " .. identity.name2
    
    -- Verificar se já possui registro na OAB
    local oabResult = exports.oxmysql:executeSync("SELECT * FROM oac_usuarios WHERE id = ?", {user_id})
    local registroOAB = nil
    
    if oabResult and #oabResult > 0 then
        registroOAB = oabResult[1]
        
        -- Atualizar último acesso
        exports.oxmysql:execute("UPDATE oac_usuarios SET ultimo_acesso = NOW() WHERE id = ?", {user_id})
    end
    
    -- Preparar resposta
    local playerInfo = {
        success = true,
        user_id = user_id,
        name = identity.name,
        firstname = identity.name,
        lastname = identity.name2,
        fullname = nomeCompleto,
        dob = identity.birth,
        registration = identity.registration,
        phone = identity.phone,
        permissions = permissoes,
        oab = registroOAB
    }
    
    return playerInfo
end)

-- ====================================================
-- Eventos para documentos e passaportes
-- ====================================================

-- Evento para criar documento
RegisterServerEvent('oac:createDocumento')
AddEventHandler('oac:createDocumento', function(data)
    local source = source
    
    -- Verificar permissão
    if not VerificarPermissaoForum(source) then
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para criar documentos!', 5000)
        TriggerClientEvent('oac:callback', source, 'createDocumento', {success = false, error = "Sem permissão"})
        return
    end
    
    -- Verificar dados obrigatórios
    if not data.tipo or not data.titulo or data.titulo == "" then
        TriggerClientEvent('Notify', source, 'negado', 'Título e tipo são obrigatórios!', 5000)
        TriggerClientEvent('oac:callback', source, 'createDocumento', {success = false, error = "Dados inválidos"})
        return
    end
    
    -- Obter informações do jogador
    local user_id = vRP.getUserId(source)
    local identity = vRP.userIdentity(user_id)
    
    if not identity then
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao obter dados do jogador!', 5000)
        TriggerClientEvent('oac:callback', source, 'createDocumento', {success = false, error = "Erro de identidade"})
        return
    end
    
    -- Gerar ID único para o documento
    local id = GerarId()
    
    -- Preparar dados para inserção
    local documentoData = {
        id = id,
        tipo = data.tipo,
        status = data.status or "rascunho",
        titulo = data.titulo,
        conteudo = data.conteudo or "",
        envolvidos = data.envolvidos and json.encode(data.envolvidos) or "[]",
        autor_id = tostring(user_id),
        autor_nome = identity.name .. " " .. identity.name2,
        anexos = data.anexos and json.encode(data.anexos) or "[]",
        assinatura = data.assinatura and json.encode(data.assinatura) or "[]",
        referencias = data.referencias and json.encode(data.referencias) or "[]",
        metadata = data.metadata and json.encode(data.metadata) or "{}"
    }
    
    -- Inserir no banco de dados
    local success = exports.oxmysql:execute([[
        INSERT INTO oac_documentos 
        (id, tipo, status, titulo, conteudo, envolvidos, autor_id, autor_nome, anexos, assinatura, referencias, metadata) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        documentoData.id,
        documentoData.tipo,
        documentoData.status,
        documentoData.titulo,
        documentoData.conteudo,
        documentoData.envolvidos,
        documentoData.autor_id,
        documentoData.autor_nome,
        documentoData.anexos,
        documentoData.assinatura,
        documentoData.referencias,
        documentoData.metadata
    })
    
    -- Verificar resultado
    if success then
        -- Adicionar ao cache
        table.insert(Cache.Documentos, 1, documentoData)
        
        -- Registrar log
        LogAcao(source, "criar_documento", {
            id = id,
            tipo = data.tipo,
            titulo = data.titulo
        })
        
        -- Notificar cliente
        TriggerClientEvent('Notify', source, 'sucesso', 'Documento criado com sucesso!', 5000)
        TriggerClientEvent('oac:callback', source, 'createDocumento', {
            success = true,
            message = "Documento criado com sucesso",
            id = id
        })
    else
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao criar documento no banco de dados!', 5000)
        TriggerClientEvent('oac:callback', source, 'createDocumento', {
            success = false,
            error = "Erro ao criar documento no banco de dados"
        })
    end
end)

-- Evento para atualizar documento
RegisterServerEvent('oac:updateDocumento')
AddEventHandler('oac:updateDocumento', function(id, data)
    local source = source
    
    -- Verificar permissão
    if not VerificarPermissaoForum(source) then
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para atualizar documentos!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateDocumento', {success = false, error = "Sem permissão"})
        return
    end
    
    -- Verificar ID
    if not id then
        TriggerClientEvent('Notify', source, 'negado', 'ID do documento não fornecido!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateDocumento', {success = false, error = "ID não fornecido"})
        return
    end
    
    -- Verificar se o documento existe
    local docResult = exports.oxmysql:executeSync("SELECT * FROM oac_documentos WHERE id = ?", {id})
    
    if not docResult or #docResult == 0 then
        TriggerClientEvent('Notify', source, 'negado', 'Documento não encontrado!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateDocumento', {success = false, error = "Documento não encontrado"})
        return
    end
    
    -- Verificar se o usuário é o autor (ou tem permissão alta)
    local user_id = vRP.getUserId(source)
    local nivelPermissao = ObterNivelPermissao(source)
    
    if docResult[1].autor_id ~= tostring(user_id) and nivelPermissao < Config.NiveisPermissao.Diretor then
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para editar este documento!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateDocumento', {success = false, error = "Sem permissão de autor"})
        return
    end
    
    -- Preparar campos para atualização
    local campos = {}
    local valores = {}
    
    if data.tipo then
        table.insert(campos, "tipo = ?")
        table.insert(valores, data.tipo)
    end
    
    if data.status then
        table.insert(campos, "status = ?")
        table.insert(valores, data.status)
    end
    
    if data.titulo then
        table.insert(campos, "titulo = ?")
        table.insert(valores, data.titulo)
    end
    
    if data.conteudo ~= nil then
        table.insert(campos, "conteudo = ?")
        table.insert(valores, data.conteudo)
    end
    
    if data.envolvidos then
        table.insert(campos, "envolvidos = ?")
        table.insert(valores, json.encode(data.envolvidos))
    end
    
    if data.anexos then
        table.insert(campos, "anexos = ?")
        table.insert(valores, json.encode(data.anexos))
    end
    
    if data.assinatura then
        table.insert(campos, "assinatura = ?")
        table.insert(valores, json.encode(data.assinatura))
    end
    
    if data.referencias then
        table.insert(campos, "referencias = ?")
        table.insert(valores, json.encode(data.referencias))
    end
    
    if data.metadata then
        table.insert(campos, "metadata = ?")
        table.insert(valores, json.encode(data.metadata))
    end
    
    -- Se não há campos para atualizar
    if #campos == 0 then
        TriggerClientEvent('Notify', source, 'negado', 'Nenhum dado para atualizar!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateDocumento', {success = false, error = "Sem dados para atualizar"})
        return
    end
    
    -- Adicionar ID para a cláusula WHERE
    table.insert(valores, id)
    
    -- Executar atualização
    local success = exports.oxmysql:execute(
        "UPDATE oac_documentos SET " .. table.concat(campos, ", ") .. " WHERE id = ?",
        valores
    )
    
    -- Verificar resultado
    if success then
        -- Atualizar cache
        for i, doc in ipairs(Cache.Documentos) do
            if doc.id == id then
                -- Atualizar campos no cache
                for field, value in pairs(data) do
                    if field == "envolvidos" or field == "anexos" or field == "assinatura" or field == "referencias" or field == "metadata" then
                        Cache.Documentos[i][field] = json.encode(value)
                    else
                        Cache.Documentos[i][field] = value
                    end
                end
                break
            end
        end
        
        -- Registrar log
        LogAcao(source, "atualizar_documento", {
            id = id,
            campos_atualizados = campos
        })
        
        -- Notificar cliente
        TriggerClientEvent('Notify', source, 'sucesso', 'Documento atualizado com sucesso!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateDocumento', {
            success = true,
            message = "Documento atualizado com sucesso"
        })
    else
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao atualizar documento no banco de dados!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateDocumento', {
            success = false,
            error = "Erro ao atualizar documento no banco de dados"
        })
    end
end)

-- Evento para excluir documento
RegisterServerEvent('oac:deleteDocumento')
AddEventHandler('oac:deleteDocumento', function(id)
    local source = source
    
    -- Verificar permissão
    if not VerificarPermissaoForum(source) then
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para excluir documentos!', 5000)
        TriggerClientEvent('oac:callback', source, 'deleteDocumento', {success = false, error = "Sem permissão"})
        return
    end
    
    -- Verificar ID
    if not id then
        TriggerClientEvent('Notify', source, 'negado', 'ID do documento não fornecido!', 5000)
        TriggerClientEvent('oac:callback', source, 'deleteDocumento', {success = false, error = "ID não fornecido"})
        return
    end
    
    -- Verificar se o documento existe
    local docResult = exports.oxmysql:executeSync("SELECT * FROM oac_documentos WHERE id = ?", {id})
    
    if not docResult or #docResult == 0 then
        TriggerClientEvent('Notify', source, 'negado', 'Documento não encontrado!', 5000)
        TriggerClientEvent('oac:callback', source, 'deleteDocumento', {success = false, error = "Documento não encontrado"})
        return
    end
    
    -- Verificar se o usuário é o autor (ou tem permissão alta)
    local user_id = vRP.getUserId(source)
    local nivelPermissao = ObterNivelPermissao(source)
    
    if docResult[1].autor_id ~= tostring(user_id) and nivelPermissao < Config.NiveisPermissao.Diretor then
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para excluir este documento!', 5000)
        TriggerClientEvent('oac:callback', source, 'deleteDocumento', {success = false, error = "Sem permissão de autor"})
        return
    end
    
    -- Executar exclusão
    local success = exports.oxmysql:execute("DELETE FROM oac_documentos WHERE id = ?", {id})
    
    -- Verificar resultado
    if success then
        -- Atualizar cache
        for i, doc in ipairs(Cache.Documentos) do
            if doc.id == id then
                table.remove(Cache.Documentos, i)
                break
            end
        end
        
        -- Registrar log
        LogAcao(source, "excluir_documento", {
            id = id,
            titulo = docResult[1].titulo
        })
        
        -- Notificar cliente
        TriggerClientEvent('Notify', source, 'sucesso', 'Documento excluído com sucesso!', 5000)
        TriggerClientEvent('oac:callback', source, 'deleteDocumento', {
            success = true,
            message = "Documento excluído com sucesso"
        })
    else
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao excluir documento do banco de dados!', 5000)
        TriggerClientEvent('oac:callback', source, 'deleteDocumento', {
            success = false,
            error = "Erro ao excluir documento do banco de dados"
        })
    end
end)

-- Evento para assinar documento
RegisterServerEvent('oac:signDocumento')
AddEventHandler('oac:signDocumento', function(id, assinatura)
    local source = source
    
    -- Verificar permissão
    if not VerificarPermissaoForum(source) then
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para assinar documentos!', 5000)
        TriggerClientEvent('oac:callback', source, 'signDocumento', {success = false, error = "Sem permissão"})
        return
    end
    
    -- Verificar ID e assinatura
    if not id or not assinatura then
        TriggerClientEvent('Notify', source, 'negado', 'ID do documento ou assinatura não fornecidos!', 5000)
        TriggerClientEvent('oac:callback', source, 'signDocumento', {success = false, error = "Dados inválidos"})
        return
    end
    
    -- Verificar se o documento existe
    local docResult = exports.oxmysql:executeSync("SELECT * FROM oac_documentos WHERE id = ?", {id})
    
    if not docResult or #docResult == 0 then
        TriggerClientEvent('Notify', source, 'negado', 'Documento não encontrado!', 5000)
        TriggerClientEvent('oac:callback', source, 'signDocumento', {success = false, error = "Documento não encontrado"})
        return
    end
    
    -- Obter informações do jogador
    local user_id = vRP.getUserId(source)
    local identity = vRP.userIdentity(user_id)
    
    if not identity then
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao obter dados do jogador!', 5000)
        TriggerClientEvent('oac:callback', source, 'signDocumento', {success = false, error = "Erro de identidade"})
        return
    end
    
    -- Preparar dados da assinatura
    local assinaturaData = {
        id = user_id,
        nome = identity.name .. " " .. identity.name2,
        registration = identity.registration,
        data = os.date("%Y-%m-%d %H:%M:%S"),
        texto = assinatura.texto or "",
        cargo = assinatura.cargo or "",
        tipo = assinatura.tipo or "normal"
    }
    
    -- Obter assinaturas existentes
    local assinaturasAtuais = json.decode(docResult[1].assinatura or "[]")
    
    -- Verificar se já assinou
    for _, assina in ipairs(assinaturasAtuais) do
        if assina.id == assinaturaData.id then
            TriggerClientEvent('Notify', source, 'negado', 'Você já assinou este documento!', 5000)
            TriggerClientEvent('oac:callback', source, 'signDocumento', {success = false, error = "Já assinado"})
            return
        end
    end
    
    -- Adicionar nova assinatura
    table.insert(assinaturasAtuais, assinaturaData)
    
    -- Atualizar status do documento para "assinado"
    local status = "assinado"
    
    -- Executar atualização
    local success = exports.oxmysql:execute([[
        UPDATE oac_documentos 
        SET assinatura = ?, status = ? 
        WHERE id = ?
    ]], {
        json.encode(assinaturasAtuais),
        status,
        id
    })
    
    -- Verificar resultado
    if success then
        -- Atualizar cache
        for i, doc in ipairs(Cache.Documentos) do
            if doc.id == id then
                Cache.Documentos[i].assinatura = json.encode(assinaturasAtuais)
                Cache.Documentos[i].status = status
                break
            end
        end
        
        -- Registrar log
        LogAcao(source, "assinar_documento", {
            id = id,
            titulo = docResult[1].titulo
        })
        
        -- Notificar cliente
        TriggerClientEvent('Notify', source, 'sucesso', 'Documento assinado com sucesso!', 5000)
        TriggerClientEvent('oac:callback', source, 'signDocumento', {
            success = true,
            message = "Documento assinado com sucesso"
        })
    else
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao assinar documento!', 5000)
        TriggerClientEvent('oac:callback', source, 'signDocumento', {
            success = false,
            error = "Erro ao assinar documento no banco de dados"
        })
    end
end)

-- ====================================================
-- Eventos para Alta Ordem e Calendário
-- ====================================================

-- Callback para buscar eventos do calendário
RegisterCreativeCallback('oac:consultarEventosCalendario', function(source, data)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    -- Parâmetros de paginação e filtros
    local pagina = data and data.pagina or 1
    local porPagina = data and data.porPagina or 10
    local filtros = data and data.filtros or {}
    
    -- Registrar log da consulta
    LogAcao(source, "consultar_eventos_calendario", {
        filtros = filtros,
        pagina = pagina
    })
    
    -- Buscar do banco de dados
    local resultado = BuscarEventosBD(filtros, pagina, porPagina)
    
    return {
        success = true,
        eventos = resultado.eventos,
        total = resultado.total,
        pagina = resultado.pagina,
        totalPaginas = resultado.totalPaginas
    }
end)

-- Callback para buscar eventos próximos do calendário
RegisterCreativeCallback('oac:consultarEventosProximos', function(source)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    -- Obter data atual
    local dataAtual = os.date("%Y-%m-%d %H:%M:%S")
    
    -- Filtrar eventos que ainda não ocorreram
    local filtros = {
        data_inicio = dataAtual,
        status = "agendado"
    }
    
    -- Buscar próximos 5 eventos
    local resultado = BuscarEventosBD(filtros, 1, 5)
    
    return {
        success = true,
        eventos = resultado.eventos,
        total = resultado.total
    }
end)

-- Callback para buscar decisões da alta ordem
RegisterCreativeCallback('oac:consultarDecisoesAltaOrdem', function(source, data)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    -- Parâmetros de paginação e filtros
    local pagina = data and data.pagina or 1
    local porPagina = data and data.porPagina or 10
    local filtros = data and data.filtros or {}
    
    -- Registrar log da consulta
    LogAcao(source, "consultar_decisoes_alta_ordem", {
        filtros = filtros,
        pagina = pagina
    })
    
    -- Buscar do banco de dados
    local resultado = BuscarDecisoesAltaOrdemBD(filtros, pagina, porPagina)
    
    return {
        success = true,
        decisoes = resultado.decisoes,
        total = resultado.total,
        pagina = resultado.pagina,
        totalPaginas = resultado.totalPaginas
    }
end)

-- Callback para buscar decisões recentes da alta ordem
RegisterCreativeCallback('oac:consultarDecisoesRecentes', function(source)
    if not VerificarPermissaoForum(source) then
        return {success = false, error = "Sem permissão"}
    end
    
    -- Buscar últimas 5 decisões ativas
    local filtros = {
        status = "ativo"
    }
    
    -- Buscar decisões recentes
    local resultado = BuscarDecisoesAltaOrdemBD(filtros, 1, 5)
    
    return {
        success = true,
        decisoes = resultado.decisoes,
        total = resultado.total
    }
end)

-- ====================================================
-- Eventos para Alta Ordem e Calendário
-- ====================================================

-- Evento para criar evento no calendário
RegisterServerEvent('oac:createCalendarEvent')
AddEventHandler('oac:createCalendarEvent', function(data)
    local source = source
    
    -- Verificar permissão
    if not VerificarPermissaoAltaOrdem(source) then
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para criar eventos no calendário!', 5000)
        TriggerClientEvent('oac:callback', source, 'createCalendarEvent', {success = false, error = "Sem permissão"})
        return
    end
    
    -- Verificar dados
    if not data.titulo or not data.tipo or not data.dataInicio or not data.dataFim then
        TriggerClientEvent('Notify', source, 'negado', 'Dados incompletos para criação do evento!', 5000)
        TriggerClientEvent('oac:callback', source, 'createCalendarEvent', {success = false, error = "Dados incompletos"})
        return
    end
    
    -- Obter informações do jogador
    local user_id = vRP.getUserId(source)
    local identity = vRP.userIdentity(user_id)
    
    if not identity then
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao obter dados do jogador!', 5000)
        TriggerClientEvent('oac:callback', source, 'createCalendarEvent', {success = false, error = "Erro de identidade"})
        return
    end
    
    -- Gerar ID único para o evento
    local id = GerarId()
    
    -- Preparar dados para inserção
    local eventoData = {
        id = id,
        titulo = data.titulo,
        descricao = data.descricao or "",
        tipo = data.tipo,
        data_inicio = data.dataInicio,
        data_fim = data.dataFim,
        local = data.local or "",
        criado_por = tostring(user_id),
        criado_por_nome = identity.name .. " " .. identity.name2,
        participantes = data.participantes and json.encode(data.participantes) or "[]",
        status = data.status or "agendado",
        notas = data.notas or "",
        documentos_relacionados = data.documentos_relacionados and json.encode(data.documentos_relacionados) or "[]"
    }
    
    -- Inserir no banco de dados
    local success = exports.oxmysql:execute([[
        INSERT INTO oac_calendario 
        (id, titulo, descricao, tipo, data_inicio, data_fim, local, criado_por, criado_por_nome, participantes, status, notas, documentos_relacionados) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        eventoData.id,
        eventoData.titulo,
        eventoData.descricao,
        eventoData.tipo,
        eventoData.data_inicio,
        eventoData.data_fim,
        eventoData.local,
        eventoData.criado_por,
        eventoData.criado_por_nome,
        eventoData.participantes,
        eventoData.status,
        eventoData.notas,
        eventoData.documentos_relacionados
    })
    
    -- Verificar resultado
    if success then
        -- Adicionar ao cache
        table.insert(Cache.Calendario, 1, eventoData)
        
        -- Registrar log
        LogAcao(source, "criar_evento_calendario", {
            id = id,
            titulo = data.titulo,
            tipo = data.tipo,
            dataInicio = data.dataInicio
        })
        
        -- Notificar participantes
        NotificarParticipantesEvento(eventoData)
        
        -- Notificar cliente
        TriggerClientEvent('Notify', source, 'sucesso', 'Evento criado com sucesso!', 5000)
        TriggerClientEvent('oac:callback', source, 'createCalendarEvent', {
            success = true,
            message = "Evento criado com sucesso",
            id = id
        })
    else
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao criar evento no banco de dados!', 5000)
        TriggerClientEvent('oac:callback', source, 'createCalendarEvent', {
            success = false,
            error = "Erro ao criar evento no banco de dados"
        })
    end
end)

-- Evento para atualizar evento no calendário
RegisterServerEvent('oac:updateCalendarEvent')
AddEventHandler('oac:updateCalendarEvent', function(data)
    local source = source
    
    -- Verificar permissão
    if not VerificarPermissaoAltaOrdem(source) then
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para atualizar eventos!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateCalendarEvent', {success = false, error = "Sem permissão"})
        return
    end
    
    -- Verificar dados
    if not data.id then
        TriggerClientEvent('Notify', source, 'negado', 'ID do evento não fornecido!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateCalendarEvent', {success = false, error = "ID não fornecido"})
        return
    end
    
    -- Preparar campos para atualização
    local campos = {}
    local valores = {}
    
    if data.titulo then
        table.insert(campos, "titulo = ?")
        table.insert(valores, data.titulo)
    end
    
    if data.descricao then
        table.insert(campos, "descricao = ?")
        table.insert(valores, data.descricao)
    end
    
    if data.dataInicio then
        table.insert(campos, "data_inicio = ?")
        table.insert(valores, data.dataInicio)
    end
    
    if data.dataFim then
        table.insert(campos, "data_fim = ?")
        table.insert(valores, data.dataFim)
    end
    
    if data.local then
        table.insert(campos, "local = ?")
        table.insert(valores, data.local)
    end
    
    if data.status then
        table.insert(campos, "status = ?")
        table.insert(valores, data.status)
    end
    
    if data.notas then
        table.insert(campos, "notas = ?")
        table.insert(valores, data.notas)
    end
    
    if data.participantes then
        table.insert(campos, "participantes = ?")
        table.insert(valores, json.encode(data.participantes))
    end
    
    if data.documentos_relacionados then
        table.insert(campos, "documentos_relacionados = ?")
        table.insert(valores, json.encode(data.documentos_relacionados))
    end
    
    -- Se não há campos para atualizar
    if #campos == 0 then
        TriggerClientEvent('Notify', source, 'negado', 'Nenhum dado para atualizar!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateCalendarEvent', {success = false, error = "Sem dados para atualizar"})
        return
    end
    
    -- Adicionar atualização de updated_at
    table.insert(campos, "updated_at = NOW()")
    
    -- Adicionar ID para a cláusula WHERE
    table.insert(valores, data.id)
    
    -- Executar atualização
    local success = exports.oxmysql:execute(
        "UPDATE oac_calendario SET " .. table.concat(campos, ", ") .. " WHERE id = ?",
        valores
    )
    
    -- Verificar resultado
    if success then
        -- Verificar se houve alteração no evento para notificar participantes
        local eventoResult = exports.oxmysql:executeSync("SELECT * FROM oac_calendario WHERE id = ?", {data.id})
        
        if eventoResult and #eventoResult > 0 then
            -- Notificar participantes sobre a atualização
            NotificarParticipantesEventoAlterado(eventoResult[1])
        end
        
        -- Registrar log
        LogAcao(source, "atualizar_evento_calendario", {
            id = data.id,
            campos_atualizados = campos
        })
        
        -- Notificar cliente
        TriggerClientEvent('Notify', source, 'sucesso', 'Evento atualizado com sucesso!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateCalendarEvent', {
            success = true,
            message = "Evento atualizado com sucesso"
        })
    else
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao atualizar evento no banco de dados!', 5000)
        TriggerClientEvent('oac:callback', source, 'updateCalendarEvent', {
            success = false,
            error = "Erro ao atualizar evento no banco de dados"
        })
    end
end)

-- Evento para criar decisão da alta ordem
RegisterServerEvent('oac:createAltaOrdemDecisao')
AddEventHandler('oac:createAltaOrdemDecisao', function(data)
    local source = source
    
    -- Verificar permissão
    if not VerificarPermissaoAltaOrdem(source) then
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para criar decisões da Alta Ordem!', 5000)
        TriggerClientEvent('oac:callback', source, 'createAltaOrdemDecisao', {success = false, error = "Sem permissão"})
        return
    end
    
    -- Verificar dados
    if not data.tipo or not data.titulo or not data.conteudo then
        TriggerClientEvent('Notify', source, 'negado', 'Dados incompletos para criação da decisão!', 5000)
        TriggerClientEvent('oac:callback', source, 'createAltaOrdemDecisao', {success = false, error = "Dados incompletos"})
        return
    end
    
    -- Obter informações do jogador
    local user_id = vRP.getUserId(source)
    local identity = vRP.userIdentity(user_id)
    
    if not identity then
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao obter dados do jogador!', 5000)
        TriggerClientEvent('oac:callback', source, 'createAltaOrdemDecisao', {success = false, error = "Erro de identidade"})
        return
    end
    
    -- Gerar ID único para a decisão
    local id = GerarId()
    
    -- Preparar data efetiva (se fornecida ou agora)
    local dataEfetiva = data.dataEfetiva or os.date("%Y-%m-%d %H:%M:%S")
    
    -- Preparar dados para inserção
    local decisaoData = {
        id = id,
        tipo = data.tipo,
        titulo = data.titulo,
        conteudo = data.conteudo,
        autor_id = tostring(user_id),
        autor_nome = identity.name .. " " .. identity.name2,
        data_efetiva = dataEfetiva,
        status = data.status or "ativo",
        referencias = data.referencias and json.encode(data.referencias) or "[]"
    }
    
    -- Inserir no banco de dados
    local success = exports.oxmysql:execute([[
        INSERT INTO oac_alta_ordem 
        (id, tipo, titulo, conteudo, autor_id, autor_nome, data_efetiva, status, referencias) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        decisaoData.id,
        decisaoData.tipo,
        decisaoData.titulo,
        decisaoData.conteudo,
        decisaoData.autor_id,
        decisaoData.autor_nome,
        decisaoData.data_efetiva,
        decisaoData.status,
        decisaoData.referencias
    })
    
    -- Verificar resultado
    if success then
        -- Adicionar ao cache
        table.insert(Cache.AltaOrdem, 1, decisaoData)
        
        -- Registrar log
        LogAcao(source, "criar_decisao_alta_ordem", {
            id = id,
            tipo = data.tipo,
            titulo = data.titulo
        })
        
        -- Notificar todos os advogados online
        NotificarNovaDecisaoAltaOrdem(decisaoData)
        
        -- Notificar cliente
        TriggerClientEvent('Notify', source, 'sucesso', 'Decisão criada com sucesso!', 5000)
        TriggerClientEvent('oac:callback', source, 'createAltaOrdemDecisao', {
            success = true,
            message = "Decisão criada com sucesso",
            id = id
        })
    else
        TriggerClientEvent('Notify', source, 'negado', 'Erro ao criar decisão no banco de dados!', 5000)
        TriggerClientEvent('oac:callback', source, 'createAltaOrdemDecisao', {
            success = false,
            error = "Erro ao criar decisão no banco de dados"
        })
    end
end)

-- Funções para notificações de eventos e decisões
function NotificarParticipantesEvento(evento)
    -- Se não houver participantes, retornar
    if not evento.participantes or evento.participantes == "[]" then
        return
    end
    
    -- Decodificar lista de participantes
    local participantes = json.decode(evento.participantes)
    
    -- Notificar cada participante que estiver online
    for _, participante in ipairs(participantes) do
        local id = tonumber(participante.id)
        if id then
            local playerSource = vRP.getUserSource(id)
            if playerSource then
                -- Formatar data do evento para exibição
                local dataEvento = string.sub(evento.data_inicio, 1, 16)
                
                -- Notificar sobre o evento
                TriggerClientEvent('Notify', playerSource, 'aviso', 'Você foi adicionado a um evento!', 10000)
                TriggerClientEvent('oac:notification', playerSource, {
                    type = "info",
                    title = "Novo Evento no Calendário",
                    message = evento.titulo .. " - " .. dataEvento,
                    icon = "calendar"
                })
            end
        end
    end
end

function NotificarParticipantesEventoAlterado(evento)
    -- Se não houver participantes, retornar
    if not evento.participantes or evento.participantes == "[]" then
        return
    end
    
    -- Decodificar lista de participantes
    local participantes = json.decode(evento.participantes)
    
    -- Notificar cada participante que estiver online
    for _, participante in ipairs(participantes) do
        local id = tonumber(participante.id)
        if id then
            local playerSource = vRP.getUserSource(id)
            if playerSource then
                -- Formatar data do evento para exibição
                local dataEvento = string.sub(evento.data_inicio, 1, 16)
                
                -- Notificar sobre a alteração
                TriggerClientEvent('Notify', playerSource, 'aviso', 'Um evento do calendário foi alterado!', 10000)
                TriggerClientEvent('oac:notification', playerSource, {
                    type = "warning",
                    title = "Evento Atualizado",
                    message = evento.titulo .. " - " .. dataEvento,
                    icon = "calendar-edit"
                })
            end
        end
    end
end

function NotificarNovaDecisaoAltaOrdem(decisao)
    -- Obter todos os jogadores online
    local players = GetPlayers()
    
    for _, playerId in ipairs(players) do
        -- Verificar se tem permissão do fórum
        if VerificarPermissaoForum(tonumber(playerId)) then
            -- Enviar notificação
            TriggerClientEvent('Notify', tonumber(playerId), 'aviso', 'Nova decisão da Alta Ordem publicada!', 10000)
            TriggerClientEvent('oac:notification', tonumber(playerId), {
                type = "info",
                title = "Nova Decisão da Alta Ordem",
                message = decisao.titulo,
                icon = "gavel"
            })
        end
    end
end

-- ====================================================
-- Inicialização do sistema
-- ====================================================

-- Inicialização do servidor
Citizen.CreateThread(function()
    -- Inicializar banco de dados
    InicializarBancoDados()
    
    -- Carregar dados
    LogInfo("Iniciando carregamento de dados...")
    
    CarregarLeis()
    CarregarPassaportes()
    CarregarDocumentos()
    CarregarUsuarios()
    CarregarProcessos()
    CarregarEventosCalendario()
    CarregarDecisoesAltaOrdem()
    
    LogInfo("Carregamento de dados concluído.")
    
    -- Agendar tarefas automáticas
    AgendarTarefasAutomaticas()
    
    -- Sincronizar dados com clientes conectados na inicialização
    Citizen.Wait(10000) -- Esperar 10 segundos para garantir que os clientes estejam conectados
    SincronizarDadosComClientes()
    
    LogInfo("Sistema OAC inicializado com sucesso!")
end)

-- Comando para recarregar os dados
RegisterCommand("oac_reload", function(source, args)
    -- Verificar se é administrador
    local user_id = vRP.getUserId(source)
    if source == 0 or vRP.hasPermission(user_id, "admin.permissao") then
        -- Recarregar dados
        CarregarLeis()
        CarregarPassaportes()
        CarregarDocumentos()
        CarregarUsuarios()
        CarregarProcessos()
        CarregarEventosCalendario()
        CarregarDecisoesAltaOrdem()
        
        -- Sincronizar com clientes
        SincronizarDadosComClientes()
        
        -- Notificar
        if source > 0 then
            TriggerClientEvent('Notify', source, 'sucesso', 'Sistema OAC recarregado com sucesso!', 5000)
        else
            LogInfo("Sistema OAC recarregado com sucesso!")
        end
    else
        TriggerClientEvent('Notify', source, 'negado', 'Você não tem permissão para usar este comando!', 5000)
    end
end, false)

-- Exportar funções úteis para outros recursos
exports("VerificarPermissaoForum", VerificarPermissaoForum)
exports("VerificarPermissaoAltaOrdem", VerificarPermissaoAltaOrdem)
exports("ObterNivelPermissao", ObterNivelPermissao)
exports("BuscarDocumentosBD", BuscarDocumentosBD)
exports("LogAcao", LogAcao)
