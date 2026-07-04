read_liberty lib/NangateOpenCellLibrary_slow.lib
read_verilog netlist/ksa4_netlist_holdfix.v
link_design ksa4_reg
read_sdc constraints/ksa4.sdc
report_checks -path_delay max -fields {slew cap input_pin_activity} -digits 4 > reports/setup_slow.rpt
report_wns > reports/wns_slow.rpt
report_tns > reports/tns_slow.rpt
report_checks -path_delay min -digits 4 > reports/hold_slow.rpt
