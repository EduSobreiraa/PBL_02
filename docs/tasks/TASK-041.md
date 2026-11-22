# TASK-041 — Fechar o pacote técnico reproduzível

## Objetivo

Consolidar as fontes, verificações e evidências técnicas finais do PBL03 em um pacote local reproduzível, vinculado a um único snapshot de fontes e configurações. Esta TASK organiza evidências técnicas existentes e novas execuções; não produz o relatório no modelo do tutor nem declara teste físico.

## Status

APPROVED

## Dependências

- TASK-034 — **APPROVED**: source checker, manifesto e integridade do VGA.
- TASK-035 — **APPROVED**: QSF/SDC, pinagem e evidências Quartus.
- TASK-036 — **APPROVED**: regressão agregada de sistema.
- TASK-037 — **APPROVED**: interseções.
- TASK-039 — **APPROVED**: vértices e STA.
- TASK-040 — **APPROVED**: pipeline de raízes, regressão e STA.
- `REGRAS.md`, PDF PBL03 e `docs/planejamento-pbl03.md`.

## Planejamento e aceite

- Fornecer comandos reproduzíveis para verificação das fontes, regressão funcional e compilação/STA Quartus.
- Amarrar comandos e evidências ao mesmo HEAD e fingerprint dos inputs.
- Registrar a lista de fontes ativas e preservar evidência de integridade do periférico VGA.
- Indexar logs e relatórios Quartus em uma pasta final local, sem usar arquivos de build como fontes RTL.
- Declarar limites dos dados disponíveis e separar entregáveis técnicos locais de entregas externas ainda pendentes: modelo do tutor e validação física na placa/monitor.

## Resultado

Pacote técnico local gerado em `verification/results/task-041/final/` pelo novo `verification/package_pbl03_release.sh`. Fingerprint dos inputs: `548358e29a6907935c81b94068018179dcac7c1bb4e95769f945bcf064cb7787`; HEAD inicial: `ec19269f6c3b71ca9ead50ee6c89d6df0dbadcc9`. A lista QSF/manifesto confere em 57 fontes e o hash do VGA confere com `UPSTREAM.md`.

- Source checker: PASS.
- Regressão Icarus/VPI e Verilator: PASS; 10 markers de runner, full-frame 800×525 e 20.161.162 verificações de vetores.
- Quartus Prime Lite 25.1std.0: compilação, fitter e STA concluídos. Foram registrados 6 avisos top-level no log (incluem truncamentos no VGA fornecido, saídas constantes e avisos de atribuição/licença); nenhum erro de compilação.
- TimeQuest: 14/14 endpoints VGA atendem ao limite existente de 40 ns; pior slack +2,587 ns em `VGA_G[0]`. Pior slack FF→FF +0,873 ns sob clock de 20 ns. Detalhes em `timing-results.txt` e `quartus-paths.log`.
- Hashes dos artefatos finais validam. `git diff --check` passou.
- Não houve teste físico da DE10-Lite/monitor, nem modelo oficial de relatório do tutor. Essas entregas continuam pendentes; não são inferidas do Quartus ou da simulação.

## Arquivos modificados e resultados

- `verification/package_pbl03_release.sh` — empacotador executável com falha fechada, fingerprint de inputs, invalidação de PASS antigo, coleta de regressão/Quartus e hashes finais.
- `verification/results/task-041/final/` — resumo, lista de fontes, manifests SHA-256, logs e relatórios da mesma execução.
- Code Auditor independente: APPROVED. Foram fechados FIND-041-01 (`git diff --check` como gate), FIND-041-02 (invalidação de PASS antigo), FIND-041-03 (estado/resultado documentado) e FIND-041-04 (falha na enumeração propagada). O auditor comparou os seis relatórios Quartus com as saídas originais e confirmou que diferem apenas pela remoção de whitespace horizontal final e linhas vazias finais.

## Implementation Brief

### Objetivo

Criar um comando de empacotamento que execute os checks aprovados do PBL03 e registre, em `verification/results/task-041/final/`, os inputs efetivamente verificados, a revisão/fingerprint, os logs de execução e os relatórios Quartus correspondentes. Todos os resultados devem referir-se ao mesmo snapshot de conteúdo. Um commit SHA isolado não substitui o fingerprint se houver mudanças locais; registrar ambos e o estado inicial do worktree.

### Requisitos

- `REGRAS.md` §§2, 6 e 10: sintaxe PBL03, periférico VGA intacto e documentação de resultados reais.
- PDF `TEC498_2026_2_Problema3.pdf`: implementação/verificação e entregáveis técnicos conforme o enunciado.
- Critérios de fechamento do projeto em `docs/planejamento-pbl03.md`: regressão, Quartus, relatórios de temporização e limitações declaradas.
- Dependências aprovadas TASK-034/035/036/037/039/040: fonte ativa, checker, regressão, configuração e resultados verificados.

