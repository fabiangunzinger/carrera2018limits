/*
===============================================================================

Replicating carrera2018limits

Fabian Gunzinger

10 September 2018

================================================================================
*/


clear all
set more off
log close _all

cd "$cloud/fab/coding/data_analysis/carrera2018limits"

log using "code/logs/stata-task.log", replace


// Macros

local start_date td(15 Apr 2016)
local end_date td(15 Jun 2016)
local study_duration = `end_date' - `start_date' + 1

local start_date_intervention td(31 May 2016)
local end_date_intervention td(12 June 2016)
local intervention_duration = `end_date_intervention' - `start_date_intervention' + 1



clear
webuse stackxmpl
list 
stack a b c d, into(e f) clear
list



/*
// Retrieve remembered visits (of control) and merge into full panel

clear
use $persondata
keep if control == 1
rename id_num id
keep id mondaymay9th-sundaymay22nd


stack mondaymay9th tuesdaymay10th

/*

stack id_string mondaymay9th id_string tuesdaymay10th id_string wednesdaymay11th id_string thursdaymay12th id_string fridaymay13th id_string saturdaymay14th id_string sundaymay15th id_string mondaymay16th id_string tuesdaymay17th id_string wednesdaymay18th id_string thursdaymay19th id_string fridaymay20th id_string saturdaymay21st id_string sundaymay22nd, into(id_string rem_hour)
*date for Monday, May 9th is 20583--this is first day for which we asked them to recall workouts
label variable rem_hour "hour of recalled workout or 'No Workout', empty if left blank on survey" 
destring id_string, gen(id_num)
generate date = 20582 + _stack




/*



// ================================
// Create empty id date hour panel
// ================================

clear
use $visitdata

collapse id_num, by(id_str)
drop id_string
rename id_num id
keep in 1

// Create days

expand `study_duration'
egen date = repeat(), values(`=`start_date'' / `=`end_date'') by(id)
format date %tdDD_Mon_CCYY
gen dow = dow(date)
gen dow_name = dow
format dow_name %tdDay
gen weekend = dow == 1 | dow == 2


// Create hours (and remove hours when gym is closed)

expand 24
sort id date 
egen hour = repeat(), values(1/24) by(id)
local open_weekday 6
local close_weekday 23
local open_weekend 8
local close_weekend 21
drop if (hour < `open_weekend' | hour > `close_weekend') & weekend == 1
drop if (hour < `open_weekday' | hour > `close_weekday') & weekend == 0
sort date dow hour


// Indicator for study phase

gen phase = ""
replace phase = "Pre" if date < `start_date_intervention'
replace phase = "Post" if date > `end_date_intervention'
replace phase = "During" if phase == ""


// Retrieve recorded visits and merge into full panel (a match means that a subject visited the gym at a given day and time)

preserve
clear
use $visitdata
keep id_num date hour
rename id_num id
tempfile recorded_visits
save `recorded_visits'
restore

merge 1:1 id date hour using `recorded_visits'
gen visit = _merge == 3
drop _merge





