# TASK-009 — Divisão estrutural inteira com resto exato

## Objetivo

Divisão estrutural inteira com resto exato, conforme a arquitetura exata aprovada em DEC-031. O candidato F=16 foi substituído; esta TASK não aguarda nova escolha de precisão.

## Status

APPROVED

## Requisitos relacionados

REQ-005, REQ-006, REQ-008, REQ-011

## Decisões relacionadas

DEC-007, DEC-013 (formatos candidatos supersedidos por DEC-031), DEC-016, DEC-020 (estratégia de evidência atualizada por DEC-031), DEC-024/025/026/027, DEC-030, DEC-031.

## Dependências

DEC-031 em CONSENSUS. Helpers privados tornam a unidade autossuficiente; sem dependência da implementação de TASK-003/007 ou do modelo de cadeia TASK-005.

## Restrições aplicáveis

Implementação do DUT exclusivamente estrutural: portas, fios, módulos fixos e instâncias explícitas; sem FSM, FF/registradores, `always`, `if`, `else`, `buf`, `for`, `generate`, `genvar` ou `begin/end`. Operadores aritméticos nas fórmulas são especificação matemática, não autorização de operadores no DUT. Testbenches separados podem usar estímulos/comparações comportamentais, laços e blocos conforme DEC-024, mas `if`/`else` continuam proibidos em todo Verilog. Não alterar interfaces públicas ou pinagem.

## Arquivos permitidos

- `rtl/divide_u9_u8.v`
- `testbench/tb_divide_u9_u8.v`
- `docs/tasks/TASK-009.md` (resultados e auditoria).

## Arquivos protegidos

Requisitos P0, decisões, regras, pin assignments, top-level e todos os arquivos fora do escopo permitido. Helpers de DUT são privados/fixos e definidos no respectivo arquivo autorizado. Novas decisões não podem ser introduzidas pela implementação.

## Plano

1. Detectar divisor zero por portas; selecionar divisor efetivo 1 nesse caso.
2. Instanciar nove estágios combinacionais restauradores explícitos, lendo dividend do bit 8 ao bit 0. R₀=0; T=2R+bit; subtrair divisor efetivo estendido. Seleção pelo borrow produz resto T ou T−divisor e bit Q correspondente.
3. T/subtrator unsigned9 (T≤509), resto parcial unsigned8; completar Q unsigned9. Mascarar Q/r em divisor zero e expor a flag combinacional. Preservar resto em todos os demais casos.
4. Comparações/subtrações/muxes estruturais. Sem operador de divisão no DUT nem compartilhamento temporal.

## Critérios de aceite

Contrato completo validado em todos os pares, flag e máscaras corretas no zero, nenhum FF, conformidade e revisão independente APPROVED com evidência real.

## Testes

TEST-005: simulação de todos os 512×256=131.072 pares, com referência matemática independente de quociente/resto e casos de divisor zero. Testbench pode usar aritmética comportamental autorizada, porém deve evitar avaliar divisão por zero e não usar if/else (seleção case é permitida no testbench). Compilar top `tb_divide_u9_u8` e executar; registrar comando, versão, contagens e logs. Compliance Gate antes de revisão funcional.

## Implementation Brief

### Objetivo

Implementar o plano acima sem reinterpretar as decisões numéricas.

### Requisitos

REQ-005, REQ-006, REQ-008, REQ-011

### Decisões aplicáveis

DEC-031 controla algoritmo/contratos; DEC-007 controla arredondamento; DEC-016 exige preservar informação; regras.md e DEC-024/025/026/027 controlam sintaxe. DEC-030 controla integração/flags externa.

### Módulos envolvidos

`divide_u9_u8` e helpers combinacionais fixos privados, com nomes prefixados `divide_`, definidos no mesmo arquivo.

### Interface

Entradas `dividend[8:0]` unsigned e `divisor[7:0]` unsigned. Saídas `quotient[8:0]` unsigned Q, `remainder[7:0]` unsigned r e `divide_by_zero`. Divisor não zero: dividend=Q·divisor+r, 0≤r<divisor, flag=0. Divisor zero: Q=0, r=0 e flag=1. Contrato total para todos os pares unsigned9×unsigned8.

### Clock e reset

Não há clock/reset neste escopo: rede puramente combinacional, zero flip-flops.

### Restrições

Implementação do DUT exclusivamente estrutural: portas, fios, módulos fixos e instâncias explícitas; sem FSM, FF/registradores, `always`, `if`, `else`, `buf`, `for`, `generate`, `genvar` ou `begin/end`. Operadores aritméticos nas fórmulas são especificação matemática, não autorização de operadores no DUT. Testbenches separados podem usar estímulos/comparações comportamentais, laços e blocos conforme DEC-024, mas `if`/`else` continuam proibidos em todo Verilog. Não alterar interfaces públicas ou pinagem.

### Arquivos permitidos

Somente os enumerados na seção homônima desta TASK.

### Arquivos protegidos

Todos os demais arquivos, incluindo contratos matemáticos, pinagem e módulos consumidores.

