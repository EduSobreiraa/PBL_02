#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

typedef struct { int x,y,video,done,f2ena,v1,v2,roots[4]; const char *name; } test_case;
static test_case cases[6000];static size_t count,index_case;
static vpiHandle video_h,done_h,f2ena_h,v1_h,v2_h,x_h,y_h,root_h[4],marker_h,label_h;
static s_cb_data cbs[2];static s_vpi_time times[2];
static const char *font[15][7]={
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
 {"11111","10000","10000","11110","10000","10000","10000"},
 {"00000","10001","01010","00100","01010","10001","00000"},
 {"00000","00000","11111","00000","11111","00000","00000"},
 {"00000","00100","00100","11111","00100","00100","00000"},
 {"00000","00000","00000","11111","00000","00000","00000"}
};
static void fail(const char *m){vpi_printf("VPI FAIL: %s\n",m);fflush(stdout);exit(EXIT_FAILURE);}
static vpiHandle geth(const char *n){vpiHandle h=vpi_handle_by_name((PLI_BYTE8*)n,NULL);if(!h){char b[200];snprintf(b,sizeof(b),"missing handle %s",n);fail(b);}return h;}
static int bit_read(vpiHandle h){s_vpi_value v;v.format=vpiVectorVal;vpi_get_value(h,&v);if(v.value.vector[0].bval&1U)fail("X/Z hit");return (int)(v.value.vector[0].aval&1U);}
static void put(vpiHandle h,int n){s_vpi_value v;v.format=vpiIntVal;v.value.integer=n;vpi_put_value(h,&v,NULL,vpiNoDelay);}
static void add_case(int sx,int sy,int video,int done,int f2ena,int v1,int v2,const int *roots,const char *name){test_case *t;if(count>=6000)fail("case overflow");t=&cases[count++];t->x=sx-320;t->y=240-sy;t->video=video;t->done=done;t->f2ena=f2ena;t->v1=v1;t->v2=v2;memcpy(t->roots,roots,4*sizeof(int));t->name=name;}
static int glyph_index(char c){if(c>='0'&&c<='9')return c-'0';if(c=='F')return 10;if(c=='x')return 11;if(c=='=')return 12;if(c=='+')return 13;if(c=='-')return 14;return -1;}
static int root_label_pixel(int screenx,int screeny,int root,int ybase,const char *prefix,int eligible){char text[10];int mag=root<0?-root:root;int col,row;char sign=root<0?'-':'+';if(!eligible||screeny<ybase||screeny>=ybase+7)return 0;snprintf(text,sizeof(text),"%s%c%03d",prefix,sign,mag);col=screenx-(320+root-27);if(col<0||col>=54)return 0;if(col%6>=5)return 0;row=screeny-ybase;{int gi=glyph_index(text[col/6]);return gi>=0&&font[gi][row][col%6]=='1';}}
static int expected_marker_xy(const test_case *t){int sx=t->x+320,sy=240-t->y;int en[4]={t->done&&t->v1,t->done&&t->v1,t->done&&t->f2ena&&t->v2,t->done&&t->f2ena&&t->v2};for(int i=0;i<4;i++){int cx=320+t->roots[i];if(en[i]&&((sx==cx&&abs(sy-240)<=1)||(sy==240&&abs(sx-cx)<=1)))return 1;}return 0;}
static int expected_label(const test_case *t){static const int ybase[4]={208,216,224,232};static const char *prefix[4]={"F1x1=","F1x2=","F2x1=","F2x2="};int screenx=t->x+320,screeny=240-t->y;int en[4]={t->done&&t->v1,t->done&&t->v1,t->done&&t->f2ena&&t->v2,t->done&&t->f2ena&&t->v2};for(int i=0;i<4;i++)if(root_label_pixel(screenx,screeny,t->roots[i],ybase[i],prefix[i],en[i]))return 1;return 0;}
static PLI_INT32 drive(p_cb_data);static PLI_INT32 check(p_cb_data);
static void schedule(PLI_INT32(*fn)(p_cb_data),int slot,int readonly){memset(&cbs[slot],0,sizeof(cbs[slot]));memset(&times[slot],0,sizeof(times[slot]));times[slot].type=vpiSimTime;times[slot].low=readonly?0:1;cbs[slot].reason=readonly?cbReadOnlySynch:cbAfterDelay;cbs[slot].cb_rtn=fn;cbs[slot].time=&times[slot];vpi_register_cb(&cbs[slot]);}
static void build_cases(void){int r[4]={-129,129,-1,0};for(int i=0;i<4;i++){int cx=320+r[i],yb=208+8*i;for(int sy=yb;sy<yb+7;sy++)for(int sx=cx-27;sx<cx+27;sx++)add_case(sx,sy,1,1,1,1,1,r,"label bitmap pixel");for(int k=0;k<5;k++){int sx=(k==1?cx-1:k==2?cx+1:cx),sy=(k==3?239:k==4?241:240);add_case(sx,sy,1,1,1,1,1,r,"five-pixel marker");}}
 add_case(319,240,1,0,1,1,1,r,"DONE gates marker");add_case(319,240,1,1,0,1,1,r,"F2 enable retains F1 only");add_case(320,240,1,1,1,0,0,r,"domain invalid gates roots");add_case(320,240,0,1,1,1,1,r,"video blanking");add_case(449,208,1,1,1,1,1,r,"rightmost label boundary");add_case(191,232,1,1,1,1,1,r,"leftmost label boundary");}
