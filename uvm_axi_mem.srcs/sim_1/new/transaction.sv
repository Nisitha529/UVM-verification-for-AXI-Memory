`include "uvm_macros.svh"
 import uvm_pkg::*;
 
 
typedef enum bit [2:0] {wrrdfixed = 0, wrrdincr = 1, wrrdwrap = 2, wrrderrfix = 3,   rstdut = 4 } oper_mode;
 
class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
  
   
 
  function new(string name = "transaction");
    super.new(name);
  endfunction
  
 
  int len = 0;
  rand bit [3:0] id;
  oper_mode op;
  rand bit awvalid;
  bit awready;
  bit [3:0] awid;
  rand bit [3:0] awlen;
  rand bit [2:0] awsize; //4byte =010
  rand bit [31:0] awaddr;
  rand bit [1:0] awburst;
  
  bit wvalid;
  bit wready;
  bit [3:0] wid;
  rand bit [31:0] wdata;
  rand bit [3:0] wstrb;
  bit wlast;
  
  bit bready;
  bit bvalid;
  bit [3:0] bid;
  bit [1:0] bresp;
  
  
  rand bit arvalid;  /// master is sending new address  
  bit arready;  /// slave is ready to accept request
  bit [3:0] arid; ////// unique ID for each transaction
  rand bit [3:0] arlen; ////// burst length AXI3 : 1 to 16, AXI4 : 1 to 256
  bit [2:0] arsize; ////unique transaction size : 1,2,4,8,16 ...128 bytes
  rand bit [31:0] araddr; ////write adress of transaction
  rand bit [1:0] arburst; ////burst type : fixed , INCR , WRAP
  
  /////////// read data channel (r)
  
  bit rvalid; //// master is sending new data
  bit rready; //// slave is ready to accept new data 
  bit [3:0] rid; /// unique id for transaction
  bit [31:0] rdata; //// data 
  bit [3:0] rstrb; //// lane having valid data
  bit rlast; //// last transfer in write burst
  bit [1:0] rresp; ///status of read transfer
  
  //constraint size { awsize == 3'b010; arsize == 3'b010;}
  constraint txid { awid == id; wid == id; bid == id; arid == id; rid == id;  }
  constraint burst {awburst inside {0,1,2}; arburst inside {0,1,2};}
  constraint valid {awvalid != arvalid;}
  constraint length {awlen == arlen;}
 
endclass : transaction