`timescale 1ns/1ps
module tb_add_sub;
    reg fa_a, fa_b, fa_cin;
    wire fa_sum, fa_cout;
    reg signed [22:0] lhs23, rhs23;
    wire signed [22:0] public_sum, core_sum;
    wire carry_out;
    reg signed [17:0] lhs18, rhs18;
    wire signed [17:0] difference;
    integer fd, scanned, kind, lhs, rhs, expected, expected_carry;
    integer n, row_count, add_count, sub_count, modular_count;
    full_adder fa (.a(fa_a), .b(fa_b), .cin(fa_cin), .sum(fa_sum), .cout(fa_cout));
    add23 public_adder (.lhs(lhs23), .rhs(rhs23), .sum(public_sum));
    add23_core core (.lhs(lhs23), .rhs(rhs23), .sum(core_sum), .carry_out(carry_out));
    sub18 subtractor (.lhs(lhs18), .rhs(rhs18), .difference(difference));
    initial begin
        for (n=0; n<8; n=n+1) begin
            {fa_a,fa_b,fa_cin}=n[2:0];
            expected=(n & 1)+((n >> 1) & 1)+((n >> 2) & 1);
            #1;
            case ({fa_cout,fa_sum} === expected[1:0])
                1'b1: ;
                default: $fatal(1,"FA mismatch n=%0d",n);
            endcase
        end
        fd=$fopen("verification/vectors/add_sub.txt","r");
        case (fd)
            0: $fatal(1,"Cannot open vectors");
            default: ;
        endcase
        row_count=0; add_count=0; sub_count=0; modular_count=0;
        while (!$feof(fd)) begin
            scanned=$fscanf(fd,"%d %d %d %d %d\n",kind,lhs,rhs,expected,expected_carry);
            case (scanned)
                5: begin
                    row_count=row_count+1;
                    case (kind)
                        0,2: begin
                            lhs23=lhs; rhs23=rhs;
                            #1;
                            case (($signed(core_sum) === expected) && (carry_out === expected_carry[0]))
                                1'b1: ;
                                default: $fatal(1,"add core row=%0d lhs=%0d rhs=%0d got=%0d carry=%0d expected=%0d carry=%0d",row_count,lhs,rhs,core_sum,carry_out,expected,expected_carry);
                            endcase
                            case (kind)
                                0: begin
                                    add_count=add_count+1;
                                    case ($signed(public_sum) === expected)
                                        1'b1: ;
                                        default: $fatal(1,"public sum row=%0d",row_count);
                                    endcase
                                end
                                2: modular_count=modular_count+1;
                            endcase
                        end
                        1: begin
                            lhs18=lhs; rhs18=rhs;
                            #1;
                            sub_count=sub_count+1;
                            case ($signed(difference) === expected)
                                1'b1: ;
                                default: $fatal(1,"sub row=%0d got=%0d expected=%0d",row_count,difference,expected);
                            endcase
                        end
                        default: $fatal(1,"Unknown vector type");
                    endcase
                end
                default: $fatal(1,"Malformed vector row=%0d scanned=%0d",row_count,scanned);
            endcase
        end
        $fclose(fd);
        case ((row_count==37212) && (add_count==24808) && (sub_count==12401) && (modular_count==3))
            1'b1: ;
            default: $fatal(1,"Incomplete vectors rows=%0d",row_count);
        endcase
        $display("TEST-002 PASS full_adder=8 exact_add=%0d delta=%0d core_modular=%0d rows=%0d",add_count,sub_count,modular_count,row_count);
        $finish;
    end
endmodule
