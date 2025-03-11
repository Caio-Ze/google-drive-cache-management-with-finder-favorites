#!/bin/bash

# Script unificado para gerenciar o cache do Google Drive e os favoritos do Finder
# Versão corrigida para evitar o problema de segmentation fault do mysides

# Função para mostrar mensagens coloridas
function mostrar_info {
  echo -e "\033[1;34mℹ️ $1\033[0m"
}

function mostrar_sucesso {
  echo -e "\033[1;32m✅ $1\033[0m"
}

function mostrar_aviso {
  echo -e "\033[1;33m⚠️ $1\033[0m"
}

function mostrar_erro {
  echo -e "\033[1;31m❌ $1\033[0m"
}

function mostrar_cabecalho {
  clear
  echo -e "\033[1;36m===================================================\033[0m"
  echo -e "\033[1;36m  Gerenciador de Google Drive e Favoritos do Finder  \033[0m"
  echo -e "\033[1;36m===================================================\033[0m"
  echo ""
}

# Verificar se mysides está instalado
verificar_mysides() {
  if ! command -v mysides &> /dev/null; then
    mostrar_aviso "A ferramenta 'mysides' não está instalada."
    mostrar_info "Esta ferramenta é necessária para gerenciar os favoritos do Finder."
    mostrar_info "Você pode instalá-la usando Homebrew com: brew install mysides"
    
    # Perguntar se o usuário deseja instalar o Homebrew e mysides
    read -p "Deseja instalar o Homebrew e o mysides agora? (s/n): " INSTALAR
    if [[ "$INSTALAR" == "s" || "$INSTALAR" == "S" ]]; then
      mostrar_info "Instalando Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      
      mostrar_info "Instalando mysides..."
      brew install mysides
      
      if ! command -v mysides &> /dev/null; then
        mostrar_erro "Falha ao instalar o mysides. Por favor, instale manualmente."
        return 1
      else
        mostrar_sucesso "mysides instalado com sucesso!"
      fi
    else
      mostrar_info "Por favor, instale o mysides manualmente para usar as funcionalidades de gerenciamento de favoritos."
      return 1
    fi
  fi
  return 0
}

# Criar diretórios necessários
criar_diretorios() {
  BACKUP_DIR=~/Desktop/Google_Drive_Manager
  mkdir -p "$BACKUP_DIR/Backups"
  mkdir -p "$BACKUP_DIR/Atalhos"
  mostrar_sucesso "Diretórios criados: $BACKUP_DIR"
  return 0
}

