#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

typedef struct {
    int a;
    int b;
    int c;
    int x;
    int y;
    const char *name;
} test_case;

static test_case *cases;
static size_t case_count;
static size_t case_capacity;
static size_t case_index;
static s_vpi_time readonly_time;
static vpiHandle a1_h, b1_h, c1_h, x_h, y_h;
static vpiHandle f_h, derivative_h, a_zero_h, vertex_outside_h, valid_h;
static vpiHandle f_hit_h, derivative_hit_h;
static vpiHandle x_num_h, x_den_h, y_num_h, y_den_h;

static void add_case(int a, int b, int c, int x, int y, const char *name)
{
    test_case *next;
    if (case_count == case_capacity) {
        size_t capacity = case_capacity == 0 ? 1024 : case_capacity * 2;
        next = realloc(cases, capacity * sizeof(*cases));
        if (next == NULL) {
            vpi_printf("VPI ERROR: test-case allocation failed\n");
            exit(EXIT_FAILURE);
        }
        cases = next;
        case_capacity = capacity;
    }
    cases[case_count].a = a;
    cases[case_count].b = b;
    cases[case_count].c = c;
    cases[case_count].x = x;
    cases[case_count].y = y;
    cases[case_count].name = name;
    case_count++;
}

static void build_cases(void)
{
    static const int x_samples[] = {-320, -1, 0, 1, 319};
    static const struct { int a, b, c; const char *name; } coefficient_sets[] = {
        {1, 0, 0, "unit parabola"},
        {-128, 127, -128, "negative a minimum, positive b maximum, negative c minimum"},
        {127, -128, 127, "positive a maximum, negative b minimum, positive c maximum"},
        {-1, 22, 119, "upper vertex boundary"},
        {1, 22, -118, "lower vertex boundary"},
        {-1, 22, 120, "vertex just above screen"},
        {1, 22, -119, "vertex just below screen"},
        {0, -128, 127, "zero a"},
        {1, -128, 127, "negative b extreme"},
        {-128, 127, -128, "negative coefficient extremes"}
    };
    size_t set_index;
    size_t x_index;
    int x;
    int y;

    for (set_index = 0; set_index < sizeof(coefficient_sets) / sizeof(coefficient_sets[0]); set_index++) {
        for (x_index = 0; x_index < sizeof(x_samples) / sizeof(x_samples[0]); x_index++) {
            add_case(coefficient_sets[set_index].a, coefficient_sets[set_index].b,
                     coefficient_sets[set_index].c, x_samples[x_index], 0,
                     coefficient_sets[set_index].name);
        }
    }

    for (x = -320; x <= 319; x++) {
        add_case(1, 0, 0, x, 0, "all VGA columns, unit parabola");
        add_case(-128, 127, -128, x, 0, "all VGA columns, signed extremes A");
        add_case(127, -128, 127, x, 0, "all VGA columns, signed extremes B");
    }

    for (y = -239; y <= 240; y++) {
        add_case(1, 0, 0, 0, y, "all visible rows and zero hit");
        add_case(-1, 22, 119, 0, y, "all visible rows and positive hits");
        add_case(1, 22, -118, 0, y, "all visible rows and negative hit");
    }

    add_case(1, 0, 120, 11, 241, "out-of-range f equality is clipped");
    add_case(127, -13, 0, 1, 241, "out-of-range derivative equality is clipped");
    add_case(-1, 22, 119, 11, 240, "f hit at upper visible boundary");
    add_case(1, 22, -118, -11, -239, "f hit at lower visible boundary");
    add_case(1, 22, -119, -11, -240, "offscreen f equality is clipped");
    add_case(127, -14, 0, 1, 240, "derivative hit at upper visible boundary");
    add_case(127, 15, 0, -1, -239, "derivative hit at lower visible boundary");
    add_case(1, 0, 0, 0, -240, "row below visible range");
    add_case(1, 0, 0, 0, 241, "row above visible range");
    add_case(1, 0, 0, 0, -512, "minimum signed y row");
    add_case(1, 0, 0, 0, 511, "maximum signed y row");
}

static vpiHandle get_handle(const char *path)
{
    vpiHandle handle = vpi_handle_by_name((PLI_BYTE8 *)path, NULL);
    if (handle == NULL) {
        vpi_printf("VPI ERROR: cannot find %s\n", path);
        fflush(stdout);
        exit(EXIT_FAILURE);
    }
    return handle;
}

