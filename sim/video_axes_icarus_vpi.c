#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

typedef struct {
    const char *name;
    int x;
    int y;
    int video_on;
    int red;
    int green;
    int blue;
    int horizontal;
    int vertical;
    int x_cart;
    int y_cart;
    int check_reset;
    int key;
    int reset;
    int processing_done;
    int hits;
} test_case;

static test_case cases[265] = {
    {"left x boundary and horizontal axis", 0, 240, 1, 15, 15, 15, 1, 0, -320, 0, 0, 0, 0, 0, 0},
    {"right x boundary", 639, 240, 1, 15, 15, 15, 1, 0, 319, 0, 0, 0, 0, 0, 0},
    {"top y boundary and vertical axis", 320, 0, 1, 15, 15, 15, 0, 1, 0, 240, 0, 0, 0, 0, 0},
    {"bottom y boundary and vertical axis", 320, 479, 1, 15, 15, 15, 0, 1, 0, -239, 0, 0, 0, 0, 0},
    {"origin activates both axes", 320, 240, 1, 15, 15, 15, 1, 1, 0, 0, 0, 0, 0, 0, 0},
    {"off-axis pixel is black", 10, 10, 1, 0, 0, 0, 0, 0, -310, 230, 0, 0, 0, 0, 0},
    {"video_on clips axis pixel to black", 320, 240, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {"KEY1 pressed asserts active-high VGA reset", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0},
    {"KEY1 released deasserts VGA reset", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 0, 0, 0}
};

static size_t case_count = 9;
static size_t case_index;
static s_vpi_time readonly_time;
static vpiHandle x_pixel_h, y_pixel_h, video_on_h;
static vpiHandle x_cart_h, y_cart_h, red_h, green_h, blue_h;
static vpiHandle horizontal_h, vertical_h, key_h, reset_h;
static vpiHandle processing_done_h, f1_hit_h, f1_derivada_hit_h, f2_hit_h, f2_derivada_hit_h;

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

static int read_integer(vpiHandle handle)
{
    s_vpi_value value;
    value.format = vpiIntVal;
    vpi_get_value(handle, &value);
    return value.value.integer;
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
    s_cb_data cb;
    memset(&cb, 0, sizeof(cb));
    memset(&readonly_time, 0, sizeof(readonly_time));
    readonly_time.type = vpiSimTime;
    cb.reason = cbReadOnlySynch;
    cb.cb_rtn = check_case;
    cb.time = &readonly_time;
    vpi_register_cb(&cb);
}

static void schedule_next_drive(void)
{
    s_cb_data cb;
    s_vpi_time delay;
    memset(&cb, 0, sizeof(cb));
    memset(&delay, 0, sizeof(delay));
    delay.type = vpiSimTime;
    delay.low = 1;
    cb.reason = cbAfterDelay;
    cb.cb_rtn = drive_case;
    cb.time = &delay;
    vpi_register_cb(&cb);
}

static PLI_INT32 drive_case(p_cb_data callback_data)
{
    test_case *test;
    (void)callback_data;
    if (case_index >= case_count) {
        vpi_printf("VPI PASS: all %lu video composition cases passed\n", (unsigned long)case_count);
        vpi_control(vpiFinish, 0);
        return 0;
    }

    test = &cases[case_index];
    if (test->check_reset) {
        write_integer(key_h, test->key);
    } else {
        write_integer(x_pixel_h, test->x);
        write_integer(y_pixel_h, test->y);
        write_integer(video_on_h, test->video_on);
        write_integer(processing_done_h, test->processing_done);
        write_integer(f1_hit_h, test->hits & 1);
        write_integer(f1_derivada_hit_h, (test->hits >> 1) & 1);
        write_integer(f2_hit_h, (test->hits >> 2) & 1);
        write_integer(f2_derivada_hit_h, (test->hits >> 3) & 1);
    }
    schedule_readonly_check();
    return 0;
}

static PLI_INT32 check_case(p_cb_data callback_data)
{
    test_case *test = &cases[case_index];
    int failed = 0;
    (void)callback_data;

#define CHECK_SIGNAL(handle, expected, label) do { \
    int actual = read_integer(handle); \
    if (actual != (expected)) { \
        vpi_printf("VPI FAIL: %s: hits=%d done=%d video=%d x=%d y=%d: %s expected %d, got %d\n", test->name, test->hits, test->processing_done, test->video_on, test->x, test->y, label, (expected), actual); \
        failed = 1; \
    } \
} while (0)

    if (test->check_reset) {
        CHECK_SIGNAL(reset_h, test->reset, "reset_vga");
    } else {
        CHECK_SIGNAL(x_cart_h, test->x_cart, "x_cartesiano");
        CHECK_SIGNAL(y_cart_h, test->y_cart, "y_cartesiano");
        CHECK_SIGNAL(horizontal_h, test->horizontal, "eixo_horizontal");
        CHECK_SIGNAL(vertical_h, test->vertical, "eixo_vertical");
        CHECK_SIGNAL(red_h, test->red, "red");
        CHECK_SIGNAL(green_h, test->green, "green");
        CHECK_SIGNAL(blue_h, test->blue, "blue");
    }
#undef CHECK_SIGNAL

    if (failed) {
        fflush(stdout);
        exit(EXIT_FAILURE);
    }
    if (case_index < 9)
        vpi_printf("VPI PASS: %s\n", test->name);
    case_index++;
    schedule_next_drive();
    return 0;
}

