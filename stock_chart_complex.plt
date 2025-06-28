reset;
set encoding utf8
eod = 'eod.txt'
set datafile missing "?"
set macro

# =============================================================================
# OUTPUT CONFIGURATION
# =============================================================================
output_file = "stock.png"

iswindows = substr(GPVAL_SYSNAME, 1, 7) eq "Windows"
if (iswindows) {
    run_command =  output_file
} else {
    run_command = "ristretto ".GPVAL_PWD.'/'.output_file
}


# =============================================================================
# TERMINAL AND DISPLAY SETTINGS
# =============================================================================

set boxwidth 0.56 absolute;
# set term
if (GPVAL_SYSNAME eq 'Linux') {set term x11 enhanced  size 1000, 680 } 
else  {set term wxt enhanced  size 1000, 680 }
    
#~ if (!exists("outfile")) outfile='def.png'
if (exists("output_file")) set term png enhanced size 1000, 680; set output output_file;
# Configuration for highlighting recent data points
mark_form = 0
form_length = 0
if (!(ARG2 eq "")){  
    mark_form = 1
    form_length = int(ARG2) 
}

# =============================================================================
# COLOR SCHEME
# =============================================================================
screen_background = '#E6EFF7'
chart_background = 'white'
grid_color = '#DCDCDC'
axis_border = "#696969"
labels_color = 'black'
stock_name_color = 'black'

# Candlestick appearance
up_color = "white"
up_border = "#3A5FCD"
down_color = "#3A5FCD"
down_border = "#828282"
last_candle_color = '#FFFF80'

# Volume bar colors
up_volume_color = '#253992'
down_volume_color = "black"

# Trading signal indicators
recommendation_sell_color = 'red'
recommendation_reduce_color = '#4F4F4F'
recommendation_buy_color = "#008400"
dividend_color = '#00008B'
report_color = '#00008B'

# =============================================================================
# FONTS
# =============================================================================
name_font = "Futura Hv Bt,16"
# name_font = "Inter Display Semibol,12"
description_font = 'Inter,12'
tick_font = "Inter,10"
small_font = 'Marke Eigenbau:Bold,6'
volume_label_font = "FuturaHv,14"

# =============================================================================
# TRADING SIGNAL SYMBOLS
# =============================================================================
recommendation_sell_symbol = 'O'
recommendation_reduce_symbol = 'O'
recommendation_buy_symbol = 'S'
dividend_symbol = 'i'
report_symbol = 'i'

recommendation_font = 'Gembats 1,14'
dividend_font = 'Seeing Stars,14'
report_font = 'Webdings,14'

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Convert month number to Polish month abbreviation
polish_month(month_number) = month_number == 1 ? "Sty" :\
    month_number == 2 ? "Lut" : \
    month_number == 3 ? "Mar" : \
    month_number == 4 ? "Kwi" : \
    month_number == 5 ? "Maj" : \
    month_number == 6 ? "Cze" : \
    month_number == 7 ? "Lip" : \
    month_number == 8 ? "Sie" : \
    month_number == 9 ? "Wrze" : \
    month_number == 10 ? "Paź" : \
    month_number == 11 ? "Lis" : \
    month_number == 12 ? "Gru" : '-'

# Extract components from YYYYMMDD date format
get_year_int(date_int) = int(date_int / 10000)
get_month_int(date_int) = int((date_int / 10000.0 - get_year_int(date_int)) * 100)

get_range(x_min, x_max) = sqrt(((x_min - x_max)**2))

# Track previous values for price change calculations
grab_values(y) = (back_2 = back_1, back_1 = y)
back_2 = 0
back_1 = 0

get_last_date(y) = (date_last = y)
get_last_volume(y) = (last_volume = y)

label_1 = 'default name'
get_labels(x, y) = (label_1 = x, label_2 = y)

# Color coding based on price change magnitude
price_change_color(change_percent) = (change_percent > 3 ? '#008B45' : ( \
                change_percent > 2 ? '#007700' : ( \
                    change_percent >= 0 ? '#007700' : '#EE0000')))

