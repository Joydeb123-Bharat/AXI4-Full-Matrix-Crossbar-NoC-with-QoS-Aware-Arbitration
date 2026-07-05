`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.07.2026 15:57:40
// Design Name: 
// Module Name: slave_aw_egress_dwrr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module slave_aw_egress_dwrr #(
    parameter int ADDR_WIDTH  = 32,
    parameter int ID_WIDTH    = 8,
    parameter int QUANTUM     = 16
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [3:0]            s_awvalid_bus,
    output logic [3:0]            s_awready_bus,

    input  logic [ID_WIDTH-1:0]   s_awid_m0, input logic [ADDR_WIDTH-1:0] s_awaddr_m0, input logic [7:0] s_awlen_m0,
    input  logic [ID_WIDTH-1:0]   s_awid_m1, input logic [ADDR_WIDTH-1:0] s_awaddr_m1, input logic [7:0] s_awlen_m1,
    input  logic [ID_WIDTH-1:0]   s_awid_m2, input logic [ADDR_WIDTH-1:0] s_awaddr_m2, input logic [7:0] s_awlen_m2,
    input  logic [ID_WIDTH-1:0]   s_awid_m3, input logic [ADDR_WIDTH-1:0] s_awaddr_m3, input logic [7:0] s_awlen_m3,

    output logic [ID_WIDTH+2-1:0] m_awid,
    output logic [ADDR_WIDTH-1:0] m_awaddr,
    output logic [7:0]            m_awlen,
    output logic                  m_awvalid,
    input  logic                  m_awready,

    output logic                  fifo_push_en,
    output logic [1:0]            fifo_master_id,
    input  logic                  fifo_full
);

    logic signed [11:0] deficit_count_r [4];
    logic [1:0]         current_master_r;
    logic [8:0]         transaction_cost;

    // Grant-hold registers. m_awvalid is only ever 1 when grant_pending_r is 1.
    // Driving m_awvalid combinationally from grant_eligible causes a timing race:
    // on the same cycle grant_eligible first goes true, the slave may already have
    // AWREADY high, making the handshake complete before grant_pending_r is even set.
    // The latch then never clears because it sees m_awready on a cycle after the
    // slave has already deasserted AWREADY. One extra cycle of latency here
    // eliminates the race entirely.
    logic                  grant_pending_r;
    logic [1:0]            grant_master_r;
    logic [ID_WIDTH+2-1:0] grant_awid_r;
    logic [ADDR_WIDTH-1:0] grant_awaddr_r;
    logic [7:0]            grant_awlen_r;

    // grant_eligible: master is requesting, has sufficient credit, and FIFO has room.
    // Shared between both always_ff blocks so they always agree on whether a grant is
    // being issued this cycle - prevents two parallel always_ff blocks from firing
    // conflicting decisions on the same posedge.
    logic grant_eligible;
    assign grant_eligible = s_awvalid_bus[current_master_r] &&
                            !fifo_full &&
                            !(deficit_count_r[current_master_r] < $signed({3'b000, transaction_cost}));

    // Grant latch: sets on eligible cycle, clears when slave asserts AWREADY
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_pending_r <= 1'b0;
            grant_master_r  <= '0;
            grant_awid_r    <= '0;
            grant_awaddr_r  <= '0;
            grant_awlen_r   <= '0;
        end else begin
            if (grant_pending_r && m_awready) begin
                grant_pending_r <= 1'b0;
            end else if (!grant_pending_r && grant_eligible) begin
                grant_pending_r <= 1'b1;
                grant_master_r  <= current_master_r;
                grant_awaddr_r  <= (current_master_r == 2'b00) ? s_awaddr_m0 :
                                   (current_master_r == 2'b01) ? s_awaddr_m1 :
                                   (current_master_r == 2'b10) ? s_awaddr_m2 : s_awaddr_m3;
                grant_awlen_r   <= (current_master_r == 2'b00) ? s_awlen_m0 :
                                   (current_master_r == 2'b01) ? s_awlen_m1 :
                                   (current_master_r == 2'b10) ? s_awlen_m2 : s_awlen_m3;
                grant_awid_r    <= (current_master_r == 2'b00) ? {current_master_r, s_awid_m0} :
                                   (current_master_r == 2'b01) ? {current_master_r, s_awid_m1} :
                                   (current_master_r == 2'b10) ? {current_master_r, s_awid_m2} :
                                                                   {current_master_r, s_awid_m3};
            end
        end
    end

    // DWRR scheduler
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 4; i++) deficit_count_r[i] <= 12'd0;
            current_master_r <= '0;
        end else begin
            if (!grant_pending_r) begin
                if (grant_eligible) begin
                    // Latch is being set this cycle - freeze arbiter
                end
                else if (!s_awvalid_bus[current_master_r]) begin
                    // Condition A: silent master, rotate
                    current_master_r <= current_master_r + 1;
                end
                else if (deficit_count_r[current_master_r] < $signed({3'b000, transaction_cost})) begin
                    // Condition B: insufficient credit, replenish and rotate
                    deficit_count_r[current_master_r] <= deficit_count_r[current_master_r] + QUANTUM;
                    current_master_r <= current_master_r + 1;
                end
                else if (fifo_full) begin
                    // Condition C: FIFO backed up, rotate without penalty
                    current_master_r <= current_master_r + 1;
                end
            end else if (grant_pending_r && m_awready) begin
                // Handshake completed: deduct credit, rotate to next master
                deficit_count_r[grant_master_r] <= deficit_count_r[grant_master_r] - transaction_cost;
                current_master_r <= current_master_r + 1;
            end
        end
    end

    // Output mux: m_awvalid is ONLY 1 when grant_pending_r=1 (never combinational).
    // When not pending, drive the payload signals anyway so transaction_cost stays
    // accurate for Condition B in the scheduler above.
    always_comb begin
        m_awid        = '0;
        m_awaddr      = '0;
        m_awlen       = '0;
        s_awready_bus = '0;
        m_awvalid     = 1'b0;

        if (grant_pending_r) begin
            // Frozen: stable registered values until slave asserts AWREADY
            m_awvalid                     = 1'b1;
            m_awid                        = grant_awid_r;
            m_awaddr                      = grant_awaddr_r;
            m_awlen                       = grant_awlen_r;
            s_awready_bus[grant_master_r] = m_awready;
        end else begin
            // Arbitrating: drive payload for cost calculation, VALID stays low
            case(current_master_r)
                2'b00: begin m_awid = {current_master_r, s_awid_m0}; m_awaddr = s_awaddr_m0; m_awlen = s_awlen_m0; end
                2'b01: begin m_awid = {current_master_r, s_awid_m1}; m_awaddr = s_awaddr_m1; m_awlen = s_awlen_m1; end
                2'b10: begin m_awid = {current_master_r, s_awid_m2}; m_awaddr = s_awaddr_m2; m_awlen = s_awlen_m2; end
                2'b11: begin m_awid = {current_master_r, s_awid_m3}; m_awaddr = s_awaddr_m3; m_awlen = s_awlen_m3; end
            endcase
        end

        transaction_cost = m_awlen + 1;
    end

    assign fifo_push_en   = m_awvalid && m_awready;
    assign fifo_master_id = grant_pending_r ? grant_master_r : current_master_r;
endmodule