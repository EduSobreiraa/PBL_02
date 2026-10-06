# Sprint 3 — Discriminante e raízes

## Objetivo

Implementar estruturalmente o caminho de `Δ = b² − 4ac` e das raízes, com domínio inválido sinalizado conforme decisões aprovadas.

## Escopo planejado

- Composição de multiplicação, soma/subtração, raiz quadrada e divisão estruturais.
- Casos `a=0`, `Δ<0`, `Δ=0` e `Δ>0`; ERR permanece ativo até reset conforme DEC-001.
- Precisão intermediária e redução/arredondamento conforme decisões aprovadas, incluindo a exceção de arredondamento final em DEC-007 e a política de DEC-016.

## Dependências

- Sprint 0 concluída e interfaces/larguras registradas nas TASKs.
- Evidência comparativa exaustiva e vetores dirigidos de PEN-019 executados e registrados; F=16 validado antes de ser usado como precisão liberada.
- Contratos numéricos de raiz e divisão suficientes para critérios de aceite objetivos.

## Critérios de conclusão

- TASKs de raiz quadrada, divisão e composição de raízes aprovadas.
- Simulação cobre domínio válido e inválido, extremos, sinal e arredondamento; resultados comparados com referência independente.
- ERR ativa nos casos definidos e limpa somente pelo reset.

## Bloqueios e limites

- PEN-019 mantém esta sprint BLOCKED até a evidência confirmar ou levar à revisão da precisão.
- Se a evidência exigir outra precisão/largura ou algoritmo, abrir/retomar o workflow de decisão antes de alterar a arquitetura.
- Não inventar formato interno de discriminante, quociente ou portas HDL.
