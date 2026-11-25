# TASK-044 — evidência de P mínimo

Data: 2026-11-24. Ferramenta: Quartus Prime Lite 25.1std, MAX 10 10M50DAF484C7G, clock `MAX10_CLK1_50` de 20 ns. As duas variantes foram compiladas em cópias isoladas (`/tmp/pbl03-p1` e `/tmp/pbl03-p2`); não foram adicionados exceções multicycle/false-path.

`P` conta as bordas de registrador desde o token de coluna emitido até o payload/endereço de escrita na RAM:

| P | Cortes | Resultado Quartus |
|---|---|---|
| 1 | Matemática combinacional desde x/coefs; um FF final para payload, endereço e validade | Não fecha: pior setup slack −4,888 ns; hold +0,239 ns. Ver `pipeline-p1.sta.rpt`. |
| 2 | Primeiro FF retém x², ax, bx, a, b e c alinhados; a etapa seguinte calcula f/f′, formata e registra payload/endereço/validade juntos | Fecha: pior setup slack +1,084 ns; hold +0,242 ns; Fmax 52,87 MHz; 9.072 LEs, 1.233 registradores e 16 M9K; compilação completa sem erro. Ver `pipeline-p2.sta.rpt`. |

Como P=1 falha e P=2 fecha, P=2 é o menor pipeline testado que atende ao contrato FF→FF ≤20 ns. O teste Icarus `sim/run_coordinate_frame_function_pipeline_icarus.sh`, usando `altera_mf.v` oficial, passou com latência de uma borda na interface matemática, throughput de uma coluna por ciclo e valores positivos, negativos e extremos; o registrador de payload no top compõe o segundo estágio até a RAM.

A análise de endpoints VGA no P=2 encontrou 14 caminhos de saída e zero violações; o pior slack foi +6,128 ns. Relatório: `pipeline-p2-vga-outputs.rpt`. O teste integrado do top repetido em P2 também passou: duas execuções gravaram 640 palavras; KEY1 em DISPLAY limpou `frame_ready`/BUSY/DONE e apagou RGB, e START em DISPLAY iniciou preparação sem revelar o frame anterior.

Após fixar no top as entradas raster não consumidas do processador auxiliar, a compilação Quartus final do P2 foi repetida: 0 erros/40 warnings; setup +1,084 ns, hold +0,242 ns, Fmax 52,87 MHz, 9.072 LEs, 1.233 registradores e 16 M9K. O teste full-frame Icarus/VPI pós-P2 passou em 2.059 s. Artefatos finais: `pipeline-p2-final.fit.rpt`, `pipeline-p2-final.sta.rpt` e `pipeline-p2-vga-outputs.rpt`.

O agregador pós-P2 também passou (exit 0): `verification/results/task-036/regression-20261124T232151Z.log`. Todos os runners Icarus, incluindo a captura full-frame, e o source check passaram. O próprio log registra o Verilator como não suportado devido ao self-loop na biblioteca Quartus oficial, sem marcar esse backend como aprovado.

Comando de síntese usado em ambas as cópias:

```sh
quartus_sh --flow compile pbl03
```

A captura full-frame Icarus/VPI pós-migração de P2 passou em 2.059 s, e a auditoria independente final aprovou a TASK-044 em 2026-11-24. Os gates deste registro estão fechados.
