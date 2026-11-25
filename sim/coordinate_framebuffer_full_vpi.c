#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

static vpiHandle completion_h;
static vpiHandle write_count_h;

static void fail(const char *message)
{
    vpi_printf("VPI FAIL: %s\n", message);
    fflush(stdout);
    exit(EXIT_FAILURE);
}

static vpiHandle get_handle(const char *name)
{
    vpiHandle handle = vpi_handle_by_name((PLI_BYTE8 *)name, NULL);
    if (handle == NULL)
        fail(name);
    return handle;
}

static unsigned read_unsigned(vpiHandle handle)
{
    s_vpi_value value;
    value.format = vpiVectorVal;
    vpi_get_value(handle, &value);
    if (value.value.vector[0].bval != 0)
        fail("unknown value at VPI full-frame completion");
    return (unsigned)value.value.vector[0].aval;
}

static PLI_INT32 completion_changed(p_cb_data callback)
{
    (void)callback;
    if (read_unsigned(completion_h) == 1) {
        unsigned writes = read_unsigned(write_count_h);
        if (writes != 640)
            fail("native testbench ended the raster without 640 ordered oracle-checked writes");
        vpi_printf("VPI PASS: native TB completed one full 800x525 raster after all 640 oracle-checked writes\n");
    }
    return 0;
}

static PLI_INT32 startup(p_cb_data callback)
{
    static s_cb_data completion_cb;
    (void)callback;
    completion_h = get_handle("tb_coordinate_framebuffer_full.vpi_capture_done");
    write_count_h = get_handle("tb_coordinate_framebuffer_full.write_count");
    completion_cb.reason = cbValueChange;
    completion_cb.cb_rtn = completion_changed;
    completion_cb.obj = completion_h;
    vpi_register_cb(&completion_cb);
    vpi_printf("VPI ACTIVE: waiting for the native full-frame capture and 640-word reference check\n");
    return 0;
}

static void register_startup(void)
{
    static s_cb_data startup_cb;
    startup_cb.reason = cbStartOfSimulation;
    startup_cb.cb_rtn = startup;
    vpi_register_cb(&startup_cb);
}

void (*vlog_startup_routines[])(void) = {register_startup, 0};