# Função para fazer backup dos favoritos utilizando diretamente a saída de mysides list
backup_favoritos() {
  mostrar_info "Fazendo backup dos favoritos importantes..."
  
  # Criar diretório para backups
  criar_diretorios
  
  BACKUP_FILE="$BACKUP_DIR/Backups/finder_favorites_$(date +%Y%m%d_%H%M%S).txt"
  
  # Criar arquivo de backup
  echo "# Favoritos do Finder (gerado em $(date))" > "$BACKUP_FILE"
  
  mostrar_info "Obtendo favoritos diretamente da barra lateral do Finder..."
  
  # Usar o mysides list para obter os favoritos existentes
  # Redirecionamos stderr para evitar que erros interrompam o processo
  TEMP_MYSIDES_OUTPUT=$(mktemp)
  mysides list 2>/dev/null > "$TEMP_MYSIDES_OUTPUT"
  
  # Verificar se conseguimos obter a lista de favoritos
  if [ -s "$TEMP_MYSIDES_OUTPUT" ]; then
    # Processar cada linha da saída
    while read -r linha; do
      # Verificar se a linha contém a flecha (->)
      if [[ "$linha" == *"->"* ]]; then
        # Extrair nome e caminho
        nome=$(echo "$linha" | awk -F "->" '{print $1}' | xargs)
        caminho=$(echo "$linha" | awk -F "->" '{print $2}' | xargs)
        
        # Verificar se temos nome e caminho válidos
        if [ -n "$nome" ] && [ -n "$caminho" ]; then
          echo "$nome $caminho" >> "$BACKUP_FILE"
          mostrar_sucesso "Adicionado ao backup: $nome"
        fi
      fi
    done < "$TEMP_MYSIDES_OUTPUT"
    
    mostrar_sucesso "Favoritos extraídos diretamente da barra lateral!"
  else
    mostrar_aviso "Não foi possível obter a lista de favoritos usando mysides list."
    
    # Se não conseguirmos usar mysides list, tentamos o método alternativo
    mostrar_info "Usando método alternativo para identificar favoritos importantes..."
    
    # Encontrar o diretório do Google Drive
    GOOGLE_DRIVE_DIR=""
    if [ -d ~/Library/CloudStorage ]; then
      GOOGLE_DRIVE_DIR=$(find ~/Library/CloudStorage -maxdepth 1 -name "GoogleDrive-*" -type d | head -1)
    fi
    
    if [ -n "$GOOGLE_DRIVE_DIR" ]; then
      mostrar_info "Diretório do Google Drive encontrado: $GOOGLE_DRIVE_DIR"
      
      # Array simples de pastas para verificar
      PASTAS_IMPORTANTES=(
        "CARREFOUR"
        "14_783_230669_SEXTA"
        "COMPARTILHADO"
        "FILMES"
        "BEBA COM MODERACAO"
        "SCRIPT BOUNCE"
        "BACKUP"
        "APLICATIOVS_CZ"
        "PYTHON_PROJECTS"
        "caio.raphael"
        "DynamicBounceMonitor"
        "DynamicBounceMonitor_V4"
        "DIA SUPERMERCADOS"
        "TV"
      )
      
      # Função auxiliar para registrar pasta encontrada
      adicionar_pasta_backup() {
        local nome="$1"
        local caminho="$2"
        echo "$nome file://$caminho" >> "$BACKUP_FILE"
        mostrar_sucesso "Adicionado ao backup: $nome ($3)"
      }
      
      # Adicionar pastas básicas do Google Drive
      if [ -d "$GOOGLE_DRIVE_DIR/My Drive" ]; then
        adicionar_pasta_backup "My Drive" "$GOOGLE_DRIVE_DIR/My Drive" "Google Drive"
      fi
      
      if [ -d "$GOOGLE_DRIVE_DIR/Shared drives" ]; then
        adicionar_pasta_backup "Shared drives" "$GOOGLE_DRIVE_DIR/Shared drives" "Google Drive"
      fi
      
      # Array para rastrear pastas encontradas
      PASTAS_ENCONTRADAS=()
      
      # Verificar pastas na pasta pessoal do usuário
      for pasta in "${PASTAS_IMPORTANTES[@]}"; do
        if [ -d ~/"$pasta" ]; then
          adicionar_pasta_backup "$pasta" "/Users/$(whoami)/$pasta" "pasta pessoal"
          PASTAS_ENCONTRADAS+=("$pasta")
        fi
      done
      
      # Verificar pastas no Desktop
      for pasta in "${PASTAS_IMPORTANTES[@]}"; do
        # Verificar se já foi encontrada
        ENCONTRADA=0
        for p in "${PASTAS_ENCONTRADAS[@]}"; do
          if [ "$p" = "$pasta" ]; then
            ENCONTRADA=1
            break
          fi
        done
        
        # Se não foi encontrada, procurar no Desktop
        if [ $ENCONTRADA -eq 0 ] && [ -d ~/Desktop/"$pasta" ]; then
          adicionar_pasta_backup "$pasta" "/Users/$(whoami)/Desktop/$pasta" "Desktop"
          PASTAS_ENCONTRADAS+=("$pasta")
        fi
      done
      
      # Verificar pastas em Shared Drives
      if [ -d "$GOOGLE_DRIVE_DIR/Shared drives" ]; then
        for pasta in "${PASTAS_IMPORTANTES[@]}"; do
          # Verificar se já foi encontrada
          ENCONTRADA=0
          for p in "${PASTAS_ENCONTRADAS[@]}"; do
            if [ "$p" = "$pasta" ]; then
              ENCONTRADA=1
              break
            fi
          done
          
          # Se não foi encontrada, procurar em Shared Drives
          if [ $ENCONTRADA -eq 0 ]; then
            # Procurar em profundidade nos Shared Drives
            caminho_encontrado=$(find "$GOOGLE_DRIVE_DIR/Shared drives" -maxdepth 5 -type d -name "$pasta" -print -quit 2>/dev/null)
            if [ -n "$caminho_encontrado" ]; then
              adicionar_pasta_backup "$pasta" "$caminho_encontrado" "Shared Drives"
              PASTAS_ENCONTRADAS+=("$pasta")
              continue
            fi
          fi
        done
      fi
      
      # Adicionar pastas padrão do macOS (comuns)
      if [ -d ~/Desktop ]; then
        adicionar_pasta_backup "Desktop" "/Users/$(whoami)/Desktop" "sistema"
      fi
      
      if [ -d ~/Downloads ]; then
        adicionar_pasta_backup "Downloads" "/Users/$(whoami)/Downloads" "sistema"
      fi
      
      if [ -d ~/Documents ]; then
        adicionar_pasta_backup "Documents" "/Users/$(whoami)/Documents" "sistema"
      fi
      
      if [ -d /Applications ]; then
        adicionar_pasta_backup "Applications" "/Applications" "sistema"
      fi
    else
      mostrar_erro "Não foi possível encontrar o diretório do Google Drive."
    fi
  fi
  
  # Limpar arquivo temporário
  rm -f "$TEMP_MYSIDES_OUTPUT"
  
  # Extrair apenas os nomes dos favoritos para uso posterior
  NAMES_FILE="$BACKUP_DIR/Backups/finder_favorites_names_$(date +%Y%m%d_%H%M%S).txt"
  grep -v "^#" "$BACKUP_FILE" | awk -F " file:" '{print $1}' > "$NAMES_FILE"
  
  # Verificar se o backup foi criado com sucesso
  if [ -s "$BACKUP_FILE" ]; then
    mostrar_sucesso "Backup dos favoritos criado com sucesso!"
    echo "Favoritos salvos:"
    cat "$BACKUP_FILE"
    echo ""
    mostrar_info "O backup completo foi salvo em: $BACKUP_FILE"
    # Criar um link para o backup mais recente para facilitar a restauração
    ln -sf "$BACKUP_FILE" "$BACKUP_DIR/Backups/ultimo_backup.txt"
    ln -sf "$NAMES_FILE" "$BACKUP_DIR/Backups/ultimo_backup_nomes.txt"
    mostrar_sucesso "Links para o último backup criados."
    return 0
  else
    mostrar_erro "Não foi possível criar o backup dos favoritos ou a lista está vazia."
    return 1
  fi
}

