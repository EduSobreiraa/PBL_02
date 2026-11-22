#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

typedef struct { int a,b,c,delta,x1,x2,err; const char *name; } vector;
static vector vectors[256];
static size_t vector_count, vector_index;
static int random_count;
static unsigned stage_index;
static int start_mode,start_saw_low;
static vector active_vector;
static unsigned rng_state=0x031040UL;
static vpiHandle reset_h,start_h,enable_h,clk_h,a_h,b_h,c_h,delta_h,x1_h,x2_h,error_h,result_valid_h;
static vpiHandle valid_h[22];
static s_cb_data callbacks[16];
static s_vpi_time callback_times[16];
static unsigned callback_slot;

static void fail(const char *message) {
    vpi_printf("VPI FAIL: %s\n",message);
    fflush(stdout);
    vpi_control(vpiFinish,1);
    exit(EXIT_FAILURE);
}
static vpiHandle handle(const char *name) {
    vpiHandle h=vpi_handle_by_name((PLI_BYTE8 *)name,NULL);
    if(!h){char msg[200];snprintf(msg,sizeof(msg),"missing VPI handle %s",name);fail(msg);}
    return h;
}
static void put(vpiHandle h,int value) {
    s_vpi_value v;v.format=vpiIntVal;v.value.integer=value;vpi_put_value(h,&v,NULL,vpiNoDelay);
}
static int signed_value(vpiHandle h,unsigned width) {
    s_vpi_value v;unsigned mask=(1U<<width)-1U;v.format=vpiVectorVal;vpi_get_value(h,&v);
    if((v.value.vector[0].bval&mask)!=0U)fail("DUT output contains X/Z");
    unsigned raw=v.value.vector[0].aval&mask;
    if(raw&(1U<<(width-1U)))raw|=~mask;
    return (int)raw;
}
static int bit_value(vpiHandle h) {
    s_vpi_value v;v.format=vpiVectorVal;vpi_get_value(h,&v);
    if(v.value.vector[0].bval&1U)fail("DUT output contains X/Z");
    return (int)(v.value.vector[0].aval&1U);
}
static void schedule(PLI_INT32(*fn)(p_cb_data),unsigned delay) {
    unsigned slot=callback_slot++%16U;
    memset(&callbacks[slot],0,sizeof(callbacks[slot]));
    memset(&callback_times[slot],0,sizeof(callback_times[slot]));
    callback_times[slot].type=vpiSimTime;callback_times[slot].low=delay;
    callbacks[slot].reason=cbAfterDelay;callbacks[slot].cb_rtn=fn;
    callbacks[slot].time=&callback_times[slot];vpi_register_cb(&callbacks[slot]);
}
static int field_int(const char *start,const char *end,const char *key,int *out) {
    char needle[64];snprintf(needle,sizeof(needle),"\"%s\"",key);
    const char *p=strstr(start,needle);if(!p||p>=end)return 0;
    p=strchr(p,':');if(!p||p>=end)return 0;*out=(int)strtol(p+1,NULL,10);return 1;
}
static void load_vectors(void) {
    FILE *f=fopen("tests/vectors/roots_directed.json","rb");long n;char *data,*p;
    if(!f)fail("cannot open tests/vectors/roots_directed.json");
    fseek(f,0,SEEK_END);n=ftell(f);rewind(f);data=(char*)malloc((size_t)n+1);
    if(!data)fail("allocation failed");
    if(fread(data,1,(size_t)n,f)!=(size_t)n)fail("cannot read directed vectors");
    data[n]='\0';fclose(f);p=data;
    while((p=strstr(p,"\"category\""))!=NULL) {
        char *start=p,*end=strchr(p,'}');vector *v;
        while(start>data&&*start!='{')start--;
        if(!end||vector_count>=256)fail("malformed or oversized directed vector file");
        v=&vectors[vector_count++];v->name="directed";
        if(!field_int(start,end,"a",&v->a)||!field_int(start,end,"b",&v->b)||!field_int(start,end,"c",&v->c)
            ||!field_int(start,end,"delta",&v->delta)||!field_int(start,end,"x1",&v->x1)||!field_int(start,end,"x2",&v->x2))
            fail("directed vector missing numeric field");
        {const char *q=strstr(start,"\"domain_error\"");
            if(!q||q>=end)fail("directed vector missing domain_error");
            v->err=(strstr(q,"true")&&strstr(q,"true")<end)?1:0;}
        p=end+1;
    }
    free(data);if(vector_count!=30)fail("expected exactly 30 directed vectors");
}
static int integer_sqrt(int value) {
    int low=0,high=512;
    while(low+1<high){int mid=(low+high)/2;if(mid*mid<=value)low=mid;else high=mid;}
    return low;
}
static int rounded_root(int a,int b,int delta,int plus) {
    int s=integer_sqrt(delta),e=delta-s*s,n=-b+(plus?s:-s),mag_a=a<0?-a:a;
    int mag_n=n<0?-n:n,q=mag_n/mag_a,r=mag_n%mag_a;
    int correction=plus?(n>0):(n<0);
    int up=((q&1)!=0)&&(r!=0||e==0||correction);
    int magnitude=(q>>1)+up;
    return ((n<0)^(a<0))?-magnitude:magnitude;
}
static void make_random(vector *v) {
    v->a=(int)(rng_state&255U)-128;rng_state^=rng_state<<13;rng_state^=rng_state>>17;rng_state^=rng_state<<5;
    v->b=(int)(rng_state&255U)-128;rng_state^=rng_state<<13;rng_state^=rng_state>>17;rng_state^=rng_state<<5;
    v->c=(int)(rng_state&255U)-128;rng_state^=rng_state<<13;rng_state^=rng_state>>17;rng_state^=rng_state<<5;
    v->delta=v->b*v->b-4*v->a*v->c;v->err=(v->a==0||v->delta<0);
    if(v->err){v->x1=0;v->x2=0;}
    else{v->x1=rounded_root(v->a,v->b,v->delta,1);v->x2=rounded_root(v->a,v->b,v->delta,0);}
    v->name="deterministic pseudo-random";
}
static void check_result(vector *v) {
    int d=signed_value(delta_h,18),r1=signed_value(x1_h,9),r2=signed_value(x2_h,9),e=bit_value(error_h);
    if(d!=v->delta||r1!=v->x1||r2!=v->x2||e!=v->err){
        char msg[256];snprintf(msg,sizeof(msg),"root mismatch vector %lu (%s): a=%d b=%d c=%d expected (%d,%d,%d,%d), got (%d,%d,%d,%d)",
            (unsigned long)vector_index,v->name,v->a,v->b,v->c,v->delta,v->x1,v->x2,v->err,d,r1,r2,e);fail(msg);
    }
}
static PLI_INT32 check_clear(p_cb_data cb) {
    (void)cb;
    int clear_valid=bit_value(result_valid_h),clear_delta=signed_value(delta_h,18),clear_x1=signed_value(x1_h,9),clear_x2=signed_value(x2_h,9),clear_error=bit_value(error_h);
    if(clear_valid||clear_delta||clear_x1||clear_x2||clear_error) {
        vpiHandle hreset=handle("tb_quadratic_roots.system_reset"),hstart=handle("tb_quadratic_roots.start_accepted"),hclear=handle("tb_quadratic_roots.dut.output_clear_n"),hv21=handle("tb_quadratic_roots.dut.valid_s21");
        s_vpi_time now;memset(&now,0,sizeof(now));now.type=vpiSimTime;vpi_get_time(NULL,&now);
        vpi_printf("CLEAR DEBUG: t=%u reset=%d start=%d clear_n=%d v21=%d result=%d delta=%d x1=%d x2=%d error=%d\n",now.low,bit_value(hreset),bit_value(hstart),bit_value(hclear),bit_value(hv21),clear_valid,clear_delta,clear_x1,clear_x2,clear_error);
        fail("accepted START did not clear previous result/token");
    }
    return 0;
}
static PLI_INT32 begin_vector(p_cb_data cb);
static PLI_INT32 wait_start_edge(p_cb_data cb);
static PLI_INT32 accepted_start_edge(p_cb_data cb);
static PLI_INT32 begin_disabled(p_cb_data cb);
static PLI_INT32 begin_reset_probe(p_cb_data cb);
static PLI_INT32 check_stage(p_cb_data cb);
static PLI_INT32 check_no_token(p_cb_data cb);
static PLI_INT32 check_reset_clear(p_cb_data cb);
static PLI_INT32 finish_reset_probe(p_cb_data cb);
static PLI_INT32 assert_mid_reset(p_cb_data cb);
static PLI_INT32 release_reset(p_cb_data cb);
static PLI_INT32 check_end(p_cb_data cb);

