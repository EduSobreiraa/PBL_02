#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

typedef struct {
    int reset;
    int start;
    int a;
    int b;
    int c;
    int x;
    int y;
    int busy;
    int done;
    int error_a_zero;
    int error_vertex;
    int display_enable;
    int f1_hit;
    int f1_derivative_hit;
    int key_n;
    int sw;
    int check_entry;
    int check_roots;
    int entry_system_reset;
    int entry_start;
    int entry_input_ready;
    int entry_processing_done;
    int entry_busy;
    int entry_a1;
    const char *label;
} test_step;

enum { MAX_STEPS = 128 };
static test_step steps[MAX_STEPS];
static size_t step_count;
static size_t step_index;
static s_cb_data scheduled_callbacks[4];
static s_vpi_time scheduled_times[4];
static vpiHandle clk_h, reset_h, start_h, a_h, b_h, c_h, x_h, y_h;
static vpiHandle busy_h, done_h, error_a_h, error_vertex_h, display_h, hit_h, derivative_hit_h;
static vpiHandle root_x1_h, root_x2_h, root_valid_h;
static vpiHandle key_h, sw_h, entry_reset_h, entry_start_h, entry_ready_h, entry_done_h, entry_busy_h, entry_a_h;

static void fail_now(const char *message)
{
    vpi_printf("VPI FAIL: %s\n", message);
    fflush(stdout);
    exit(EXIT_FAILURE);
}

static vpiHandle get_handle(const char *path)
{
    vpiHandle handle = vpi_handle_by_name((PLI_BYTE8 *)path, NULL);
    if (handle == NULL) {
        char message[256];
        snprintf(message, sizeof(message), "cannot find VPI handle %s", path);
        fail_now(message);
    }
    return handle;
}

static void put_integer(vpiHandle handle, int value)
{
    s_vpi_value v;
    v.format = vpiIntVal;
    v.value.integer = value;
    vpi_put_value(handle, &v, NULL, vpiNoDelay);
}

static int read_bit(vpiHandle handle)
{
    s_vpi_value v;
    PLI_BYTE8 *name;
    v.format = vpiVectorVal;
    vpi_get_value(handle, &v);
    if ((v.value.vector[0].bval & 1U) != 0U) {
        name = vpi_get_str(vpiFullName, handle);
        vpi_printf("VPI FAIL: %s contains X/Z\n", name);
        fflush(stdout);
        exit(EXIT_FAILURE);
    }
    return (int)(v.value.vector[0].aval & 1U);
}

static int read_signed(vpiHandle handle, unsigned width)
{
    s_vpi_value v;
    PLI_BYTE8 *name;
    unsigned mask;
    unsigned raw;
    v.format = vpiVectorVal;
    vpi_get_value(handle, &v);
    mask = (1U << width) - 1U;
    if ((v.value.vector[0].bval & mask) != 0U) {
        name = vpi_get_str(vpiFullName, handle);
        vpi_printf("VPI FAIL: %s contains X/Z\n", name);
        fflush(stdout);
        exit(EXIT_FAILURE);
    }
    raw = v.value.vector[0].aval & mask;
    if ((raw & (1U << (width - 1U))) != 0U) raw |= ~mask;
    return (int)raw;
}

static int rounded_root(long double value)
{
    return value < 0.0L ? (int)ceill(value - 0.5L) : (int)floorl(value + 0.5L);
}

static void expected_roots(int a, int b, int c, int *x1, int *x2, int *valid)
{
    int delta = b * b - 4 * a * c;
    *valid = a != 0 && delta >= 0;
    if (!*valid) {
        *x1 = 0;
        *x2 = 0;
    } else {
        long double radical = sqrtl((long double)delta);
        long double denominator = (long double)(2 * a);
        *x1 = rounded_root((-(long double)b + radical) / denominator);
        *x2 = rounded_root((-(long double)b - radical) / denominator);
    }
}

static void add_step(int reset, int start, int a, int b, int c, int x, int y,
                     int busy, int done, int error_a_zero, int error_vertex,
                     int display_enable, int f1_hit, int derivative_hit,
                     const char *label)
{
    test_step *step;
    if (step_count >= MAX_STEPS) fail_now("test step capacity exceeded");
    step = &steps[step_count++];
    step->reset = reset;
    step->start = start;
    step->a = a;
    step->b = b;
    step->c = c;
    step->x = x;
    step->y = y;
    step->busy = busy;
    step->done = done;
    step->error_a_zero = error_a_zero;
    step->error_vertex = error_vertex;
    step->display_enable = display_enable;
    step->f1_hit = f1_hit;
    step->f1_derivative_hit = derivative_hit;
    step->key_n = 3;
    step->sw = 0;
    step->check_entry = 0;
    step->check_roots = 0;
    step->entry_system_reset = 0;
    step->entry_start = 0;
    step->entry_input_ready = 0;
    step->entry_processing_done = 0;
    step->entry_busy = 0;
    step->entry_a1 = 0;
    step->label = label;
}

