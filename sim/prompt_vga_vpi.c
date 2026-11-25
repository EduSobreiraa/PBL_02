#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

typedef struct {
    int glyph_id, row, column;
    int x, y, video_on, prompt_mode;
    int expected_pixel, expected_prompt;
    const char *name;
} test_case;

static const char *font[32][7] = {
    {"00000","00000","00000","00000","00000","00000","00000"},
    {"01110","10001","10011","10101","11001","10001","01110"},
    {"00100","01100","00100","00100","00100","00100","01110"},
    {"01110","10001","00001","00010","00100","01000","11111"},
    {"11110","00001","00001","01110","00001","00001","11110"},
    {"00010","00110","01010","10010","11111","00010","00010"},
    {"11111","10000","10000","11110","00001","00001","11110"},
    {"01110","10000","10000","11110","10001","10001","01110"},
    {"11111","00001","00010","00100","01000","01000","01000"},
    {"01110","10001","10001","01110","10001","10001","01110"},
    {"01110","10001","10001","01111","00001","00001","01110"},
    {"00000","00100","00100","11111","00100","00100","00000"},
    {"00000","00000","00000","11111","00000","00000","00000"},
    {"00000","00000","00000","00000","00000","00110","00110"},
    {"00000","00000","00000","00000","00110","00100","01000"},
    {"00001","00010","00010","00100","01000","01000","10000"},
    {"01110","10001","10001","11111","10001","10001","10001"},
    {"11111","10000","10000","11110","10000","10000","10000"},
    {"01110","00100","00100","00100","00100","00100","01110"},
    {"10001","11001","11001","10101","10011","10011","10001"},
    {"01110","10001","10001","10001","10001","10001","01110"},
    {"11110","10001","10001","11110","10100","10010","10001"},
    {"10001","10001","10001","10001","01010","01010","00100"},
    {"10001","01010","00100","00100","00100","01010","10001"},
    {"10001","01010","00100","00100","00100","00100","00100"},
    {"00000","01110","00001","01111","10001","10011","01101"},
    {"10000","10000","10110","11001","10001","10001","11110"},
    {"00000","01110","10001","10000","10000","10001","01110"},
    {"00100","00000","01100","00100","00100","00100","01110"},
    {"00000","10110","11001","10001","10001","10001","10001"},
    {"00000","10110","11001","10000","10000","10000","10000"},
    {"00000","01111","10000","01110","00001","10001","01110"}
};
static const int prompt_ids[18] = {18,29,31,28,30,25,0,25,2,13,26,2,13,27,2,13,13,13};
static test_case cases[10000];
static size_t case_count, case_index;
static vpiHandle glyph_h, row_h, column_h, x_h, y_h, video_h, mode_h, pixel_h, prompt_h;
static s_cb_data callbacks[2];
static s_vpi_time callback_times[2];