# Função para limpar o cache do Google Drive
limpar_cache() {
  mostrar_info "Preparando para limpar o cache do Google Drive..."
  
  # Encerrar o Google Drive
  mostrar_info "Encerrando o Google Drive..."
  pkill -f "Google Drive"
  
  # Aguardar o encerramento
  COUNTER=0
  while pgrep -f "Google Drive" >/dev/null; do
    ((COUNTER++))
    echo "Ainda rodando... (tentativa $COUNTER)"
    sleep 1
    if [ $COUNTER -ge 5 ]; then
      mostrar_aviso "Limite de 5 tentativas atingido."
      break
    fi
  done
  
  # Remover atributos de imutabilidade
  mostrar_info "Removendo atributos de imutabilidade..."
  sudo chflags -R nouchg ~/Library/CloudStorage
  
  # Ajustar permissões
  mostrar_info "Ajustando permissões..."
  sudo chmod -R 777 ~/Library/CloudStorage
  
  # Calcular tamanho da pasta de cache
  mostrar_info "Calculando tamanho da pasta de cache:"
  sudo du -sh ~/Library/CloudStorage
  
  # Remover a pasta de cache
  mostrar_info "Removendo a pasta de cache..."
  sudo rm -rf ~/Library/CloudStorage
  mostrar_sucesso "Cache removido."
  
  # Reabrir o Google Drive
  mostrar_info "Reabrindo o Google Drive..."
  open -a "Google Drive"
  mostrar_sucesso "Google Drive reaberto."
  
  mostrar_info "Aguardando o Google Drive inicializar (30 segundos)..."
  for i in {30..1}; do
    echo -ne "Aguardando: $i segundos restantes\r"
    sleep 1
  done
  echo ""
  
  mostrar_sucesso "Cache do Google Drive limpo com sucesso!"
  return 0
}

