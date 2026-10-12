`timescale 1ns/1ps
module tb_status_flags;
    reg loaded;
    reg signed [7:0] a;
    reg signed [17:0] delta;
    wire OV,ERR;
    reg clk,key0_n,key1_n;
    reg [7:0] sw;
    reg [1:0] sel;
    wire signed [7:0] stored_a,stored_b,stored_c;
    wire stored_loaded,integrated_ov,integrated_err,domain_error;
    wire signed [17:0] stored_delta;
    wire signed [8:0] x1,x2;
    wire signed [22:0] selected_value;
    integer l,av,dv,expected,index,checks,integrated_checks;
    flag_ov_err dut(.loaded(loaded),.a(a),.delta(delta),.OV(OV),.ERR(ERR));
    coefficient_input_core capture(.clk(clk),.key0_n(key0_n),.key1_n(key1_n),.sw(sw),.a(stored_a),.b(stored_b),.c(stored_c),.loaded(stored_loaded));
    quadratic_roots roots(.a(stored_a),.b(stored_b),.c(stored_c),.delta(stored_delta),.x1(x1),.x2(x2),.domain_error(domain_error));
    flag_ov_err integrated(.loaded(stored_loaded),.a(stored_a),.delta(stored_delta),.OV(integrated_ov),.ERR(integrated_err));
    result_select selector(.x(sw),.y(23'sd0),.x1(x1),.x2(x2),.sel(sel),.value(selected_value));
    always #5 clk=~clk;
    task reset_capture;
        begin
            key0_n=1;key1_n=0;
            repeat(8) @(negedge clk);
            key1_n=1;
            repeat(8) @(negedge clk);
            case({stored_loaded,integrated_ov,integrated_err})
                3'b000:;
                default:$fatal(1,"reset did not clear ERR/loaded");
            endcase
            integrated_checks=integrated_checks+1;
        end
    endtask
    task capture_value(input [7:0] value);
        begin
            sw=value;key0_n=1;
            repeat(8) @(negedge clk);
            key0_n=0;
            repeat(8) @(negedge clk);
            key0_n=1;
            repeat(8) @(negedge clk);
        end
    endtask
    task hold_and_check(input expected_err);
        integer k;
        begin
            for(k=0;k<16;k=k+1) begin
                sw=k*17;sel=k[1:0];
                repeat(2) @(negedge clk);
                case((integrated_err===expected_err)&&(integrated_ov===1'b0)&&(stored_loaded===1'b1))
                    1'b1:;
                    default:$fatal(1,"persist k=%0d ERR=%0d",k,integrated_err);
                endcase
                integrated_checks=integrated_checks+1;
            end
        end
    endtask
    initial begin
        clk=0;key0_n=1;key1_n=0;sw=0;sel=0;
        loaded=0;a=0;delta=0;checks=0;integrated_checks=0;
        for(l=0;l<2;l=l+1) begin
            for(av=-128;av<128;av=av+1) begin
                for(index=0;index<7;index=index+1) begin
                    case(index)
                        0:dv=-131072;1:dv=-65536;2:dv=-1;3:dv=0;
                        4:dv=1;5:dv=81408;6:dv=131071;
                    endcase
                    loaded=l[0];a=av[7:0];delta=dv[17:0];
                    expected=(l!=0)&&((av==0)||(dv<0));#1;
                    case((ERR===expected[0])&&(OV===1'b0))
                        1'b1:;
                        default:$fatal(1,"isolated loaded=%0d a=%0d delta=%0d",l,av,dv);
                    endcase
                    checks=checks+1;
                end
            end
        end
        reset_capture;
        capture_value(8'd0);
        capture_value(8'd1);
        case({stored_loaded,integrated_err})
            2'b00:;default:$fatal(1,"partial a0 raised ERR");
        endcase
        integrated_checks=integrated_checks+1;
        capture_value(8'd1);
        hold_and_check(1'b1);
        reset_capture;
        capture_value(8'd1);capture_value(8'd0);capture_value(8'd1);
        hold_and_check(1'b1);
        reset_capture;
        capture_value(8'd1);capture_value(8'd0);capture_value(8'd0);
        hold_and_check(1'b0);
        reset_capture;
        case((checks==3584)&&(integrated_checks==53))
            1'b1:;default:$fatal(1,"incomplete checks=%0d integrated=%0d",checks,integrated_checks);
        endcase
        $display("TEST-009 TASK010 PASS isolated=%0d integrated=%0d failures=0",checks,integrated_checks);
        $finish;
    end
endmodule

// Independent top preserves the TASK010 regression unchanged.
module tb_flag_z;
    reg signed [22:0] value;
    reg [1:0] sel;
    reg ERR;
    wire Z;
    integer selection,error_value,index,number,expected,checked;
    flag_z dut(.value(value),.sel(sel),.ERR(ERR),.Z(Z));
    initial begin
        checked=0;
        for(selection=0;selection<4;selection=selection+1) begin
            for(error_value=0;error_value<2;error_value=error_value+1) begin
                for(index=0;index<30;index=index+1) begin
                    case(index)
                        0:number=0;
                        1:number=1;
                        2:number=-1;
                        3:number=-4194304;
                        4:number=4194303;
                        5:number=1000000;
                        6:number=-100000;
                        default:number=1 << (index-7);
                    endcase
                    value=number[22:0];sel=selection[1:0];ERR=error_value[0];
                    expected=(number==0)&&!((selection>=2)&&(error_value!=0));
                    #1;
                    case(Z===expected[0])
                        1'b1:;
                        default:$fatal(1,"TASK018 mismatch sel=%0d ERR=%0d value=%0d Z=%0d",selection,error_value,value,Z);
                    endcase
                    checked=checked+1;
                end
            end
        end
        case(checked)
            240:;
            default:$fatal(1,"TASK018 incomplete coverage=%0d",checked);
        endcase
        $display("TEST-009 TASK018 PASS checks=%0d failures=0",checked);
        $finish;
    end
endmodule

module tb_flag_c;
    reg carry_y,loaded;
    reg [1:0] sel;
    wire C;
    reg signed [7:0] a,b,c,x;
    wire signed [22:0] y;
    wire OV,core_carry,integrated_C;
    integer cy,ld,selection,scenario,checks,integrated_checks,expected;
    integer va,vb,vc,vx,partial,expected_y,unsigned_partial,unsigned_c,expected_carry;
    flag_c dut(.carry_y(carry_y),.loaded(loaded),.sel(sel),.C(C));
    polynomial_y_core core(.a(a),.b(b),.c(c),.x(x),.y(y),.OV(OV),.carry_y(core_carry));
    flag_c integrated(.carry_y(core_carry),.loaded(loaded),.sel(sel),.C(integrated_C));
    initial begin
        a=0;b=0;c=0;x=0;checks=0;integrated_checks=0;
        for(cy=0;cy<2;cy=cy+1) begin
            for(ld=0;ld<2;ld=ld+1) begin
                for(selection=0;selection<4;selection=selection+1) begin
                    carry_y=cy[0];loaded=ld[0];sel=selection[1:0];
                    expected=(cy!=0)&&(ld!=0)&&(selection==1);#1;
                    case(C===expected[0])
                        1'b1:;default:$fatal(1,"TASK019 isolated cy=%0d ld=%0d sel=%0d",cy,ld,selection);
                    endcase
                    checks=checks+1;
                end
            end
        end
        for(scenario=0;scenario<8;scenario=scenario+1) begin
            case(scenario)
                0:begin va=0;vb=-1;vc=1;vx=1;end
                1:begin va=1;vb=-1;vc=0;vx=1;end
                2:begin va=0;vb=1;vc=1;vx=1;end
                3:begin va=0;vb=-1;vc=-1;vx=1;end
                4:begin va=0;vb=0;vc=-128;vx=0;end
                5:begin va=-128;vb=127;vc=-128;vx=-128;end
                6:begin va=127;vb=-128;vc=127;vx=-128;end
                7:begin va=-128;vb=-128;vc=127;vx=127;end
            endcase
            a=va[7:0];b=vb[7:0];c=vc[7:0];x=vx[7:0];
            partial=va*vx*vx+vb*vx;
            expected_y=partial+vc;
            unsigned_partial=partial & 8388607;
            unsigned_c=vc & 8388607;
            expected_carry=(unsigned_partial+unsigned_c)>>23;
            for(ld=0;ld<2;ld=ld+1) begin
                for(selection=0;selection<4;selection=selection+1) begin
                    loaded=ld[0];sel=selection[1:0];
                    expected=(expected_carry!=0)&&(ld!=0)&&(selection==1);#1;
                    case((integrated_C===expected[0])&&(core_carry===expected_carry[0])&&
                         ($signed(y)===expected_y)&&(OV===1'b0))
                        1'b1:;default:$fatal(1,"TASK019 integrated scenario=%0d ld=%0d sel=%0d carry=%0d expectedcarry=%0d",scenario,ld,selection,core_carry,expected_carry);
                    endcase
                    integrated_checks=integrated_checks+1;
                end
            end
        end
        case((checks==16)&&(integrated_checks==64))
            1'b1:;default:$fatal(1,"TASK019 incomplete coverage");
        endcase
        $display("TEST-009 TASK019 PASS isolated=%0d integrated=%0d failures=0",checks,integrated_checks);
        $finish;
    end
endmodule
