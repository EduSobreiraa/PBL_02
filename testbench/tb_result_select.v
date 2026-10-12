`timescale 1ns/1ps
module tb_result_select;
    reg signed [7:0] x;
    reg signed [22:0] y;
    reg signed [8:0] x1,x2;
    reg [1:0] sel;
    wire signed [22:0] value;
    integer i,j,seed,expected,count,random_value;
    result_select dut(.x(x),.y(y),.x1(x1),.x2(x2),.sel(sel),.value(value));
    task check_selections;
        begin
            for (j=0;j<4;j=j+1) begin
                sel=j[1:0];
                case (j)
                    0: expected=$signed(x);
                    1: expected=$signed(y);
                    2: expected=$signed(x1);
                    3: expected=$signed(x2);
                endcase
                #1;
                case ($signed(value)===expected)
                    1: ;
                    default: $fatal(1,"select sel=%d got=%d expected=%d",j,value,expected);
                endcase
                count=count+1;
            end
        end
    endtask
    initial begin
        count=0; seed=20261011;
        for (i=0;i<512;i=i+1) begin
            x=i[7:0]; x1=i[8:0]; x2=~i[8:0];
            case (i[0]) 0: y=-4194304; 1: y=4194303; endcase
            check_selections;
        end
        for (i=0;i<1000;i=i+1) begin
            random_value=$random(seed); x=random_value[7:0];
            random_value=$random(seed); y=random_value[22:0];
            random_value=$random(seed); x1=random_value[8:0];
            random_value=$random(seed); x2=random_value[8:0];
            check_selections;
        end
        case (count) 6048: ; default: $fatal(1,"Incomplete select test"); endcase
        $display("TEST-008 SELECT PASS cases=%0d seed=20261011",count);
        $finish;
    end
endmodule
