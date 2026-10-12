# TASK-004 — caminho de y e TEST-006

Data: 11/10/2026. Code Implementer; execução concluída, auditoria independente pendente.

## Implementação

`polynomial_y` preserva a interface pública a,b,c,x signed8 → y signed23,OV. Um `polynomial_y_core` privado disponibiliza carry_y por porta normal, sem acesso hierárquico. O core contém dois mul_s8_s8, um mul_s8_u15 e dois add23_core simultâneos. x² está em0..16384: a seleção explícita dos bits14:0 remove somente o bit15 comprovadamente zero. ax²/bx/c são estendidos explicitamente para23 bits. Carry privado vem exclusivamente da soma final com c; subtotal carry não é exposto. OV=0 para todo domínio aprovado. Zero FF/estado, FSM, comportamento ou geração. Dependências aprovadas permanecem inalteradas.

## Referência e cobertura

`verification/reference_y.py` calcula a*x*x+b*x+c com inteiros Python de precisão ilimitada. Carry esperado usa soma dos padrões unsigned23 de subtotal e c, extraindo bit23; independe de implementação ripple/portas. Semente20261011. São12413 vetores:12 dirigidos,2401 do produto cartesiano de {-128,-127,-1,0,1,126,127}⁴ e10000 pseudoaleatórios. Extremos observados -2113536 e2097279; inclui x0, zero, sinais mistos, cancelamento de termos não nulos e -1+1 final com carry1. Cada vetor compara y público/privado, carry e OV0; X/Z ou arquivo ausente/malformado/incompleto causam fatal. A composição completa não foi testada exaustivamente nas2³² entradas; unidades multiplicadoras têm evidência exaustiva separada em TASK-007.

## Reprodução

```sh
python3 verification/reference_y.py
tar -cf - rtl/arithmetic_cells.v rtl/add_sub.v rtl/multipliers.v rtl/polynomial_y.v testbench/tb_polynomial_y.v verification/vectors/y.txt | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_polynomial_y -o /tmp/task004.vvp rtl/arithmetic_cells.v rtl/add_sub.v rtl/multipliers.v rtl/polynomial_y.v testbench/tb_polynomial_y.v && vvp /tmp/task004.vvp' > verification/results/task-004.log 2>&1
```

Backend: Docker hdlc/iverilog:latest, Icarus14.0 devel s20260301-394-g9edaf7b6a. Tag mutável; comparar versão registrada. A primeira tentativa encontrou permissão negada no socket; reexecução autorizada por escalação, sem bind mount. Execução retornou código0. Compilação -Wall sem warnings. Resultado real: `TEST-006 PASS directed=12 cartesian=2401 random=10000 rows=12413 wrapper_core=PASS carry=PASS OV=PASS`. Nenhuma síntese, análise temporal ou validação física executada nesta TASK.

## SHA-256 dos artefatos executados

```text
b3d2788521b3e646eb585813e0a3a50390eaa8b71c7edb07f5b3392369477fb7  rtl/polynomial_y.v
1144d2c35051acfd64267259db899a6192107a4a3fd24d744c50506aa95310e9  testbench/tb_polynomial_y.v
42feae35a483998b19ff4ffffba0768ec086209946bc00fc5b4e2a3f94d1d3f2  verification/reference_y.py
5d38330651081ee8b74a410c6ddc8039984670388f825b6261dd0a0d64e9d832  verification/vectors/y.txt
0e9e393098a238cf0e5992a187834922fea4506eea13d4cdc635debf7376098e  rtl/arithmetic_cells.v
fad812f3d306bc60b327a464946f96a2915c28f0dbb44b01a782d212dc75da3a  rtl/add_sub.v
95d8de13e7cab690e72544c5b4c89efe7c956f46eadcc714a112f80123ddc371  rtl/multipliers.v
```

## Code Auditor independente — ciclo 1, 11/10/2026

**APPROVED.** Gate 1 PASS: leitura do DUT confirmou três multiplicadores e dois add23_core aprovados, wrapper preservado, conexões estáticas e nenhuma construção proibida/estado novo. Gate 2 PASS: modelo usa inteiros arbitrários e carry dos padrões binários de subtotal/c; testbench compara ambos os resultados/OV e carry com rejeição de X/Z e contagens obrigatórias. Log Icarus final confirma 12413 vetores PASS, término normal e compilação sem warnings. Gate 3 PASS: square_full[14:0] elimina somente bit15 comprovadamente zero; multiplicador misto permanece no domínio aprovado; ax²/bx/c são estendidos explicitamente para23 e carry_y vem da segunda soma. Os sete hashes foram conferidos contra arquivos atuais; dependências mantidas aprovadas.

Nenhum finding. Sem reexecução desnecessária de simulação. Evidência cobre os vetores definidos, não todas as 2³² entradas; síntese/timing/placa e ligação das flags no top-level permanecem trabalhos posteriores.
