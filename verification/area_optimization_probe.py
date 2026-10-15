#!/usr/bin/env python3
"""Compara opções estruturais de BCD em diretórios separados do Quartus."""
import hashlib
import json
from pathlib import Path
import subprocess
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
BIN = Path('/home/edupires/altera_lite/25.1std/quartus/bin')
OUT = ROOT / 'verification/results/quartus/optimization-probe'
RUN = OUT / ('run-' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
RTL = [f'rtl/{name}.v' for name in (
    'entrada_coeficientes', 'somador_completo', 'somador_subtrator', 'multiplicadores',
    'polinomio_y', 'raiz_quadrada_u17', 'divisor_9_por_8', 'raizes_quadraticas',
    'seletor_resultado', 'exibicao_decimal', 'sinalizadores_status', 'modulo_principal')]
PROJECT = [f'quartus/pbl02.{ext}' for ext in ('qpf', 'qsf', 'sdc')]

ADD3 = '''module decimal_add3(input wire [3:0] digit,output wire [3:0] corrected);
wire [3:0] n;
wire [2:0] a0,a1,a2,b0,b1,b2,c0,c1,d1,d2;
not n0(n[0],digit[0]); not n1(n[1],digit[1]);
not n2(n[2],digit[2]); not n3(n[3],digit[3]);
and a00(a0[0],digit[2],digit[1],n[0]);
and a01(a0[1],n[3],n[2],digit[0]);
and a02(a0[2],digit[3],n[0]); or o0(corrected[0],a0[0],a0[1],a0[2]);
and a10(b0[0],digit[1],digit[0]);
and a11(b0[1],n[2],digit[1]);
and a12(b0[2],digit[3],n[0]); or o1(corrected[1],b0[0],b0[1],b0[2]);
and a20(c0[0],digit[3],digit[0]);
and a21(c0[1],digit[2],n[1],n[0]); or o2(corrected[2],c0[0],c0[1]);
and a30(d1[0],digit[2],digit[0]);
and a31(d2[0],digit[2],digit[1]); or o3(corrected[3],digit[3],d1[0],d2[0]);
endmodule
'''

DECODER = '''module decimal_bcd_segments(input wire [3:0] digit,output wire [6:0] segments);
wire [3:0] n;
wire [1:0] p0,p1,p2,p6;
wire [2:0] p3,p5;
not n0(n[0],digit[0]); not n1(n[1],digit[1]);
not n2(n[2],digit[2]); not n3(n[3],digit[3]);
and a00(p0[0],n[3],n[2],n[1],digit[0]);
and a01(p0[1],digit[2],n[1],n[0]); or o0(segments[0],p0[0],p0[1]);
and a10(p1[0],digit[2],digit[1],n[0]);
and a11(p1[1],digit[2],n[1],digit[0]); or o1(segments[1],p1[0],p1[1]);
and a20(p2[0],digit[3],digit[0]);
and a21(p2[1],n[2],digit[1],n[0]); or o2(segments[2],p2[0],p2[1]);
and a30(p3[0],n[3],n[2],n[1],digit[0]);
and a31(p3[1],digit[2],digit[1],digit[0]);
and a32(p3[2],digit[2],n[1],n[0]); or o3(segments[3],p3[0],p3[1],p3[2]);
or o4(segments[4],digit[0],p0[1]);
and a50(p5[0],digit[1],digit[0]);
and a51(p5[1],n[2],digit[1]);
and a52(p5[2],n[3],n[2],digit[0]); or o5(segments[5],p5[0],p5[1],p5[2]);
and a60(p6[0],n[3],n[2],n[1]);
and a61(p6[1],digit[2],digit[1],digit[0]); or o6(segments[6],p6[0],p6[1]);
endmodule
'''


def replace_module(source, name, replacement):
    """Troca o texto de um módulo Verilog pelo módulo indicado."""
    start = source.index(f'module {name}(')
    end = source.index('\nendmodule', start) + len('\nendmodule')
    return source[:start] + replacement.rstrip() + source[end:]


def candidate(source, mode):
    """Monta a versão do projeto com a otimização escolhida."""
    if mode in ('add3', 'both'):
        source = replace_module(source, 'decimal_add3', ADD3)
    if mode in ('decoder', 'both'):
        source = replace_module(source, 'decimal_bcd_segments', DECODER)
    return source


def check_truth_tables():
    """Confere as tabelas lógicas das duas opções de BCD."""
    corrected = (0, 1, 2, 3, 4, 8, 9, 10, 11, 12)
    for digit, expected in enumerate(corrected):
        d3, d2, d1, d0 = ((digit >> bit) & 1 for bit in (3, 2, 1, 0))
        n3, n2, n1, n0 = (1-d3, 1-d2, 1-d1, 1-d0)
        outputs = (
            (d2*d1*n0) | (n3*n2*d0) | (d3*n0),
            (d1*d0) | (n2*d1) | (d3*n0),
            (d3*d0) | (d2*n1*n0),
            d3 | (d2*d0) | (d2*d1))
        actual = sum(value << bit for bit, value in enumerate(outputs))
        assert actual == expected == (digit if digit < 5 else digit + 3)
        for carry_in in (0, 1):
            assert (((expected & 7) << 1) | carry_in) <= 9
    off = (
        {1, 4}, {5, 6}, {2, 9}, {1, 4, 7},
        {1, 3, 4, 5, 7, 9}, {1, 2, 3, 7}, {0, 1, 7})
    for digit in range(10):
        d3, d2, d1, d0 = ((digit >> bit) & 1 for bit in (3, 2, 1, 0))
        n3, n2, n1, n0 = (1-d3, 1-d2, 1-d1, 1-d0)
        outputs = (
            (n3*n2*n1*d0) | (d2*n1*n0),
            (d2*d1*n0) | (d2*n1*d0),
            (d3*d0) | (n2*d1*n0),
            (n3*n2*n1*d0) | (d2*d1*d0) | (d2*n1*n0),
            d0 | (d2*n1),
            (d1*d0) | (n2*d1) | (n3*n2*d0),
            (n3*n2*n1) | (d2*d1*d0))
        assert tuple(bit for bit, value in enumerate(outputs) if value) == tuple(
            bit for bit, values in enumerate(off) if digit in values)


def main():
    """Executa a comparação das opções em diretórios separados do Quartus."""
    check_truth_tables()
    RUN.mkdir(parents=True, exist_ok=False)
    version = subprocess.run([str(BIN / 'quartus_sh'), '--version'],
                             check=True, capture_output=True, text=True).stdout
    results = {'tool': str(BIN / 'quartus_sh'), 'version': version.strip(), 'modes': {}}
    for mode in ('add3', 'decoder', 'both'):
        workspace = RUN / mode
        source_hashes = {}
        for name in RTL + PROJECT:
            target = workspace / name
            target.parent.mkdir(parents=True, exist_ok=True)
            data = (ROOT / name).read_bytes()
            if name == 'rtl/exibicao_decimal.v':
                data = candidate(data.decode(), mode).encode()
            target.write_bytes(data)
            source_hashes[name] = hashlib.sha256(data).hexdigest()
        compile_log = workspace / 'compile.log'
        with compile_log.open('wb') as log:
            result = subprocess.run(
                [str(BIN / 'quartus_sh'), '--flow', 'compile', 'pbl02'],
                cwd=workspace / 'quartus', stdout=log, stderr=subprocess.STDOUT)
        output = workspace / 'quartus/output_files'
        fit = output / 'pbl02.fit.summary'
        mode_result = {
            'exit_code': result.returncode,
            'input_source_sha256': source_hashes,
            'command': [str(BIN / 'quartus_sh'), '--flow', 'compile', 'pbl02'],
            'compile_log': str(compile_log.relative_to(ROOT)),
        }
        if result.returncode == 0 and fit.exists():
            mode_result['fit_summary'] = fit.read_text(errors='replace')
            timing_dir = workspace / 'timing'
            timing_dir.mkdir()
            timing_log = workspace / 'timing.log'
            with timing_log.open('wb') as log:
                timing = subprocess.run(
                    [str(BIN / 'quartus_sta'), '-t',
                     str(ROOT / 'verification/results/quartus/report_timing.tcl'),
                     str(timing_dir)], cwd=workspace / 'quartus',
                    stdout=log, stderr=subprocess.STDOUT)
            mode_result['timing_exit_code'] = timing.returncode
            mode_result['timing_command'] = [
                str(BIN / 'quartus_sta'), '-t',
                str(ROOT / 'verification/results/quartus/report_timing.tcl'),
                str(timing_dir)]
            mode_result['timing_log'] = str(timing_log.relative_to(ROOT))
        results['modes'][mode] = mode_result
        (RUN / 'manifest.json').write_text(json.dumps(results, indent=2) + '\n')
        if result.returncode:
            raise SystemExit(result.returncode)
    print(json.dumps({'run': str(RUN.relative_to(ROOT)), 'results': results}, indent=2))


if __name__ == '__main__':
    main()
