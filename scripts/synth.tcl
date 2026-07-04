read_liberty -lib lib/NangateOpenCellLibrary_typical.lib
read_verilog rtl/ksa4_reg.v
hierarchy -check -top ksa4_reg
proc; opt; fsm; opt; memory; opt
techmap; opt
dfflibmap -liberty lib/NangateOpenCellLibrary_typical.lib
abc -liberty lib/NangateOpenCellLibrary_typical.lib
clean
write_verilog -noattr netlist/ksa4_netlist.v
stat -liberty lib/NangateOpenCellLibrary_typical.lib
