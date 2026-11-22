#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

enum { MAX_STEPS = 600, COEFFICIENTS = 6 };
typedef struct {
    int key_n, sw, start, busy, done, ready, processor_busy, processor_done;
    int coefficients[COEFFICIENTS];
    int check_coefficients;
    int probe_reset, probe_ready, probe_start, probe_f1, probe_f2, probe_roots_ready;
    int probe_busy, probe_done;
    const char *label;
} test_step;
static test_step steps[MAX_STEPS];
static int count, index_now, expected_coefficients[COEFFICIENTS];
static vpiHandle clk_h, key_h, sw_h, start_h, busy_h, done_h, ready_h;
static vpiHandle coefficient_h[COEFFICIENTS], busy1_h, busy2_h, done1_h, done2_h;
static vpiHandle error2_h, vertex2_h, reset_h;
static vpiHandle probe_reset_h, probe_ready_h, probe_start_h, probe_f1_h, probe_f2_h, probe_roots_ready_h;
static vpiHandle probe_busy_h, probe_done_h;
static s_vpi_time readonly_time;

static void fail(const char *message)
{
    vpi_printf("VPI FAIL: %s\n", message);
    fflush(stdout);
    exit(EXIT_FAILURE);
}

static vpiHandle handle(const char *name)
{
    vpiHandle h = vpi_handle_by_name((PLI_BYTE8 *)name, NULL);
    if (!h) fail(name);
    return h;
}

static void put(vpiHandle h, int value)
{
    s_vpi_value v;
    v.format = vpiIntVal;
    v.value.integer = value;
    vpi_put_value(h, &v, NULL, vpiNoDelay);
}

static int get(vpiHandle h)
{
    s_vpi_value v;
    v.format = vpiIntVal;
    vpi_get_value(h, &v);
    return v.value.integer;
}

static test_step *add(int key, int sw, int start, int busy, int done, int ready,
                      const char *label)
{
    test_step *s;
    if (count == MAX_STEPS) fail("scenario capacity exceeded");
    s = &steps[count++];
    memset(s, 0, sizeof(*s));
    s->key_n = key; s->sw = sw;
    s->start = start; s->busy = busy; s->done = done; s->ready = ready;
    s->processor_busy = -1; s->processor_done = -1;
    s->probe_reset = 1; s->probe_busy = 0; s->probe_done = 0;
    s->probe_roots_ready = 1;
    s->check_coefficients = 1;
    memcpy(s->coefficients, expected_coefficients, sizeof(s->coefficients));
    s->label = label;
    return s;
}

static void reset_session(const char *label)
{
    int i;
    for (i = 0; i < 5; ++i) {
        test_step *s;
        if (i == 2) memset(expected_coefficients, 0, sizeof(expected_coefficients));
        s = add(1, 0, i < 2 ? -1 : 0, i < 2 ? -1 : 0,
                i < 2 ? -1 : 0, i < 2 ? -1 : 0, i == 4 ? label : NULL);
        if (i < 2) s->check_coefficients = 0;
    }
    for (i = 0; i < 5; ++i) add(3, 0, 0, 0, 0, 0, NULL);
}

static void capture(int slot, int value)
{
    int i, sw = value < 0 ? 256 - value : value;
    for (i = 0; i < 2; ++i) add(2, sw, 0, 0, 0, 0, NULL);
    expected_coefficients[slot] = value;
    add(2, sw, 0, 0, 0, slot == 5, slot == 5 ? "six coefficients captured; review before START" : NULL);
    for (i = 0; i < 3; ++i) add(3, sw, 0, 0, 0, slot == 5, NULL);
}

static void capture_tuple(int f2_enabled)
{
    capture(0, 1); capture(1, 0); capture(2, 0);
    capture(3, f2_enabled); capture(4, 0); capture(5, 0);
}

static void execute(const char *label)
{
    int i;
    int previous_done = count ? steps[count - 1].done : 0;
    test_step *s;
    add(2, 0, 0, 0, previous_done, 1, NULL);
    add(2, 0, 0, 0, previous_done, 1, NULL);
    add(2, 0, 1, 0, previous_done, 1, "KEY0 produces one START pulse");
    s = add(2, 0, 0, 1, 0, 1, "START clears main DONE and validates both processors");
    s->processor_busy = 1; s->processor_done = 0;
    s = add(2, 0, 0, 1, 0, 1, "main waits until it observes both processor DONEs");
    s->processor_busy = 0; s->processor_done = 1;
    for (i = 0; i < 32; ++i) {
        s = add(2, 0, 0, 1, 0, 1, NULL);
        s->busy = -1; s->done = -1;
        s->processor_busy = 0; s->processor_done = 1;
    }
    add(2, 0, 0, 0, 1, 1, label);
    for (i = 0; i < 5; ++i) add(3, 0, 0, 0, 1, 1, i == 4 ? "DONE retained and coefficients preserved" : NULL);
}

