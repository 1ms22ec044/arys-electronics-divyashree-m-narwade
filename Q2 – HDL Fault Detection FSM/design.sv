module fault_detector (
  input logic clk,
  input logic reset,
  input logic [3:0] fault_flags, // {undervoltage, overtemperature, overvoltage, overcurrent}
  input logic [3:0] mask_reg,
  output logic [1:0] y
);
  
  localparam undervoltage = 0;
  localparam overtemp = 1;
  localparam overvoltage = 2;
  localparam overcurrent = 3;
  localparam debounce_threshold = 5;
  localparam persistence_threshold = 15;

  typedef enum logic [1:0] { NORMAL, WARNING, FAULT, SHUTDOWN } state_t;
  state_t state, next_state;

  logic [7:0] debounce_counter;
  logic [7:0] persistence_counter; 
  logic [3:0] masked_faults;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= NORMAL;
      debounce_counter <= 0;
      persistence_counter <= 0;
    end
    
    else begin
      state <= next_state;
      
      if ((masked_faults[undervoltage] || masked_faults[overtemp])) 
        debounce_counter <= debounce_counter + 1;
      else 
        debounce_counter <= 0;

      if (state == WARNING && (masked_faults[undervoltage] || masked_faults[overtemp])) 
        persistence_counter <= persistence_counter + 1;
      else 
        persistence_counter <= 0;
      
    end
  end

  always_comb begin
    masked_faults = fault_flags & (~mask_reg);
    y = state;
    next_state = state;

    case(state)
      NORMAL: begin
        if (masked_faults[overcurrent])
          next_state = SHUTDOWN;
        else if (masked_faults[overvoltage])
          next_state = FAULT;
        else if (debounce_counter >= debounce_threshold)
          next_state = WARNING;
      end
      
      WARNING: begin
        if (masked_faults[overcurrent])
          next_state = SHUTDOWN;
        else if (masked_faults[overvoltage] || persistence_counter >= persistence_threshold)
          next_state = FAULT;
        else if (masked_faults == 4'b0000)
          next_state = NORMAL;
      end
      
      FAULT: begin
        if (masked_faults[overcurrent])
          next_state = SHUTDOWN;
        else if (masked_faults == 4'b0000)
          next_state = NORMAL;
      end
      
      SHUTDOWN: begin
        next_state = SHUTDOWN;
      end
    endcase
  end
endmodule