static PLI_INT32 wait_start_edge(p_cb_data cb) {
    (void)cb;
    int level=bit_value(clk_h);
    if(!level)start_saw_low=1;
    else if(start_saw_low) {
        schedule(accepted_start_edge,1);
        return 0;
    }
    schedule(wait_start_edge,1);
    return 0;
}
static PLI_INT32 accepted_start_edge(p_cb_data cb) {
    (void)cb;put(start_h,0);(void)check_clear(NULL);
    if(start_mode==0){stage_index=0;(void)check_stage(NULL);}
    else if(start_mode==1)schedule(check_no_token,225);
    else schedule(assert_mid_reset,70);
    return 0;
}
static PLI_INT32 check_stage(p_cb_data cb) {
    (void)cb;
    for(unsigned i=0;i<22;i++) {
        int expected=(i==stage_index)?1:0;
        if(bit_value(valid_h[i])!=expected) {
            char msg[160];snprintf(msg,sizeof(msg),"token expected stage %u, observed valid[%u]=%d",stage_index,i,bit_value(valid_h[i]));fail(msg);
        }
    }
    if(bit_value(result_valid_h)!=(stage_index==22))fail("result_valid timing is not N+22");
    if(stage_index==22) {
        check_result(&active_vector);
        schedule(check_end,10);
    } else {
        stage_index++;
        schedule(check_stage,10);
    }
    return 0;
}
static PLI_INT32 begin_vector(p_cb_data cb) {
    (void)cb;
    if(vector_index>=(size_t)(random_count)+(size_t)vector_count){schedule(begin_disabled,6);return 0;}
    if(vector_index<vector_count)active_vector=vectors[vector_index];else make_random(&active_vector);
    put(a_h,active_vector.a);put(b_h,active_vector.b);put(c_h,active_vector.c);
    put(enable_h,1);put(reset_h,0);put(start_h,1);stage_index=0;start_mode=0;start_saw_low=0;
    schedule(wait_start_edge,1);
    return 0;
}
static PLI_INT32 check_end(p_cb_data cb) {
    (void)cb;
    if(bit_value(result_valid_h))fail("result_valid was wider than one cycle");
    check_result(&active_vector);
    vector_index++;
    schedule(begin_vector,6);
    return 0;
}
static PLI_INT32 begin_disabled(p_cb_data cb) {
    (void)cb;
    put(a_h,0);put(b_h,0);put(c_h,0);put(enable_h,0);put(start_h,1);put(reset_h,0);start_mode=1;start_saw_low=0;
    schedule(wait_start_edge,1);
    return 0;
}
static PLI_INT32 check_no_token(p_cb_data cb) {
    (void)cb;
    if(bit_value(result_valid_h))fail("inactive root lane emitted result_valid");
    for(unsigned i=0;i<22;i++)if(bit_value(valid_h[i]))fail("inactive root lane injected a valid token");
    if(signed_value(delta_h,18)||signed_value(x1_h,9)||signed_value(x2_h,9)||bit_value(error_h))
        fail("inactive root lane did not keep cleared outputs");
    schedule(begin_reset_probe,6);
    return 0;
}
static PLI_INT32 begin_reset_probe(p_cb_data cb) {
    (void)cb;
    put(a_h,1);put(b_h,-3);put(c_h,1);put(enable_h,1);put(start_h,1);put(reset_h,0);start_mode=2;start_saw_low=0;
    schedule(wait_start_edge,1);
    return 0;
}
static PLI_INT32 assert_mid_reset(p_cb_data cb) {
    (void)cb;
    put(start_h,0);put(reset_h,1);schedule(release_reset,10);
    return 0;
}
static PLI_INT32 release_reset(p_cb_data cb) {
    (void)cb;put(reset_h,0);schedule(check_reset_clear,5);schedule(finish_reset_probe,225);return 0;
}
static PLI_INT32 check_reset_clear(p_cb_data cb) {
    (void)cb;
    if(bit_value(result_valid_h)||signed_value(delta_h,18)||signed_value(x1_h,9)||signed_value(x2_h,9)||bit_value(error_h))
        fail("reset failed to flush root pipeline and outputs");
    for(unsigned i=0;i<22;i++)if(bit_value(valid_h[i]))fail("reset failed to clear pipeline valid token");
    return 0;
}
static PLI_INT32 finish_reset_probe(p_cb_data cb) {
    (void)cb;
    if(bit_value(result_valid_h)||signed_value(delta_h,18)||signed_value(x1_h,9)||signed_value(x2_h,9)||bit_value(error_h))
        fail("reset probe left stale result/token");
    for(unsigned i=0;i<22;i++)if(bit_value(valid_h[i]))fail("reset probe left stale pipeline token");
    vpi_printf("VPI PASS: %lu directed, %d deterministic integer-reference vectors; N+22 token, one-cycle valid, hold, START clear, inactive lane, reset flush\n",
        (unsigned long)vector_count,random_count);
    vpi_control(vpiFinish,0);return 0;
}
static PLI_INT32 start(p_cb_data cb) {
    (void)cb;
    reset_h=handle("tb_quadratic_roots.system_reset");start_h=handle("tb_quadratic_roots.start_accepted");clk_h=handle("tb_quadratic_roots.clk");
    enable_h=handle("tb_quadratic_roots.root_enable");a_h=handle("tb_quadratic_roots.a");b_h=handle("tb_quadratic_roots.b");c_h=handle("tb_quadratic_roots.c");
    delta_h=handle("tb_quadratic_roots.delta");x1_h=handle("tb_quadratic_roots.x1");x2_h=handle("tb_quadratic_roots.x2");
    error_h=handle("tb_quadratic_roots.domain_error");result_valid_h=handle("tb_quadratic_roots.result_valid");
    for(unsigned i=0;i<22;i++){char name[80];snprintf(name,sizeof(name),"tb_quadratic_roots.dut.valid_s%u",i);valid_h[i]=handle(name);}
    put(reset_h,1);put(start_h,0);put(enable_h,1);put(a_h,0);put(b_h,0);put(c_h,0);
    load_vectors();random_count=256;schedule(begin_vector,12);return 0;
}
static void register_callbacks(void) {
    s_cb_data cb;memset(&cb,0,sizeof(cb));cb.reason=cbStartOfSimulation;cb.cb_rtn=start;vpi_register_cb(&cb);
}
void (*vlog_startup_routines[])(void)={register_callbacks,0};
