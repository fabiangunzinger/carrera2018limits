/*
===============================================================================

Replicating carrera2018limits

Fabian Gunzinger

10 September 2018

===============================================================================
*/


clear all
set more off
log close _all

cd "$cloud/fab/coding/data_analysis/carrera2018limits"

log using "logs/stata-task.log", replace


// Macros
global persondata "./data/input/person_level_stata13"
global visitdata "./data/input/visit_level_stata13"
global fullpanel "./data/output/panel_full"

local start_date td(15 Apr 2016)
local end_date td(15 Jun 2016)
local study_duration = `end_date' - `start_date' + 1

local start_date_intervention td(31 May 2016)
local end_date_intervention td(12 June 2016)
local intervention_duration = `end_date_intervention' - `start_date_intervention' + 1


// Control file
global buildfull = 0
global buildaggregate = 0
global sandbox = 1



// ================================
// Build full panel
// ================================

if $buildfull {

// --------------------------------
// Create empty id date hour panel
// --------------------------------

clear
use $visitdata

collapse id_num, by(id_str)
drop id_string
rename id_num id

// Create days

expand `study_duration'
egen date = repeat(), values(`=`start_date'' / `=`end_date'') by(id)
format date %tdDD_Mon_CCYY
gen day = day(date)
gen day_name = day
format day_name %tdDay
gen weekend = day == 1 | day == 2


// Create hours (and remove hours when gym is closed)

expand 24
sort id date 
egen hour = repeat(), values(1/24) by(id)
local open_day 6
local close_day 23
local open_weekend 8
local close_weekend 21
drop if (hour < `open_weekend' | hour > `close_weekend') & weekend == 1
drop if (hour < `open_day' | hour > `close_day') & weekend == 0
sort date day hour


save $fullpanel, replace

// -------------------------
// Retrieve recorded visits
// -------------------------

clear
use $visitdata
keep id_num date hour
rename id_num id
tempfile recorded_visits
save `recorded_visits'

clear
use $fullpanel
merge 1:1 id date hour using `recorded_visits'
gen visit = _merge == 3
drop _merge
save $fullpanel, replace



// --------------------------------------------------------------
// Retrieve remembered exercise hours of pre-intervention period
// --------------------------------------------------------------

clear
use $persondata


// Stack all days

local remdays mondaymay9th tuesdaymay10th wednesdaymay11th thursdaymay12th fridaymay13th saturdaymay14th sundaymay15th mondaymay16th tuesdaymay17th wednesdaymay18th thursdaymay19th fridaymay20th saturdaymay21st sundaymay22nd
local remstack
foreach day of local remdays {
	local remstack `remstack' id_string `day'
}
stack `remstack', into(id_string rem_hour) clear
label var rem_hour "hour of recalled workout or 'No Workout', empty if left blank on survey" 


// Generate time of remembered workout variable

gen time = .
replace time = 5 if rem_hour == "5:00 AM"
replace time = 6 if rem_hour == "6:00 AM"
replace time = 7 if rem_hour == "7:00 AM"
replace time = 8 if rem_hour == "8:00 AM"
replace time = 9 if rem_hour == "9:00 AM"
replace time = 10 if rem_hour == "10:00 AM"
replace time = 11 if rem_hour == "11:00 AM"
replace time = 12 if rem_hour == "Noon"
replace time = 13 if rem_hour == "1:00 PM"
replace time = 14 if rem_hour == "2:00 PM"
replace time = 15 if rem_hour == "3:00 PM"
replace time = 16 if rem_hour == "4:00 PM"
replace time = 17 if rem_hour == "5:00 PM"
replace time = 18 if rem_hour == "6:00 PM"
replace time = 19 if rem_hour == "7:00 PM"
replace time = 20 if rem_hour == "8:00 PM"
replace time = 21 if rem_hour == "9:00 PM"
replace time = 22 if rem_hour == "10:00 PM"
replace time = 23 if rem_hour == "11:00 PM"

gen rem_workout = 1 if rem_hour ~= ""
replace rem_workout = 0 if rem_hour == "No Workout"
label var rem_workout "1 if remembered workout that day, 0 if 'No Workout', missing if left blank"
destring id_string, gen(id)
gen date = td(8 May 2016) + _stack

drop _stack id_string rem_hour
sort id date time
tempfile rem_hours
save `rem_hours'


// Merge into full panel

clear
use $fullpanel

merge m:1 id date using `rem_hours'

gen remembered = .
replace remembered = 1 if time == hour
replace remembered = 0 if rem_workout == 0
replace remembered = 0 if time != hour & !mi(time)
label var remembered "1 if remembered workout for that hour, 0 if no workout that day or workout at other time"

drop time _merge rem_workout

save $fullpanel, replace



// ----------------------------------------------------------
// Retrieve planned exercise sessions of intervention period
// ----------------------------------------------------------


clear
use $persondata


// Stack all days

local plandays tuesdaymay31st wednesdayjune1st thursdayjune2nd fridayjune3rd saturdayjune4th sundayjune5th mondayjune6th tuesdayjune7th wednesdayjune8th thursdayjune9th fridayjune10th saturdayjune11th sundayjune12th
local planstack
foreach day of local plandays {
	local planstack `planstack' id_string `day'
}
stack `planstack', into(id_string plan_hour) clear
label var plan_hour "hour of planned workout, 'No Workout', or empty if left blank on survey"


// Generate time of planned workout variable

gen time = .
replace time = 5 if plan_hour=="5:00 AM"
replace time = 6 if plan_hour=="6:00 AM"
replace time = 7 if plan_hour=="7:00 AM"
replace time = 8 if plan_hour=="8:00 AM"
replace time = 9 if plan_hour=="9:00 AM"
replace time = 10 if plan_hour=="10:00 AM"
replace time = 11 if plan_hour=="11:00 AM"
replace time = 12 if plan_hour=="Noon"
replace time = 13 if plan_hour=="1:00 PM"
replace time = 14 if plan_hour=="2:00 PM"
replace time = 15 if plan_hour=="3:00 PM"
replace time = 16 if plan_hour=="4:00 PM"
replace time = 17 if plan_hour=="5:00 PM"
replace time = 18 if plan_hour=="6:00 PM"
replace time = 19 if plan_hour=="7:00 PM"
replace time = 20 if plan_hour=="8:00 PM"
replace time = 21 if plan_hour=="9:00 PM"
replace time = 22 if plan_hour=="10:00 PM"
replace time = 23 if plan_hour=="11:00 PM"
generat plan_workout = 1 if plan_hour ~= ""
replace plan_workout = 0 if plan_hour == "No Workout"
label variable plan_workout "1 if planned, 0 if 'No Workout', missing if left blank"

destring id_string, gen(id)
gen date = td(30 May 2016) + _stack

drop _stack id_string plan_hour
sort id date time
tempfile plan_hours
save `plan_hours'


