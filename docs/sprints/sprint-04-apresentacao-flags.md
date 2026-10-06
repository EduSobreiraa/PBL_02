# Sprint 4 — Seleção, displays e flags

## Objetivo

Apresentar o valor selecionado por SW[9:8] nos seis displays e encaminhar as flags acordadas aos LEDs.

## Escopo planejado

- Seletor contínuo `x`, `y`, `x₁`, `x₂` na ordem definida em DEC-011.
- Conversão signed para decimal, sinal e fallback `------` quando o valor completo não couber nos seis displays (DEC-017/019).
- Integração das saídas de OV, Z, C e ERR com o mapeamento de LEDs documentado.
- Revisão de padrões ativos baixos e ordem de segmentos a–g, sem alterar pin assignments.

## Dependências

- Interfaces finais do seletor e da apresentação especificadas nas TASKs.
- Caminhos de resultado disponíveis nas Sprints 1–3; componentes de apresentação podem avançar antes, com entradas de teste controladas.
- Decisão de PEN-004 para liberar aceite completo da flag C.

## Critérios de conclusão

- TEST-008 cobre seleção, conversão, sinal, limites dos displays e fallback.
- TEST-009 cobre flags cuja semântica está fechada; flag C só é aprovada após fechamento de PEN-004.
- Mapeamento lógico de LEDs e segmentos confere com interfaces/hardware documentados.

## Bloqueios e limites

- PEN-004 bloqueia a definição/aceite de C; não inferir estágio de carry.
- PEN-019 também impede validar a apresentação de raízes até o caminho da Sprint 3 ser liberado.
