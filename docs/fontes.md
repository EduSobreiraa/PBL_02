# Inventário de fontes

Hierarquia factual exigida pelo responsável do projeto: P0 enunciado; P1 manual DE10-Lite; P2 handbook Quartus; P3 referências técnicas oficiais; P4 decisões explicitamente aprovadas; P5 documentação interna; P6 planejamentos/inferências; P7 conhecimento geral. `regras.md` governa o comportamento do agente, sem sobrepor fatos técnicos oficiais.

| Fonte | Tipo | Prioridade | Assuntos fundamentados | Observações | Consultada? |
|---|---|---:|---|---|---|
| `TEC498_2026_2_Problema2.pdf` | Enunciado institucional | P0 | Função, requisitos, entregáveis, avaliação, cronograma e relatório | Fonte normativa primária; lido integralmente por extração local de texto | Sim |
| `DE10_Lite_User_Manual.pdf` | Manual oficial Terasic da placa | P1 | MAX 10, clocks, KEY/SW/LED, segmentos e pinagem | Edição de 24 jan. 2017; §§1.3, 3.2–3.4 consultados; figs. 3-13/14 confirmam KEY ativo baixo e fig. 3-17 confirma segmentos `[0..6]=a..g` | Sim |
| Quartus Prime instalado em `/home/edupires/altera_lite/25.1std` | Ferramenta local de implementação | P2 | Compilação e síntese do projeto | `quartus_sh --version` e `quartus_pgm --version` retornaram Standard Lite 25.1std.0 Build 1129 (10/21/2025); compilação ainda não executada | Identificada |
| `qts-qps-5v1_design-synthesis_17.1.pdf` | Intel Quartus Prime Standard Handbook, Design and Synthesis | P2 (referência histórica) | Síntese Verilog, práticas de projeto, latches/warnings | Atualizado para Quartus 17.1; publicação 2018. A instalação local identificada é Quartus Prime Standard Lite 25.1std.0 Build 1129 | Sim |
| `DE10-Lite_Computer_NiosII.pdf` | Manual Intel FPGA University Program de sistema exemplo | P3 (complementar) | Sistema Nios II de exemplo | Não fundamenta requisitos ou pinagem do projeto; apenas metadados inspecionados, conteúdo não consultado; não usado para decisões técnicas | Parcial |
| `Pbl1felipe.7z` | Arquivo compactado com fontes PBL1 | Não normativa; artefato de referência | Módulos estruturais legados e interface do PBL1 | Extensão `.7z`, conteúdo detectado como ZIP; contém seis `.v`, sem `.qsf`/`.qpf`; fonte não é especificação PBL2 | Sim, inspeção estática |
| `Pbl1felipe.zip` | Arquivo compactado legado PBL1 | Não normativa; artefato de referência | Projeto Quartus antigo, fontes, backups e artefatos | Inventariado; não tratado como requisito; possui conteúdo redundante/gerado | Sim, listagem e comparação anterior |
| `docs/regras.md` | Regras internas do projeto | Autoridade comportamental | Limites HDL, arredondamento, modo de colaboração | Não altera fatos técnicos de P0–P3 | Sim |
| `docs/agente_workflow.md` | Workflow interno de agentes | Autoridade de processo, subordinada às instruções vigentes em `AGENTS.md` | Papéis de planejamento/implementação/revisão, tarefas, evidências e intervenção humana | Para decisões técnicas aplica-se também o fluxo de Orchestrator/Architect/Reviewer definido em `AGENTS.md` e `agents/` | Sim |
| Esclarecimentos do responsável compartilhados em 06/10/2026 sobre mensagens de 05/10 | Decisões e propostas do projeto | P4 | PEN-001/002/005/006/007/008/009/011/012/016/017/018 | Decisões finais CONSENSUS registradas em DEC-001 a DEC-014 e resumidas em `docs/decisoes.md`; relatos de aprovação docente sustentam exceção de implementação, sem substituir o texto P0 | Sim |
| `docs/requisitos_pbl.md` | Resumo interno anterior | P5 | Conteúdo derivado do PBL | Auditado; substituído pelo arquivo canônico `requisitos.md` e `criterios_avaliacao.md` | Sim |
| `docs/pre-projeto.md` | Rascunho interno anterior | P5/P6 | Propostas de arquitetura, verificações e pendências | Auditado; conteúdo aproveitado onde válido, mas substituído por documentos separados | Sim |
| `docs/planejamento-implementacao.md` | Plano interno anterior | P5/P6 | Plano e inferências anteriores | Auditado e marcado como supersedido pela documentação modular | Sim |

## Evidência do arquivo PBL1

O arquivo atual `Pbl1felipe.7z` lista `top_module.v`, `somadores - Copia.v`, `Muxes - Copia.v`, `flags - Copia.v`, `BCD - Copia.v` e `Display - Copia.v` sob `verilog/`. O conteúdo corresponde aos módulos centrais do ZIP antigo, mas exclui seu HDL monolítico, backups e bases de compilação. Nenhuma conclusão sobre funcionalidade PBL2 deve ser derivada apenas desse pacote.

## Referências citadas em documentos internos

- Requisitos: PBL §3–5 e §8; manual DE10-Lite §§3.2–3.4.
- Práticas de síntese: Quartus Handbook v17.1, §11.2.1.2 (latches não intencionais) e §16.2.1 (suporte Verilog/SystemVerilog).
- Inventário dos arquivos antigos: ver tabela acima; as decisões internas são sempre subordinadas às fontes oficiais.