static void fail(const char *message) {
    vpi_printf("VPI FAIL: %s\n", message);
    fflush(stdout);
    exit(EXIT_FAILURE);
}
static vpiHandle get_handle(const char *name) {
    vpiHandle handle = vpi_handle_by_name((PLI_BYTE8 *)name, NULL);
    if (!handle) {
        char buffer[200];
        snprintf(buffer, sizeof(buffer), "missing VPI handle %s", name);
        fail(buffer);
    }
    return handle;
}
static void put_integer(vpiHandle handle, int value) {
    s_vpi_value v;
    v.format = vpiIntVal;
    v.value.integer = value;
    vpi_put_value(handle, &v, NULL, vpiNoDelay);
}
static int read_bit(vpiHandle handle) {
    s_vpi_value v;
    v.format = vpiVectorVal;
    vpi_get_value(handle, &v);
    if (v.value.vector[0].bval & 1U) fail("output is X/Z");
    return (int)(v.value.vector[0].aval & 1U);
}
static void append_case(int id, int row, int column, int x, int y, int video, int mode, int pixel, int prompt, const char *name) {
    test_case *t;
    if (case_count >= sizeof(cases) / sizeof(cases[0])) fail("test-case capacity exceeded");
    t = &cases[case_count++];
    t->glyph_id=id; t->row=row; t->column=column; t->x=x; t->y=y;
    t->video_on=video; t->prompt_mode=mode; t->expected_pixel=pixel; t->expected_prompt=prompt; t->name=name;
}
static int prompt_reference(int x, int y) {
    int dx=x-267, dy=y-237, character, column;
    if (dx < 0 || dy < 0 || dy >= 7) return 0;
    character=dx/6; column=dx%6;
    if (character >= 18 || column >= 5) return 0;
    return font[prompt_ids[character]][dy][column]=='1';
}
static void build_cases(void) {
    int id,row,column,x,y,expected;
    for (id=0; id<32; ++id)
        for (row=0; row<8; ++row)
            for (column=0; column<8; ++column) {
                expected=(row<7 && column<5) ? font[id][row][column]=='1' : 0;
                append_case(id,row,column,0,0,0,0,expected,0,"glyph bitmap");
            }
    for (y=230; y<=248; ++y)
        for (x=260; x<=378; ++x) {
            expected=prompt_reference(x,y);
            append_case(0,0,0,x,y,1,1,0,expected,"prompt visible area");
            append_case(0,0,0,x,y,1,0,0,0,"prompt disabled");
            append_case(0,0,0,x,y,0,1,0,0,"video blanking");
        }
    append_case(31,7,4,639,479,1,1,0,0,"outside raster text");
    append_case(31,6,5,267,237,1,1,0,0,"column outside glyph");
    append_case(31,6,4,267,244,1,1,0,0,"row outside glyph");
}
static PLI_INT32 drive(p_cb_data cb);
static PLI_INT32 check(p_cb_data cb);
static void schedule(PLI_INT32 (*fn)(p_cb_data), int slot, int readonly) {
    memset(&callbacks[slot],0,sizeof(callbacks[slot]));
    memset(&callback_times[slot],0,sizeof(callback_times[slot]));
    callback_times[slot].type=vpiSimTime;
    callback_times[slot].low=readonly ? 0 : 1;
    callbacks[slot].reason=readonly ? cbReadOnlySynch : cbAfterDelay;
    callbacks[slot].cb_rtn=fn;
    callbacks[slot].time=&callback_times[slot];
    vpi_register_cb(&callbacks[slot]);
}
static PLI_INT32 drive(p_cb_data cb) {
    test_case *t;
    (void)cb;
    if (case_index >= case_count) {
        vpi_printf("VPI PASS: %lu glyph/prompt pixel cases\n",(unsigned long)case_count);
        vpi_control(vpiFinish,0);
        return 0;
    }
    t=&cases[case_index];
    put_integer(glyph_h,t->glyph_id); put_integer(row_h,t->row); put_integer(column_h,t->column);
    put_integer(x_h,t->x); put_integer(y_h,t->y); put_integer(video_h,t->video_on); put_integer(mode_h,t->prompt_mode);
    schedule(check,1,1);
    return 0;
}
static PLI_INT32 check(p_cb_data cb) {
    test_case *t=&cases[case_index];
    int actual_pixel=read_bit(pixel_h), actual_prompt=read_bit(prompt_h);
    (void)cb;
    if (actual_pixel!=t->expected_pixel || actual_prompt!=t->expected_prompt) {
        vpi_printf("VPI FAIL: case=%lu name=%s id=%d row=%d col=%d xy=%d,%d expected=%d/%d actual=%d/%d\n",
            (unsigned long)case_index,t->name,t->glyph_id,t->row,t->column,t->x,t->y,t->expected_pixel,t->expected_prompt,actual_pixel,actual_prompt);
        vpi_control(vpiFinish,1);
        return 0;
    }
    ++case_index;
    schedule(drive,0,0);
    return 0;
}
static PLI_INT32 start(p_cb_data cb) {
    (void)cb;
    glyph_h=get_handle("tb_prompt_vga.glyph_id"); row_h=get_handle("tb_prompt_vga.row"); column_h=get_handle("tb_prompt_vga.column");
    x_h=get_handle("tb_prompt_vga.x_pixel"); y_h=get_handle("tb_prompt_vga.y_pixel");
    video_h=get_handle("tb_prompt_vga.video_on"); mode_h=get_handle("tb_prompt_vga.prompt_mode");
    pixel_h=get_handle("tb_prompt_vga.pixel"); prompt_h=get_handle("tb_prompt_vga.prompt_white");
    build_cases();
    schedule(drive,0,0);
    return 0;
}
static void register_callbacks(void) {
    s_cb_data cb;
    memset(&cb,0,sizeof(cb)); cb.reason=cbStartOfSimulation; cb.cb_rtn=start; vpi_register_cb(&cb);
}
void (*vlog_startup_routines[])(void)={register_callbacks,0};
