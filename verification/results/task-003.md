# TASK-003 — implementação e TEST-002

Data: 2026-10-11. Code Implementer; revisão independente pendente.

## Implementação

`rtl/arithmetic_cells.v`: full_adder XOR/AND/OR. `rtl/add_sub.v`: add23_core com 23 células explícitas e carry inicial zero, wrapper add23 sem carry público; sub18 com 18 inversores e 18 células explícitas, carry inicial um. Zero FF, comportamento, geração ou parâmetros no DUT. Carry final descartado em wrappers não é perda de magnitude nos domínios aprovados; core possui semântica binária modular fora desses domínios.

## Referência e cobertura

`verification/reference_add_sub.py` usa inteiros Python, independentemente das portas, produzindo `verification/vectors/add_sub.txt`: 24.808 adições exatas, 12.401 subtrações Δ e três provas adicionais do core modular. Produto cartesiano de {-128,-127,-1,0,1,126,127} para a,b,c,x e 10.000 quádruplas aleatórias, semente 20261011; cada quádrupla verifica ax²+bx, subtotal+c e b²−4ac. Inclui y mínimo/máximo, Δ -65536/81408/0/-4, sinais e cancelamento. Seis identidades adicionais incluem -1+1 (carry=1 sem overflow signed). Três vetores explicitamente fora do domínio do wrapper demonstram overflow signed com e sem carry, sem alegar exatidão signed irrestrita. Full adder testado exaustivamente nas oito combinações.

## Reprodução

```sh
python3 verification/reference_add_sub.py
tar -cf - rtl/arithmetic_cells.v rtl/add_sub.v testbench/tb_add_sub.v verification/vectors/add_sub.txt | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_add_sub -o /tmp/task003.vvp rtl/arithmetic_cells.v rtl/add_sub.v testbench/tb_add_sub.v && vvp /tmp/task003.vvp' > verification/results/task-003.log 2>&1
```

Backend executado: Docker hdlc/iverilog:latest, Icarus Verilog 14.0 (devel), s20260301-394-g9edaf7b6a. Versão completa registrada no log. A tag é mutável; para reprodução comparar a versão registrada. Execução retornou código 0.

Resultado: `TEST-002 PASS full_adder=8 exact_add=24808 delta=12401 core_modular=3 rows=37212`. Compilação com -Wall sem warnings. Primeira tentativa sem escalonamento foi impedida pelo acesso ao socket Docker; segunda por permissão de leitura do bind mount; transmissão via tar/stdin executou corretamente. Nenhuma falha funcional observada. Vetores têm contagem fixa verificada; arquivo ausente, linha inválida, X/Z ou divergência encerram com $fatal.

TEST-013: inspeção local dos dois DUTs confirma portas/instâncias/fiação estática; auditoria independente ainda necessária. Não houve síntese, timing ou validação física; não se afirma custo mínimo global de portas.

Correção documental da auditoria: Δ=-1 não é alcançável com coeficientes inteiros, pois b²−4ac é congruente a 0 ou 1 módulo 4. O caso negativo próximo de zero presente nos vetores é Δ=-4. Nenhuma alteração de RTL, vetores ou nova execução foi necessária.

## Code Auditor independente — ciclo 1, 11/10/2026

**APPROVED.** Gate 1 PASS: inspeção integral dos dois DUTs confirma portas primitivas, 23/18 full_adders com carry encadeado bit a bit e inversão de rhs no subtrator, assign limitado a constantes/conexões, zero FF/comportamento/laços/parâmetros. Testbench separado não usa if/else. Gate 2 PASS: referência usa inteiros independentes do ripple, com carry dos padrões binários23; testbench rejeita X/Z, verifica o wrapper em casos exatos e distingue explicitamente probes modulares fora do contrato público. Log Icarus confirma FA8 e 37212 casos. Inspeção aritmética independente do arquivo de vetores encontrou contagens 24808/12401/3 e zero inconsistências; confirmou Δ mínimo/máximo/zero/-4. Gate 3 PASS: portas/formatos aprovados e carry privado preservados, nenhum consumidor ou pinagem alterado.

FIND-003-01, LOW, relato de cobertura em relatório/TASK: a afirmação anterior Δ=-1 era impossível no domínio inteiro. Implementer corrigiu para Δ=-4 e justificou módulo4; finding encerrado. Nenhum finding aberto. Simulação não repetida; não há síntese/timing/placa alegados.
