`timescale 1ns/1ps
module tb_quadratic_roots;
    reg signed [7:0] a,b,c;
    wire signed [17:0] delta;
    wire signed [8:0] x1,x2;
    wire domain_error;
    integer count,valid_count,invalid_count,seed,n,random_value;
    quadratic_roots dut(.a(a),.b(b),.c(c),.delta(delta),.x1(x1),.x2(x2),.domain_error(domain_error));
    // Independent oracle: exact integer comparisons with half-integer boundaries.
    // Does not compute S, E, Q, remainder, or the DUT rounding expression.
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
    task check;
        input integer va,vb,vc;
        integer ed,ex1,ex2;
        reg invalid;
        begin
            ed=vb*vb-4*va*vc;
            invalid=(va==0)||(ed<0);
            case (invalid)
                1: begin ex1=0; ex2=0; invalid_count=invalid_count+1; end
                0: begin
                    ex1=reference_round(va,vb,ed,1);
                    ex2=reference_round(va,vb,ed,-1);
                    valid_count=valid_count+1;
                end
            endcase
            a=va[7:0]; b=vb[7:0]; c=vc[7:0];
            #1;
            case (($signed(delta)===ed) && ($signed(x1)===ex1) && ($signed(x2)===ex2) && (domain_error===invalid))
                1: ;
                default: $fatal(1,"roots a=%0d b=%0d c=%0d delta=%0d x1=%0d x2=%0d err=%b expected=%0d,%0d,%0d,%b",va,vb,vc,delta,x1,x2,domain_error,ed,ex1,ex2,invalid);
            endcase
            count=count+1;
        end
    endtask
    integer ra,rb,rc;
    initial begin
        count=0; valid_count=0; invalid_count=0; seed=20261011;
        // TASK-005: a_zero
        check(0,-128,127);
        // TASK-005: negative_discriminant
        check(1,0,1);
        // TASK-005: zero_discriminant
        check(1,2,1);
        // TASK-005: positive_half_tie
        check(2,-3,1);
        // TASK-005: negative_half_tie
        check(2,3,1);
        // TASK-005: negative_a_branch_order
        check(-1,0,1);
        // TASK-005: zero_root_and_positive_128
        check(1,-128,0);
        // TASK-005: minimum_coefficients
        check(-128,-128,-128);
        // TASK-005: maximum_discriminant
        check(-128,-128,127);
        // TASK-005: minimum_discriminant
        check(-128,0,-128);
        // TASK-005: maximum_coefficients
        check(127,127,127);
        // TASK-005: sqrt_perfect
        check(1,0,-4);
        // TASK-005: sqrt_nonperfect
        check(1,0,-2);
        // TASK-005: mixed_sign_roots
        check(1,1,-1);
        // TASK-005: branch_plus_r0_perfect_positive_correction_odd_quotient
        check(-128,-128,-32);
        // TASK-005: branch_minus_r0_perfect_nonpositive_correction_odd_quotient
        check(-128,-128,-32);
        // TASK-005: branch_plus_r0_perfect_positive_correction_even_quotient
        check(-128,-128,0);
        // TASK-005: branch_minus_r0_perfect_nonpositive_correction_even_quotient
        check(-128,-128,0);
        // TASK-005: branch_minus_r0_perfect_positive_correction_odd_quotient
        check(-128,-128,96);
        // TASK-005: branch_plus_r0_irrational_positive_correction_odd_quotient
        check(-128,-128,97);
        // TASK-005: branch_minus_r0_irrational_positive_correction_odd_quotient
        check(-128,-128,97);
        // TASK-005: branch_plus_r0_perfect_nonpositive_correction_even_quotient
        check(-128,0,0);
        // TASK-005: branch_minus_r0_perfect_positive_correction_even_quotient
        check(-128,1,127);
        // TASK-005: branch_plus_r0_irrational_positive_correction_even_quotient
        check(-126,0,127);
        // TASK-005: branch_minus_r0_irrational_positive_correction_even_quotient
        check(-126,0,127);
        // TASK-005: branch_plus_r0_perfect_nonpositive_correction_odd_quotient
        check(-126,127,-32);
        // TASK-005: branch_minus_r0_irrational_nonpositive_correction_odd_quotient
        check(-83,-128,-43);
        // TASK-005: branch_plus_r0_irrational_nonpositive_correction_odd_quotient
        check(-83,126,-42);
        // TASK-005: branch_minus_r0_irrational_nonpositive_correction_even_quotient
        check(-64,-128,1);
        // TASK-005: branch_plus_r0_irrational_nonpositive_correction_even_quotient
        check(-63,126,1);
        for (n=0;n<10000;n=n+1) begin
            random_value=$random(seed); ra=$signed(random_value[7:0]);
            random_value=$random(seed); rb=$signed(random_value[7:0]);
            random_value=$random(seed); rc=$signed(random_value[7:0]);
            check(ra,rb,rc);
        end
        case ((count==10030) && (valid_count+invalid_count==10030))
            1: ;
            default: $fatal(1,"Incomplete roots test");
        endcase
        $display("TEST-007 PASS directed=30 random=10000 seed=20261011 total=%0d valid=%0d invalid=%0d delta_roots_error=PASS",count,valid_count,invalid_count);
        $finish;
    end
endmodule
