# TEST-010/011 — reprodução controlada de TASK-013

Executado em11/10/2026 (UTC2026-10-12T00:21:24.884300+00:00). Resultado **PASS**, processo0, compilação -Wall sem warnings. Runner novo verificado por execução integral da suite de sistema; suites unitárias/exaustivas não repetidas. TB e todos DUTs preservam exatamente os hashes aprovados em TASK-012.

## Reprodução

```sh
python3 verification/run_system.py
```

Requer Python3 stdlib e Docker com imagem hdlc/iverilog:latest disponível. Runner consulta identidade da imagem, executa pelo ID imutável retornado, empacota somente12RTL explícitos+tb_top_module via tar/stdin e grava log/manifest. Manifest anterior é invalidado antes de iniciar; PASS exige código0 e marcador exato único. Uma falha de infraestrutura não é aprovação funcional. Primeira tentativa encontrou socket Docker negado; reexecução escalada concluiu.

- Icarus Verilog14.0 devel s20260301-394-g9edaf7b6a.
- Imagem executada: `sha256:80bee5d44cb0fe60fa98f020b9c1ea18c857a4a92185158f7cd2d7076f8598d0`.
- Repo digest: `hdlc/iverilog@sha256:80bee5d44cb0fe60fa98f020b9c1ea18c857a4a92185158f7cd2d7076f8598d0`.
- SHA256 runner: `59978ebd6625ac7898a0cf75e1470eedc76c3cffbc4606f9efdc7c576ece4e9c`.
- SHA256 log: `48e6ca10ab17a42f5c7132c36dae2339e99c7325e226b4a7b800d98b9db206e5`.
- Fontes/hash/comando exato/data/backend: `system-icarus.json`.
- Log completo real: `system-icarus.log`.
- Seed: não aplicável, estímulos dirigidos determinísticos; não alegar pseudoaleatoriedade nesta suite.

## Cobertura

| Cenário | Evidência exercitada |
|---|---|
|10 conjuntos de coeficientes|raízes positivas/negativas, empate dos dois sinais, a negativo, a0,delta negativo/zero, extremos y|
|Cada conjunto|reset com ambas teclas ativas, carga a/b/c, mascaramento parcial, x antes de loaded, quatro seleções|
|KEY0 mantido|SW/seleção alterados enquanto pressionado, sem recaptura|
|Carga completa|quarta captura ignorada, y/C/raízes não substituídos|
|Sequência adicional|reset durante captura parcial, nova carga completa e reset final|
|660 observações|comparação simultânea dos10LEDs e42segmentos, X/Z rejeitados|

Referência calcula y/carry por inteiros, raízes por comparação de fronteiras meio-inteiro com quadrados e decimal por divisão/resto10. Não consulta sinais internos nem instancia DUT como oracle. Os660checks exercitam LED0=OV,1=Z,2=C,3=ERR,9:4=0 e a máscara visual. Cobertura detalhada permanece no testbench versionado; vetores dirigidos embutidos evitam arquivo duplicado.

```text
TEST-010/011 PASS scenarios=10 output_checks=660 reset_partial_full=PASS held_key=PASS extra_capture=PASS flags_displays=PASS
```

Não é exaustão das entradas do sistema. Suites unitárias aprovadas complementam a cobertura; síntese, temporização física, bounce e placa não recebem PASS desta simulação.
