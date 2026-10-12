# TASK-015 — compilação, fitting e STA reais

Execução11/10/2026. **Compilação/fitting e revisão independente concluídos; TASK-015 APPROVED.** Nenhuma programação/validação de placa executada.

## Reprodução e identidade

```sh
python3 verification/results/quartus/run_compile.py
```

Quartus25.1std.0 Build1129 SC Lite, instalado em `/home/edupires/altera_lite/25.1std/quartus/bin`. `version.log` registra versão real. Runner copia12RTL+QPF/QSF/SDC para workspace temporário e `source_snapshot`, executa `quartus_sh --flow compile pbl02`, preserva output_files e executa `quartus_sta -t report_timing.tcl <diretório de resultados>` em todos corners disponíveis. `manifest.json` registra comandos,workspace,exitcodes e SHA256 dos fontes/evidências. Os comandos foram executados com exit0. QPF/QSF/SDC e RTL congelados após execução válida.

Primeira tentativa: QSF com nomes entre braces foi interpretado literalmente; assignments ignorados e pinos realocados. Essa tentativa não é evidência de aprovação, apesar de exit0. Todo seu resultado está segregado em `attempt-1-invalid-qsf-names/`. Segunda tentativa corrige apenas serialização dos nomes e configura2processadores; é a evidência final neste diretório. Nenhum RTL alterado.

## Recursos finais

| Item | Resultado |
|---|---:|
| Dispositivo |10M50DAF484C7G|
| LEs |2187/49760 (4%)|
| Funções combinacionais |2182|
| FF |31|
| Latches |0|
| Pinos |65|
| Memória |0bits|
| Multiplicadores embarcados |0|
| PLL |0|

Fonte: `output_files/pbl02.fit.summary`. Census STA confirma31registros/0latches (`timing-detail.log`), usando get_register_info -is_latch, não inferindo ausência apenas por silêncio de warnings.31FF concordam com24coeficientes+2progresso+5sincronização/histórico. Isso não prova mínimo global de LEs.

## Pinagem

`pins-audit.json`:65/65 portas pós-fit conferidas contra docs/hardware.md, incluindo clockP11, KEY Schmitt e demaisLVTTL;65pinos únicos. QSF local e arquivo pós-fit `output_files/pbl02.pin` coincidem. Sem DP extra. Auditor independente deve confirmar o mesmo mapa.

## Timing

Clock real20ns. Exceções false_path apenas KEY0/KEY1 até primeiro estágio correspondente; consultas STA encontraram exatamente1registro em cada destino. Nenhuma exceção entre estágios ou global. Saídas recebem max_delay1000000ns (1ms), separado do clock registrado.

| Corner | Setup registrado mínimo(ns) | Hold mínimo(ns) | Maior atraso até output(ns) | Slack orçamento output(ns) |
|---|---:|---:|---:|---:|
|Slow1200mV85C|15.669|0.348|160.472|999835.821|
|Slow1200mV0C|15.957|0.312|147.619|999848.975|
|Fast1200mV0C|18.027|0.153|69.713|999928.541|

Pior caminho registrado: key0_history→coefficient_c_bit5, atraso de dados4.257ns, slack15.669ns. Maior caminho combinacional até saída: coefficient_a_bit2→HEX2[5],160.472ns. O slack de orçamento usa análise completa incluindo efeitos de lançamento; não é simplesmente1ms menos report_path. Relatórios detalhados por corner incluem10caminhos de setup/hold/output e SW→registro; maior SW→registro no corner lento85C:4.921ns.

Setup/hold registrados e orçamento de acomodação de saída atendem às restrições modeladas. **Não é fechamento temporal de todas as interfaces assíncronas.** SW não tem relação de fase com clock e não recebeu input delay inventado; requer estabilidade manual antes/durante captura. Relatório UCP mantém entradas assíncronas e hold externo de outputs sem garantia: displays/LEDs não têm receptor registrado com hold especificado. Outputs têm orçamento máximo explícito, sem mínimo externo inventado. Nenhuma falha foi escondida por false_path global. Não se promete captura consistente durante comutação/bounce. STA detectou automaticamente1cadeia sincronizadora e não calculou MTBF; isso não comprova MTBF dos dois botões.

## Warnings tratados

Compilação final:0errors,11warnings,0critical warnings.

-13024 + sete13410: LEDR0 eLEDR4..9 constantes0, conforme contratos OV/faixas e LEDs não usados.
-292013: LogicLock opcional requer licença; não utilizado pelo projeto, fitting final foi concluído na Lite.
-15714: drive strength não especificado para52outputs. Baseline aprova pino/I/O, não drive strength; fitter aplicou8mA como mostrado no relatório. Nenhuma escolha elétrica foi inventada para silenciar aviso. Validação elétrica/placa continua externa.
-169177:13inputs3.3V devem respeitar condições elétricas MAX10/AN447. Usa pinagem oficial DE10-Lite, sem periféricos externos; aviso registrado, sem alegação de validação elétrica física.

Arquivos .sof/.pof são produto real da compilação, não evidência de gravação em placa. Síntese não altera regras de descrição do RTL auditado.
