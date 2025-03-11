# Google Drive Manager

Script para gerenciar o cache do Google Drive e os favoritos da barra lateral do Finder no macOS.

## Funcionalidades

- Backup dos favoritos da barra lateral do Finder
- Limpeza do cache do Google Drive
- Restauração dos favoritos após limpeza
- Adição automática de favoritos importantes do Google Drive

## Requisitos

- macOS
- Homebrew (opcional, para instalar o mysides)
- Ferramenta `mysides` (será instalada automaticamente se necessário)

## Uso

1. Torne o script executável:
```bash
chmod +x google_drive_manager_fixed.sh
```

2. Execute o script:
```bash
./google_drive_manager_fixed.sh
```

3. Siga as instruções no menu interativo:
   - Opção 1: Processo completo (backup, limpeza e restauração)
   - Opção 2: Fazer backup dos favoritos do Finder
   - Opção 3: Limpar cache do Google Drive
   - Opção 4: Restaurar favoritos do backup
   - Opção 5: Adicionar apenas favoritos do Google Drive
   - Opção 6: Sair

## Observações

- Os backups são salvos em `~/Desktop/Google_Drive_Manager/Backups/`
- A restauração usa o backup mais recente por padrão
- Caso haja problemas com a restauração automática, o script fornece instruções para adicionar favoritos manualmente

## Versões

- **v1.0**: Versão inicial com funcionalidades básicas
- **v1.1**: Correção do problema de "segmentation fault" com o mysides
- **v1.2**: Melhorias na decodificação de URLs e suporte a caracteres especiais

## Licença

Este script é fornecido "como está", sem garantias.

## Autor

Criado para gerenciar o Google Drive e seus favoritos do Finder. 