static void add_entry_step(int key_n, int sw, int check_entry, int reset,
                           int start, int ready, int done, int busy, int a1,
                           const char *label)
{
    add_step(1,0,1,0,0,0,0,0,0,0,0,0,0,0,label);
    steps[step_count - 1].key_n = key_n;
    steps[step_count - 1].sw = sw;
    steps[step_count - 1].check_entry = check_entry;
    steps[step_count - 1].entry_system_reset = reset;
    steps[step_count - 1].entry_start = start;
    steps[step_count - 1].entry_input_ready = ready;
    steps[step_count - 1].entry_processing_done = done;
    steps[step_count - 1].entry_busy = busy;
    steps[step_count - 1].entry_a1 = a1;
}

static void add_entry_cycles(int count, int key_n, int sw, int check_last,
                             int reset, int start, int ready, int done,
                             int busy, int a1, const char *label)
{
    int i;
    for (i = 0; i < count; i++) {
        add_entry_step(key_n, sw, check_last && i == count - 1,
                       reset, start, ready, done, busy, a1,
                       i == count - 1 ? label : NULL);
    }
}

static void append_capture(int sw, int a1_value, int ready, const char *label)
{
    add_entry_cycles(4, 2, sw, 0, 0, 0, ready, 0, 0, a1_value, NULL);
    add_entry_cycles(4, 3, sw, 1, 0, 0, ready, 0, 0, a1_value, label);
}

static void build_steps(void)
{
#define ADD(r,s,a,b,c,x,y,bu,d,ea,ev,de,h,dh,n) \
    add_step(r,s,a,b,c,x,y,bu,d,ea,ev,de,h,dh,n)
    ADD(1,0,1,0,0,0,0, 0,0,0,0,0,0,0,"reset in WAIT_START");
    ADD(0,0,1,0,0,0,0, 0,0,0,0,0,0,0,"idle after reset");
    ADD(0,1,1,0,0,0,0, 1,0,0,0,0,0,0,"START enters VALIDATE and asserts BUSY");
    ADD(0,1,1,0,0,0,0, 0,1,0,0,1,1,1,"START ignored in VALIDATE; valid outputs complete");
    ADD(0,0,1,0,0,0,0, 0,1,0,0,1,1,1,"DONE and hits retained in COMPLETE");
    ADD(0,1,0,1,0,0,0, 1,0,0,0,0,0,0,"new START lowers old DONE and clears status");
    ADD(0,0,0,1,0,0,0, 0,1,1,0,0,0,0,"a1 zero captured as error");
    ADD(0,0,0,1,0,0,0, 0,1,1,0,0,0,0,"error and DONE retained");
    ADD(0,1,1,22,-119,-11,-240, 1,0,0,0,0,0,0,"new START clears prior error");
    ADD(0,0,1,22,-119,-11,-240, 0,1,0,1,0,0,0,"vertex outside captured; no display or clipped hit");
    ADD(0,0,1,22,-119,-11,-240, 0,1,0,1,0,0,0,"vertex error retained");
    ADD(0,1,1,0,0,0,0, 1,0,0,0,0,0,0,"valid START from COMPLETE");
    ADD(1,1,1,0,0,0,0, 0,0,0,0,0,0,0,"reset in VALIDATE overrides START");
    ADD(0,0,1,0,0,0,0, 0,0,0,0,0,0,0,"idle after VALIDATE reset");
    ADD(0,1,1,0,0,0,0, 1,0,0,0,0,0,0,"start before reset in VALIDATE test");
    ADD(0,0,1,0,0,0,0, 0,1,0,0,1,1,1,"complete before reset in COMPLETE test");
    ADD(1,0,1,0,0,0,0, 0,0,0,0,0,0,0,"reset in COMPLETE clears DONE and display");
    ADD(1,0,1,0,0,0,0, 0,0,0,0,0,0,0,"reset held has priority");
    add_entry_cycles(5,1,0,1,1,0,0,0,0,0,"entry observes synchronized KEY1 reset");
    add_entry_cycles(5,3,0,1,0,0,0,0,0,0,"entry reset released");
    append_capture(1,1,0,"integrated entry captures a1=1");
    append_capture(0,1,0,NULL);
    append_capture(0,1,0,NULL);
    append_capture(0,1,0,NULL);
    append_capture(0,1,0,NULL);
    append_capture(0,1,1,"integrated entry completes c2");
    add_entry_cycles(2,2,0,0,0,0,1,0,0,1,NULL);
    add_entry_cycles(1,2,0,1,0,1,1,0,0,1,"new KEY0 after c2 pulses START");
    add_entry_cycles(1,2,0,1,0,0,1,0,1,1,"integrated processor accepts START and enters BUSY");
    add_entry_cycles(1,3,0,1,0,0,1,1,0,1,"integrated processor completes F1");
    add_entry_cycles(3,3,0,1,0,0,1,1,0,1,"DONE retained and entry rearmed");
    add_entry_cycles(2,2,0,0,0,0,1,1,0,1,NULL);
    add_entry_cycles(1,2,0,1,0,1,1,1,0,1,"rearmed entry accepts a second START while old DONE is high");
    add_entry_cycles(1,2,0,1,0,0,1,0,1,1,"second START lowers processing_done");
    add_entry_cycles(1,3,0,1,0,0,1,1,0,1,"second validation completes after processing_done was low");
    add_entry_cycles(1,3,0,1,0,0,1,1,0,1,"entry observes second DONE high");
    add_entry_cycles(2,3,0,1,0,0,1,1,0,1,"entry remains rearmed after new DONE high");
    ADD(1,0,1,0,0,0,0, 0,0,0,0,0,0,0,"isolated root monitor reset");
    ADD(0,1,1,0,0,0,0, 1,0,0,0,0,0,0,"isolated root monitor START");
    {
        int i;
        for (i = 0; i < 22; ++i)
            add_step(0,0,1,0,0,0,0, 0,1,0,0,1,1,1,NULL);
    }
    add_step(0,0,1,0,0,0,0, 0,1,0,0,1,1,1,"isolated root pipeline token N+22");
    steps[step_count - 1].check_roots = 1;
    ADD(1,0,1,0,0,0,0, 0,0,0,0,0,0,0,"root-domain sticky output clears on reset");
    steps[step_count - 1].check_roots = 1;
#undef ADD
}

