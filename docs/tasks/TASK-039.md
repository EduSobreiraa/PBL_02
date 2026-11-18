# TASK-039 | Calcular e marcar vértices como extra

## Objetivo

Exibir as coordenadas dos vértices e seus marcadores sem alterar a validação racional exata de F1 e F2.

## Status

PLANNED

## Dependências

- TASK-036 | regressão obrigatória aprovada.
- TASK-028 e TASK-029 | vértices racionais válidos disponíveis.
- Decisão de formato fixo, arredondamento, texto e cor dos marcadores.

## Planejamento e aceite

- Converter vértices racionais para apresentação segundo o formato aprovado.
- Se forem exibidos rótulos numéricos, incluir apenas a renderização necessária junto aos marcadores, sem painel lateral ou dependência de gerador de caracteres compartilhado.
- Não usar o valor arredondado para validar a função.
- Marcar somente coordenadas representáveis e visíveis, com clipping correto.
- Cobrir vértices inteiros e fracionários, sinais, bordas e duas funções.

## Arquivos

Definir a lista permitida na análise de contexto. Incluir conversão, texto, compositor e verificações numéricas independentes.

## Resultado

Pendente. Não há implementação nem evidência nesta TASK.
