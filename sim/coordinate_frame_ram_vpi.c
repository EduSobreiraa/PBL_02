#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

enum { FRAME_DEPTH = 640 };
enum { DRIVE_LOW = 0, DRIVE_HIGH = 1, CHECK_READ = 2, CHECK_HOLD = 3, FINISHED = 4 };
static vpiHandle clk_h, write_enable_h, write_address_h;
static vpiHandle write_data_low_h, write_data_high_h;
static vpiHandle read_enable_h, read_address_h, read_data_h;
static vpiHandle read_data_low_h, read_data_high_h;
static int phase, index_now;
static s_cb_data callback;
static s_vpi_time delay_time;

static void fail(const char *message)
{
    vpi_printf("COORDINATE FRAME RAM FAIL: %s\n", message);
    fflush(stdout);
    vpi_control(vpiFinish, 1);
}

static vpiHandle get_handle(const char *name)
{
    vpiHandle handle = vpi_handle_by_name((PLI_BYTE8 *)name, NULL);
    if (!handle)
        fail(name);
    return handle;
}

static void put_int(vpiHandle handle, int value)
{
    s_vpi_value signal_value;
    signal_value.format = vpiIntVal;
    signal_value.value.integer = value;
    vpi_put_value(handle, &signal_value, NULL, vpiNoDelay);
}

static int get_int(vpiHandle handle)
{
    s_vpi_value signal_value;
    signal_value.format = vpiIntVal;
    vpi_get_value(handle, &signal_value);
    return signal_value.value.integer;
}

static void put_wide(uint64_t value)
{
    put_int(write_data_low_h, (int)(value & UINT64_C(0xffffffff)));
    put_int(write_data_high_h, (int)((value >> 32) & UINT64_C(0x1ff)));
}

static uint64_t expected_word(int address)
{
    return (((uint64_t)(address + 1) * UINT64_C(0x13579BDF)) ^
            ((uint64_t)(address + 17) << 21) ^ UINT64_C(0x12A55AA5)) &
           ((UINT64_C(1) << 41) - 1);
}

static uint64_t get_wide(vpiHandle handle)
{
    uint64_t low, high;
    (void)handle;
    low = (uint32_t)get_int(read_data_low_h);
    high = (uint32_t)get_int(read_data_high_h);
    return (high << 32) | low;
}

static void schedule_next(PLI_INT32 (*function)(p_cb_data), PLI_UINT32 delay)
{
    memset(&callback, 0, sizeof(callback));
    memset(&delay_time, 0, sizeof(delay_time));
    delay_time.type = vpiSimTime;
    delay_time.low = delay;
    callback.reason = cbAfterDelay;
    callback.cb_rtn = function;
    callback.time = &delay_time;
    vpi_register_cb(&callback);
}

static PLI_INT32 step(p_cb_data cb)
{
    (void)cb;
    if (phase == DRIVE_LOW) {
        put_int(clk_h, 0);
        if (index_now < FRAME_DEPTH) {
            put_int(write_enable_h, 1);
            put_int(write_address_h, index_now);
            put_wide(expected_word(index_now));
            put_int(read_enable_h, 0);
        } else if (index_now == FRAME_DEPTH) {
            put_int(write_enable_h, 0);
            put_int(read_enable_h, 1);
            put_int(read_address_h, 0);
        } else if (index_now < FRAME_DEPTH * 2) {
            put_int(write_enable_h, 0);
            put_int(read_enable_h, 1);
            put_int(read_address_h, index_now - FRAME_DEPTH);
        } else if (index_now == FRAME_DEPTH * 2) {
            put_int(write_enable_h, 0);
            put_int(read_enable_h, 1);
            put_int(read_address_h, FRAME_DEPTH - 1);
        } else {
            put_int(write_enable_h, 0);
            put_int(read_enable_h, 0);
            put_int(read_address_h, 0);
        }
        phase = DRIVE_HIGH;
        schedule_next(step, 5);
        return 0;
    }
    if (phase == DRIVE_HIGH) {
        put_int(clk_h, 1);
        phase = CHECK_READ;
        schedule_next(step, 1);
        return 0;
    }
    if (phase == CHECK_READ) {
        if (index_now > FRAME_DEPTH && index_now < FRAME_DEPTH * 2) {
            const int address = index_now - FRAME_DEPTH - 1;
            const uint64_t observed = get_wide(read_data_h);
            const uint64_t expected = expected_word(address);
            if (observed != expected) {
                char message[160];
                (void)snprintf(message, sizeof(message), "address %d expected 0x%llx, observed 0x%llx", address,
                               (unsigned long long)expected, (unsigned long long)observed);
                fail(message);
                return 0;
            }
        }
        if (index_now == FRAME_DEPTH * 2) {
            const uint64_t observed = get_wide(read_data_h);
            const uint64_t expected = expected_word(FRAME_DEPTH - 1);
            if (observed != expected) {
                fail("last RAM word was not returned after the final synchronous read");
                return 0;
            }
        }
        if (index_now == FRAME_DEPTH * 2 + 1) {
            const uint64_t observed = get_wide(read_data_h);
            const uint64_t expected = expected_word(FRAME_DEPTH - 1);
            if (observed != expected) {
                fail("q_a did not retain the last value when rden_a was low");
                return 0;
            }
        }
        ++index_now;
        if (index_now > FRAME_DEPTH * 2 + 1) {
            phase = FINISHED;
            vpi_printf("COORDINATE FRAME RAM PASS: 640 writes/reads, 41-bit payload, synchronous output, q hold\n");
            vpi_control(vpiFinish, 0);
            return 0;
        }
        phase = DRIVE_LOW;
        schedule_next(step, 1);
    }
    return 0;
}

static PLI_INT32 start(p_cb_data cb)
{
    (void)cb;
    clk_h = get_handle("tb_coordinate_frame_ram.clk");
    write_enable_h = get_handle("tb_coordinate_frame_ram.write_enable");
    write_address_h = get_handle("tb_coordinate_frame_ram.write_address");
    write_data_low_h = get_handle("tb_coordinate_frame_ram.write_data_low");
    write_data_high_h = get_handle("tb_coordinate_frame_ram.write_data_high");
    read_enable_h = get_handle("tb_coordinate_frame_ram.read_enable");
    read_address_h = get_handle("tb_coordinate_frame_ram.read_address");
    read_data_h = get_handle("tb_coordinate_frame_ram.read_data");
    read_data_low_h = get_handle("tb_coordinate_frame_ram.read_data_low");
    read_data_high_h = get_handle("tb_coordinate_frame_ram.read_data_high");
    phase = DRIVE_LOW;
    index_now = 0;
    put_int(clk_h, 0);
    schedule_next(step, 1);
    return 0;
}

static void register_callbacks(void)
{
    s_cb_data cb;
    memset(&cb, 0, sizeof(cb));
    cb.reason = cbStartOfSimulation;
    cb.cb_rtn = start;
    vpi_register_cb(&cb);
}

void (*vlog_startup_routines[])(void) = {register_callbacks, NULL};
