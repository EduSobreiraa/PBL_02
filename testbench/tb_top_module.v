`timescale 1ns/1ps
module tb_top_module;
    reg clk;
    reg [1:0] KEY;
    reg [9:0] SW;
    wire [9:0] LEDR;
    wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
    integer ma,mb,mc,progress,checks,scenarios;
    top_module dut(.MAX10_CLK1_50(clk),.KEY(KEY),.SW(SW),.LEDR(LEDR),
        .HEX0(HEX0),.HEX1(HEX1),.HEX2(HEX2),.HEX3(HEX3),.HEX4(HEX4),.HEX5(HEX5));
    initial begin clk=0; forever #10 clk=~clk; end
    function integer reference_round;
        input integer va,vb,disc,branch;
        integer low,high,k,h,threshold,square,cmp,relation,asign,done;
        begin
            low=-129; high=129; done=0;
            case (va>0) 1: asign=1; default: asign=-1; endcase
            while ((low<high) && (done==0)) begin
                k=low+(high-low)/2;
                h=vb+va*(2*k+1);
                threshold=branch*h;
                case (threshold<0)
                    1: cmp=1;
                    default: begin
                        square=threshold*threshold;
                        cmp=(disc>square)-(disc<square);
                    end
                endcase
                relation=asign*branch*cmp;
                case (relation)
                    0: begin
                        case (k>=0) 1: reference_round=k+1; default: reference_round=k; endcase
                        done=1;
                    end
                    -1: high=k;
                    1: low=k+1;
                    default: $fatal(1,"Invalid oracle relation");
                endcase
            end
            case (done) 0: reference_round=low; default: ; endcase
        end
    endfunction
    function [6:0] encode;
        input integer decimal_digit;
        begin
            case (decimal_digit)
                0: encode=7'b1000000;
                1: encode=7'b1111001;
                2: encode=7'b0100100;
                3: encode=7'b0110000;
                4: encode=7'b0011001;
                5: encode=7'b0010010;
                6: encode=7'b0000010;
                7: encode=7'b1111000;
                8: encode=7'b0000000;
                9: encode=7'b0010000;
                default: encode=7'b1111111;
            endcase
        end
    endfunction

    task wait_clocks;
        input integer cycles;
        integer k;
        begin
            for(k=0;k<cycles;k=k+1) @(posedge clk);
            #1;
        end
    endtask
    task observe;
        input integer xv;
        integer selection,disc,root1,root2,yvalue,subtotal,selected,carry_unsigned;
        integer magnitude,remaining,pos,digit_value;
        reg err,zero_flag,carry_flag,masked,bad;
        reg [9:0] expected_leds;
        reg [41:0] expected_hex;
        begin
            disc=mb*mb-4*ma*mc;
            case ((ma==0)||(disc<0))
                1: begin root1=0; root2=0; end
                default: begin
                    root1=reference_round(ma,mb,disc,1);
                    root2=reference_round(ma,mb,disc,-1);
                end
            endcase
            subtotal=ma*xv*xv+mb*xv;
            yvalue=subtotal+mc;
            carry_unsigned=((subtotal & 8388607)+(mc & 8388607))>>23;
            err=(progress==3)&&((ma==0)||(disc<0));
            for(selection=0;selection<4;selection=selection+1) begin
                @(negedge clk); SW={selection[1:0],xv[7:0]};
                #2;
                case(selection)
                    0: selected=xv;
                    1: selected=yvalue;
                    2: selected=root1;
                    3: selected=root2;
                endcase
                zero_flag=(selected==0)&&!((selection>=2)&&err);
                carry_flag=(selection==1)&&(progress==3)&&(carry_unsigned==1);
                expected_leds={6'b0,err,carry_flag,zero_flag,1'b0};
                masked=((selection!=0)&&(progress!=3))||((selection>=2)&&err);
                bad=masked||(selected>999999)||(selected< -99999);
                expected_hex={6{7'b1111111}};
                case(bad)
                    1: expected_hex={6{7'b0111111}};
                    default: begin
                        case(selected<0) 1:magnitude=-selected; default:magnitude=selected; endcase
                        remaining=magnitude;
                        for(pos=0;pos<6;pos=pos+1) begin
                            digit_value=remaining%10;
                            case((pos==0)||(remaining!=0))
                                1:expected_hex[pos*7+:7]=encode(digit_value);
                                default:;
                            endcase
                            remaining=remaining/10;
                        end
                        case(selected<0) 1:expected_hex[35+:7]=7'b0111111; default:; endcase
                    end
                endcase
                case((LEDR===expected_leds)&&({HEX5,HEX4,HEX3,HEX2,HEX1,HEX0}===expected_hex))
                    1:;
                    default:$fatal(1,"top check=%0d a=%0d b=%0d c=%0d progress=%0d x=%0d sel=%0d LEDs=%b expected=%b HEX=%h expected=%h",checks,ma,mb,mc,progress,xv,selection,LEDR,expected_leds,{HEX5,HEX4,HEX3,HEX2,HEX1,HEX0},expected_hex);
                endcase
                checks=checks+1;
            end
        end
    endtask
    task reset_system;
        begin
            @(negedge clk); KEY=2'b00;
            wait_clocks(8);
            ma=0;mb=0;mc=0;progress=0;
            observe(0);
            @(negedge clk); KEY=2'b11;
            wait_clocks(8);
            observe(-128);
        end
    endtask
    task capture;
        input integer coefficient;
        begin
            @(negedge clk); SW={2'b00,coefficient[7:0]}; KEY[0]=0;
            wait_clocks(8);
            case(progress)
                0:begin ma=coefficient; progress=1;end
                1:begin mb=coefficient; progress=2;end
                2:begin mc=coefficient; progress=3;end
                default:;
            endcase
            // Switch changes and all selections while KEY0 remains pressed.
            observe(99);
            wait_clocks(5);
            @(negedge clk); KEY[0]=1;
            wait_clocks(6);
            observe(0);
        end
    endtask
    task scenario;
        input integer va,vb,vc;
        begin
            reset_system;
            capture(va);capture(vb);capture(vc);
            observe(-128);observe(-1);observe(1);observe(127);
            capture(42); // fourth capture must be ignored
            observe(-3);
            scenarios=scenarios+1;
        end
    endtask
    initial begin
        KEY=2'b00;SW=0;ma=0;mb=0;mc=0;progress=0;checks=0;scenarios=0;
        scenario(1,-3,2);  // positive integer roots
        scenario(1,3,2);   // negative integer roots
        scenario(2,-3,1);  // positive half tie
        scenario(2,3,1);   // negative half tie
        scenario(-1,0,1);  // reversed branch order, final carry -1+1
        scenario(1,0,1);   // negative discriminant
        scenario(0,1,0);   // a zero
        scenario(1,2,1);   // zero discriminant
        scenario(-128,127,-128); // minimum y and visual overflow
        scenario(127,-128,127);  // maximum y and visual overflow
        reset_system;capture(17); // reset during partial load
        reset_system;capture(18);capture(52);capture(86);
        observe(127);
        reset_system;
        case((scenarios==10)&&(checks==660))
            1:;
            default:$fatal(1,"Coverage mismatch scenarios=%0d checks=%0d",scenarios,checks);
        endcase
        $display("TEST-010/011 PASS scenarios=%0d output_checks=%0d reset_partial_full=PASS held_key=PASS extra_capture=PASS flags_displays=PASS",scenarios,checks);
        $finish;
    end
endmodule
