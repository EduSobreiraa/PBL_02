# Planejamento incremental do PBL02

Este roteiro é uma proposta de organização, não uma decisão técnica aprovada. A implementação Verilog só começa após revisão documental humana e fechamento das pendências marcadas como bloqueadoras.

## Fase 0 — Consolidar e aprovar requisitos

- **Objetivo:** validar `requisitos.md`, rastreabilidade e decisões delegadas ao grupo.
- **Dependências:** enunciado PBL, manual oficial da placa, `regras.md`.
- **Entregáveis:** requisitos e critérios revisados; lacunas confirmadas.
- **Conclusão:** responsável/tutor aprova a interpretação dos requisitos sem ambiguidade crítica.
- **Riscos:** enunciado não quantifica larguras, precisão interna e semântica detalhada de flags.

## Fase 1 — Fechar interfaces e representação

- **Objetivo:** decidir controles, carga, reset/clock, formatos e comportamento de saída.
- **Dependências:** Fase 0; parecer sobre sintaxe de flip-flop estrutural.
- **Entregáveis:** `decisoes.md` aprovado, `pendencias.md` reduzido, contratos em `interfaces.md`.
- **Conclusão:** cada sinal e formato necessário tem origem, largura, temporização e comportamento documentados.
- **Riscos:** as restrições do HDL podem exigir uma forma de armazenamento diferente da inicialmente imaginada.

## Fase 2 — Arquitetura mínima e dimensionamento

- **Objetivo:** desenhar e dimensionar as duas operações e os recursos compartilhados, com circuito mínimo conforme o PBL.
- **Dependências:** Fase 1.
- **Entregáveis:** arquitetura revisada, responsabilidades finais dos módulos, cálculo das larguras e formatos.
- **Conclusão:** nenhuma largura/interpretação numérica crítica fica implícita; módulos e interfaces são revisáveis.
- **Riscos:** área/caminho lógico de multiplicação, raiz e divisão; precisão intermediária. O arredondamento final das raízes está decidido como exceção autorizada, embora REQ-006/PDF ainda publique truncamento (DEC-007).

## Fase 3 — Implementação incremental (futura; sem iniciar nesta etapa)

- **Objetivo:** implementar módulos estruturais pequenos conforme `modulos.md` e regras Verilog.
- **Dependências:** aprovação explícita da documentação e da arquitetura; regras e ferramenta confirmadas.
- **Entregáveis:** HDL estrutural acompanhado de revisão de escopo e interface por módulo.
- **Conclusão:** cada módulo compila isoladamente no fluxo definido e não usa construções proibidas.
- **Riscos:** escopo de sintaxe ambíguo, warnings, largura assinada e comportamento de reset.

## Fase 4 — Simulação e verificação

- **Objetivo:** validar módulos e integração contra casos de `verificacao.md`.
- **Dependências:** Fase 3; simulador e convenções aprovados.
- **Entregáveis:** testbenches, resultados, casos reprodutíveis e relatório de falhas/correções.
- **Conclusão:** requisitos testáveis rastreados para evidências; divergências explicadas.
- **Riscos:** valores esperados dependem do formato aprovado; simulação pode não refletir pinagem/temporização física.

## Fase 5 — Projeto e síntese Quartus

- **Objetivo:** configurar projeto para o dispositivo DE10-Lite, compilar e revisar síntese/ajustes de pinos.
- **Dependências:** Fases 3–4, Quartus Prime Standard Lite 25.1std.0 Build 1129 (DEC-021), baseline de pinagem oficial (DEC-018).
- **Entregáveis:** arquivos de projeto, relatórios de compilação/síntese, warnings e contagem de LEs.
- **Conclusão:** compilação sem erros; warnings e resultados relevantes revisados; restrições de clock/pinos documentadas.
- **Riscos:** handbook disponível é v17.1, anterior à instalação confirmada Quartus Prime Standard Lite 25.1std.0 Build 1129; ainda não há QSF/QPF do PBL02.

## Fase 6 — Validação física e documentação final

- **Objetivo:** testar entradas, armazenamento, resultados, displays e LEDs na DE10-Lite; concluir relatório e apresentação.
- **Dependências:** síntese bem-sucedida, placa disponível, pinagem e fluxo de operação aprovados.
- **Entregáveis:** evidências de demonstração, análise de recursos/testes e relatório conforme modelo do tutor.
- **Conclusão:** casos físicos relevantes documentados; integrantes preparados para explicar o projeto.
- **Riscos:** polaridade de botões, restrições físicas dos displays e divergência entre bancada e simulação.

## Estado atual

Baseline documental alinhada às decisões ratificadas e pronta para revisão humana. Todas as pendências de alta prioridade estão resolvidas. PEN-004 segue bloqueada pela origem de C; PEN-019 aguarda execução da estratégia de validação aprovada. PEN-020 foi adiada para a etapa de relatório. Não iniciar implementação ou síntese antes da revisão humana da baseline e do fechamento das pendências que bloqueiam a tarefa específica.
