#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

typedef struct { int a,b,c,delta,x1,x2,err; const char *name; } vector;
static vector vectors[256];
static size_t vector_count, vector_index;
static int random_count;
static unsigned rng_state=0x031040UL;
static vpiHandle a_h,b_h,c_h,delta_h,x1_h,x2_h,error_h;
static s_cb_data cb_data[3];
static s_vpi_time cb_time[3];
static void fail(const char *message) { vpi_printf("VPI FAIL: %s\n",message); fflush(stdout); exit(EXIT_FAILURE); }
static vpiHandle handle(const char *name) { vpiHandle h=vpi_handle_by_name((PLI_BYTE8 *)name,NULL); if(!h){char msg[200];snprintf(msg,sizeof(msg),"missing VPI handle %s",name);fail(msg);}return h; }
static void put(vpiHandle h,int value) { s_vpi_value v;v.format=vpiIntVal;v.value.integer=value;vpi_put_value(h,&v,NULL,vpiNoDelay); }
static int signed_value(vpiHandle h,unsigned width) { s_vpi_value v;unsigned mask=(1U<<width)-1U;v.format=vpiVectorVal;vpi_get_value(h,&v);if((v.value.vector[0].bval&mask)!=0U)fail("DUT output contains X/Z");unsigned raw=v.value.vector[0].aval&mask;if(raw&(1U<<(width-1U)))raw|=~mask;return (int)raw; }
static int bit_value(vpiHandle h) { s_vpi_value v;v.format=vpiVectorVal;vpi_get_value(h,&v);if(v.value.vector[0].bval&1U)fail("DUT domain_error contains X/Z");return (int)(v.value.vector[0].aval&1U); }
static int field_int(const char *start,const char *end,const char *key,int *out) { char needle[64];snprintf(needle,sizeof(needle),"\"%s\"",key);const char *p=strstr(start,needle);if(!p||p>=end)return 0;p=strchr(p,':');if(!p||p>=end)return 0;*out=(int)strtol(p+1,NULL,10);return 1; }
static void load_vectors(void) {
    FILE *f=fopen("tests/vectors/roots_directed.json","rb");long n;char *data,*p;
    if(!f) { fail("cannot open tests/vectors/roots_directed.json"); }
    fseek(f,0,SEEK_END);n=ftell(f);rewind(f);data=(char*)malloc((size_t)n+1);
    if(!data) { fail("allocation failed"); }
    if(fread(data,1,(size_t)n,f)!=(size_t)n) { fail("cannot read directed vectors"); }
    data[n]='\0';fclose(f);
    p=data;
    while((p=strstr(p,"\"category\""))!=NULL) {
        char *start=p;char *end=strchr(p,'}');vector *v;
        while(start>data&&*start!='{') { start--; }
        if(!start||!end||vector_count>=256)fail("malformed or oversized directed vector file");
        v=&vectors[vector_count++];v->name="directed";
        if(!field_int(start,end,"a",&v->a)||!field_int(start,end,"b",&v->b)||!field_int(start,end,"c",&v->c)||!field_int(start,end,"delta",&v->delta)||!field_int(start,end,"x1",&v->x1)||!field_int(start,end,"x2",&v->x2))fail("directed vector missing numeric field");
        {const char *q=strstr(start,"\"domain_error\"");if(!q||q>=end)fail("directed vector missing domain_error");v->err=(strstr(q,"true")&&strstr(q,"true")<end)?1:0;}
        p=end+1;
    }
    free(data);if(vector_count!=30)fail("expected exactly 30 directed vectors");
}
static unsigned next_random(void) { rng_state^=rng_state<<13;rng_state^=rng_state>>17;rng_state^=rng_state<<5;return rng_state; }
static int round_away(long double x) { return x<0.0L?(int)ceill(x-0.5L):(int)floorl(x+0.5L); }
static void make_random(vector *v) {
    v->a=(int)(next_random()%256U)-128;v->b=(int)(next_random()%256U)-128;v->c=(int)(next_random()%256U)-128;
    v->delta=v->b*v->b-4*v->a*v->c;v->err=(v->a==0||v->delta<0);
    if(v->err){v->x1=0;v->x2=0;}else{long double root=sqrtl((long double)v->delta);long double d=(long double)(2*v->a);v->x1=round_away((-(long double)v->b+root)/d);v->x2=round_away((-(long double)v->b-root)/d);}
    v->name="deterministic pseudo-random";
}
static PLI_INT32 drive(p_cb_data);
static PLI_INT32 check(p_cb_data);
static void schedule(PLI_INT32(*fn)(p_cb_data),unsigned slot,int readonly) { memset(&cb_data[slot],0,sizeof(cb_data[slot]));memset(&cb_time[slot],0,sizeof(cb_time[slot]));cb_time[slot].type=vpiSimTime;cb_time[slot].low=readonly?0:1;cb_data[slot].reason=readonly?cbReadOnlySynch:cbAfterDelay;cb_data[slot].cb_rtn=fn;cb_data[slot].time=&cb_time[slot];vpi_register_cb(&cb_data[slot]); }
static PLI_INT32 drive(p_cb_data cb) { (void)cb;if(vector_index>=vector_count+(size_t)random_count){vpi_printf("VPI PASS: %lu directed and %d deterministic random root vectors\n",(unsigned long)vector_count,random_count);vpi_control(vpiFinish,0);return 0;}vector *v;if(vector_index<vector_count)v=&vectors[vector_index];else{static vector rv;make_random(&rv);v=&rv;}put(a_h,v->a);put(b_h,v->b);put(c_h,v->c);schedule(check,1,1);return 0; }
static PLI_INT32 check(p_cb_data cb) { (void)cb;vector *v;if(vector_index<vector_count)v=&vectors[vector_index];else{static vector rv; /* values are reconstructed from the driven inputs below */s_vpi_value q;rv.a=signed_value(a_h,8);rv.b=signed_value(b_h,8);rv.c=signed_value(c_h,8);rv.delta=rv.b*rv.b-4*rv.a*rv.c;rv.err=(rv.a==0||rv.delta<0);if(rv.err){rv.x1=0;rv.x2=0;}else{long double d=sqrtl((long double)rv.delta);long double den=(long double)(2*rv.a);rv.x1=round_away((-(long double)rv.b+d)/den);rv.x2=round_away((-(long double)rv.b-d)/den);}rv.name="deterministic pseudo-random";v=&rv;(void)q;}
    int delta=signed_value(delta_h,18),x1=signed_value(x1_h,9),x2=signed_value(x2_h,9),err=bit_value(error_h);
    if(delta!=v->delta||x1!=v->x1||x2!=v->x2||err!=v->err){vpi_printf("VPI FAIL: vector %lu (%s) a=%d b=%d c=%d expected delta=%d x1=%d x2=%d err=%d got delta=%d x1=%d x2=%d err=%d\n",(unsigned long)vector_index,v->name,v->a,v->b,v->c,v->delta,v->x1,v->x2,v->err,delta,x1,x2,err);vpi_control(vpiFinish,1);return 0;}
    vector_index++;schedule(drive,0,0);return 0; }
static PLI_INT32 start(p_cb_data cb) { (void)cb;a_h=handle("tb_quadratic_roots.a");b_h=handle("tb_quadratic_roots.b");c_h=handle("tb_quadratic_roots.c");delta_h=handle("tb_quadratic_roots.delta");x1_h=handle("tb_quadratic_roots.x1");x2_h=handle("tb_quadratic_roots.x2");error_h=handle("tb_quadratic_roots.domain_error");load_vectors();random_count=256;schedule(drive,0,0);return 0; }
static void register_callbacks(void) { s_cb_data cb;memset(&cb,0,sizeof(cb));cb.reason=cbStartOfSimulation;cb.cb_rtn=start;vpi_register_cb(&cb); }
void (*vlog_startup_routines[])(void)={register_callbacks,0};
