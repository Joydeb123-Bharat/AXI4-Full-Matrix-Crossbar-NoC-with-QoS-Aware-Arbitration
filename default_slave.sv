`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.07.2026 10:58:51
// Design Name: 
// Module Name: default_slave
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

module default_slave #(
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 10 
)(
    input logic clk,
    input logic rst_n,

    // Write Address Channel
    input  logic [ID_WIDTH-1:0] awid,
    input  logic                awvalid,
    output logic                awready,

    // Write Data Channel
    input  logic                wlast,
    input  logic                wvalid,
    output logic                wready,

    // Write Response Channel
    output logic [ID_WIDTH-1:0] bid,
    output logic [1:0]          bresp,
    output logic                bvalid,
    input  logic                bready,

    // Read Address Channel
    input  logic [ID_WIDTH-1:0] arid,
    input  logic                arvalid,
    output logic                arready,

    // Read Data Channel
    output logic [ID_WIDTH-1:0]   rid,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic [1:0]            rresp,
    output logic                  rlast,
    output logic                  rvalid,
    input  logic                  rready
);

    // State definitions
    typedef enum logic [1:0] {W_IDLE, W_ABSORB, W_RESP} w_state_t;
    typedef enum logic [0:0] {R_IDLE, R_RESP} r_state_t;
    
    w_state_t w_curr, w_next;
    r_state_t r_curr, r_next;

    logic [ID_WIDTH-1:0] latched_awid, latched_arid;
    
    // WRITE CHANNEL LOGIC
    always_comb 
    begin
        w_next = w_curr;
        awready = 0; wready = 0; bvalid = 0;
        bresp = 2'b11; bid = latched_awid;

        case (w_curr)
            W_IDLE: 
            begin
                awready = 1;
                wready = 0;
                if (awvalid) w_next = W_ABSORB;
            end
            W_ABSORB: 
            begin
                wready = 1;
                if (wvalid && wlast) w_next = W_RESP;
            end
            W_RESP: 
            begin
                bvalid = 1;
                if (bready) w_next = W_IDLE;
            end
        endcase
    end

    // READ CHANNEL LOGIC
    always_comb
    begin
        r_next = r_curr;
        arready = 0; rvalid = 0; rlast = 0;
        rresp = 2'b11; rid = latched_arid; rdata = 32'hDEAD_BEEF;

        case (r_curr)
            R_IDLE: 
            begin
                arready = 1;
                if (arvalid) r_next = R_RESP;
            end
            R_RESP: 
            begin
                rvalid = 1; rlast = 1;
                if (rready) r_next = R_IDLE;
            end
        endcase
    end

    // SEQUENTIAL REGISTERS
    always_ff @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            w_curr <= W_IDLE;
            r_curr <= R_IDLE;
            latched_awid <= '0;
            latched_arid <= '0;
        end 
        else 
        begin
            w_curr <= w_next;
            r_curr <= r_next;
            if (awvalid && awready) latched_awid <= awid;
            if (arvalid && arready) latched_arid <= arid;
        end
    end

endmodule