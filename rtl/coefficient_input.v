`timescale 1ns/1ps

module coefficient_input (
    input wire clk,
    input wire key0_n,
    input wire key1_n,
    input wire [7:0] sw,
    output wire signed [7:0] a,
    output wire signed [7:0] b,
    output wire signed [7:0] c
);
    wire key1_meta;
    wire key1_sync;
    wire key0_meta;
    wire key0_sync;
    wire key0_previous;
    wire reset_request;
    wire key0_press_event;
    wire key0_released_sync;
    wire progress_done;
    wire not_complete;
    wire capture_event;
    wire progress_0_next;
    wire progress_1_next;
    wire progress_0;
    wire progress_1;
    wire not_progress_0;
    wire not_progress_1;
    wire select_a;
    wire select_b;
    wire select_c;
    wire enable_a;
    wire enable_b;
    wire enable_c;
    wire [7:0] a_value;
    wire [7:0] b_value;
    wire [7:0] c_value;

    pbl_dff_plain key1_sync_stage_1 (
        .clk(clk), .d(key1_n), .q(key1_meta)
    );

    pbl_dff_plain key1_sync_stage_2 (
        .clk(clk), .d(key1_meta), .q(key1_sync)
    );

    pbl_dff_sync_reset key0_sync_stage_1 (
        .clk(clk), .reset(reset_request), .reset_value(1'b1), .enable(1'b1),
        .d(key0_n), .q(key0_meta)
    );

    pbl_dff_sync_reset key0_sync_stage_2 (
        .clk(clk), .reset(reset_request), .reset_value(1'b1), .enable(1'b1),
        .d(key0_meta), .q(key0_sync)
    );

    pbl_dff_sync_reset key0_history (
        .clk(clk), .reset(reset_request), .reset_value(1'b1), .enable(1'b1),
        .d(key0_sync), .q(key0_previous)
    );

    not reset_from_key1 (reset_request, key1_sync);
    not invert_key0_sync (key0_released_sync, key0_sync);
    and detected_key0_press (key0_press_event, key0_previous, key0_released_sync);
    not invert_progress_done (not_complete, progress_done);
    and decode_progress_done (progress_done, progress_0, progress_1);
    and allowed_capture (capture_event, key0_press_event, not_complete, key1_sync);

    not invert_progress_0 (not_progress_0, progress_0);
    not invert_progress_1 (not_progress_1, progress_1);
    and decode_a (select_a, not_progress_1, not_progress_0);
    and decode_b (select_b, not_progress_1, progress_0);
    and decode_c (select_c, progress_1, not_progress_0);

    and write_a (enable_a, capture_event, select_a);
    and write_b (enable_b, capture_event, select_b);
    and write_c (enable_c, capture_event, select_c);

    not progress_bit_0_toggle (progress_0_next, progress_0);
    xor progress_bit_1_toggle (progress_1_next, progress_1, progress_0);

    pbl_dff_sync_reset progress_counter_bit_0 (
        .clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(capture_event),
        .d(progress_0_next), .q(progress_0)
    );

    pbl_dff_sync_reset progress_counter_bit_1 (
        .clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(capture_event),
        .d(progress_1_next), .q(progress_1)
    );

    pbl_dff_sync_reset coefficient_a_bit_0 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_a), .d(sw[0]), .q(a_value[0]));
    pbl_dff_sync_reset coefficient_a_bit_1 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_a), .d(sw[1]), .q(a_value[1]));
    pbl_dff_sync_reset coefficient_a_bit_2 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_a), .d(sw[2]), .q(a_value[2]));
    pbl_dff_sync_reset coefficient_a_bit_3 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_a), .d(sw[3]), .q(a_value[3]));
    pbl_dff_sync_reset coefficient_a_bit_4 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_a), .d(sw[4]), .q(a_value[4]));
    pbl_dff_sync_reset coefficient_a_bit_5 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_a), .d(sw[5]), .q(a_value[5]));
    pbl_dff_sync_reset coefficient_a_bit_6 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_a), .d(sw[6]), .q(a_value[6]));
    pbl_dff_sync_reset coefficient_a_bit_7 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_a), .d(sw[7]), .q(a_value[7]));

    pbl_dff_sync_reset coefficient_b_bit_0 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_b), .d(sw[0]), .q(b_value[0]));
    pbl_dff_sync_reset coefficient_b_bit_1 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_b), .d(sw[1]), .q(b_value[1]));
    pbl_dff_sync_reset coefficient_b_bit_2 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_b), .d(sw[2]), .q(b_value[2]));
    pbl_dff_sync_reset coefficient_b_bit_3 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_b), .d(sw[3]), .q(b_value[3]));
    pbl_dff_sync_reset coefficient_b_bit_4 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_b), .d(sw[4]), .q(b_value[4]));
    pbl_dff_sync_reset coefficient_b_bit_5 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_b), .d(sw[5]), .q(b_value[5]));
    pbl_dff_sync_reset coefficient_b_bit_6 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_b), .d(sw[6]), .q(b_value[6]));
    pbl_dff_sync_reset coefficient_b_bit_7 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_b), .d(sw[7]), .q(b_value[7]));

    pbl_dff_sync_reset coefficient_c_bit_0 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_c), .d(sw[0]), .q(c_value[0]));
    pbl_dff_sync_reset coefficient_c_bit_1 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_c), .d(sw[1]), .q(c_value[1]));
    pbl_dff_sync_reset coefficient_c_bit_2 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_c), .d(sw[2]), .q(c_value[2]));
    pbl_dff_sync_reset coefficient_c_bit_3 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_c), .d(sw[3]), .q(c_value[3]));
    pbl_dff_sync_reset coefficient_c_bit_4 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_c), .d(sw[4]), .q(c_value[4]));
    pbl_dff_sync_reset coefficient_c_bit_5 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_c), .d(sw[5]), .q(c_value[5]));
    pbl_dff_sync_reset coefficient_c_bit_6 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_c), .d(sw[6]), .q(c_value[6]));
    pbl_dff_sync_reset coefficient_c_bit_7 (.clk(clk), .reset(reset_request), .reset_value(1'b0), .enable(enable_c), .d(sw[7]), .q(c_value[7]));

    assign a = a_value;
    assign b = b_value;
    assign c = c_value;
endmodule

module pbl_dff_plain (
    input wire clk,
    input wire d,
    output reg q
);
    always @(posedge clk) begin
        q <= d;
    end
endmodule

module pbl_dff_sync_reset (
    input wire clk,
    input wire reset,
    input wire reset_value,
    input wire enable,
    input wire d,
    output reg q
);
    wire not_enable;
    wire enabled_data;
    wire held_data;
    wire normal_data;
    wire not_reset;
    wire reset_data;
    wire normal_selected_data;
    wire d_next;

    not invert_enable (not_enable, enable);
    and select_enabled_data (enabled_data, enable, d);
    and select_held_data (held_data, not_enable, q);
    or combine_enable_mux (normal_data, enabled_data, held_data);

    not invert_reset (not_reset, reset);
    and select_reset_value (reset_data, reset, reset_value);
    and select_normal_value (normal_selected_data, not_reset, normal_data);
    or combine_reset_mux (d_next, reset_data, normal_selected_data);

    always @(posedge clk) begin
        q <= d_next;
    end
endmodule
