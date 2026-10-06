# Sprint 2 — Aritmética e caminho de `y`

## Objetivo

Construir e integrar o caminho combinacional estrutural de `y = ax² + bx + c` e suas unidades aritméticas reutilizáveis.

## Escopo planejado

- Unidades estruturais de soma/subtração e multiplicação signed para os operandos requeridos.
- Caminho de `y` com resultado signed de 23 bits e semântica de OV conforme DEC-012.
- Testes dos extremos signed de 8 bits, sinais mistos, cancelamento e produtos/somas de fronteira.

## Dependências

- Sprint 0 concluída.
- Larguras, extensões de sinal, interfaces e contratos por unidade especificados e revisados nas TASKs antes de READY.
- TEST-002, TEST-003 e TEST-006 planejados com vetores de referência reproduzíveis.

## Critérios de conclusão

- TASKs das unidades e do caminho de `y` aprovadas.
- Simulação cobre casos dirigidos e extremos; a evidência confirma o valor de 23 bits e OV conforme DEC-012.
- Auditoria confirma construção estrutural e ausência das construções proibidas.

## Bloqueios e limites

- Não assumir que uma largura intermediária ou semântica de carry está definida além do que consta nas decisões.
- PEN-004 não bloqueia soma/subtração nem o resultado de `y`; bloqueia apenas o aceite da origem/semântica da flag C. Registrar essa separação nas TASKs.
