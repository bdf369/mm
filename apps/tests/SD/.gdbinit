#no threads

source ../../.gdb2618
source ../../.gdb_mm

set remoteaddresssize 0d64
set remotetimeout 0d999999
target remote localhost:2000

disp/i $pc
x/i $pc

b RealMainP.nc:75
b RealMainP.nc:82
b SchedulerBasicP.nc:151
b SchedulerBasicP.nc:148

#b VirtualizeTimerC.nc:81
dis

# 5 debug_break  (optimized out)
# b PanicP.nc:62

# 5 panic
b PanicP.nc:77
comm
printf "pcode: 0d%d (0x%0x)  where: 0d%d  0x%04x 0x%04x 0x%04x 0x%04x\n",_p,_p, _w, _a0, _a1, _a2, _a3
end

# sd_send_command
b SDspP.nc:474
comm
printf "sd_send_command\n"
printf "prelim delta: "
x/hd &d1
printf "cmd delta:    "
x/hd &d2
printf "rsp delta:    "
x/hd &d3
printf "total time:   "
x/hd &t4
end

b SDspP.nc:656
comm
printf "SDreset.reset complete\n"
p/d SDspP__sd_go_op_count
p/d SDspP__last_reset_time_mis
p/d SDspP__last_reset_time_uis
end

dis
ena 5

b sdP.nc:37
