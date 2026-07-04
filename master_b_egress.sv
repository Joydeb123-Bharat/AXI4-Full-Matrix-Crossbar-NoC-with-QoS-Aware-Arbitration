`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.07.2026 16:16:18
// Design Name: 
// Module Name: master_b_egress
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

module master_b_egress #(
    parameter int ID_WIDTH   = 8,
    parameter logic [1:0] MASTER_INDEX = 2'b00
)(
    input logic clk,
    input logic rst_n,

    // Flat B channel response buses coming backward out of all 4 Slaves
    input  logic [ID_WIDTH+2-1:0] s_bid_s0, input logic [1:0] s_bresp_s0, input logic s_bvalid_s0,
    input  logic [ID_WIDTH+2-1:0] s_bid_s1, input logic [1:0] s_bresp_s1, input logic s_bvalid_s1,
    input  logic [ID_WIDTH+2-1:0] s_bid_s2, input logic [1:0] s_bresp_s2, input logic s_bvalid_s2,
    input  logic [ID_WIDTH+2-1:0] s_bid_s3, input logic [1:0] s_bresp_s3, input logic s_bvalid_s3,
    // Flat B channel response coming backward out of the Default (decode-error) Slave
    input  logic [ID_WIDTH+2-1:0] s_bid_s4, input logic [1:0] s_bresp_s4, input logic s_bvalid_s4,
    
    // Backpressure ready feedback signals returned to the 4 Slaves + Default Slave
    output logic [4:0]            s_bready_bus,

    // Outbound clean B Port heading toward the external Master
    output logic [ID_WIDTH-1:0]   m_bid, 
    output logic [1:0]            m_bresp,
    output logic                  m_bvalid,
    input  logic                  m_bready
);

    // Round-Robin Combinational Slave Response Multiplexer
    // Fixed S0>S1>S2>S3 priority was replaced: it could starve a low-index
    // slave's B response indefinitely under sustained traffic from a higher one.
    logic [4:0] req;
    assign req[0] = s_bvalid_s0 && (s_bid_s0[ID_WIDTH+1:ID_WIDTH] == MASTER_INDEX);
    assign req[1] = s_bvalid_s1 && (s_bid_s1[ID_WIDTH+1:ID_WIDTH] == MASTER_INDEX);
    assign req[2] = s_bvalid_s2 && (s_bid_s2[ID_WIDTH+1:ID_WIDTH] == MASTER_INDEX);
    assign req[3] = s_bvalid_s3 && (s_bid_s3[ID_WIDTH+1:ID_WIDTH] == MASTER_INDEX);
    assign req[4] = s_bvalid_s4 && (s_bid_s4[ID_WIDTH+1:ID_WIDTH] == MASTER_INDEX);

    // Rotating priority pointer - advances past whichever source was last granted
    logic [2:0] rr_ptr;
    logic [2:0] grant_idx;
    logic       grant_valid;

    // Priority scan starting at rr_ptr so no single slave can starve the others
    always_comb
    begin
        grant_idx   = 3'd0;
        grant_valid = 1'b0;
        for(int i=0;i<5;i++)
        begin
            automatic int idx = (rr_ptr + i) % 5;
            if(!grant_valid && req[idx])
            begin
                grant_idx   = idx[2:0];
                grant_valid = 1'b1;
            end
        end
    end

    always_comb
    begin
        m_bid = '0;
        m_bresp = '0;
        m_bvalid = '0;
        s_bready_bus = '0;
        if(grant_valid)
        begin
            case(grant_idx)
                3'd0: begin m_bid = s_bid_s0[ID_WIDTH-1:0]; m_bresp = s_bresp_s0; m_bvalid = s_bvalid_s0; s_bready_bus[0] = m_bready; end
                3'd1: begin m_bid = s_bid_s1[ID_WIDTH-1:0]; m_bresp = s_bresp_s1; m_bvalid = s_bvalid_s1; s_bready_bus[1] = m_bready; end
                3'd2: begin m_bid = s_bid_s2[ID_WIDTH-1:0]; m_bresp = s_bresp_s2; m_bvalid = s_bvalid_s2; s_bready_bus[2] = m_bready; end
                3'd3: begin m_bid = s_bid_s3[ID_WIDTH-1:0]; m_bresp = s_bresp_s3; m_bvalid = s_bvalid_s3; s_bready_bus[3] = m_bready; end
                3'd4: begin m_bid = s_bid_s4[ID_WIDTH-1:0]; m_bresp = s_bresp_s4; m_bvalid = s_bvalid_s4; s_bready_bus[4] = m_bready; end
                default: ;
            endcase
        end
    end

    // Advance the rotating pointer past whichever source was just served
    always_ff @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            rr_ptr <= '0;
        else if(grant_valid && m_bvalid && m_bready)
            rr_ptr <= (grant_idx + 3'd1) % 3'd5;
    end

endmodule