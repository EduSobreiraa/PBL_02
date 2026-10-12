# Plano de execução do PBL02

## Mudança aprovada em 11/10/2026

O responsável delegou decisões técnicas compatíveis aos agentes, sem novas consultas. Um sprint único fecha as escolhas; em seguida, os sprints de implementação executam contratos já definidos. Architect e Reviewer aceitaram DEC-030/031 na primeira rodada. Não há decisão técnica local em aberto; validações e obrigações externas continuam rastreadas.

## Sequência

1. Fechamento: DEC-030/031, atualização canônica, TASKs e briefs, auditoria documental.
2. Sprint2: extensão loaded de TASK002; células/soma/subtração TASK003; multiplicadores TASK007; composição y TASK004. 002 e003 são independentes;007 reutiliza células003;004 depende de003/007 aprovadas.
3. Sprint3: executar referência independente/exaustão TASK005 e unidades sqrt/divisão TASK008/009, depois composição TASK011. F16 não bloqueia: foi substituído por método exato com resíduos, cuja prova não dispensa testes.
4. Sprint4: seletor/decimal/flags, com testes isolados e integração dos contratos de saída.
5. Sprint5: top-level, simulação de sistema, conformidade e Quartus com pinagem/timing reais.
6. Sprint6: validação física e relatório baseado em resultados; aplicar o modelo externo quando obtido.

## Regras de avanço

Somente código de TASK READY, com brief. Testes e auditoria independentes antes de APPROVED; nunca fechar implementação por simples decisão. Escolhas compatíveis posteriores passam pelo fluxo de decisão delegado sem consulta automática ao usuário. Achados que violem restrições são corrigidos, não autorizados por urgência. Gates antigos de revisão humana da baseline estão satisfeitos pela delegação atual.

## Critérios que permanecem

DUT estrutural salvo captura incondicional em FF dedicado; mínimo31FF justificado; ausência de FSM/if/else/buf/laços/generate; matemática exata no domínio; interfaces públicas preservadas por cores privados; arredondamento DEC007; síntese, testes e placa com evidência. Recursos em LEs e atraso só são conhecidos após medição.

Detalhamento em `sprints/README.md`, `interfaces.md`, `arquitetura.md` e `tasks/`. Requisitos P0 não foram reescritos.

## Progresso após fechamento — 11/10/2026

Sprint de decisões e Sprints2–5 concluídas e auditadas. TASK002/003/004/005/006/007/008/009/010/011/012/013/015/017/018/019 APPROVED. A síntese/STA registra 2.187 LEs, 31 FF, zero latches e 65 pinos conferidos. Permanecem validação física e relatório conforme requisitos de placa/entrega nas TASKs014/016. Evidências em docs/sprints e nas TASKs correspondentes.
