read_liberty -lib lib/NangateOpenCellLibrary_typical.lib
read_verilog netlist/ksa4_netlist_holdfix.v
hierarchy -check -top ksa4_reg
stat -liberty lib/NangateOpenCellLibrary_typical.lib
