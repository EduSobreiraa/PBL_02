# TASK-040 | Calcular e marcar raízes como extra

## Objetivo

Adaptar os cálculos estruturais legados necessários para exibir raízes e marcadores de F1 e F2.

## Status

PLANNED

## Dependências

- TASK-036 | regressão obrigatória aprovada.
- Processadores F1 e F2 aprovados.
- Decisões de formato numérico, arredondamento, cor e prioridade dos marcadores.

## Planejamento e aceite

- Auditar os módulos legados de raiz, divisão e raiz quadrada antes de reutilizar lógica.
- Calcular raízes sem alterar a validade da parábola quando o discriminante for negativo.
- Apresentar valores e marcadores no formato aprovado, com clipping e prioridades corretos.
- Incluir apenas a renderização necessária aos rótulos das raízes; não criar painel lateral ou depender de gerador de caracteres compartilhado.
- Cobrir discriminante positivo, zero e negativo, raízes racionais/fracionárias, repetidas e fora da tela.
- Medir novamente recursos e timing após incluir os extras.

## Arquivos

Definir a lista permitida na análise de contexto. Não instanciar fontes PBL02 diretamente no QSF; portar somente módulos auditados para a árvore PBL03.

## Resultado

Pendente. Não há implementação nem evidência nesta TASK.
