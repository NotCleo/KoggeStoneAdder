# SDC for ksa4_reg -- 500 MHz target, Nangate45
create_clock -name clk -period 2.0 [get_ports clk]
set_clock_uncertainty 0.10 [get_clocks clk]
set_clock_latency 0.30 [get_clocks clk]
set_input_delay  0.40 -clock clk [get_ports {a b cin}]
set_output_delay 0.40 -clock clk [get_ports {sum cout}]
set_driving_cell -lib_cell BUF_X2 [get_ports {a b cin}]
set_load 0.02 [all_outputs]
set_false_path -from [get_ports rst_n]
# No multicycle paths: this is a single-stage registered adder; every
# reg-to-reg path is a genuine single-cycle path.
