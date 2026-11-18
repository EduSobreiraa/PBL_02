#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

enum { COEFFICIENTS = 6, MAX_STEPS = 400 };
typedef struct {
    int key_n;
    int sw;
    int processing_done;
    int expect_start;
    int expect_input_ready;
    int check;
    int expected[COEFFICIENTS];
    const char *label;
} test_step;

static test_step steps[MAX_STEPS];
static int step_count;
static int step_index;
static int expected_coefficients[COEFFICIENTS];
static int expected_ready;
static vpiHandle clk_h, key_h, sw_h, done_h;
static vpiHandle coefficient_h[COEFFICIENTS];
static vpiHandle start_h, ready_h;
static s_vpi_time readonly_time;

static void fail_now(const char *message)
{
    vpi_printf("VPI FAIL: %s\n", message);
    fflush(stdout);
    exit(EXIT_FAILURE);
}

static vpiHandle handle(const char *path)
{
    vpiHandle result = vpi_handle_by_name((PLI_BYTE8 *)path, NULL);
    if (result == NULL) {
        char message[256];
        snprintf(message, sizeof(message), "cannot find VPI handle %s", path);
        fail_now(message);
    }
    return result;
}

static void put_integer(vpiHandle target, int value)
{
    s_vpi_value v;
    v.format = vpiIntVal;
    v.value.integer = value;
    vpi_put_value(target, &v, NULL, vpiNoDelay);
}

static int get_integer(vpiHandle target)
{
    s_vpi_value v;
    v.format = vpiIntVal;
    vpi_get_value(target, &v);
    return v.value.integer;
}

static void append_step(int key_n, int sw, int done, int start,
                        int ready, const char *label)
{
    test_step *s;
    int i;
    if (step_count >= MAX_STEPS) fail_now("scenario step capacity exceeded");
    s = &steps[step_count++];
    s->key_n = key_n;
    s->sw = sw;
    s->processing_done = done;
    s->expect_start = start;
    s->expect_input_ready = ready;
    s->check = 1;
    s->label = label;
    for (i = 0; i < COEFFICIENTS; i++) s->expected[i] = expected_coefficients[i];
}

static void idle_cycles(int count, int key_n, int sw, int done, const char *label)
{
    int i;
    for (i = 0; i < count; i++) append_step(key_n, sw, done, 0, expected_ready, (i == count - 1) ? label : NULL);
}

static void key0_event(int sw, int accepted_slot, int accepted_value,
                       int ready_after, int done, const char *label)
{
    int i;
    /* Two synchronizer stages and the following edge-qualified consumer edge. */
    for (i = 0; i < 2; i++) append_step(2, sw, done, 0, expected_ready, NULL);
    if (accepted_slot >= 0) expected_coefficients[accepted_slot] = accepted_value;
    expected_ready = ready_after;
    append_step(2, sw, done, 0, expected_ready, label);
    /* Holding KEY0 cannot repeat the capture or START. */
    append_step(2, sw, done, 0, expected_ready, NULL);
    append_step(2, sw, done, 0, expected_ready, NULL);
    idle_cycles(3, 3, sw, done, NULL);
}

static void start_event(int done, const char *label)
{
    int i;
    for (i = 0; i < 2; i++) append_step(2, 0, done, 0, expected_ready, NULL);
    append_step(2, 0, done, 1, expected_ready, label);
    append_step(2, 0, done, 0, expected_ready, "START pulse deasserts after one cycle");
    idle_cycles(3, 3, 0, done, NULL);
}

static void reset_session(const char *label)
{
    int i;
    /* KEY0 stays released; KEY1 low is synchronized through two stages. */
    for (i = 0; i < 5; i++) {
        if (i == 2) {
            memset(expected_coefficients, 0, sizeof(expected_coefficients));
            expected_ready = 0;
        }
        append_step(1, 0, 0, 0, expected_ready, (i == 4) ? label : NULL);
    }
    idle_cycles(5, 3, 0, 0, "release KEY1 without a spurious KEY0 event");
}

