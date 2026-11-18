# TASK-037 | Destacar interseções inteiras

## Objetivo

Aplicar a quinta cor quando F1 e F2 têm valores completos iguais em uma das 640 colunas inteiras e o ponto passa pelo clipping.

## Status

PLANNED

## Dependências

- TASK-036 | regressão obrigatória aprovada.
- TASK-029 e TASK-031 | resultados de ambas as funções e compositor.

## Planejamento e aceite

- Comparar f₁(x) e f₂(x) antes de qualquer conversão para coordenada VGA.
- Destacar somente pontos visíveis que satisfaçam a igualdade exata.
- Confirmar funções coincidentes, interseções com x inteiro e ausência de destaque para cruzamento apenas fracionário.
- Preservar a prioridade de cores definida em `REGRAS.md`.

## Arquivos

Definir a lista permitida na análise de contexto. Incluir comparador/compositor e casos externos de pixel.

## Resultado

Pendente. Não há implementação nem evidência nesta TASK.
