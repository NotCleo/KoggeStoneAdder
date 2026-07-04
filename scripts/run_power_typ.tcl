read_liberty lib/NangateOpenCellLibrary_typical.lib
read_verilog netlist/ksa4_netlist_holdfix.v
link_design ksa4_reg
read_sdc constraints/ksa4.sdc
report_power > reports/power_typ.rpt