static void probe_step(int reset, int ready, int start, int f1, int f2,
                       int busy, int done, const char *label)
{
    test_step *s = add(1, 0, 0, 0, 0, 0, label);
    s->probe_reset = reset; s->probe_ready = ready; s->probe_start = start;
    s->probe_f1 = f1; s->probe_f2 = f2;
    s->probe_busy = busy; s->probe_done = done;
}

static void probe_step_with_roots(int reset, int ready, int start, int f1, int f2,
                                  int roots_ready, int busy, int done, const char *label)
{
    probe_step(reset, ready, start, f1, f2, busy, done, label);
    steps[count - 1].probe_roots_ready = roots_ready;
}

static void build_scenario(void)
{
    int i;
    reset_session("initial synchronized KEY1 reset");
    probe_step(0,0,1,1,1,0,0,"START ignored before input_ready");
    probe_step(0,1,0,1,1,0,0,"main enters REVIEW after input_ready");
    probe_step(1,1,1,1,1,0,0,"reset overrides START in REVIEW");
    probe_step(0,1,0,0,0,0,0,NULL);
    probe_step(0,1,1,0,0,1,0,"START enters processor wait");
    probe_step(0,1,0,1,0,1,0,"F1 DONE alone does not finish main handshake");
    probe_step(0,1,1,0,1,1,0,"F2 DONE alone and START while waiting do not finish");
    probe_step_with_roots(0,1,0,1,1,0,1,0,"both processor DONEs wait for roots_ready");
    probe_step_with_roots(0,1,0,1,1,1,0,1,"both DONEs and roots_ready release DISPLAY");
    probe_step(0,1,0,0,0,0,1,"main DONE retained independently of incoming levels");
    probe_step(0,1,1,1,1,1,0,"new START clears stale main DONE");
    probe_step(1,1,0,0,0,0,0,"reset during WAIT_PROCESSORS");
    probe_step(0,1,0,0,0,0,0,NULL);
    probe_step(0,1,1,0,0,1,0,NULL);
    probe_step(0,1,0,1,1,0,1,NULL);
    probe_step(1,1,1,1,1,0,0,"reset in DISPLAY has priority over new START");
    reset_session("prepare physical-button integration");
    capture_tuple(0);
    for (i=0; i<3; ++i) add(3,127,0,0,0,1,"review holds coefficients without starting");
    execute("F2 null completes without errors or stuck BUSY");
    execute("new execution completes without recapturing coefficients");
    reset_session("reset in DISPLAY clears all coefficients and main outputs");
    capture_tuple(1);
    reset_session("reset in REVIEW clears captured coefficients");
    capture_tuple(1);
    add(2,0,0,0,0,1,NULL);
    add(2,0,0,0,0,1,NULL);
    add(0,0,1,0,0,1,"START emitted while KEY1 enters synchronizer");
    add(0,0,0,1,0,1,"validation begins before synchronized reset is consumed");
    memset(expected_coefficients,0,sizeof(expected_coefficients));
    add(1,0,0,0,0,0,"synchronized KEY1 resets main and processors during validation");
    reset_session("release after validation reset returns to fresh entry");
    capture_tuple(1);
    execute("both enabled processors complete after reset");
}

static void expect(vpiHandle h, int expected, const char *name, const test_step *s)
{
    char message[256];
    int actual;
    if (expected < 0) return;
    actual = get(h);
    if (actual != expected) {
        snprintf(message,sizeof(message),"cycle %d %s: %s expected %d got %d",
                 index_now,s->label ? s->label : "cycle",name,expected,actual);
        fail(message);
    }
}

static PLI_INT32 drive(p_cb_data cb);
static PLI_INT32 raise_clock(p_cb_data cb);
static PLI_INT32 check(p_cb_data cb);
static PLI_INT32 lower_clock(p_cb_data cb);

static void later(PLI_INT32 (*fn)(p_cb_data))
{
    s_cb_data cb;
    s_vpi_time time;
    memset(&cb,0,sizeof(cb)); memset(&time,0,sizeof(time));
    time.type=vpiSimTime; time.low=1;
    cb.reason=cbAfterDelay; cb.cb_rtn=fn; cb.time=&time;
    vpi_register_cb(&cb);
}

