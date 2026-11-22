#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

typedef struct { int reset, start, a1, b1, c1, a2, b2, c2, x, y; const char *label; } step_t;
typedef struct { int state, busy, done, err_a, err_v, display; } model_t;
enum { WAIT_START, VALIDATE, COMPLETE, MAX_STEPS = 128 };
static step_t steps[MAX_STEPS];
static size_t count, index_step;
static model_t f1, f2;
static s_cb_data callbacks[4];
static s_vpi_time times[4];
static vpiHandle clk_h, reset_h, start_h, a1_h, b1_h, c1_h, a2_h, b2_h, c2_h, x_h, y_h;
static vpiHandle busy1_h, done1_h, ea1_h, ev1_h, de1_h, hit1_h, dhit1_h;
static vpiHandle busy2_h, done2_h, ea2_h, ev2_h, de2_h, hit2_h, dhit2_h;
static vpiHandle xnum1_h,xden1_h,ynum1_h,yden1_h,xnum2_h,xden2_h,ynum2_h,yden2_h;
static vpiHandle rootx1_h[2],rootx2_h[2],rootvalid_h[2];

static void fail(const char *s) { vpi_printf("VPI FAIL: %s\n", s); fflush(stdout); exit(EXIT_FAILURE); }
static vpiHandle handle(const char *s) { vpiHandle h=vpi_handle_by_name((PLI_BYTE8 *)s,NULL); if(!h){char b[256];snprintf(b,sizeof b,"missing VPI handle %s",s);fail(b);}return h; }
static void put(vpiHandle h,int n){s_vpi_value v;v.format=vpiIntVal;v.value.integer=n;vpi_put_value(h,&v,NULL,vpiNoDelay);}
static int bit(vpiHandle h){s_vpi_value v;v.format=vpiVectorVal;vpi_get_value(h,&v);if(v.value.vector[0].bval&1U)fail("output contains X/Z");return (int)(v.value.vector[0].aval&1U);}
static int64_t number(vpiHandle h,unsigned width,int sign){s_vpi_value v;uint32_t mask=(1U<<width)-1U,raw;v.format=vpiVectorVal;vpi_get_value(h,&v);if(v.value.vector[0].bval&mask)fail("rational term contains X/Z");raw=v.value.vector[0].aval&mask;if(sign&&(raw&(1U<<(width-1U))))return (int64_t)raw-(INT64_C(1)<<width);return raw;}
static void add(int r,int s,int a1,int b1,int c1,int a2,int b2,int c2,int x,int y,const char *l){if(count>=MAX_STEPS)fail("step capacity");steps[count++]=(step_t){r,s,a1,b1,c1,a2,b2,c2,x,y,l};}
static int vertex_out(int a,int b,int c){long n,d;if(a==0)return 0;n=4L*a*c-(long)b*b;d=4L*a;if(d<0){d=-d;n=-n;}return n < -239L*d || n > 240L*d;}
static void update(model_t *m,int reset,int start,int a,int b,int c){if(reset){*m=(model_t){WAIT_START,0,0,0,0,0};return;}switch(m->state){case WAIT_START:if(start)*m=(model_t){VALIDATE,1,0,0,0,0};break;case VALIDATE:m->state=COMPLETE;m->busy=0;m->done=1;m->err_a=(a==0);m->err_v=vertex_out(a,b,c);m->display=(a!=0&&!m->err_v);break;case COMPLETE:if(start)*m=(model_t){VALIDATE,1,0,0,0,0};break;default:*m=(model_t){WAIT_START,0,0,0,0,0};}}
static int hit(int a,int b,int c,int x,int y,int derivative,int display){long value;if(!display||y < -239||y > 240)return 0;value=derivative?2L*a*x+b:(long)a*x*x+(long)b*x+c;return value==y;}
static PLI_INT32 drive(p_cb_data cb);
static PLI_INT32 raise_clock(p_cb_data cb);
static PLI_INT32 check_step(p_cb_data cb);
static PLI_INT32 lower_clock(p_cb_data cb);
static void schedule(PLI_INT32 (*fn)(p_cb_data),unsigned delay){int slot=(fn==raise_clock)?0:(fn==check_step)?1:(fn==lower_clock)?2:3;memset(&callbacks[slot],0,sizeof callbacks[slot]);memset(&times[slot],0,sizeof times[slot]);times[slot].type=vpiSimTime;times[slot].low=delay;callbacks[slot].reason=cbAfterDelay;callbacks[slot].cb_rtn=fn;callbacks[slot].time=&times[slot];vpi_register_cb(&callbacks[slot]);}
static PLI_INT32 raise_clock(p_cb_data cb){(void)cb;put(clk_h,1);step_t *s=&steps[index_step];update(&f1,s->reset,s->start,s->a1,s->b1,s->c1);update(&f2,s->reset,s->start,s->a2,s->b2,s->c2);schedule(check_step,1);return 0;}
static void check(vpiHandle h,int expected,const char *name,int *bad){int got=bit(h);if(got!=expected){vpi_printf("VPI FAIL step %lu (%s): %s expected %d got %d\n",(unsigned long)index_step,steps[index_step].label,name,expected,got);*bad=1;}}
static void check_processor(model_t *m,int a,int b,int c,int is_f2,int *bad){vpiHandle xn=is_f2?xnum2_h:xnum1_h,xd=is_f2?xden2_h:xden1_h,yn=is_f2?ynum2_h:ynum1_h,yd=is_f2?yden2_h:yden1_h;check(is_f2?busy2_h:busy1_h,m->busy,is_f2?"busy_f2":"busy_f1",bad);check(is_f2?done2_h:done1_h,m->done,is_f2?"done_f2":"done_f1",bad);check(is_f2?ea2_h:ea1_h,m->err_a&&(!is_f2||(a!=0||b!=0||c!=0)),is_f2?"error_a_zero_f2":"error_a_zero_f1",bad);check(is_f2?ev2_h:ev1_h,m->err_v&&(!is_f2||(a!=0||b!=0||c!=0)),is_f2?"error_vertex_f2":"error_vertex_f1",bad);check(is_f2?de2_h:de1_h,m->display,is_f2?"display_enable_f2":"display_enable_f1",bad);check(is_f2?hit2_h:hit1_h,hit(a,b,c,steps[index_step].x,steps[index_step].y,0,m->display),is_f2?"f2_hit":"f1_hit",bad);check(is_f2?dhit2_h:dhit1_h,hit(a,b,c,steps[index_step].x,steps[index_step].y,1,m->display),is_f2?"f2_derivada_hit":"f1_derivada_hit",bad);if(is_f2&&a==0&&b==0&&c==0){check(rootvalid_h[1],0,"inactive F2 root domain valid",bad);if(number(rootx1_h[1],9,1)!=0||number(rootx2_h[1],9,1)!=0){vpi_printf("VPI FAIL step %lu: inactive F2 roots are not zero\n",(unsigned long)index_step);*bad=1;}}if(a!=0){int64_t yn_expected=4LL*a*c-(int64_t)b*b;if(a<0)yn_expected=-yn_expected;if(number(xn,9,1)!=(a>0?-b:b)||number(xd,9,0)!=2*abs(a)||number(yn,18,1)!=yn_expected||number(yd,10,0)!=4*abs(a)){vpi_printf("VPI FAIL step %lu: rational terms differ for %s\n",(unsigned long)index_step,is_f2?"F2":"F1");*bad=1;}}}
static PLI_INT32 check_step(p_cb_data cb){step_t *s=&steps[index_step];int bad=0;(void)cb;check_processor(&f1,s->a1,s->b1,s->c1,0,&bad);check_processor(&f2,s->a2,s->b2,s->c2,1,&bad);if(bad){fflush(stdout);exit(EXIT_FAILURE);}schedule(lower_clock,1);return 0;}
static PLI_INT32 lower_clock(p_cb_data cb){(void)cb;put(clk_h,0);index_step++;schedule(drive,1);return 0;}
static PLI_INT32 drive(p_cb_data cb){step_t *s;(void)cb;if(index_step>=count){vpi_printf("VPI PASS: %lu F1/F2 processor cycles\n",(unsigned long)count);vpi_control(vpiFinish,0);return 0;}s=&steps[index_step];put(clk_h,0);put(reset_h,s->reset);put(start_h,s->start);put(a1_h,s->a1);put(b1_h,s->b1);put(c1_h,s->c1);put(a2_h,s->a2);put(b2_h,s->b2);put(c2_h,s->c2);put(x_h,s->x);put(y_h,s->y);schedule(raise_clock,5);return 0;}
static PLI_INT32 start_test(p_cb_data cb){(void)cb;
#define H(v,n) v=handle("tb_f1_f2_processors." #n)
H(clk_h,clk);H(reset_h,system_reset);H(start_h,start_pulse);H(a1_h,a1);H(b1_h,b1);H(c1_h,c1);H(a2_h,a2);H(b2_h,b2);H(c2_h,c2);H(x_h,x_cartesiano);H(y_h,y_cartesiano);H(busy1_h,busy_f1);H(done1_h,done_f1);H(ea1_h,error_a_zero_f1);H(ev1_h,error_vertex_f1);H(de1_h,display_enable_f1);H(hit1_h,f1_hit);H(dhit1_h,f1_derivada_hit);H(busy2_h,busy_f2);H(done2_h,done_f2);H(ea2_h,error_a_zero_f2);H(ev2_h,error_vertex_f2);H(de2_h,display_enable_f2);H(hit2_h,f2_hit);H(dhit2_h,f2_derivada_hit);H(rootx1_h[0],root_x1_f1);H(rootx2_h[0],root_x2_f1);H(rootvalid_h[0],root_domain_valid_f1);H(rootx1_h[1],root_x1_f2);H(rootx2_h[1],root_x2_f2);H(rootvalid_h[1],root_domain_valid_f2);H(xnum1_h,f1_x_num);H(xden1_h,f1_x_den);H(ynum1_h,f1_y_num);H(yden1_h,f1_y_den);H(xnum2_h,f2_x_num);H(xden2_h,f2_x_den);H(ynum2_h,f2_y_num);H(yden2_h,f2_y_den);
#undef H
memset(&f1,0,sizeof f1);memset(&f2,0,sizeof f2);
add(1,0,1,0,0,0,0,0,0,0,"reset in WAIT_START; null F2");add(0,0,1,0,0,0,0,0,0,0,"F1 valid, F2 null");add(0,1,1,0,0,0,0,0,0,0,"START both processors");add(0,1,1,0,0,0,0,0,0,0,"VALIDATE; START ignored; null F2 BUSY");add(0,0,1,0,0,0,0,0,0,0,"F1/F2 complete; null F2 done without errors");add(0,0,1,0,0,0,0,0,0,0,"DONE retained");add(0,1,1,0,0,1,0,0,0,0,"new START, F2 a zero with b nonzero");add(0,0,1,0,0,1,0,0,0,0,"F2 a=0,b nonzero error independent of F1");add(0,1,1,0,0,0,0,1,0,0,"new START, F2 a zero with c nonzero");add(0,0,1,0,0,0,0,1,0,0,"F2 a=0,c nonzero error");add(0,1,0,0,0,1,0,1,0,0,"F1 invalid while F2 valid");add(0,0,0,0,0,1,0,1,0,0,"F1 a=0 error, F2 valid display");add(1,0,0,0,0,1,0,1,0,0,"reset from COMPLETE");add(0,1,1,127,0,1,0,0,0,0,"start F1 vertex outside while F2 valid");add(0,0,1,127,0,1,0,0,0,0,"independent F1 vertex error and valid F2");add(0,1,1,0,0,1,127,0,0,0,"start F2 vertex outside while F1 valid");add(0,0,1,0,0,1,127,0,0,0,"independent F2 vertex error and valid F1");add(1,1,1,0,0,1,0,0,0,0,"reset overrides START in WAIT_START");add(0,1,1,0,0,1,0,0,0,0,"start before VALIDATE reset");add(1,0,1,0,0,1,0,0,0,0,"reset in VALIDATE");add(0,1,1,0,0,1,0,0,0,0,"restart after VALIDATE reset");add(0,0,1,0,0,1,0,0,0,0,"COMPLETE before reset");add(1,0,1,0,0,1,0,0,0,0,"reset from COMPLETE");add(0,1,1,0,0,1,0,0,0,0,"restart after reset");add(0,0,1,0,0,1,0,0,0,0,"final completion");
schedule(drive,1);return 0;}
static void startup(void){s_cb_data cb;memset(&cb,0,sizeof cb);cb.reason=cbStartOfSimulation;cb.cb_rtn=start_test;vpi_register_cb(&cb);}
void (*vlog_startup_routines[])(void)={startup,0};
