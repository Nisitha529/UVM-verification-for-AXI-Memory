interface axi_if();
  
  // Write address channel (aw)
  logic        awvalid;  // Master is sending new address  
  logic        awready;  // Slave is ready to accept request
  logic [3:0]  awid;     // Unique ID for each transaction
  logic [3:0]  awlen;    // Burst length AXI3 : 1 to 16, AXI4 : 1 to 256
  logic [2:0]  awsize;   // Unique transaction size : 1,2,4,8,16 ...128 bytes
  logic [31:0] awaddr;   // Write adress of transaction
  logic [1:0]  awburst;  // Burst type : fixed , INCR , WRAP

  // Write data channel (w)
  logic        wvalid;   // Master is sending new data
  logic        wready;   // Slave is ready to accept new data 
  logic [3:0]  wid;      // Unique id for transaction
  logic [31:0] wdata;    // Data 
  logic [3:0]  wstrb;    // Lane having valid data
  logic        wlast;    // Last transfer in write burst
  
  
  // Write response channel (b) 
  logic        bready;   // Master is ready to accept response
  logic        bvalid;   // Slave has valid response
  logic [3:0]  bid;      // Unique id for transaction
  logic [1:0]  bresp;    // Status of write transaction 
  
  // Read address channel (ar)
 
  logic        arvalid;  // Master is sending new address  
  logic        arready;  // Slave is ready to accept request
  logic [3:0]  arid;     // Unique ID for each transaction
  logic [3:0]  arlen;    // Burst length AXI3 : 1 to 16, AXI4 : 1 to 256
  logic [2:0]  arsize;   // Unique transaction size : 1,2,4,8,16 ...128 bytes
  logic [31:0] araddr;   // Write adress of transaction
  logic [1:0]  arburst;  // Burst type : fixed , INCR , WRAP
  
  // Read data channel (r)
  
  logic        rvalid;   // Master is sending new data
  logic        rready;   // Slave is ready to accept new data 
  logic [3:0]  rid;      // Unique id for transaction
  logic [31:0] rdata;    // Data 
  logic [3:0]  rstrb;    // Lane having valid data
  logic        rlast;    // Last transfer in write burst
  logic [1:0]  rresp;    // Status of read transfer
  
  logic clk;
  logic resetn;

  logic [31:0] next_addrwr;
  logic [31:0] next_addrrd;

endinterface 