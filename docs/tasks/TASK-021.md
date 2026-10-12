# TASK-021 — Nomes descritivos em português no RTL

## Objetivo

Aplicar a convenção da DEC-037 aos módulos internos, sinais locais, instâncias e variáveis de testbench, mantendo portas públicas e pinagem inalteradas.

## Status

BLOCKED — renomeação implementada; aprovação final depende de regressão funcional e compilação Quartus, não executadas nesta tarefa.

## Decisões relacionadas

- DEC-037 — nomes locais em português `snake_case`, sem acentos; fronteiras públicas preservadas.

## Restrições

- Não mudar funcionalidade, largura, polaridade, hierarquia lógica, FF, pinagem, ports públicos ou conteúdo de estímulos/oráculos.
- Atualizar todos os callers, scripts/manifests e documentação viva que nomeiem os identificadores migrados.
- Operadores primitivos e tokens Verilog permanecem intactos.

## Arquivos permitidos

Fontes RTL ativos e arquivados afetados; testbenches/callers que usem identificadores migrados; documentação de interfaces, módulos, convenções, tarefas e decisões que descreva nomes atuais; scripts e manifests de compilação/verificação. Não editar logs/resultados gerados.

## Critérios de aceite

- Todos os módulos não primitivos têm nomes portugueses descritivos ou são ports públicos preservados.
- Identificadores locais em RTL/testbenches migrados são descritivos em português e consistentes entre definição e uso.
- Ports públicos e ports físicos mantêm nome, direção, ordem e largura.
- Nenhuma diferença funcional ou de estímulo; suites existentes e integração passam.
- Auditoria de hierarquia/callers passa.

## Resultado da implementação

Renomeados os módulos RTL para português descritivo sem acentos, incluindo `modulo_principal`, com `TOP_LEVEL_ENTITY` atualizado no QSF. Identificadores de sinais locais, instâncias e variáveis dos testbenches foram traduzidos em RTL, `.save` e testbenches. Scripts Python de verificação mantiveram APIs, builtins e caminhos de arquivos válidos; foram alteradas as referências vivas de documentação. Nomes, direção, largura e ordem das portas foram mantidos conforme os contratos existentes, incluindo as APIs privadas vigentes de DEC-035/036; nomes de arquivos, nomes dos módulos de testbench, primitivas Verilog e termos reservados permanecem como identificadores de ferramenta/linguagem.

Atualizadas as páginas vivas `docs/interfaces.md`, `docs/modulos.md`, `docs/arquitetura.md` e `docs/verificacao.md`. A alteração no QSF limita-se à entidade top-level; assignments e pinagem não foram editados.

## Resultado das ferramentas

Verificação estática: auditorias independentes confirmaram labels nomeados consistentes, portas públicas sem alteração e QSF com mudança somente em `TOP_LEVEL_ENTITY`; `git diff --check` passou. Após correções de nomes em testbenches, comparação estática com HEAD confirmou contagem idêntica de system tasks, especificadores de formato e tokens `input`/`output`. Simulação, compilação Quartus e validação física não foram executadas nesta tarefa.

## Resultado da revisão

**Revisões independentes em 12/10/2026.** As portas públicas conferidas preservam nomes, ordem, direção e largura; os labels nomeados correspondem às declarações. O QSF altera somente `TOP_LEVEL_ENTITY` para `modulo_principal`, preservando assignments físicos. Findings anteriores em scripts e caminhos documentais foram corrigidos. Revisões posteriores encontraram tokens de direção traduzidos e nomes locais abreviados/ingleses em testbenches; os tokens foram restaurados e os nomes citados foram traduzidos. Em seguida, foram traduzidos outros sinais locais internos identificados por inspeção estática. A comparação estática após as correções confirmou tokens de ferramenta/sintaxe preservados e `git diff --check` passou. Não houve nova auditoria independente depois da última tradução de nomes locais. A aprovação funcional permanece bloqueada por ausência de simulação e compilação Quartus; nenhuma dessas ferramentas foi executada nesta tarefa.

### Findings encerrados/corrigidos

- Scripts Python de verificação preservam caminhos, APIs, builtins e tokens Verilog gerados.
- `docs/modulos.md` referencia os nomes reais dos arquivos RTL.
- Tokens Verilog de direção e system tasks nos testbenches foram restaurados; nomes locais apontados nas revisões foram traduzidos.

## Pendências

Executar as suítes funcionais e validar a entidade `modulo_principal` em compilação Quartus quando houver solicitação/autorização de validação; manter BLOCKED até existir essa evidência.
