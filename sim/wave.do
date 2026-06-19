onerror {resume}
# ===== GET TOP & DATASET PREFIX =====
set TOP $1
set DS  "$2:"

# ============================================================
# WAVE CONFIG
# ============================================================
view wave
configure wave -namecolwidth    180
configure wave -valuecolwidth   80
configure wave -signalnamewidth 1
configure wave -justifyvalue    left
configure wave -timelineunits   ns

# ===== LOG ALL (only in live sim, not WLF view) =====
if { [string equal $2 "sim"] } {
    log -r sim:/$TOP/*
}

radix -default hex

# ============================================================
# ===== TOP MODULE =====
# ============================================================
add wave -noupdate -divider "$TOP"

# ===== GROUP CONTROL (clk/rst) =====
add wave -noupdate -color cyan  ${DS}/$TOP/clk
add wave -noupdate -color red   ${DS}/$TOP/rst

# ===== GROUP INPUT (i_*) =====
add wave -noupdate -divider "INPUTS"
add wave -noupdate -color green  ${DS}/$TOP/i_*

# ===== GROUP OUTPUT (o_*) =====
add wave -noupdate -divider "OUTPUTS"
add wave -noupdate -color yellow ${DS}/$TOP/o_*


# ============================================================
# ===== UPDATE & RUN =====
# ============================================================
update

if { [string equal $2 "sim"] && [string equal [runStatus] "ready"] } {
    run -all
}

wave zoom full