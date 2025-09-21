module testbench;
  logic clk;
  logic reset;
  logic [3:0] fault_flags;
  logic [3:0] mask_reg;
  logic [1:0] y;
  
  localparam undervoltage = 0;
  localparam overtemp = 1;
  localparam overvoltage = 2;
  localparam overcurrent = 3;
  
  fault_detector fd (
    .clk(clk),
    .reset(reset),
    .fault_flags(fault_flags),
    .mask_reg(mask_reg),
    .y(y)
  );
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $display("Test 1: Initial state & Normal operation");
    reset = 1;
    fault_flags = 4'b0000;
    mask_reg = 4'b0000;
    #10 reset = 0;

    $display("Test 2: Transient undervoltage fault (should be ignored)");
    #10 fault_flags[undervoltage] = 1;
    #15 fault_flags[undervoltage] = 0; 

    $display("Test 3: Persistent overtemp fault (transition to WARNING -> FAULT)");
    #10 fault_flags[overtemp] = 1;
    #250 fault_flags[overtemp] = 0;

    #5 $display("Test 4: High-priority overcurrent fault");
    reset = 1;
    #5 reset = 0;
    #10 fault_flags[overcurrent] = 1;
    
    
    #30 $display("Test 5: High-priority overvoltage fault");
    reset = 1; fault_flags = 4'b0000;
    #10 reset = 0;
    #10 fault_flags[overvoltage] = 1;


    #30 $display("Test 6: Overvoltage fault is masked");
    mask_reg[overvoltage] = 1;    
    
    #50 $display("All test cases completed. Finishing simulation.");
    $finish;
  end
  
  initial begin
    $monitor("Time: %0t, State: %s, Faults: %b, Mask: %b, DebounceCnt: %0d, PersistenceCnt: %0d", 
             $time, fd.state.name(), fault_flags, mask_reg, fd.debounce_counter, fd.persistence_counter);
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0);
  end

endmodule