### Decisões aplicáveis

- DEC-043: regras vigentes do PBL03 são as de `REGRAS.md`, sem transportar restrições do PBL02.
- DEC-044/057/063: STA e limites VGA/FF→FF aplicáveis ao sistema final.
- DEC-059: QSF e SDC protegidos fora de mudanças explicitamente autorizadas.
- DEC-064: hierarquia normativa PBL03; não é necessária alteração de arquitetura nesta TASK.

### Módulos e entradas do pacote

- Fontes Quartus ativas: o conjunto exato de 57 caminhos `VERILOG_FILE` de `quartus/pbl03.qsf`, que deve coincidir com os 57 objetos de `verification/pbl03_sources.json`. O pacote deve registrar os caminhos efetivos em `active-sources.txt`; não manter uma segunda lista manual como fonte da verdade.
- Periférico: `vendor/vga/vga_sync.v`, cuja SHA-256 deve corresponder a `vendor/vga/UPSTREAM.md`.
- Configuração: `quartus/pbl03.qpf`, `quartus/pbl03.qsf`, `quartus/pbl03.sdc`, `verification/pbl03_sources.json`.
- Verificação: `verification/check_pbl03_sources.py` e seus testes; `sim/run_pbl03_regression.sh` e runners/harnesses chamados por ele.
- Build: `quartus_sh --flow compile quartus/pbl03`, executado com a revisão `pbl03` no dispositivo configurado pelo QSF.

### Interface e comandos

O novo script `verification/package_pbl03_release.sh` não recebe parâmetros obrigatórios; deriva a raiz pelo próprio caminho. Deve falhar com código não zero se qualquer fase falhar, se a lista de fontes divergir ou se hashes finais não validarem.

Comandos base reproduzíveis e registrados no sumário:

1. `python3 verification/check_pbl03_sources.py`
2. `./sim/run_pbl03_regression.sh` — contém as suites Icarus/VPI, o full-frame Verilator/C++ e repete o source checker.
3. `quartus_sh --flow compile quartus/pbl03` — Quartus Prime Lite 25.1std.0 Build 1129; compila A&S, fitter, assembler e STA do projeto.
4. O script executa `quartus_sta -t <Tcl temporário de paths detalhados> pbl03` — capturar o relatório TimeQuest da compilação atual, incluindo slack dos 14 endpoints VGA e caminho FF→FF.
5. `git rev-parse HEAD`, `git status --short`, versões de Python, Docker, Icarus/Verilator (registradas pelo runner agregado) e Quartus.
6. Gerar `input-sha256.txt` após congelar o snapshot e antes das execuções. O conjunto inclui os arquivos rastreados/não ignorados necessários à build, simulação, checker, QSF/SDC, manifesto e VGA; exclui `.git`, `verification/results/**` e diretórios gerados/ignorados do Quartus. Calcular fingerprint SHA-256 do arquivo ordenado.
7. Gerar `artifact-sha256.txt` ao final para validar sumário, logs, fontes ativas e relatórios copiados, excluindo o próprio manifesto de artefatos. Verificar com `sha256sum -c`.

O script captura stdout/stderr e status de cada comando, registra UTC de início/fim e a mesma revisão/fingerprint em todos os logs ou no índice que os vincula. O resultado não pode ser marcado PASS se algum comando for omitido.

### Clock e reset

Não aplicável ao empacotador. Para a evidência Quartus, preservar clock e constraints do projeto existente; esta TASK não os modifica.

### Restrições

- Não editar RTL, testbenches, runners existentes, QSF, SDC, `verification/pbl03_sources.json`, checker, decisões, requisitos, pin assignments ou fontes vendor.
- O único novo código permitido é `verification/package_pbl03_release.sh`, para orquestração e empacotamento; não mudar os comandos dos runners aprovados.
- Não incluir arquivos de build como fontes nem acrescentar dependências de software/hardware sem documentar a versão.
- Capturar logs sem mascarar códigos de saída (`pipefail` ou mecanismo equivalente).
- Não declarar aprovação acadêmica, cumprimento do modelo do tutor, operação de placa ou monitor físico sem evidência específica.
- Distinguir resultados Quartus de validação física: relatórios de síntese/fitter/TimeQuest não comprovam imagem em monitor ou funcionamento na DE10-Lite.

### Arquivos permitidos

1. `docs/tasks/TASK-041.md` — brief e resultados reais da execução.
2. `verification/package_pbl03_release.sh` — novo script único de empacotamento/reprodução.
3. `verification/results/task-041/final/` — saídas geradas somente pelo script e cópias identificadas de relatórios.

Arquivos esperados sob a pasta final:

- `release-summary.md` — HEAD, estado/fingerprint do worktree, comandos, versões, resultados, limitações e links.
- `active-sources.txt`, `input-sha256.txt`, `artifact-sha256.txt`.
- `source-check.log`, `regression.log`, `quartus-compile.log`.
- `quartus/pbl03.map.summary`, `quartus/pbl03.fit.summary`, `quartus/pbl03.sta.summary`, `quartus/pbl03.sta.rpt` e os relatórios detalhados necessários para os 14 endpoints VGA e caminhos FF→FF, obtidos da mesma execução.
- `vga-upstream.sha256`.

O script pode usar `quartus/output_files_pbl03/` como diretório de saída transitório gerado pelo Quartus, mas nenhum arquivo ali se torna fonte. Qualquer outro arquivo permanente fora desta allowlist exige nova análise de contexto.

### Arquivos protegidos

- Todo `rtl/**`, `sim/**` existente e `vendor/**`.
- `quartus/pbl03.qpf`, `quartus/pbl03.qsf`, `quartus/pbl03.sdc`, projetos PBL02 e pin assignments.
- `verification/pbl03_sources.json`, `verification/check_pbl03_sources.py` e `verification/test_check_pbl03_sources.py`.
- Evidências já aprovadas de TASK-034/035/036/037/039/040: somente leitura; não reescrever logs ou relatórios anteriores.
- PDFs, `REGRAS.md`, decisões, planejamento e tarefas distintas da TASK-041.

### Testes exigidos

- Conferir automaticamente que 57 caminhos ativos do QSF e do manifesto coincidem, sem duplicatas, e registrar a lista.
- Executar `python3 verification/check_pbl03_sources.py`.
- Executar `./sim/run_pbl03_regression.sh`; exigir todos os markers de sucesso dos runners e código final zero.
- Executar `quartus_sh --flow compile quartus/pbl03` e `quartus_sta pbl03 -c pbl03`; exigir A&S, fitter e STA concluídos e extrair dos relatórios atuais os 14 endpoints VGA e caminhos FF→FF.
- Verificar hash de `vendor/vga/vga_sync.v` contra `UPSTREAM.md` e validar os manifests com `sha256sum -c`.
- Executar `git diff --check` sobre as alterações documentais/script da TASK.
- Não reutilizar um log isolado como se fosse build da revisão atual; se for referenciado resultado de task anterior, registrar SHA/fingerprint e demonstrar igualdade do conjunto de inputs.

### Casos de borda e limitações declaradas

- Falha do checker, runner, compilador ou hash interrompe o pacote e não produz status global PASS.
- Relatórios sem todos os endpoints, sem caminho FF→FF ou sem identificação de revisão ficam incompletos e bloqueiam o aceite técnico.
- A compilação e STA podem passar sem estabelecer cobertura de atrasos externos em todos os ports; registrar limitações do TimeQuest declaradas em TASK-035/040.
- O pacote local não inclui o modelo oficial de relatório do tutor, pois ainda precisa ser obtido externamente.
- O pacote local não demonstra conexão/operação física da DE10-Lite nem monitor VGA. Teste de placa e demonstração permanecem entregas externas pendentes da equipe; registrar como “não executado”, sem alegar PASS.

### Critérios de aceite

- `verification/package_pbl03_release.sh` executa os comandos definidos e termina com sucesso somente se todas as fases passam.
- A lista de fontes, snapshot/fingerprint, HEAD, logs de toolchain e resultados ficam ligados a um mesmo conjunto de inputs; manifests verificam sem divergências.
- Regressão Icarus/VPI/Verilator e source checker passam.
- Quartus conclui A&S/fitter/STA, com relatório completo dos 14 endpoints VGA sob 40 ns e caminhos FF→FF sob 20 ns, conforme DEC-063; qualquer violação impede aceite.
- Hash do periférico VGA confere com a origem registrada.
- Sumário separa fatos medidos, limitações e entregas externas. Não afirma revisão do tutor ou teste físico.
- Code Auditor aprova script, manifests e rastreabilidade; nenhum arquivo fora da allowlist foi alterado.

### Dependências

- TASK-034/035/036/037/039/040 aprovadas; os logs/runs anteriores são histórico e referência, não substituem execuções se os hashes dos inputs divergirem.
- O source checker define o conjunto Quartus ativo e compara o QSF com manifesto de 57 módulos.
- `sim/run_pbl03_regression.sh` é o runner agregado oficial.
- `quartus/pbl03.qsf` e `quartus/pbl03.sdc` definem a compilação, dispositivo, clock e critérios temporais.
- `vendor/vga/UPSTREAM.md` define o hash esperado do módulo do professor.

### Pendências

- Nenhuma decisão arquitetural bloqueia este pacote técnico local.
- O modelo de relatório do tutor e a validação física na placa/monitor ficam explicitamente fora do escopo executável desta TASK e continuam pendentes externamente, conforme `docs/planejamento-pbl03.md`.