# =============================================================================
# CHART SETUP
# =============================================================================
set style line 1 lc rgb 'gray'

# Screen and chart backgrounds
set obj 1 rect from screen 0,0 to screen 1,1 fs solid 1 \
    border rgb 'gray' behind fc rgb screen_background   
set obj 2 rect from graph 0,0 to graph 1,1 fs solid 1 behind fc rgb chart_background

set border lc rgb 'gray' front
set multiplot
set key off

# Main chart layout
set lmargin 0.1
set rmargin 3.5
set bmargin 0
set tmargin 0
set size 1, 0.72
set origin 0, 0.235

set style fill empty

# =============================================================================
# DATA EXTRACTION PASS
# Dummy plot to extract data ranges and values
# =============================================================================
set autoscale y
plot eod u 0:2:4:3:(grab_values($5)) with financebars lc rgb "blue", \
     '' u 0:(get_last_date($1) == -999 ? $5 : 1/0) w points, \
     '' u 0:(get_last_volume($6)) w p axes x2y2 lc rgb "gray", \
     '' u (int($0) == 0 ? get_labels(stringcolumn(1), stringcolumn(2)): 1/0) w points pt -1

# Extract plot boundaries
y_min = GPVAL_DATA_Y_MIN
y_max = GPVAL_DATA_Y_MAX
x_max = GPVAL_DATA_X_MAX
max_volume = GPVAL_DATA_Y2_MAX

# Adjust x-axis range for better display
x_max_adjusted = (x_max < 100 ? 150 : \
                 (x_max < 180 ? x_max + 200 - x_max : x_max))
             
set xrange[0:x_max_adjusted + 1]
final_min = (y_min == 0 ? 0.1 : y_min)  # Prevent log scale errors
set yrange[0.98 * final_min : y_max * 1.01]

# Calculate price changes
previous_day_close = back_2
last_close = back_1
step = get_range(log10(y_min), log10(y_max)) * 0.2
change_percent = (last_close - previous_day_close) / previous_day_close * 100
min_max_range = (y_max - y_min) / y_min * 100

# Median price for symbol positioning
my_median = 10**(log10(y_min) + ((log10(y_max) - log10(y_min)) / 2.))

# =============================================================================
# CHART LABELS
# =============================================================================
set label 1 label_1 front at screen 0.015,0.975 font name_font tc rgb stock_name_color

set label 6 "Zakres Min/Max:".gprintf("{/Inter:Bold=12 %.1f%%}", min_max_range) \
    front at screen 0.5,0.975 center font description_font tc rgb labels_color 

# =============================================================================
# GRID AND AXIS SETUP
# =============================================================================
set grid y2tics back xtics back lt 1 lw 0.9 lc rgb grid_color

set logscale y
set logscale y2

set y2tics nolog (y_min, (y_min + (y_min + y_max) * 0.5) / 2, \
    (y_min + y_max) * 0.5, ((y_min + y_max) * 0.5 + y_max) / 2, y_max) \
    tc rgb labels_color format "%.2f" offset -0.7,0 font tick_font

set xtics scale 0.5 nomirror in font tick_font tc rgb labels_color offset 2.9, 1.7

# =============================================================================
# MAIN PRICE CHART
# =============================================================================

# Date processing for x-axis month labels
previous_1 = 0
shift_date(x) = (previous_2 = previous_1, previous_1 = x)
year_month(date_int) = int(date_int / 100)