static PLI_INT32 drive_step(p_cb_data cb);
static PLI_INT32 raise_clock(p_cb_data cb);
static PLI_INT32 check_step(p_cb_data cb);
static PLI_INT32 lower_clock(p_cb_data cb);

static void schedule(PLI_INT32 (*callback)(p_cb_data), unsigned delay)
{
    int slot;
    if (callback == raise_clock) slot = 0;
    else if (callback == check_step) slot = 1;
    else if (callback == lower_clock) slot = 2;
    else slot = 3;
    memset(&scheduled_callbacks[slot], 0, sizeof(scheduled_callbacks[slot]));
    memset(&scheduled_times[slot], 0, sizeof(scheduled_times[slot]));
    scheduled_times[slot].type = vpiSimTime;
    scheduled_times[slot].low = delay;
    scheduled_callbacks[slot].reason = cbAfterDelay;
    scheduled_callbacks[slot].cb_rtn = callback;
    scheduled_callbacks[slot].time = &scheduled_times[slot];
    vpi_register_cb(&scheduled_callbacks[slot]);
}

static PLI_INT32 drive_step(p_cb_data cb)
{
    test_step *step;
    (void)cb;
    if (step_index >= step_count) {
        vpi_printf("VPI PASS: %lu F1 processor cycles passed\n", (unsigned long)step_count);
        vpi_control(vpiFinish, 0);
        return 0;
    }
    step = &steps[step_index];
    put_integer(clk_h, 0);
    put_integer(reset_h, step->reset);
    put_integer(start_h, step->start);
    put_integer(a_h, step->a);
    put_integer(b_h, step->b);
    put_integer(c_h, step->c);
    put_integer(x_h, step->x);
    put_integer(y_h, step->y);
    put_integer(key_h, step->key_n);
    put_integer(sw_h, step->sw);
    schedule(raise_clock, 5);
    return 0;
}

static PLI_INT32 raise_clock(p_cb_data cb)
{
    (void)cb;
    put_integer(clk_h, 1);
    schedule(check_step, 1);
    return 0;
}

static void check_output(vpiHandle handle, int expected, const char *name, int *failed)
{
    int actual = read_bit(handle);
    if (actual != expected) {
        vpi_printf("VPI FAIL: step %lu (%s): %s expected %d got %d\n",
                   (unsigned long)step_index, steps[step_index].label,
                   name, expected, actual);
        *failed = 1;
    }
}