// Merge into full panel

clear
use $fullpanel

merge m:1 id date using `plan_hours'

gen planned = .
replace planned = 1 if time == hour
replace planned = 0 if plan_workout == 0
replace planned = 0 if time != hour & !mi(time)
label var planned "1 if planned workout for that hour, 0 if no workout that day or workout at other time"

drop time _merge plan_workout

save $fullpanel, replace



// -----------------------------------------------------------------
// Retrieve useful variables from visit-level and person-level data 
// -----------------------------------------------------------------


// From visit-level data
clear
use $visitdata
desc, f

rename id_num id
rename howmanydaysdoyouexpecttobeoutoft days_out_of_town
rename howmuchdoesyourweeklyroutineofwo routine_variation
rename pleasefeelfreetoshareanycomments comments
tab whattypeofcalendarifanydoyouuset, m gen(calendar)
rename calendar2 calendar_none
rename calendar3 calendar_online
rename calendar4 calendar_paper
rename visits_during visits_during_visit_level

local varstokeep id days_out_of_town routine_variation comments calendar_none calendar_online calendar_paper treatment age gender visits_0 visits_pre2 visits_during_visit_level visits_post

keep `varstokeep'
duplicates drop `varstokeep', force
isid id

tempfile visit_vars
save `visit_vars'


// From person-level data

clear
use $persondata

desc, full

rename schedule_notatall schedule_yes
rename schedule_verymuch schedule_no
rename id_num id
rename doyouthinkyouwouldgotothegymmore believe_in_plan


tab think_plan_eff

local varstokeep believe_in_plan student university secondary grad_init wellness treated control schedule_yes schedule_somewhat schedule_no think_plan_inapplic think_plan_not_eff think_plan_maybe_eff think_plan_is_eff male id

keep `varstokeep'
duplicates drop `varstokeep', force
isid id

tempfile person_vars
save `person_vars'


// Merge into full panel

clear
use $fullpanel

merge m:1 id using `visit_vars', nogen
merge m:1 id using `person_vars', nogen

save $fullpanel, replace


// ------------------------------
// Generate additional variables 
// ------------------------------

// Indicator for study phase

gen phase = ""
replace phase = "Pre" if date < `start_date_intervention'
replace phase = "Post" if date > `end_date_intervention'
replace phase = "During" if phase == ""


// Total visits

bysort id: egen visits_total = total(visit), missing
bysort id: egen visits_during = total(visit) if phase == "During", missing
bysort id: egen total_remembered = total(remembered), missing
bysort id: egen total_planned = total(planned), missing

save $fullpanel, replace



} // End of $buildfull




// ==================================================
// Build aggregate panel (1 observation per subject)
// ==================================================

if $buildaggregate {

// Collapse full panel and count visits

clear
use $fullpanel


// Dates before May 9th are not covered by the survey (May 9th is the beginning of the 2-weeks-before-intervention period and hence the first date for which people were asked to remember workouts.)
drop if date < td(9 May 2016)

tab phase, m

collapse total_visits visits_during total_remembered total_planned, by(id)
bro

reg visits_during total_planned

}


// ========
// Sandbox
// ========

if $sandbox {


clear
use $fullpanel

* order _all, alphabet
* order id date hour
* order comments, last
* sort id date hour

desc, fu


// Consistency checks


// Consistency checks

tab gender male

tab treatment treated, m
tab treatment wellness, m

gen check1 = (visits_during == visits_during_visit_level)
tab check1

gen check2 = (visits_total == visits_0)
tab check2


}








/*
Stuff to do

- Figure out inconsistencies with visits 
- Fix weekday label / weekend definition issue