static int64_t read_signed(vpiHandle handle, unsigned width)
{
    s_vpi_value value;
    uint32_t raw;
    uint32_t unknown;
    uint32_t mask;
    uint32_t sign;
    PLI_BYTE8 *name;
    value.format = vpiVectorVal;
    vpi_get_value(handle, &value);
    raw = value.value.vector[0].aval;
    mask = (1U << width) - 1U;
    unknown = value.value.vector[0].bval & mask;
    if (unknown != 0U) {
        name = vpi_get_str(vpiFullName, handle);
        vpi_printf("VPI FAIL: %s contains X/Z bits, mask=0x%08x\n", name, unknown);
        fflush(stdout);
        exit(EXIT_FAILURE);
    }
    sign = 1U << (width - 1U);
    raw &= mask;
    if ((raw & sign) != 0U) {
        return (int64_t)raw - (INT64_C(1) << width);
    }
    return (int64_t)raw;
}

static uint32_t read_unsigned(vpiHandle handle, unsigned width)
{
    s_vpi_value value;
    uint32_t mask = (1U << width) - 1U;
    value.format = vpiVectorVal;
    vpi_get_value(handle, &value);
    if ((value.value.vector[0].bval & mask) != 0U) {
        PLI_BYTE8 *name = vpi_get_str(vpiFullName, handle);
        vpi_printf("VPI FAIL: %s contains X/Z bits\n", name);
        exit(EXIT_FAILURE);
    }
    return value.value.vector[0].aval & mask;
}

static int read_bit(vpiHandle handle)
{
    s_vpi_value value;
    PLI_BYTE8 *name;
    value.format = vpiVectorVal;
    vpi_get_value(handle, &value);
    if ((value.value.vector[0].bval & 1U) != 0U) {
        name = vpi_get_str(vpiFullName, handle);
        vpi_printf("VPI FAIL: %s contains X/Z\n", name);
        fflush(stdout);
        exit(EXIT_FAILURE);
    }
    return (int)(value.value.vector[0].aval & 1U);
}

static void write_integer(vpiHandle handle, int integer)
{
    s_vpi_value value;
    value.format = vpiIntVal;
    value.value.integer = integer;
    vpi_put_value(handle, &value, NULL, vpiNoDelay);
}

static PLI_INT32 check_case(p_cb_data callback_data);
static PLI_INT32 drive_case(p_cb_data callback_data);

static void schedule_readonly_check(void)
{
    s_cb_data callback;
    memset(&callback, 0, sizeof(callback));
    memset(&readonly_time, 0, sizeof(readonly_time));
    readonly_time.type = vpiSimTime;
    callback.reason = cbReadOnlySynch;
    callback.cb_rtn = check_case;
    callback.time = &readonly_time;
    vpi_register_cb(&callback);
}

static void schedule_next_drive(void)
{
    s_cb_data callback;
    s_vpi_time delay;
    memset(&callback, 0, sizeof(callback));
    memset(&delay, 0, sizeof(delay));
    delay.type = vpiSimTime;
    delay.low = 1;
    callback.reason = cbAfterDelay;
    callback.cb_rtn = drive_case;
    callback.time = &delay;
    vpi_register_cb(&callback);
}

static PLI_INT32 drive_case(p_cb_data callback_data)
{
    const test_case *test;
    (void)callback_data;
    if (case_index >= case_count) {
        vpi_printf("VPI PASS: %lu datapath cases passed\n", (unsigned long)case_count);
        free(cases);
        vpi_control(vpiFinish, 0);
        return 0;
    }
    test = &cases[case_index];
    write_integer(a1_h, test->a);
    write_integer(b1_h, test->b);
    write_integer(c1_h, test->c);
    write_integer(x_h, test->x);
    write_integer(y_h, test->y);
    schedule_readonly_check();
    return 0;
}