### Testes exigidos

Executar integralmente o plano da seção Testes, com resultados reais e reproduzíveis.

### Casos de borda

Divisor 0,1,2,128,255; dividendo 0,1,413,511; menor/igual/maior que divisor; resto zero e divisor−1; quociente máximo.

### Critérios de aceite

Contrato completo validado em todos os pares, flag e máscaras corretas no zero, nenhum FF, conformidade e revisão independente APPROVED com evidência real.

### Dependências

DEC-031 em CONSENSUS. Helpers privados tornam a unidade autossuficiente; sem dependência da implementação de TASK-003/007 ou do modelo de cadeia TASK-005.

### Pendências

Nenhuma decisão aberta. Implementação e simulação concluídas; auditoria independente pendente.

### Resultado do Context Analyst — 11/10/2026

READY_FOR_IMPLEMENTATION. Contratos, formatos, arquivos, testes e critérios definidos por decisão em CONSENSUS; sem dependência crítica de implementação externa.

## Resultado da implementação

Implementados `rtl/divide_u9_u8.v` e `testbench/tb_divide_u9_u8.v`. Nove estágios combinacionais restauradores explícitos,81 full adders privados, comparação por carry de subtração e seleção por portas; divisor efetivo1 e máscaras no domínio zero. Nenhum FF, FSM ou operador aritmético comportamental no DUT. Teste exaustivo completo PASS; fontes congelados para auditoria.

## Resultado das ferramentas

Docker hdlc/iverilog:latest, Icarus Verilog14.0 devel s20260301-394-g9edaf7b6a; compilação -Wall sem warnings, simulação retornou0. TEST-005 PASS nos131072 pares:130560 divisões válidas e512 divisores zero. Referência independente usa / e % no testbench somente no ramo divisor não zero; também verifica identidade e limite do resto. X/Z causam fatal. Tentativa inicial negada no socket Docker; reexecução escalada concluída via tar/stdin. Nenhuma síntese/timing/placa executada.

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: leitura integral confirma nove estágios e 81 full adders privados, portas/fiação estática, zero estado/comportamento proibido, escopo e portas preservados. Gate 2 PASS: carry9 da subtração identifica ausência de borrow; seleção do resto mantém valor menor que divisor efetivo≤255, justificando remoção do bit8. Divisor zero vira1 internamente e máscaras finais produzem Q/r0 e flag1. Testbench independente usa / e % somente para divisor não zero, compara estritamente saídas e verifica identidade/limite do resto. Log final TEST-005 PASS131072 (130560 válidos+512 zero) inspecionado. Gate 3 PASS: contratos u9/u8 e flag consistentes com DEC-031; hashes atuais de DUT/TB conferem com execução; helpers prefixados sem colisão com módulos aprovados. Nenhum finding. Simulação não repetida; síntese/timing/placa não incluídos nesta aprovação.

## Pendências

Nenhuma pendência desta implementação: TEST-005 e auditoria independente aprovados. Integração das raízes e síntese/placa seguem nas tarefas correspondentes.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status BLOCKED.
- 2026-10-11 — DEC-031 em CONSENSUS substitui F16 por arquitetura exata com resíduos; contratos e Implementation Brief atualizados. Estado READY, sem execução de código/testes.

## Reprodução e evidência do Code Implementer — 11/10/2026

```sh
tar -cf - rtl/divide_u9_u8.v testbench/tb_divide_u9_u8.v | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_divide_u9_u8 -o /tmp/task009.vvp rtl/divide_u9_u8.v testbench/tb_divide_u9_u8.v && vvp /tmp/task009.vvp' > /tmp/task-009.log 2>&1
```

A tag Docker é mutável; comparar versão registrada para reprodução. Log temporário capturado em `/tmp/task-009.log`; versão e saída funcional persistidas abaixo para manter o escopo de arquivos autorizado. Não houve warnings de compilação ou falhas funcionais.

```text
Icarus Verilog version 14.0 (devel) (s20260301-394-g9edaf7b6a)
TEST-005 PASS pairs=131072 valid=130560 divisor_zero=512 quotient_remainder=PASS identity=PASS masks=PASS
testbench/tb_divide_u9_u8.v:51: $finish called at 131072000 (1ps)
process exit code: 0
```

### SHA-256 dos fontes executados

```text
3c78a3f6df23183f9e395cde079e9e2e074fad85cd5ae5e1643d10a2690783cb  rtl/divide_u9_u8.v
b7a5b32d0b0144481dd1f84d80f7144e9fa95eb18d263118da099b97f0c91e56  testbench/tb_divide_u9_u8.v
```

A restauração seleciona trial ou trial−divisor pelo carry final da subtração unsigned9; cada resto selecionado é menor que divisor efetivo, portanto seu bit8 é zero. Os oito bits retidos são exatos. Divisor efetivo1 mantém os estágios definidos quando divisor original0; máscaras finais produzem Q/r0 e flag1. Nove estágios espaciais não armazenam estado.

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; TEST-005 exaustivo PASS, saída0, sem warnings. Auditoria independente solicitada.