plot eod \
    u 0:(shift_date($1)):xtic(year_month(previous_2) != year_month($1) ? polish_month(get_month_int($1)) : 1/0) \
    w p pt -1 lc rgb 'red', \
    \
    "" u 0:(($0 * mark_form == x_max - form_length + 1) ? $5 : 1/0):($0):($0 + (x_max - $0 + 1)):($4):(last_close) \
    w boxxyerrorbars lw 5 lc rgb last_candle_color fs solid border rgb 'gray', \
    \
    '' u 0:($0 == x_max ? $2 : 1/0):4:3:5 w candlesticks lc rgb last_candle_color lw 4 fs solid, \
    \
    '' u 0:($2 <= $5 ? $2 : 1/0):4:3:5 axes x1y2 w candlesticks lc rgb up_color \
    fs solid border rgb up_border, \
    \
    '' u 0:($2 > $5 ? $2 : 1/0):4:3:5 w candlesticks lc rgb up_border \
    fs solid border rgb up_border, \
    \
    '' u 0:($2 == $5 ? $2 : 1/0):4:3:5 w candlesticks lc rgb up_border lw 2, \
    \
    '' u 0:($8 == 1 ? ($4 * (1 - step)) : 1/0):(recommendation_sell_symbol) \
    w labels tc rgb recommendation_sell_color font recommendation_font offset 0.3,0, \
    \
    '' u 0:($8 == 2 ? ($4 * (1 - step)) : 1/0):(recommendation_reduce_symbol) \
    w labels tc rgb recommendation_reduce_color font recommendation_font offset 0.3,0, \
    \
    '' u 0:($8 == 4 ? (($5 > (my_median)) ? $4 * (1 - step) : $3 * (1 + step)) : 1/0):(recommendation_buy_symbol) w \
    labels tc rgb recommendation_reduce_color font recommendation_font offset 0.35,0, \
    \
    '' u 0:($8 == 5 ? (($5 > (my_median)) ? $4 * (1 - step) : $3 * (1 + step)) : 1/0):(recommendation_buy_symbol) w \
    labels tc rgb recommendation_buy_color font recommendation_font offset 0.35,0, \
    \
    '' u 0:($8 == 9 ? (($5 > (my_median)) ? $4 * (1 - step) : $3 * (1 + step)) : 1/0):(dividend_symbol) \
    w labels tc rgb dividend_color font dividend_font offset 0.35,0, \
    \
    '' u 0:($8 == 8 ? (($5 > (my_median)) ? $4 * (1 - step) : $3 * (1 + step)) : 1/0):(report_symbol) \
    w labels tc rgb report_color font report_font offset 0.35, 0

# Clean up main chart labels
unset object 1
unset label 1
unset label 6

# =============================================================================
# VOLUME SUBPLOT
# =============================================================================
set size 1.0, 0.2
set origin 0.0, 0.03

unset yrange
unset y2range
unset y2tics
unset ytics
unset logscale y
unset logscale y2
set autoscale y
set autoscale y2
set grid back xtics y2tics

set format y2 "%-.0s %c "

set y2tics (0, 0.25 * max_volume, max_volume * 0.5, max_volume * 0.75) \
    scale 0.1 out textcolor rgb labels_color offset -0.7, 0 font tick_font

set label 1 "Wolumen: ".gprintf("%-.2s %c ", last_volume) front \
    at graph 0.01,0.81 font volume_label_font tc rgb labels_color

set label 100 "{/Inter=9 }~{Copyright T.S.}" front at graph 0.01,-0.095 \
    font small_font tc rgb "#5D5D5D"

# Volume bars with color coding
plot eod \
    u 0:($0 == x_max ? $6 : 1/0) w impulses lc rgb last_candle_color lw 4, \
    '' u 0:6 w impulses lc rgb 'black' lw 1, \
    '' u 0:(0):xtic(int($7) == 9 ? '' : 1/0) w dots lc rgb 'red', \
    '' u 0:($2 > $5 ? $6 : 1/0) w impulses lc rgb down_volume_color, \
    '' u 0:($2 < $5 ? $6 : 1/0) w impulses lc rgb up_volume_color, \
    '' u 0:6*1.1:(0.01) smooth acsplines lc rgb "black"

unset multiplot
print '> big OK ', label_1
pause mouse key
set output
if (ARG1 eq "") { 
    system run_command 
}