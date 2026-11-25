#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vpi_user.h>

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
static int x, y, video_on, frame_ready, processing_done, f2_enabled, az1, rd1, rx11, rx12, vx1, vy1, az2, rd2, rx21, rx22, vx2, vy2;
static int phase, scenario, checked;
static char rows[4][15];
static vpiHandle handles[22];
static s_cb_data callbacks[2];
static s_vpi_time times[2];
static const char *names[22] = {"x_pixel","y_pixel","video_on","frame_ready","processing_done","f2_enabled","a_zero_f1","root_domain_valid_f1","root_x1_f1","root_x2_f1","vertex_x_f1","vertex_y_f1","a_zero_f2","root_domain_valid_f2","root_x1_f2","root_x2_f2","vertex_x_f2","vertex_y_f2","panel_active","panel_red","panel_green","panel_blue"};
static vpiHandle handle(const char *name) { char path[100]; vpiHandle h; snprintf(path,sizeof(path),"tb_task046_panel.%s",name); h=vpi_handle_by_name((PLI_BYTE8 *)path,NULL); if(!h){vpi_printf("missing %s\n",path);vpi_control(vpiFinish,1);} return h; }
static void put(vpiHandle h,int value) { s_vpi_value v; v.format=vpiIntVal;v.value.integer=value;vpi_put_value(h,&v,NULL,vpiNoDelay); }
static int get(vpiHandle h) { s_vpi_value v;v.format=vpiIntVal;vpi_get_value(h,&v);return v.value.integer; }
static int glyph_id(char c) {
    if(c==' ') return 0;
    if(c>='0' && c<='9') return c-'0'+1;
    if(c=='+') return 11;
    if(c=='-') return 12;
    if(c=='.') return 13;
    if(c==',') return 14;
    if(c=='/') return 15;
    if(c=='A')return 16;
    if(c=='F')return 17;
    if(c=='I')return 18;
    if(c=='N')return 19;
    if(c=='O')return 20;
    if(c=='R')return 21;
    if(c=='V')return 22;
    if(c=='X')return 23;
    if(c=='Y')return 24;
    if(c=='a')return 25;
    if(c=='b')return 26;
    if(c=='c')return 27;
    if(c=='i')return 28;
    if(c=='n')return 29;
    if(c=='r')return 30;
    if(c=='s')return 31;
    return 0;
}
static void append_root(char *out,int domain,int a_zero,int value1,int value2,int off) {
    char f1[8],f2[8];
    if(off){strcpy(f1,"OFF ");strcpy(f2,"OFF ");}
    else if(a_zero || !domain){strcpy(f1,"N/A ");strcpy(f2,"N/A ");}
    else {snprintf(f1,sizeof(f1),"%+04d",value1);snprintf(f2,sizeof(f2),"%+04d",value2);}
    memcpy(out,"R F",3);out[3]=off?'2':(out==rows[0]?'1':'2');out[4]=' ';
    memcpy(out+5,f1,4);out[9]=',';memcpy(out+10,f2,4);out[14]='\0';
}
static void append_vertex(char *out,int a_zero,int xval,int yval,int off,int which) {
    char xfield[4]={' ',' ',' ','\0'}, yfield[6]={' ',' ',' ',' ',' ','\0'};
    int ax=xval<0?-xval:xval, ay=yval<0?-yval:yval;
    if(off){memcpy(xfield,"OFF",3);memcpy(yfield,"OFF  ",5);}
    else if(a_zero){memcpy(xfield,"N/A",3);memcpy(yfield,"N/A  ",5);}
    else {
        xfield[0]=xval<0?'-':'+'; xfield[2]=(char)('0'+(ax%10)); xfield[1]=ax>=10?(char)('0'+((ax/10)%10)):' ';
        char digits[5];snprintf(digits,sizeof(digits),"%04d",ay);
        yfield[0]=yval<0?'-':'+'; memcpy(yfield+1,digits,4);
        if(ay<1000)yfield[1]=' ';
        if(ay<100)yfield[2]=' ';
        if(ay<10)yfield[3]=' ';
    }
    memcpy(out,"V F",3);out[3]=which?'2':'1';out[4]=' ';
    memcpy(out+5,xfield,3);out[8]=',';memcpy(out+9,yfield,5);out[14]='\0';
}
static void build_rows(void) {
    append_root(rows[0],rd1,az1,rx11,rx12,0);
    append_root(rows[1],rd2,az2,rx21,rx22,!f2_enabled);
    append_vertex(rows[2],az1,vx1,vy1,0,0);
    append_vertex(rows[3],az2,vx2,vy2,!f2_enabled,1);
}
static int reference_pixel(int xx,int yy,int *active,int *red,int *green,int *blue) {
    int line,dx,cell,col,row,id;
    *active=(frame_ready && processing_done && video_on && xx>=520 && xx<=639 && yy>=300 && yy<=479);
    *red=0;*green=0;*blue=0;
    if(!*active)return 0;
    if(xx==520 || xx==639 || yy==300 || yy==479){*red=15;*green=15;*blue=15;return 1;}
    if(xx>=524 && xx<=527 && ((yy>=321 && yy<=324)||(yy>=337 && yy<=340))){*red=15;*green=8;return 1;}
    if(xx>=524 && xx<=527 && ((yy>=361 && yy<=364)||(yy>=377 && yy<=380))){*green=15;return 1;}
    for(line=0;line<4;++line){
        int top=line==0?320:line==1?336:line==2?360:376;
        if(yy<top || yy>top+6 || xx<532 || xx>614) continue;
        dx=xx-532;cell=dx/6;col=dx%6;row=yy-top;
        if(cell>=14 || col>=5)continue;
        id=glyph_id(rows[line][cell]);
        if(font[id][row][col]=='1'){*red=15;*green=15;*blue=15;return 1;}
    }
    return 1;
}
static void select_scenario(int n) {
    static const int values[4][13] = {
        {1,0,1,1,-129,129,-64,-4224,0,1,-2,2,64},
        {0,0,0,0,0,0,7,1234,0,0,0,0,0},
        {1,1,0,1,0,0,0,0,1,1,0,0,0}
    };
    f2_enabled=values[n][0];az1=values[n][1];rd1=values[n][2];rx11=values[n][3]?values[n][4]:0;rx12=values[n][3]?values[n][5]:0;vx1=values[n][6];vy1=values[n][7];az2=values[n][8];rd2=values[n][9];rx21=values[n][10];rx22=values[n][11];vx2=values[n][12];vy2=(n==0?4223:0);
    build_rows();
}
static void schedule(PLI_INT32 (*fn)(p_cb_data),int slot,int readonly){memset(&callbacks[slot],0,sizeof(callbacks[slot]));memset(&times[slot],0,sizeof(times[slot]));times[slot].type=vpiSimTime;times[slot].low=readonly?0:1;callbacks[slot].reason=readonly?cbReadOnlySynch:cbAfterDelay;callbacks[slot].cb_rtn=fn;callbacks[slot].time=&times[slot];vpi_register_cb(&callbacks[slot]);}
static PLI_INT32 drive(p_cb_data cb);
static PLI_INT32 check(p_cb_data cb){int expected_active,er,eg,eb,ar,ag,ab,aa;(void)cb;reference_pixel(x,y,&expected_active,&er,&eg,&eb);aa=get(handles[18]);ar=get(handles[19]);ag=get(handles[20]);ab=get(handles[21]);if(aa!=expected_active||ar!=er||ag!=eg||ab!=eb){vpi_printf("TASK-046 PANEL FAIL: scenario=%d xy=%d,%d expected active/rgb=%d/%x%x%x actual=%d/%x%x%x text=%s | %s | %s | %s\n",scenario,x,y,expected_active,er,eg,eb,aa,ar,ag,ab,rows[0],rows[1],rows[2],rows[3]);vpi_control(vpiFinish,1);return 0;}++checked;schedule(drive,0,0);return 0;}
static PLI_INT32 drive(p_cb_data cb){(void)cb;
    if(scenario==4){video_on=1;frame_ready=0;processing_done=1;put(handles[2],video_on);put(handles[3],frame_ready);put(handles[4],processing_done);x=520;y=300;put(handles[0],x);put(handles[1],y);scenario=5;schedule(check,1,1);return 0;}
    if(scenario==5){video_on=1;frame_ready=1;processing_done=0;put(handles[2],video_on);put(handles[3],frame_ready);put(handles[4],processing_done);x=532;y=320;put(handles[0],x);put(handles[1],y);scenario=6;schedule(check,1,1);return 0;}
    if(scenario==6){video_on=0;frame_ready=1;processing_done=1;put(handles[2],video_on);put(handles[3],frame_ready);put(handles[4],processing_done);x=639;y=479;put(handles[0],x);put(handles[1],y);scenario=7;schedule(check,1,1);return 0;}
    if(scenario>=7 && scenario<=10){static const int boundary_y[4]={299,300,479,480};video_on=1;frame_ready=1;processing_done=1;put(handles[2],video_on);put(handles[3],frame_ready);put(handles[4],processing_done);x=520;y=boundary_y[scenario-7];put(handles[0],x);put(handles[1],y);scenario++;schedule(check,1,1);return 0;}
    if(scenario>=11){vpi_printf("TASK-048 PANEL PASS: %d full-window/reference pixel checks across valid, N/A, OFF, gates and y=299/300/479/480 limits\n",checked);vpi_control(vpiFinish,0);return 0;}
    select_scenario(scenario<4?scenario:0);
    if(phase==0){
        video_on=1;frame_ready=1;processing_done=1;
        put(handles[2],video_on);put(handles[3],frame_ready);put(handles[4],processing_done);
        put(handles[5],f2_enabled);put(handles[6],az1);put(handles[7],rd1);put(handles[8],rx11);put(handles[9],rx12);put(handles[10],vx1);put(handles[11],vy1);
        put(handles[12],az2);put(handles[13],rd2);put(handles[14],rx21);put(handles[15],rx22);put(handles[16],vx2);put(handles[17],vy2);
        phase=1;
    }
    if(phase==1){x=520;y=300;phase=2;} else {x++;if(x>639){x=520;y++;}if(y>479){scenario++;phase=0;schedule(drive,0,0);return 0;}}
    put(handles[0],x);put(handles[1],y);schedule(check,1,1);return 0;
}
static PLI_INT32 start(p_cb_data cb){int i;(void)cb;for(i=0;i<22;i++)handles[i]=handle(names[i]);scenario=0;phase=0;checked=0;schedule(drive,0,0);return 0;}
static void register_callbacks(void){s_cb_data cb;memset(&cb,0,sizeof(cb));cb.reason=cbStartOfSimulation;cb.cb_rtn=start;vpi_register_cb(&cb);}
void (*vlog_startup_routines[])(void)={register_callbacks,0};
