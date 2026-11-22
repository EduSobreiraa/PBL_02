#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

enum { MAX_STEPS = 1200 };
typedef struct {
    int key, sw, busy, done, errors;
    int probe_busy, probe_done, probe_errors, glyph;
    const char *label;
} test_step;
static test_step steps[MAX_STEPS];
static int count, current, probe_cases;
static vpiHandle clk_h, key_h, sw_h, probe_busy_h, probe_done_h, probe_errors_h, glyph_h;
static vpiHandle top_led_h, probe_led_h, top_hex_h[6], probe_hex_h[6], segments_h;
static s_vpi_time readonly_time;
static const int glyph_segments[8] = {0x7f,0x06,0x2f,0x0e,0x63,0x79,0x24,0x7f};

static void fail(const char *message)
{
    vpi_printf("VPI FAIL: %s\n",message);
    fflush(stdout);
    exit(EXIT_FAILURE);
}
static vpiHandle handle(const char *name)
{
    vpiHandle h = vpi_handle_by_name((PLI_BYTE8 *)name,NULL);
    if (!h) fail(name);
    return h;
}
static void put(vpiHandle h, int value)
{
    s_vpi_value v;
    v.format=vpiIntVal; v.value.integer=value;
    vpi_put_value(h,&v,NULL,vpiNoDelay);
}
static void expect(vpiHandle h, int expected, const char *name)
{
    s_vpi_value v;
    char message[192];
    v.format=vpiVectorVal;
    vpi_get_value(h,&v);
    if (v.value.vector[0].bval || v.value.vector[0].aval != expected) {
        snprintf(message,sizeof(message),"cycle %d %s expected 0x%x got 0x%x unknown 0x%x",current,name,expected,v.value.vector[0].aval,v.value.vector[0].bval);
        fail(message);
    }
}
static test_step *add(int key, int sw, int busy, int done, int errors, const char *label)
{
    test_step *s;
    if (count==MAX_STEPS) fail("scenario capacity exceeded");
    s=&steps[count++]; memset(s,0,sizeof(*s));
    s->key=key; s->sw=sw; s->busy=busy; s->done=done; s->errors=errors; s->label=label;
    return s;
}
static void reset_session(void)
{
    int i;
    for (i=0;i<5;++i) add(1,0,i<2?-1:0,0,0,i==4?"KEY1 clears LEDs and HEX":NULL);
    for (i=0;i<5;++i) add(3,0,0,0,0,NULL);
}
static void capture(int value)
{
    int i, sw=value<0?256-value:value;
    for(i=0;i<3;++i) add(2,sw,0,0,0,NULL);
    for(i=0;i<3;++i) add(3,sw,0,0,0,NULL);
}
static void execute(int errors, int previous_done, int previous_errors)
{
    int i;
    for(i=0;i<3;++i) add(2,0,0,previous_done,previous_errors,NULL);
    add(2,0,1,0,0,"BUSY clears old message during validation");
    add(2,0,1,0,errors,"retained errors precede global DONE with HEX blank");
    for(i=0;i<24;++i) {
        test_step *wait=add(3,0,1,0,errors,NULL);
        wait->busy=-1; wait->done=-1;
    }
    add(3,0,0,1,errors,"global DONE presents selected message and both error LEDs");
    for(i=0;i<5;++i) add(3,0,0,1,errors,i==4?"message retained after DONE":NULL);
}
static void scenario(void)
{
    int busy, done, mask, f1, f2;
    reset_session();
    for(busy=0;busy<2;++busy) for(done=0;done<2;++done) for(mask=0;mask<16;++mask) {
        test_step *s=add(3,0,0,0,0,NULL);
        s->probe_busy=busy; s->probe_done=done; s->probe_errors=mask; s->glyph=mask%8;
        ++probe_cases;
    }
    for(f1=0;f1<3;++f1) for(f2=0;f2<4;++f2) {
        int errors=(f1==1?1:f1==2?2:0)|(f2==2?4:f2==3?8:0);
        reset_session();
        capture(f1==1?0:1); capture(f1==2?127:f1==1?1:0); capture(0);
        capture(f2==0||f2==2?0:1); capture(f2==3?127:f2==2?1:0); capture(0);
        add(3,0,0,0,0,"six captured coefficients leave status blank before START");
        execute(errors,0,0);
        if(f1==2&&f2==2) execute(errors,1,errors);
    }
    reset_session();
}
static void check_status(vpiHandle led, vpiHandle hex[6], int busy, int done, int errors)
{
    int expected_led=busy|(done<<1)|((errors&3?1:0)<<2)|((errors&12?1:0)<<3);
    int selected=-1, i, expected[6]={0x7f,0x7f,0x7f,0x7f,0x7f,0x7f};
    expect(led,expected_led,"LEDR");
    if(done) for(i=0;i<4;++i) if(errors&(1<<i)) {selected=i;break;}
    if(selected>=0) {
        expected[5]=0x06; expected[4]=0x2f; expected[3]=0x2f;
        expected[1]=(selected==0||selected==2)?0x0e:0x63;
        expected[0]=selected<2?0x79:0x24;
    }
    for(i=0;i<6;++i) expect(hex[i],expected[i],"HEX segments");
}
static PLI_INT32 drive(p_cb_data cb);
static PLI_INT32 raise_clock(p_cb_data cb);
static PLI_INT32 check(p_cb_data cb);
static PLI_INT32 lower_clock(p_cb_data cb);
static void later(PLI_INT32 (*fn)(p_cb_data))
{
    s_cb_data cb; s_vpi_time time;
    memset(&cb,0,sizeof(cb)); memset(&time,0,sizeof(time));
    time.type=vpiSimTime; time.low=1;
    cb.reason=cbAfterDelay; cb.cb_rtn=fn; cb.time=&time;
    vpi_register_cb(&cb);
}
static PLI_INT32 drive(p_cb_data cb)
{
    test_step *s=&steps[current]; (void)cb;
    put(clk_h,0); put(key_h,s->key); put(sw_h,s->sw);
    put(probe_busy_h,s->probe_busy); put(probe_done_h,s->probe_done);
    put(probe_errors_h,s->probe_errors); put(glyph_h,s->glyph);
    later(raise_clock); return 0;
}
static PLI_INT32 raise_clock(p_cb_data unused)
{
    s_cb_data cb; (void)unused;
    put(clk_h,1); memset(&cb,0,sizeof(cb)); memset(&readonly_time,0,sizeof(readonly_time));
    readonly_time.type=vpiSimTime;
    cb.reason=cbReadOnlySynch; cb.cb_rtn=check; cb.time=&readonly_time;
    vpi_register_cb(&cb); return 0;
}
static PLI_INT32 check(p_cb_data cb)
{
    test_step *s=&steps[current]; (void)cb;
    check_status(probe_led_h,probe_hex_h,s->probe_busy,s->probe_done,s->probe_errors);
    expect(segments_h,glyph_segments[s->glyph],"decoder glyph");
    if(s->busy>=0) check_status(top_led_h,top_hex_h,s->busy,s->done,s->errors);
    if(s->label) vpi_printf("VPI PASS: %s\n",s->label);
    later(lower_clock); return 0;
}
static PLI_INT32 lower_clock(p_cb_data cb)
{
    (void)cb; put(clk_h,0);
    if(++current==count) {
        vpi_printf("VPI PASS: %d status combinations, all 8 glyph codes and %d total status/top cycles\n",probe_cases,count);
        vpi_control(vpiFinish,0);
    } else drive(NULL);
    return 0;
}
static PLI_INT32 startup_test(p_cb_data cb)
{
    char path[128]; int i; (void)cb;
    clk_h=handle("tb_status_errors_pbl03.clk"); key_h=handle("tb_status_errors_pbl03.key_n"); sw_h=handle("tb_status_errors_pbl03.sw");
    probe_busy_h=handle("tb_status_errors_pbl03.probe_busy"); probe_done_h=handle("tb_status_errors_pbl03.probe_done");
    probe_errors_h=handle("tb_status_errors_pbl03.probe_errors"); glyph_h=handle("tb_status_errors_pbl03.probe_glifo");
    segments_h=handle("tb_status_errors_pbl03.probe_segmentos");
    top_led_h=handle("tb_status_errors_pbl03.dut.LEDR"); probe_led_h=handle("tb_status_errors_pbl03.probe_led");
    for(i=0;i<6;++i) {
        snprintf(path,sizeof(path),"tb_status_errors_pbl03.dut.HEX%d",i); top_hex_h[i]=handle(path);
        snprintf(path,sizeof(path),"tb_status_errors_pbl03.probe_hex%d",i); probe_hex_h[i]=handle(path);
    }
    scenario(); drive(NULL); return 0;
}
static void startup(void)
{
    s_cb_data cb; memset(&cb,0,sizeof(cb)); cb.reason=cbStartOfSimulation; cb.cb_rtn=startup_test;
    vpi_register_cb(&cb);
}
void (*vlog_startup_routines[])(void)={startup,0};
