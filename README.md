# UVM-verification-for-AXI-Memory
## AXI Slave Module

### Overview
This module implements an AXI4-compliant slave interface capable of handling both read and write transactions. It supports multiple burst types and uses dedicated state machines for each AXI channel, ensuring full protocol compliance.

### Interface signals

#### Global signals
- clk: System clock
- resetn: Active-low reset

#### Write Address Channel
- awvalid : Write address valid
- awready : Write address ready
- awid    : Transaction ID
- awlen   : Burst length
- awsize  : Transfer size
- awaddr  : Write address
- awburst : Burst type

#### Write Data Channel
- wvalid  : Write data valid
- wready  : Write data ready
- wid     : Data ID
- wdata   : Write data
- wstrb   : Write strobes (byte enables)
- wlast   : Last transfer in burst

#### Write Response Channel
- bready  : Master ready for response
- bvalid  : Response valid
- bid     : Response ID
- bresp   : Response status

#### Read Address Channel
- arvalid : Read address valid
- arready : Read address ready
- arid    : Transaction ID
- araddr  : Read address
- arlen   : Burst length
- arsize  : Transfer size
- arburst : Burst type

#### Read Data Channel
- rvalid  : Read data valid
- rready: Read data ready
- rid: Data ID
- rdata: Read data
- rresp: Read response status
- rlast: Last transfer in burst

### Functional Description
- The design uses five independent finite state machines (FSMs), one per AXI channel:
- Write Address FSM: Manages write address transactions
- Write Data FSM: Accepts and stores burst write data
- Write Response FSM: Generates write completion responses
- Read Address FSM: Handles read address requests
- Read Data FSM: Streams out read data with burst handling

### Burst Support
- All AXI4 burst types are supported:
- FIXED: Repeated transfers to the same address
- INCR: Sequential addresses for each transfer
- WRAP: Address wraps around at a defined boundary

### Internal Memory
- The module includes a 128-byte internal memory block. It is byte-addressable, supports selective writes via wstrb, and aligns read data according to the access size.

### Error Handling
The slave returns AXI-compliant response codes:

- OKAY (0b00): Successful access
- SLVERR (0b10): Slave-side error (e.g., unsupported size)
- DECERR (0b11): Decode error (e.g., invalid address)

## AXI4 Slave UVM Testbench
### Overview
This repository contains a UVM-based testbench for verifying an AXI slave module. The testbench implements a complete verification environment with various test sequences to validate the functionality of an AXI slave device.

### Testbench structure
The testbench follows standard UVM architecture with the following components:
- Transaction: UVM sequence item containing all AXI signals and constraints
- Sequences: Multiple test scenarios for different AXI operations
- Driver: Translates transactions to AXI protocol signals
- Monitor: Observes DUT behavior and checks for correctness
- Agent: Contains driver, monitor, and sequencer
- Environment: Top-level container for all testbench components
- Test: Configures the environment and executes test sequences

### Test Sequences
The testbench includes these verification scenarios:
- Reset Sequence: Initializes the DUT and verifies reset behavior
- Fixed Burst Mode: Tests FIXED burst type transactions
- Incremental Burst Mode: Tests INCR burst type transactions
- Wrapping Burst Mode: Tests WRAP burst type transactions
- Error Condition Tests: Verifies error responses for invalid addresses

### Verification Approach
- The testbench uses a comprehensive approach to verify the AXI slave:
- Protocol Compliance: Checks that all AXI signals follow protocol timing requirements
- Data Integrity: Verifies that written data matches read data for valid transactions
- Error Handling: Confirms proper error responses for invalid operations
- Burst Support: Validates all supported burst types (FIXED, INCR, WRAP)