static PLI_INT32 check_step(p_cb_data cb)
{
    test_step *step = &steps[step_index];
    int failed = 0;
    int expected_x1, expected_x2, expected_valid;
    (void)cb;
    check_output(busy_h, step->busy, "busy", &failed);
    check_output(done_h, step->done, "done", &failed);
    check_output(error_a_h, step->error_a_zero, "error_a_zero", &failed);
    check_output(error_vertex_h, step->error_vertex, "error_vertex", &failed);
    check_output(display_h, step->display_enable, "display_enable", &failed);
    check_output(hit_h, step->f1_hit, "f1_hit", &failed);
    check_output(derivative_hit_h, step->f1_derivative_hit, "f1_derivada_hit", &failed);
    if (step->check_roots) {
        expected_roots(step->a, step->b, step->c, &expected_x1, &expected_x2, &expected_valid);
        if (step->reset) expected_valid = 0;
        int actual_x1 = read_signed(root_x1_h, 9);
        int actual_x2 = read_signed(root_x2_h, 9);
        int actual_valid = read_bit(root_valid_h);
        if (actual_x1 != expected_x1 || actual_x2 != expected_x2 || actual_valid != expected_valid) {
            vpi_printf("VPI FAIL: step %lu (%s): roots expected (%d,%d valid=%d), got (%d,%d valid=%d)\n",
                       (unsigned long)step_index, step->label, expected_x1, expected_x2,
                       expected_valid, actual_x1, actual_x2, actual_valid);
            failed = 1;
        }
    }
    if (step->check_entry) {
        check_output(entry_reset_h, step->entry_system_reset, "entry_system_reset", &failed);
        check_output(entry_start_h, step->entry_start, "entry_start_pulse", &failed);
        check_output(entry_ready_h, step->entry_input_ready, "entry_input_ready", &failed);
        check_output(entry_done_h, step->entry_processing_done, "entry_processing_done", &failed);
        check_output(entry_busy_h, step->entry_busy, "entry_busy", &failed);
        {
            int actual = read_signed(entry_a_h, 8);
            if (actual != step->entry_a1) {
                vpi_printf("VPI FAIL: step %lu (%s): integrated a1 expected %d got %d\n",
                           (unsigned long)step_index, step->label,
                           step->entry_a1, actual);
                failed = 1;
            }
        }
    }
    if (failed) {
        fflush(stdout);
        exit(EXIT_FAILURE);
    }
    schedule(lower_clock, 1);
    return 0;
}

static PLI_INT32 lower_clock(p_cb_data cb)
{
    (void)cb;
    put_integer(clk_h, 0);
    step_index++;
    schedule(drive_step, 1);
    return 0;
}

static PLI_INT32 start_test(p_cb_data cb)
{
    (void)cb;
    clk_h = get_handle("tb_f1_processor.clk");
    reset_h = get_handle("tb_f1_processor.system_reset");
    start_h = get_handle("tb_f1_processor.start_pulse");
    a_h = get_handle("tb_f1_processor.a1");
    b_h = get_handle("tb_f1_processor.b1");
    c_h = get_handle("tb_f1_processor.c1");
    x_h = get_handle("tb_f1_processor.x_cartesiano");
    y_h = get_handle("tb_f1_processor.y_cartesiano");
    busy_h = get_handle("tb_f1_processor.busy");
    done_h = get_handle("tb_f1_processor.done");
    error_a_h = get_handle("tb_f1_processor.error_a_zero");
    error_vertex_h = get_handle("tb_f1_processor.error_vertex");
    display_h = get_handle("tb_f1_processor.display_enable");
    hit_h = get_handle("tb_f1_processor.f1_hit");
    derivative_hit_h = get_handle("tb_f1_processor.f1_derivada_hit");
    root_x1_h = get_handle("tb_f1_processor.root_x1");
    root_x2_h = get_handle("tb_f1_processor.root_x2");
    root_valid_h = get_handle("tb_f1_processor.root_domain_valid");
    key_h = get_handle("tb_f1_processor.key_n");
    sw_h = get_handle("tb_f1_processor.sw");
    entry_reset_h = get_handle("tb_f1_processor.entry_system_reset");
    entry_start_h = get_handle("tb_f1_processor.entry_start_pulse");
    entry_ready_h = get_handle("tb_f1_processor.entry_input_ready");
    entry_done_h = get_handle("tb_f1_processor.entry_processing_done");
    entry_busy_h = get_handle("tb_f1_processor.entry_busy");
    entry_a_h = get_handle("tb_f1_processor.entry_a1");
    step_index = 0;
    build_steps();
    schedule(drive_step, 1);
    return 0;
}

static void register_callbacks(void)
{
    s_cb_data cb;
    memset(&cb, 0, sizeof(cb));
    cb.reason = cbStartOfSimulation;
    cb.cb_rtn = start_test;
    vpi_register_cb(&cb);
}

void (*vlog_startup_routines[])(void) = {register_callbacks, 0};
