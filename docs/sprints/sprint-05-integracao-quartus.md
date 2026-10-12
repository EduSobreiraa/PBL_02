# Sprint 5 — Integração e Quartus

## Estado

CONCLUÍDA — TASK-012, TASK-013, TASK-017 e TASK-015 APPROVED, com evidências reais e auditorias independentes.

## Resultados

| TASK | Entrega | Resultado |
|---|---|---|
| 012 | Top-level e simulação de sistema | 10 cenários, 660 observações de LEDs e HEX; três gates aprovados |
| 013 | Fluxo reproduzível de simulação | Runner Icarus, log/manifesto e 660 verificações PASS; três gates aprovados |
| 017 | Auditoria estática global | 12 RTL, 11 testbenches, 31 FF, zero latches/ciclos combinacionais/drivers múltiplos; nenhum finding impeditivo |
| 015 | Quartus compile, fitting e STA | 2.187 LEs, 31 FF, zero latches, 65 pinos; compilação e análise nos três corners concluídas |

TEST-014 foi executado no Quartus Prime 25.1std.0 Build 1129 SC Lite, código de saída zero. A pinagem e I/O foram comparados com `docs/hardware.md` e auditados em três níveis: QSF, pinos pós-fit e revisão independente. O projeto usa 20 ns para o clock registrado. O setup registrado mais lento teve slack de 15,669 ns e hold mais baixo de 0,153 ns. O maior caminho combinacional até uma saída foi 160,472 ns, dentro do orçamento modelado de 1 ms. Os detalhes por corner, warnings, comandos, hashes e artefatos estão em `verification/results/quartus/README.md` e `docs/tasks/TASK-015.md`.

## Limites registrados

Quartus reportou 11 warnings e zero critical warnings na execução válida. LEDs não usados/constantes e LogicLock indisponível na licença Lite foram documentados. A força de drive permaneceu no default aplicado pelo fitter, 8 mA, sem decisão elétrica nova. Treze entradas acionam o aviso AN447 para interfaces 3.3 V. Esses pontos não tiveram validação elétrica em placa.

SW é assíncrono ao clock e depende de estabilidade manual durante captura. Foram aplicadas exceções apenas entre KEY e o primeiro flip-flop de cada sincronizador; os caminhos entre os estágios permanecem cronometrados. A análise não comprova MTBF nem comportamento durante bounce/comutação. Não houve programação nem validação física da DE10-Lite.

## Próxima etapa

Sprint 6: validação física na placa e documentação final, sujeitas ao acesso à DE10-Lite e ao modelo oficial de relatório. As evidências de Quartus não são evidência de programação ou funcionamento físico.