static void build_scenario(void)
{
    memset(expected_coefficients, 0, sizeof(expected_coefficients));
    expected_ready = 0;
    reset_session("synchronized KEY1 reset clears initialized session");

    /* Invalid +128 does not capture a1 or advance; valid +127 then does. */
    key0_event(0x080, -1, 0, 0, 0, "positive magnitude 128 rejected without advancing");
    key0_event(0x07f, 0, 127, 0, 0, "a1 captures +127 once despite a held KEY0");
    key0_event(0x181, -1, 0, 0, 0, "negative magnitude 129 rejected without advancing");
    key0_event(0x180, 1, -128, 0, 0, "b1 captures -128");
    key0_event(0x100, 2, 0, 0, 0, "c1 normalizes negative zero to zero");
    key0_event(0x000, 3, 0, 0, 0, "a2 captures zero for disabled F2");
    key0_event(0x000, 4, 0, 0, 0, "b2 captures zero for disabled F2");
    key0_event(0x000, 5, 0, 1, 0, "c2 completes ordered capture but does not start");

    start_event(0, "separate KEY0 event starts after c2");
    key0_event(0x000, -1, 0, 1, 0, "KEY0 event ignored while processing_done is low");
    idle_cycles(2, 3, 0, 1, "processing_done rearms start wait");
    start_event(1, "new START accepted while old processing_done remains high");
    key0_event(0x000, -1, 0, 1, 1, "KEY0 event ignored while stale processing_done remains high");
    idle_cycles(3, 3, 0, 0, "processing_done low is observed before next completion");
    key0_event(0x000, -1, 0, 1, 0, "KEY0 event ignored during rearmed processing");
    idle_cycles(2, 3, 0, 1, "new completion rearms start wait after low-to-high handshake");
    start_event(1, "later START rearmed after processing_done deassertion and assertion");

    reset_session("KEY1 synchronously clears all six coefficients and progress");
    key0_event(0x001, 0, 1, 0, 0, "new session a1=1");
    key0_event(0x002, 1, 2, 0, 0, "new session b1=2");
    key0_event(0x003, 2, 3, 0, 0, "new session c1=3");
    key0_event(0x000, 3, 0, 0, 0, "F2 tuple a2=0");
    key0_event(0x001, 4, 1, 0, 0, "F2 tuple b2=1 retained for processor error classification");
    key0_event(0x000, 5, 0, 1, 0, "F2 a2=0 nonzero tuple captured without input-range error");
    idle_cycles(3, 3, 0, 0, "F2 tuple remains stored after completion of input");
}

static PLI_INT32 drive_inputs(p_cb_data cb);
static PLI_INT32 raise_clock(p_cb_data cb);
static PLI_INT32 check_outputs(p_cb_data cb);
static PLI_INT32 lower_clock(p_cb_data cb);

static void after_delay(PLI_INT32 (*callback)(p_cb_data))
{
    s_cb_data cb;
    s_vpi_time delay;
    memset(&cb, 0, sizeof(cb));
    memset(&delay, 0, sizeof(delay));
    delay.type = vpiSimTime;
    delay.low = 1;
    cb.reason = cbAfterDelay;
    cb.cb_rtn = callback;
    cb.time = &delay;
    vpi_register_cb(&cb);
}

static void readonly_check(void)
{
    s_cb_data cb;
    memset(&cb, 0, sizeof(cb));
    memset(&readonly_time, 0, sizeof(readonly_time));
    readonly_time.type = vpiSimTime;
    cb.reason = cbReadOnlySynch;
    cb.cb_rtn = check_outputs;
    cb.time = &readonly_time;
    vpi_register_cb(&cb);
}