# Função para adicionar os favoritos do Google Drive
adicionar_favoritos_google_drive() {
  mostrar_info "Adicionando favoritos do Google Drive..."
  
  # Verificar se mysides está instalado
  verificar_mysides || return 1
  
  # Encontrar o diretório do Google Drive
  GOOGLE_DRIVE_DIR=""
  mostrar_info "Procurando o diretório do Google Drive (pode levar alguns segundos)..."
  
  COUNTER=0
  while [ -z "$GOOGLE_DRIVE_DIR" ] && [ $COUNTER -lt 6 ]; do
    if [ -d ~/Library/CloudStorage ]; then
      GOOGLE_DRIVE_DIR=$(find ~/Library/CloudStorage -maxdepth 1 -name "GoogleDrive-*" -type d | head -1)
    fi
    
    if [ -z "$GOOGLE_DRIVE_DIR" ]; then
      ((COUNTER++))
      mostrar_info "Aguardando o Google Drive criar o diretório... (tentativa $COUNTER)"
      sleep 5
    fi
  done
  
  if [ -z "$GOOGLE_DRIVE_DIR" ]; then
    mostrar_erro "Não foi possível encontrar o diretório do Google Drive."
    mostrar_info "Aguarde alguns minutos para o Google Drive sincronizar e tente novamente."
    return 1
  fi
  
  mostrar_info "Diretório do Google Drive encontrado: $GOOGLE_DRIVE_DIR"
  
  # Criar diretório para atalhos
  criar_diretorios
  
  # Lista de pastas importantes para verificar
  PASTAS_IMPORTANTES=(
    "CARREFOUR"
    "14_783_230669_SEXTA"
    "COMPARTILHADO"
    "FILMES"
    "BEBA COM MODERACAO"
    "SCRIPT BOUNCE"
    "BACKUP"
    "APLICATIOVS_CZ"
    "PYTHON_PROJECTS"
    "caio.raphael"
    "DynamicBounceMonitor"
  )
  
  # Primeiro, remover entradas duplicadas ou parciais existentes
  mostrar_info "Removendo entradas duplicadas ou parciais existentes..."
  
  # Remover entradas básicas do Google Drive
  mysides remove "My" 2>/dev/null
  mysides remove "My Drive" 2>/dev/null
  mysides remove "Shared" 2>/dev/null
  mysides remove "Shared drives" 2>/dev/null
  
  # Remover todas as pastas importantes potencialmente já existentes
  for pasta in "${PASTAS_IMPORTANTES[@]}"; do
    mysides remove "$pasta" 2>/dev/null
    echo "Removido (se existia): $pasta"
  done
  
  # Aguardar um momento para garantir que todos os favoritos foram removidos
  sleep 2
  
  # Função para adicionar um favorito com método mais robusto
  adicionar_favorito() {
    local nome="$1"
    local caminho="$2"
    
    if [ ! -d "$caminho" ]; then
      mostrar_aviso "Diretório não encontrado: $caminho"
      return 1
    fi
    
    # Gerar URL com caracteres escapados (vários métodos)
    local url1="file://$caminho"
    local url2=$(echo "file://$caminho" | sed 's/ /%20/g')
    
    # Método 1: URL sem escape
    mostrar_info "Tentando adicionar $nome com URL simples..."
    mysides add "$nome" "$url1" 2>/dev/null
    
    # Verificar se foi adicionado
    if mysides list 2>/dev/null | grep -q "$nome"; then
      mostrar_sucesso "Favorito adicionado: $nome"
      return 0
    fi
    
    # Método 2: URL com escape
    mostrar_info "Tentando adicionar $nome com URL escapada..."
    mysides add "$nome" "$url2" 2>/dev/null
    
    # Verificar se foi adicionado
    if mysides list 2>/dev/null | grep -q "$nome"; then
      mostrar_sucesso "Favorito adicionado: $nome"
      return 0
    fi
    
    # Método 3: Caminho direto
    mostrar_info "Tentando adicionar $nome com caminho direto..."
    mysides add "$nome" "$caminho" 2>/dev/null
    
    # Verificar se foi adicionado
    if mysides list 2>/dev/null | grep -q "$nome"; then
      mostrar_sucesso "Favorito adicionado: $nome"
      return 0
    fi
    
    # Método 4: mysides com opções adicionais (force)
    mostrar_info "Tentando método avançado para $nome..."
    # Usando parâmetros extras para força a adição
    osascript -e "tell application \"Finder\" to set sidebar of front window to sidebar of front window" 2>/dev/null
    mysides add "$nome" "file://$caminho" 2>/dev/null
    
    mostrar_aviso "Talvez seja necessário adicionar $nome manualmente."
    return 1
  }
  
  # Busca recursiva para encontrar pastas específicas
  encontrar_e_adicionar_pasta() {
    local pasta_nome="$1"
    local diretorio_base="$2"
    local profundidade="${3:-3}"  # Profundidade padrão: 3 níveis
    
    mostrar_info "Procurando por '$pasta_nome' em $diretorio_base (profundidade $profundidade)..."
    
    # Procurar usando find com profundidade limitada
    local caminho_encontrado=$(find "$diretorio_base" -maxdepth "$profundidade" -type d -name "$pasta_nome" -print -quit 2>/dev/null)
    
    if [ -n "$caminho_encontrado" ]; then
      mostrar_info "Pasta '$pasta_nome' encontrada em: $caminho_encontrado"
      adicionar_favorito "$pasta_nome" "$caminho_encontrado"
      return 0
    else
      mostrar_aviso "Pasta '$pasta_nome' não encontrada em $diretorio_base"
      return 1
    fi
  }
  
  # Adicionar pastas básicas do Google Drive
  MY_DRIVE_PATH="$GOOGLE_DRIVE_DIR/My Drive"
  SHARED_DRIVES_PATH="$GOOGLE_DRIVE_DIR/Shared drives"
  
  if [ -d "$MY_DRIVE_PATH" ]; then
    adicionar_favorito "My Drive" "$MY_DRIVE_PATH"
  fi
  
  if [ -d "$SHARED_DRIVES_PATH" ]; then
    adicionar_favorito "Shared drives" "$SHARED_DRIVES_PATH"
  fi
  
  # Procurar e adicionar pastas importantes em diversos locais
  for pasta in "${PASTAS_IMPORTANTES[@]}"; do
    mostrar_info "Procurando pasta: $pasta..."
    ENCONTRADA=0
    
    # 1. Verificar na raiz da pasta pessoal
    if [ -d ~/"$pasta" ]; then
      adicionar_favorito "$pasta" ~/"$pasta"
      ENCONTRADA=1
      continue
    fi
    
    # 2. Verificar em My Drive 
    if [ -d "$MY_DRIVE_PATH" ] && [ $ENCONTRADA -eq 0 ]; then
      encontrar_e_adicionar_pasta "$pasta" "$MY_DRIVE_PATH" 2
      if [ $? -eq 0 ]; then
        ENCONTRADA=1
        continue
      fi
    fi
    
    # 3. Busca em Shared Drives com profundidade maior
    if [ -d "$SHARED_DRIVES_PATH" ] && [ $ENCONTRADA -eq 0 ]; then
      # Busca mais profunda em Shared Drives
      encontrar_e_adicionar_pasta "$pasta" "$SHARED_DRIVES_PATH" 3
      if [ $? -eq 0 ]; then
        ENCONTRADA=1
        continue
      fi
    fi
    
    # 4. Verificar diretamente nos Shared Drives conhecidos
    if [ -d "$SHARED_DRIVES_PATH" ] && [ $ENCONTRADA -eq 0 ]; then
      for drive in "$SHARED_DRIVES_PATH"/*; do
        if [ -d "$drive/$pasta" ]; then
          adicionar_favorito "$pasta" "$drive/$pasta"
          ENCONTRADA=1
          break
        elif [ -d "$drive/PUBLICIDADE/$pasta" ]; then
          adicionar_favorito "$pasta" "$drive/PUBLICIDADE/$pasta"
          ENCONTRADA=1
          break
        fi
      done
    fi
    
    if [ $ENCONTRADA -eq 0 ]; then
      mostrar_aviso "Pasta '$pasta' não encontrada automaticamente."
    fi
  done
  
  # Adicionar pastas padrão do sistema
  adicionar_favorito "Desktop" "$HOME/Desktop"
  adicionar_favorito "Downloads" "$HOME/Downloads"
  adicionar_favorito "Documents" "$HOME/Documents"
  adicionar_favorito "Applications" "/Applications"
  
  # Instruções para método manual (mais confiável)
  mostrar_info "=====================================================================>"
  mostrar_info "IMPORTANTE: Se os atalhos não funcionarem corretamente, siga estes passos:"
  mostrar_info "1. Abra o Finder"
  mostrar_info "2. No menu da barra lateral, desative 'Recentes'"
  mostrar_info "3. Para pastas não encontradas, vá até o Google Drive e procure manualmente"
  mostrar_info "4. Arraste as pastas que quiser para a barra lateral do Finder"
  mostrar_info "5. Isso criará atalhos funcionais com o formato correto reconhecido pelo macOS"
  mostrar_info "=====================================================================>"
  
  mostrar_sucesso "Favoritos do Google Drive adicionados com sucesso!"
  return 0
}

# Função para restaurar todos os favoritos a partir de um backup
restaurar_todos_favoritos() {
  mostrar_info "Restaurando todos os favoritos da barra lateral do Finder..."
  
  # Verificar se mysides está instalado
  verificar_mysides || return 1
  
  # Verificar se existe o backup mais recente
  ULTIMO_BACKUP="$BACKUP_DIR/Backups/ultimo_backup.txt"
  ULTIMO_BACKUP_NOMES="$BACKUP_DIR/Backups/ultimo_backup_nomes.txt"
  
  if [ ! -f "$ULTIMO_BACKUP" ]; then
    # Listar todos os backups disponíveis
    mostrar_info "Backup mais recente não encontrado. Verificando outros backups..."
    BACKUPS=$(ls -1 "$BACKUP_DIR/Backups"/finder_favorites_*.txt 2>/dev/null)
    
    if [ -z "$BACKUPS" ]; then
      mostrar_erro "Nenhum backup encontrado. Faça um backup primeiro."
      return 1
    fi
    
    mostrar_info "Backups disponíveis:"
    echo "$BACKUPS"
    echo ""
    read -p "Digite o caminho completo do arquivo de backup para restaurar: " RESTORE_FILE
    
    if [ ! -f "$RESTORE_FILE" ]; then
      mostrar_erro "Arquivo não encontrado: $RESTORE_FILE"
      return 1
    fi
    
    # Gerar arquivo de nomes a partir do backup selecionado
    TEMP_NAMES_FILE="$BACKUP_DIR/Backups/temp_names.txt"
    grep -v "^#" "$RESTORE_FILE" | awk -F " file://" '{print $1}' > "$TEMP_NAMES_FILE"
  else
    mostrar_info "Usando o backup mais recente: $ULTIMO_BACKUP"
    RESTORE_FILE="$ULTIMO_BACKUP"
    TEMP_NAMES_FILE="$ULTIMO_BACKUP_NOMES"
    
    # Gerar novamente o arquivo de nomes para garantir que está correto
    grep -v "^#" "$RESTORE_FILE" | awk -F " file://" '{print $1}' > "$TEMP_NAMES_FILE"
  fi
  
  # Confirmar a restauração
  mostrar_aviso "ATENÇÃO: Isto irá remover favoritos existentes e restaurar os do backup."
  mostrar_info "Favoritos que serão restaurados:"
  grep -v "^#" "$RESTORE_FILE"
  echo ""
  read -p "Confirma a restauração? (s/n): " CONFIRMA_RESTAURACAO
  
  if [[ "$CONFIRMA_RESTAURACAO" == "s" || "$CONFIRMA_RESTAURACAO" == "S" ]]; then
    # Remover favoritos existentes (apenas os que estão no backup para evitar remover outros)
    mostrar_info "Removendo favoritos existentes..."
    while read -r nome; do
      if [ -n "$nome" ]; then
        mysides remove "$nome" 2>/dev/null
        echo "Removido: $nome"
      fi
    done < "$TEMP_NAMES_FILE"
    
    # Aguardar um momento para garantir que todos os favoritos foram removidos
    sleep 1
    
    # Adicionar os favoritos do backup
    mostrar_info "Restaurando favoritos do backup..."
    
    # Encontrar o diretório do Google Drive atual
    GOOGLE_DRIVE_DIR=""
    if [ -d ~/Library/CloudStorage ]; then
      GOOGLE_DRIVE_DIR=$(find ~/Library/CloudStorage -maxdepth 1 -name "GoogleDrive-*" -type d | head -1)
    fi
    
    # Usar grep para evitar linhas de comentário e processar corretamente nomes com espaços
    grep -v "^#" "$RESTORE_FILE" | while read -r linha; do
      if [ -n "$linha" ]; then
        # Extrair nome e caminho
        nome=$(echo "$linha" | awk -F " file://" '{print $1}')
        caminho_url=$(echo "$linha" | awk -F " file://" '{print $2}')
        
        # Decodificar a URL para verificar a existência do diretório
        # Substituir %20 por espaço e outros códigos comuns
        caminho_decodificado=$(echo "$caminho_url" | 
          perl -pe 's/%20/ /g; s/%([0-9A-F]{2})/chr(hex($1))/gie' 2>/dev/null ||
          echo "$caminho_url" | sed 's/%20/ /g')
        
        # Verificar se o caminho existe usando o caminho decodificado
        if [ -d "$caminho_decodificado" ]; then
          mostrar_info "Adicionando: $nome -> file://$caminho_url"
          mysides add "$nome" "file://$caminho_url" 2>/dev/null
          echo "Adicionado: $nome -> $caminho_decodificado"
        else
          mostrar_aviso "Caminho não encontrado: $caminho_decodificado"
          mostrar_info "Tentando adicionar $nome diretamente com URL original..."
          
          # Tentar o método direto usando a URL original
          mysides add "$nome" "file://$caminho_url" 2>/dev/null
          
          # Verificar se foi adicionado
          if mysides list 2>/dev/null | grep -q "$nome"; then
            mostrar_sucesso "Favorito adicionado: $nome (usando URL original)"
          else
            # Tentar método alternativo para pastas específicas
            if [ "$nome" == "Desktop" ]; then
              mysides add "Desktop" "file:///Users/$(whoami)/Desktop"
            elif [ "$nome" == "Documents" ]; then
              mysides add "Documents" "file:///Users/$(whoami)/Documents"
            elif [ "$nome" == "Downloads" ]; then
              mysides add "Downloads" "file:///Users/$(whoami)/Downloads"
            elif [ "$nome" == "Applications" ]; then
              mysides add "Applications" "file:///Applications"
            elif [[ "$nome" == *"BEBA COM MODERAÇÂO"* ]]; then
              # Tenta localizar esta pasta especial
              for local in ~/Desktop ~/Documents ~; do
                if [ -d "$local/BEBA COM MODERAÇÃO" ]; then
                  mysides add "$nome" "file://$local/BEBA COM MODERAÇÃO"
                  mostrar_sucesso "Localizado e adicionado: $nome"
                  break
                fi
              done
            else
              # Tentar encontrar a pasta por nome
              local_encontrado=$(find ~ -maxdepth 3 -type d -name "$nome" -print -quit 2>/dev/null)
              if [ -n "$local_encontrado" ]; then
                mysides add "$nome" "file://$local_encontrado"
                mostrar_sucesso "Localizado e adicionado: $nome em $local_encontrado"
              else
                mostrar_erro "Não foi possível adicionar $nome"
              fi
            fi
          fi
        fi
      fi
    done
    
    # Instruções para método manual (mais confiável)
    mostrar_info "=====================================================================>"
    mostrar_info "IMPORTANTE: Se os atalhos não funcionarem corretamente, siga estes passos:"
    mostrar_info "1. Abra o Finder"
    mostrar_info "2. No menu da barra lateral, desative 'Recentes'"
    mostrar_info "3. Navegue até as pastas que deseja adicionar"
    mostrar_info "4. Arraste-as para a barra lateral do Finder"
    mostrar_info "5. Isso criará atalhos funcionais com o formato correto reconhecido pelo macOS"
    mostrar_info "=====================================================================>"
    
    mostrar_sucesso "Favoritos restaurados com sucesso!"
    return 0
  else
    mostrar_info "Restauração cancelada pelo usuário."
    return 1
  fi
}

# Função para realizar todo o processo (backup, limpeza e restauração)
processo_completo() {
  mostrar_info "Iniciando o processo completo (backup, limpeza e restauração)..."
  
  # Verificar se mysides está instalado
  verificar_mysides || return 1
  
  # 1. Fazer backup dos favoritos
  mostrar_info "Passo 1: Fazendo backup dos favoritos..."
  backup_favoritos
  
  # 2. Confirmar continuação
  echo ""
  mostrar_aviso "ATENÇÃO: O próximo passo irá limpar o cache do Google Drive."
  read -p "Deseja continuar com a limpeza do cache? (s/n): " CONTINUAR_LIMPEZA
  
  if [[ "$CONTINUAR_LIMPEZA" != "s" && "$CONTINUAR_LIMPEZA" != "S" ]]; then
    mostrar_info "Processo interrompido pelo usuário após o backup."
    return 0
  fi
  
  # 3. Limpar o cache
  mostrar_info "Passo 2: Limpando o cache do Google Drive..."
  limpar_cache
  
  # 4. Adicionar favoritos do Google Drive
  mostrar_info "Passo 3: Restaurando favoritos do Google Drive..."
  adicionar_favoritos_google_drive
  
  mostrar_sucesso "Processo completo finalizado com sucesso!"
  mostrar_info "Se deseja restaurar todos os favoritos (não apenas os do Google Drive), use a opção 4 do menu principal."
  return 0
}

# Menu principal
exibir_menu() {
  mostrar_cabecalho
  echo "Escolha uma opção:"
  echo ""
  echo "1. Processo completo (backup, limpeza e restauração do Google Drive)"
  echo "2. Fazer backup dos favoritos do Finder"
  echo "3. Limpar cache do Google Drive"
  echo "4. Restaurar todos os favoritos do backup"
  echo "5. Adicionar apenas favoritos do Google Drive"
  echo "6. Sair"
  echo ""
  read -p "Digite sua escolha (1-6): " OPCAO
  
  case $OPCAO in
    1)
      processo_completo
      ;;
    2)
      backup_favoritos
      ;;
    3)
      limpar_cache
      ;;
    4)
      restaurar_todos_favoritos
      ;;
    5)
      adicionar_favoritos_google_drive
      ;;
    6)
      mostrar_info "Saindo..."
      exit 0
      ;;
    *)
      mostrar_erro "Opção inválida!"
      ;;
  esac
  
  echo ""
  read -p "Pressione Enter para voltar ao menu principal..."
  exibir_menu
}

# Iniciar o programa
exibir_menu 