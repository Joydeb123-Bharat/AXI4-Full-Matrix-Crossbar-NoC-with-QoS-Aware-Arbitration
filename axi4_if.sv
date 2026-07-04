`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.07.2026 21:24:09
// Design Name: 
// Module Name: axi4_if
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

interface axi4_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ID_WIDTH   = 8
)(
    input logic clk,
    input logic rst_n
);

    // Write Address Channel (AW)
    logic [ID_WIDTH-1:0]    AWID;
    logic [ADDR_WIDTH-1:0]  AWADDR;
    logic [7:0]             AWLEN;
    logic [2:0]             AWSIZE;
    logic [1:0]             AWBURST;
    logic [3:0]             AWQOS;
    logic                   AWVALID;
    logic                   AWREADY;
    
    // Write Data Channel (W)
    logic [DATA_WIDTH-1:0]  WDATA;
    logic [DATA_WIDTH/8-1:0]WSTRB;
    logic                   WLAST;
    logic                   WVALID;
    logic                   WREADY;
    
    // Write Response Channel (B)
    logic [ID_WIDTH-1:0]    BID;
    logic [1:0]             BRESP;
    logic                   BVALID;
    logic                   BREADY;
    
    // Read Address Channel (AR)
    logic [ID_WIDTH-1:0]    ARID;
    logic [ADDR_WIDTH-1:0]  ARADDR;
    logic [7:0]             ARLEN;
    logic [2:0]             ARSIZE;
    logic [1:0]             ARBURST;
    logic [3:0]             ARQOS;
    logic                   ARVALID;
    logic                   ARREADY;
    
    // Read Data Channel (R)
    logic [ID_WIDTH-1:0]    RID;
    logic [DATA_WIDTH-1:0]  RDATA;
    logic [1:0]             RRESP;
    logic                   RLAST;
    logic                   RVALID;
    logic                   RREADY;
    
    // Modports
    modport master (
        // Write Address Channel (AW)
        output AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWQOS, AWVALID,
        input  AWREADY,

        // Write Data Channel (W)
        output WDATA, WSTRB, WLAST, WVALID,
        input  WREADY,

        // Write Response Channel (B)
        input  BID, BRESP, BVALID,
        output BREADY,

        // Read Address Channel (AR)
        output ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARQOS, ARVALID,
        input  ARREADY,

        // Read Data Channel (R)
        input  RID, RDATA, RRESP, RLAST, RVALID,
        output RREADY
    );

    modport slave (
        // Write Address Channel (AW)
        input  AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWQOS, AWVALID,
        output AWREADY,

        // Write Data Channel (W)
        input  WDATA, WSTRB, WLAST, WVALID,
        output WREADY,

        // Write Response Channel (B)
        output BID, BRESP, BVALID,
        input  BREADY,

        // Read Address Channel (AR)
        input  ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARQOS, ARVALID,
        output ARREADY,

        // Read Data Channel (R)
        output RID, RDATA, RRESP, RLAST, RVALID,
        input  RREADY
    );

endinterface