static PLI_INT32 drive(p_cb_data cb)
{
    test_step *s=&steps[index_now];
    (void)cb;
    put(clk_h,0); put(key_h,s->key_n); put(sw_h,s->sw);
    put(probe_reset_h,s->probe_reset); put(probe_ready_h,s->probe_ready);
    put(probe_start_h,s->probe_start); put(probe_f1_h,s->probe_f1); put(probe_f2_h,s->probe_f2);
    put(probe_roots_ready_h,s->probe_roots_ready);
    later(raise_clock);
    return 0;
}

static PLI_INT32 raise_clock(p_cb_data unused)
{
    s_cb_data cb;
    (void)unused;
    put(clk_h,1);
    memset(&cb,0,sizeof(cb)); memset(&readonly_time,0,sizeof(readonly_time));
    readonly_time.type=vpiSimTime;
    cb.reason=cbReadOnlySynch; cb.cb_rtn=check; cb.time=&readonly_time;
    vpi_register_cb(&cb);
    return 0;
}

static PLI_INT32 check(p_cb_data cb)
{
    test_step *s=&steps[index_now];
    int i;
    (void)cb;
    expect(start_h,s->start,"START",s); expect(busy_h,s->busy,"BUSY",s);
    expect(done_h,s->done,"DONE",s); expect(ready_h,s->ready,"input_ready",s);
    expect(busy1_h,s->processor_busy,"BUSY F1",s); expect(busy2_h,s->processor_busy,"BUSY F2",s);
    expect(done1_h,s->processor_done,"DONE F1",s); expect(done2_h,s->processor_done,"DONE F2",s);
    expect(probe_busy_h,s->probe_busy,"isolated BUSY",s); expect(probe_done_h,s->probe_done,"isolated DONE",s);
    if (s->check_coefficients) {
        for(i=0;i<COEFFICIENTS;++i) expect(coefficient_h[i],s->coefficients[i],"coefficient",s);
        if (s->coefficients[3]==0 && s->coefficients[4]==0 && s->coefficients[5]==0) {
            expect(error2_h,0,"disabled F2 a-zero error",s);
            expect(vertex2_h,0,"disabled F2 vertex error",s);
        }
        if (s->busy >= 0 && get(busy_h) && get(done_h)) fail("BUSY and DONE overlap");
    }
    if (s->label) vpi_printf("VPI PASS: %s\n",s->label);
    later(lower_clock);
    return 0;
}

static PLI_INT32 lower_clock(p_cb_data cb)
{
    (void)cb;
    put(clk_h,0);
    if (++index_now==count) {
        vpi_printf("VPI PASS: all %d main-handshake cycles passed\n",count);
        vpi_control(vpiFinish,0);
    } else drive(NULL);
    return 0;
}

static PLI_INT32 startup_test(p_cb_data cb)
{
    const char *names[COEFFICIENTS]={"a1","b1","c1","a2","b2","c2"};
    char path[128];
    int i;
    (void)cb;
#define H(h,n) h=handle("tb_main_handshake_pbl03." n)
    H(clk_h,"clk"); H(key_h,"key_n"); H(sw_h,"sw"); H(start_h,"dut.start_pulse");
    H(busy_h,"dut.processing_busy"); H(done_h,"dut.processing_done"); H(ready_h,"dut.input_ready");
    H(busy1_h,"dut.busy_f1"); H(busy2_h,"dut.busy_f2"); H(done1_h,"dut.done_f1"); H(done2_h,"dut.done_f2");
    H(error2_h,"dut.error_a_zero_f2"); H(vertex2_h,"dut.error_vertex_f2"); H(reset_h,"dut.system_reset");
    H(probe_reset_h,"probe_reset"); H(probe_ready_h,"probe_ready"); H(probe_start_h,"probe_start");
    H(probe_f1_h,"probe_done_f1"); H(probe_f2_h,"probe_done_f2");
    H(probe_roots_ready_h,"probe_roots_ready");
    H(probe_busy_h,"probe_busy"); H(probe_done_h,"probe_done");
#undef H
    for(i=0;i<COEFFICIENTS;++i) {
        snprintf(path,sizeof(path),"tb_main_handshake_pbl03.dut.%s",names[i]);
        coefficient_h[i]=handle(path);
    }
    build_scenario();
    drive(NULL);
    return 0;
}

static void startup(void)
{
    s_cb_data cb;
    memset(&cb,0,sizeof(cb)); cb.reason=cbStartOfSimulation; cb.cb_rtn=startup_test;
    vpi_register_cb(&cb);
}
void (*vlog_startup_routines[])(void)={startup,0};
