`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.07.2026 15:27:48
// Design Name: 
// Module Name: master_r_egress
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

module master_r_egress #(
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 8, // Raw Master ID width
    parameter logic [1:0] MASTER_INDEX = 2'b00 // Master ID
)(
    input logic clk,
    input logic rst_n,

    // Flat R channel buses coming backward out of all 4 Slaves
    input  logic [ID_WIDTH+2-1:0] s_rid_s0,   input logic [DATA_WIDTH-1:0] s_rdata_s0, input logic [1:0] s_rresp_s0, input logic s_rlast_s0, input logic s_rvalid_s0,
    input  logic [ID_WIDTH+2-1:0] s_rid_s1,   input logic [DATA_WIDTH-1:0] s_rdata_s1, input logic [1:0] s_rresp_s1, input logic s_rlast_s1, input logic s_rvalid_s1,
    input  logic [ID_WIDTH+2-1:0] s_rid_s2,   input logic [DATA_WIDTH-1:0] s_rdata_s2, input logic [1:0] s_rresp_s2, input logic s_rlast_s2, input logic s_rvalid_s2,
    input  logic [ID_WIDTH+2-1:0] s_rid_s3,   input logic [DATA_WIDTH-1:0] s_rdata_s3, input logic [1:0] s_rresp_s3, input logic s_rlast_s3, input logic s_rvalid_s3,
    // Flat R channel bus coming backward out of the Default (decode-error) Slave
    input  logic [ID_WIDTH+2-1:0] s_rid_s4,   input logic [DATA_WIDTH-1:0] s_rdata_s4, input logic [1:0] s_rresp_s4, input logic s_rlast_s4, input logic s_rvalid_s4,
    
    // Backpressure ready feedback signals returned to the 4 Slaves + Default Slave
    output logic [4:0]            s_rready_bus,

    // Outbound clean R Port heading toward the external Master's Skid Buffer
    output logic [ID_WIDTH-1:0]   m_rid, // Stripped back down to original master width
    output logic [DATA_WIDTH-1:0] m_rdata,
    output logic [1:0]            m_rresp,
    output logic                  m_rlast,
    output logic                  m_rvalid,
    input  logic                  m_rready
);

    // Burst-Lock State Machine: AXI4 forbids interleaving read data beats from
    // different bursts on the same port, so once a slave is granted we must hold
    // the mux on it until RLAST fires, regardless of what other slaves request.
    typedef enum logic { R_ARB, R_LOCK } r_state_t;
    r_state_t r_state;

    // Request vector: bit set if that source has data targeting this master
    logic [4:0] req;
    assign req[0] = s_rvalid_s0 && (s_rid_s0[ID_WIDTH+1:ID_WIDTH] == MASTER_INDEX);
    assign req[1] = s_rvalid_s1 && (s_rid_s1[ID_WIDTH+1:ID_WIDTH] == MASTER_INDEX);
    assign req[2] = s_rvalid_s2 && (s_rid_s2[ID_WIDTH+1:ID_WIDTH] == MASTER_INDEX);
    assign req[3] = s_rvalid_s3 && (s_rid_s3[ID_WIDTH+1:ID_WIDTH] == MASTER_INDEX);
    assign req[4] = s_rvalid_s4 && (s_rid_s4[ID_WIDTH+1:ID_WIDTH] == MASTER_INDEX);

    // Rotating priority pointer, consulted only while arbitrating a new burst (R_ARB)
    logic [2:0] rr_ptr;
    logic [2:0] grant_idx;
    logic       grant_valid;
    logic [2:0] locked_idx;
    logic [2:0] active_idx;

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

    // Active index is latched for the duration of a burst; otherwise freshly arbitrated
    assign active_idx = (r_state == R_LOCK) ? locked_idx : grant_idx;

    // Implement Combinational Slave Response Multiplexer, steered by active_idx
    always_comb
    begin
        m_rid = '0;
        m_rdata = '0;
        m_rresp = '0;
        m_rlast = '0;
        m_rvalid = '0;
        s_rready_bus = '0;

        if((r_state == R_LOCK) || grant_valid)
        begin
            case(active_idx)
                3'd0: begin m_rid = s_rid_s0[ID_WIDTH-1:0]; m_rdata = s_rdata_s0; m_rresp = s_rresp_s0; m_rlast = s_rlast_s0; m_rvalid = s_rvalid_s0; s_rready_bus[0] = m_rready; end
                3'd1: begin m_rid = s_rid_s1[ID_WIDTH-1:0]; m_rdata = s_rdata_s1; m_rresp = s_rresp_s1; m_rlast = s_rlast_s1; m_rvalid = s_rvalid_s1; s_rready_bus[1] = m_rready; end
                3'd2: begin m_rid = s_rid_s2[ID_WIDTH-1:0]; m_rdata = s_rdata_s2; m_rresp = s_rresp_s2; m_rlast = s_rlast_s2; m_rvalid = s_rvalid_s2; s_rready_bus[2] = m_rready; end
                3'd3: begin m_rid = s_rid_s3[ID_WIDTH-1:0]; m_rdata = s_rdata_s3; m_rresp = s_rresp_s3; m_rlast = s_rlast_s3; m_rvalid = s_rvalid_s3; s_rready_bus[3] = m_rready; end
                3'd4: begin m_rid = s_rid_s4[ID_WIDTH-1:0]; m_rdata = s_rdata_s4; m_rresp = s_rresp_s4; m_rlast = s_rlast_s4; m_rvalid = s_rvalid_s4; s_rready_bus[4] = m_rready; end
                default: ;
            endcase
        end
    end

    // State & rotating pointer update
    always_ff @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
        begin
            r_state    <= R_ARB;
            locked_idx <= '0;
            rr_ptr     <= '0;
        end
        else
        begin
            case(r_state)
                R_ARB:
                begin
                    if(grant_valid)
                    begin
                        locked_idx <= grant_idx;
                        if(m_rvalid && m_rready && m_rlast)
                            rr_ptr <= (grant_idx + 3'd1) % 3'd5; // Single-beat burst, no need to lock
                        else
                            r_state <= R_LOCK;
                    end
                end
                R_LOCK:
                begin
                    if(m_rvalid && m_rready && m_rlast)
                    begin
                        r_state <= R_ARB;
                        rr_ptr  <= (locked_idx + 3'd1) % 3'd5;
                    end
                end
            endcase
        end
    end

endmodule