static PLI_INT32 drive_inputs(p_cb_data cb)
{
    test_step *s;
    (void)cb;
    if (step_index >= step_count) {
        vpi_printf("VPI PASS: all %d coefficient-input steps passed\n", step_count);
        vpi_control(vpiFinish, 0);
        return 0;
    }
    s = &steps[step_index];
    put_integer(clk_h, 0);
    put_integer(key_h, s->key_n);
    put_integer(sw_h, s->sw);
    put_integer(done_h, s->processing_done);
    after_delay(raise_clock);
    return 0;
}

static PLI_INT32 raise_clock(p_cb_data cb)
{
    (void)cb;
    put_integer(clk_h, 1);
    readonly_check();
    return 0;
}

static PLI_INT32 check_outputs(p_cb_data cb)
{
    test_step *s = &steps[step_index];
    static const char *names[COEFFICIENTS] = {"a1", "b1", "c1", "a2", "b2", "c2"};
    int i;
    (void)cb;
    if (!s->check) {
        after_delay(lower_clock);
        return 0;
    }
    for (i = 0; i < COEFFICIENTS; i++) {
        int actual = get_integer(coefficient_h[i]);
        if (actual != s->expected[i]) {
            char message[256];
            snprintf(message, sizeof(message), "step %d %s: %s expected %d, got %d", step_index, s->label ? s->label : "cycle", names[i], s->expected[i], actual);
            fail_now(message);
        }
    }
    if (get_integer(start_h) != s->expect_start) {
        char message[256];
        snprintf(message, sizeof(message), "%s: start_pulse expected %d, got %d", s->label ? s->label : "cycle", s->expect_start, get_integer(start_h));
        fail_now(message);
    }
    if (get_integer(ready_h) != s->expect_input_ready) {
        char message[256];
        snprintf(message, sizeof(message), "%s: input_ready expected %d, got %d", s->label ? s->label : "cycle", s->expect_input_ready, get_integer(ready_h));
        fail_now(message);
    }
    if (s->label) vpi_printf("VPI PASS: %s\n", s->label);
    after_delay(lower_clock);
    return 0;
}

static PLI_INT32 lower_clock(p_cb_data cb)
{
    (void)cb;
    put_integer(clk_h, 0);
    step_index++;
    if (step_index >= step_count) {
        vpi_printf("VPI PASS: all %d coefficient-input steps passed\n", step_count);
        vpi_control(vpiFinish, 0);
    } else {
        drive_inputs(NULL);
    }
    return 0;
}

static PLI_INT32 start_simulation(p_cb_data cb)
{
    (void)cb;
    clk_h = handle("tb_coefficient_input_pbl03.clk");
    key_h = handle("tb_coefficient_input_pbl03.key_n");
    sw_h = handle("tb_coefficient_input_pbl03.sw");
    done_h = handle("tb_coefficient_input_pbl03.processing_done");
    coefficient_h[0] = handle("tb_coefficient_input_pbl03.a1");
    coefficient_h[1] = handle("tb_coefficient_input_pbl03.b1");
    coefficient_h[2] = handle("tb_coefficient_input_pbl03.c1");
    coefficient_h[3] = handle("tb_coefficient_input_pbl03.a2");
    coefficient_h[4] = handle("tb_coefficient_input_pbl03.b2");
    coefficient_h[5] = handle("tb_coefficient_input_pbl03.c2");
    start_h = handle("tb_coefficient_input_pbl03.start_pulse");
    ready_h = handle("tb_coefficient_input_pbl03.input_ready");
    build_scenario();
    step_index = 0;
    put_integer(clk_h, 0);
    drive_inputs(NULL);
    return 0;
}

static void register_callbacks(void)
{
    s_cb_data cb;
    memset(&cb, 0, sizeof(cb));
    cb.reason = cbStartOfSimulation;
    cb.cb_rtn = start_simulation;
    vpi_register_cb(&cb);
}

void (*vlog_startup_routines[])(void) = {register_callbacks, 0};
