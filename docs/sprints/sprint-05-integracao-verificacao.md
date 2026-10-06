# Sprint 5 — Integração, simulação e Quartus

## Objetivo

Integrar os blocos aprovados sob o top-level e gerar evidências reprodutíveis de funcionamento e síntese.

## Escopo planejado

- Instanciar armazenamento, caminhos de cálculo, seletor, apresentação e flags no top-level.
- Executar os testes de integração TEST-010/011 e revisão estática TEST-013.
- Criar/ajustar projeto Quartus para DE10-Lite conforme top-level e baseline de pinagem; compilar e revisar warnings, recursos e LEs (TEST-014).
- Registrar comandos, versões, vetores, resultados e falhas nas TASKs.

## Dependências

- TASKs das sprints anteriores aprovadas ou bloqueios explicitamente isolados e sem ligação ao caminho integrado avaliado.
- Top-level, interfaces e pin assignments definidos; backend/versão do simulador registrados.
- Quartus Prime Standard Lite 25.1std.0 Build 1129 (DEC-021).

## Critérios de conclusão

- Integração corresponde às interfaces acordadas e não introduz lógica proibida.
- Casos integrados exercitam carga, seleção, cálculo, flags e apresentação.
- Síntese compila sem erros; warnings, dispositivo, pinos, restrições de clock e contagem de LEs são registrados e revisados.

## Bloqueios e limites

- Não atualizar pinagem sem autorização; conferir QSF contra o manual e a baseline DEC-018.
- Flags ou caminhos ainda bloqueados não podem ser declarados validados; documentar exatamente a cobertura disponível.