static PLI_INT32 check_case(p_cb_data callback_data)
{
    const test_case *test = &cases[case_index];
    int64_t f_expected = (int64_t)test->a * test->x * test->x + (int64_t)test->b * test->x + test->c;
    int64_t derivative_expected = INT64_C(2) * test->a * test->x + test->b;
    int expected_a_zero = test->a == 0;
    int expected_vertex_outside = 0;
    int expected_valid = 0;
    int expected_f_hit = 0;
    int expected_derivative_hit = 0;
    int64_t numerator;
    int64_t denominator;
    int failed = 0;
    int64_t actual;
    (void)callback_data;

    if (test->a != 0) {
        numerator = INT64_C(4) * test->a * test->c - (int64_t)test->b * test->b;
        denominator = INT64_C(4) * test->a;
        if (denominator < 0) {
            numerator = -numerator;
            denominator = -denominator;
        }
        expected_vertex_outside = numerator < -INT64_C(239) * denominator ||
                                  numerator > INT64_C(240) * denominator;
        expected_valid = !expected_vertex_outside;
    }
    if (test->y >= -239 && test->y <= 240) {
        expected_f_hit = f_expected == test->y;
        expected_derivative_hit = derivative_expected == test->y;
    }

#define CHECK_SIGNED(handle, expected, width, label) do { \
    actual = read_signed(handle, width); \
    if (actual != (expected)) { \
        vpi_printf("VPI FAIL: %s x=%d y=%d: %s expected %" PRId64 ", got %" PRId64 "\n", \
                   test->name, test->x, test->y, label, (int64_t)(expected), actual); \
        failed = 1; \
    } \
} while (0)
#define CHECK_BIT(handle, expected, label) do { \
    int bit_actual = read_bit(handle); \
    if (bit_actual != (expected)) { \
        vpi_printf("VPI FAIL: %s x=%d y=%d: %s expected %d, got %d\n", \
                   test->name, test->x, test->y, label, (expected), bit_actual); \
        failed = 1; \
    } \
} while (0)
#define CHECK_UNSIGNED(handle, expected, width, label) do { \
    uint32_t unsigned_actual = read_unsigned(handle, width); \
    if (unsigned_actual != (uint32_t)(expected)) { \
        vpi_printf("VPI FAIL: %s: %s expected %u, got %u\n", test->name, label, (unsigned)(expected), unsigned_actual); \
        failed = 1; \
    } \
} while (0)

    if (test->a != 0) {
        CHECK_SIGNED(x_num_h, test->a > 0 ? -test->b : test->b, 9, "vertex x numerator");
        CHECK_UNSIGNED(x_den_h, 2 * abs(test->a), 9, "vertex x denominator");
        CHECK_SIGNED(y_num_h, numerator, 18, "vertex y numerator");
        CHECK_UNSIGNED(y_den_h, 4 * abs(test->a), 10, "vertex y denominator");
    }
    CHECK_SIGNED(f_h, f_expected, 25, "f1_y");
    CHECK_SIGNED(derivative_h, derivative_expected, 18, "f1_derivada");
    CHECK_BIT(a_zero_h, expected_a_zero, "a1_zero");
    CHECK_BIT(vertex_outside_h, expected_vertex_outside, "vertice_y_fora");
    CHECK_BIT(valid_h, expected_valid, "function_valid");
    CHECK_BIT(f_hit_h, expected_f_hit, "f1_hit");
    CHECK_BIT(derivative_hit_h, expected_derivative_hit, "f1_derivada_hit");
#undef CHECK_SIGNED
#undef CHECK_BIT

    if (failed) {
        fflush(stdout);
        exit(EXIT_FAILURE);
    }
    case_index++;
    schedule_next_drive();
    return 0;
}

static PLI_INT32 start_test(p_cb_data callback_data)
{
    (void)callback_data;
    a1_h = get_handle("tb_f1_function.a1");
    b1_h = get_handle("tb_f1_function.b1");
    c1_h = get_handle("tb_f1_function.c1");
    x_h = get_handle("tb_f1_function.x_cartesiano");
    y_h = get_handle("tb_f1_function.y_cartesiano");
    f_h = get_handle("tb_f1_function.f1_y");
    derivative_h = get_handle("tb_f1_function.f1_derivada");
    a_zero_h = get_handle("tb_f1_function.a1_zero");
    vertex_outside_h = get_handle("tb_f1_function.vertice_y_fora");
    valid_h = get_handle("tb_f1_function.function_valid");
    f_hit_h = get_handle("tb_f1_function.f1_hit");
    derivative_hit_h = get_handle("tb_f1_function.f1_derivada_hit");
    x_num_h = get_handle("tb_f1_function.x_num");
    x_den_h = get_handle("tb_f1_function.x_den");
    y_num_h = get_handle("tb_f1_function.y_num");
    y_den_h = get_handle("tb_f1_function.y_den");
    build_cases();
    case_index = 0;
    schedule_next_drive();
    return 0;
}

static void register_callbacks(void)
{
    s_cb_data callback;
    memset(&callback, 0, sizeof(callback));
    callback.reason = cbStartOfSimulation;
    callback.cb_rtn = start_test;
    vpi_register_cb(&callback);
}

void (*vlog_startup_routines[])(void) = {
    register_callbacks,
    0
};
