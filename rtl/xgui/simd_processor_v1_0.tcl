# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "PE_COUNT"
  ipgui::add_param $IPINST -name "DATA_WIDTH"
  ipgui::add_param $IPINST -name "INS_ADDR_WIDTH"
  ipgui::add_param $IPINST -name "INS_BRAM_WIDTH"
  ipgui::add_param $IPINST -name "ADDR_WIDTH"

}

proc update_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to update ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADDR_WIDTH { PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to validate ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.BRAM_DEPTH { PARAM_VALUE.BRAM_DEPTH } {
	# Procedure called to update BRAM_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRAM_DEPTH { PARAM_VALUE.BRAM_DEPTH } {
	# Procedure called to validate BRAM_DEPTH
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.INS_ADDR_WIDTH { PARAM_VALUE.INS_ADDR_WIDTH } {
	# Procedure called to update INS_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INS_ADDR_WIDTH { PARAM_VALUE.INS_ADDR_WIDTH } {
	# Procedure called to validate INS_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.INS_BRAM_WIDTH { PARAM_VALUE.INS_BRAM_WIDTH } {
	# Procedure called to update INS_BRAM_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INS_BRAM_WIDTH { PARAM_VALUE.INS_BRAM_WIDTH } {
	# Procedure called to validate INS_BRAM_WIDTH
	return true
}

proc update_PARAM_VALUE.PE_COUNT { PARAM_VALUE.PE_COUNT } {
	# Procedure called to update PE_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PE_COUNT { PARAM_VALUE.PE_COUNT } {
	# Procedure called to validate PE_COUNT
	return true
}


proc update_MODELPARAM_VALUE.PE_COUNT { MODELPARAM_VALUE.PE_COUNT PARAM_VALUE.PE_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PE_COUNT}] ${MODELPARAM_VALUE.PE_COUNT}
}

proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.ADDR_WIDTH { MODELPARAM_VALUE.ADDR_WIDTH PARAM_VALUE.ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADDR_WIDTH}] ${MODELPARAM_VALUE.ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.INS_ADDR_WIDTH { MODELPARAM_VALUE.INS_ADDR_WIDTH PARAM_VALUE.INS_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INS_ADDR_WIDTH}] ${MODELPARAM_VALUE.INS_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.INS_BRAM_WIDTH { MODELPARAM_VALUE.INS_BRAM_WIDTH PARAM_VALUE.INS_BRAM_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INS_BRAM_WIDTH}] ${MODELPARAM_VALUE.INS_BRAM_WIDTH}
}

proc update_MODELPARAM_VALUE.BRAM_DEPTH { MODELPARAM_VALUE.BRAM_DEPTH PARAM_VALUE.BRAM_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRAM_DEPTH}] ${MODELPARAM_VALUE.BRAM_DEPTH}
}