static void add_composition_cases(void)
{
    const int palette[4][3] = {{0, 0, 15}, {0, 15, 15}, {15, 0, 0}, {15, 15, 0}};
    int hits, done, video, axes;
    for (hits = 0; hits < 16; hits++)
        for (done = 0; done < 2; done++)
            for (video = 0; video < 2; video++)
                for (axes = 0; axes < 4; axes++) {
                    test_case *test = &cases[case_count++];
                    int curve;
                    test->name = "exhaustive palette, priority and gates";
                    test->x = (axes & 1) ? 320 : 100;
                    test->y = (axes & 2) ? 240 : 100;
                    test->x_cart = test->x - 320;
                    test->y_cart = 240 - test->y;
                    test->video_on = video;
                    test->processing_done = done;
                    test->hits = hits;
                    test->horizontal = video && (axes & 2) != 0;
                    test->vertical = video && (axes & 1) != 0;
                    if (!video)
                        continue;
                    if (done && hits) {
                        for (curve = 0; curve < 4; curve++)
                            if (hits & (1 << curve))
                                break;
                        test->red = palette[curve][0];
                        test->green = palette[curve][1];
                        test->blue = palette[curve][2];
                    } else if (axes) {
                        test->red = 15;
                        test->green = 15;
                        test->blue = 15;
                    }
                }
}

static PLI_INT32 start_test(p_cb_data callback_data)
{
    (void)callback_data;
    x_pixel_h = get_handle("tb_video_axes.x_pixel");
    y_pixel_h = get_handle("tb_video_axes.y_pixel");
    video_on_h = get_handle("tb_video_axes.video_on");
    processing_done_h = get_handle("tb_video_axes.processing_done");
    f1_hit_h = get_handle("tb_video_axes.f1_hit");
    f1_derivada_hit_h = get_handle("tb_video_axes.f1_derivada_hit");
    f2_hit_h = get_handle("tb_video_axes.f2_hit");
    f2_derivada_hit_h = get_handle("tb_video_axes.f2_derivada_hit");
    x_cart_h = get_handle("tb_video_axes.x_cartesiano");
    y_cart_h = get_handle("tb_video_axes.y_cartesiano");
    horizontal_h = get_handle("tb_video_axes.eixo_horizontal");
    vertical_h = get_handle("tb_video_axes.eixo_vertical");
    red_h = get_handle("tb_video_axes.red");
    green_h = get_handle("tb_video_axes.green");
    blue_h = get_handle("tb_video_axes.blue");
    key_h = get_handle("top_pbl03.KEY");
    reset_h = get_handle("top_pbl03.reset_vga");
    if (x_pixel_h == NULL || y_pixel_h == NULL || video_on_h == NULL ||
        x_cart_h == NULL || y_cart_h == NULL || horizontal_h == NULL ||
        vertical_h == NULL || red_h == NULL || green_h == NULL || blue_h == NULL ||
        key_h == NULL || reset_h == NULL) {
        fflush(stdout);
        exit(EXIT_FAILURE);
    }
    add_composition_cases();
    case_index = 0;
    schedule_next_drive();
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

void (*vlog_startup_routines[])(void) = {
    register_callbacks,
    0
};