static PLI_INT32 drive(p_cb_data cb){(void)cb;if(index_case>=count){vpi_printf("VPI PASS: %lu root renderer pixel/gating cases\n",(unsigned long)count);vpi_control(vpiFinish,0);return 0;}test_case *t=&cases[index_case];put(video_h,t->video);put(done_h,t->done);put(f2ena_h,t->f2ena);put(v1_h,t->v1);put(v2_h,t->v2);put(x_h,t->x);put(y_h,t->y);for(int i=0;i<4;i++)put(root_h[i],t->roots[i]);schedule(check,1,1);return 0;}
static PLI_INT32 check(p_cb_data cb){(void)cb;test_case *t=&cases[index_case];int em=t->video&&expected_marker_xy(t),el=t->video&&expected_label(t);int am=bit_read(marker_h),al=bit_read(label_h);if(am!=em||al!=el){vpi_printf("VPI FAIL: case %lu %s xcart=%d ycart=%d roots=%d,%d,%d,%d expected marker/label=%d/%d got=%d/%d\n",(unsigned long)index_case,t->name,t->x,t->y,t->roots[0],t->roots[1],t->roots[2],t->roots[3],em,el,am,al);vpi_control(vpiFinish,1);return 0;}index_case++;schedule(drive,0,0);return 0;}
static PLI_INT32 start(p_cb_data cb){(void)cb;video_h=geth("tb_root_renderer.video_on");done_h=geth("tb_root_renderer.processing_done");f2ena_h=geth("tb_root_renderer.f2_enabled");v1_h=geth("tb_root_renderer.root_domain_valid_f1");v2_h=geth("tb_root_renderer.root_domain_valid_f2");x_h=geth("tb_root_renderer.x_cartesiano");y_h=geth("tb_root_renderer.y_cartesiano");root_h[0]=geth("tb_root_renderer.f1_x1");root_h[1]=geth("tb_root_renderer.f1_x2");root_h[2]=geth("tb_root_renderer.f2_x1");root_h[3]=geth("tb_root_renderer.f2_x2");marker_h=geth("tb_root_renderer.root_marker_hit");label_h=geth("tb_root_renderer.root_label_hit");build_cases();schedule(drive,0,0);return 0;}
static void register_callbacks(void){s_cb_data cb;memset(&cb,0,sizeof(cb));cb.reason=cbStartOfSimulation;cb.cb_rtn=start;vpi_register_cb(&cb);}
void (*vlog_startup_routines[])(void)={register_callbacks,0};
