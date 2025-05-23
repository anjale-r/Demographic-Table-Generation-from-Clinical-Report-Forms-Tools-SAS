/* Generated Code (IMPORT) */
/* Source File: project.xlsx */
/* Source Path: /home/u64220165 */
/* Code generated on: 4/26/25, 11:30 AM */

%web_drop_table(WORK.project);
/* Step 1: Import the Excel file */
filename reffile '/home/u64220165/project.xlsx';

proc import datafile=reffile
    out=work.project
    dbms=xlsx
    replace;
    getnames=yes;
run;

/* Step 2: Check the structure */
proc contents data=work.project; run;

/* Step 3: Create dob1 from Month, Day, and Year */
data project1;
    set project;

    /* Make sure Month, Day, Year are numeric */
    dob1 = mdy(month, day, year);
    format dob1 mmddyy10.;
    
    age=(diagdt-dob1)/365;
    
    output;
    trt=2;
    output;
run;

/* Step 4: Preview the result */
/*proc print data=demog1 (obs=5); run;*/

proc sort data=project1;
	by trt;
run;

proc means data=project1;
	var age;
	output out=agestats;
	by trt;
run;

data agestats;
	set agestats;
	ord=1;		/*order in the final table*/
	if _stat_='N' then do; subord=1; value=strip(put(age,8.)); end;
	else if _stat_='MEAN' then do; subord=2; value=strip(put(age,8.1)); end;
	else if _stat_='STD' then do; subord=3; value=strip(put(age,8.2)); end;
	else if _stat_='MIN' then do; subord=4; value=strip(put(age,8.1)); end;
	else if _stat_='MAX' then do; subord=5; value=strip(put(age,8.1)); end;
	value= put(age, 8.);
	rename _stat_=stat;
	drop _type_ _freq_ age;
run;

/* Step 5: odtaining the statistical parameters for age groups*/

/* Step 1: Define age group format */
proc format;
  value groupfmt
    low - <18   = '<= 18 years'
    18  - 65    = '18 to 65 years'
    65  - high  = '> 65 years';
run;

/* Step 2: Create age group variable */
data project2;
  set project1;
  age_group = put(age, groupfmt.);
run;

/* Step 3: Get frequency stats by treatment and age group */
proc freq data=project2 noprint;
  tables trt*age_group / outpct out=groupstats;
run;

/* Step 4: Prepare output for report */
data groupstats;
  set groupstats;
  ord = 2;  /* can be used to order stats in final table */

  /* assign ordering within age group */
  if age_group = '<= 18 years' then subord = 1;
  else if age_group = '18 to 65 years' then subord = 2;
  else if age_group = '> 65 years' then subord = 3;

  /* create formatted value column: 12 (34.5%) */
  value = catx(' ', count, '(' || strip(put(pct_row, 5.1)) || '%)');

  rename age_group = stat;
  drop count percent pct_row pct_col;
run;


/* Step 6: odtaining the statistical parameters for gender*/

proc format;
value genfmt
1='Male'
2='Female'
;
run;

data project3;
	set project2;
	
	sex=put(gender, genfmt.);
run;

proc freq data=project3 noprint;
table trt*sex / outpct out=genderstats;
run;

data genderstats;
	set genderstats;
	ord=3;
	if sex='Male' then subord=1;
	else if sex='Female' then subord=2;
	value= cat(count,'(',round(pct_row, .1),'%',')');
	rename sex=stat;
	drop count percent pct_row pct_col;
run;


/* Step 7: odtaining the statistical parameters for race */

proc format;
value racefmt
1='White'
2='Black'
3='Hipsenic'
4='Asian'
5='Others'
;
run;

data project4;
	set project3;
	
	race_new=put(race, racefmt.);
run;

proc freq data=project4 noprint;
table trt*race_new / outpct out=racestats;
run;

data racestats;
	set racestats;
	ord=4;
	if race_new='White' then subord=1;
	else if  race_new='Black' then subord=2;
	else if  race_new='Hipsenic' then subord=3;
	else if  race_new='Asian' then subord=4;
	else if  race_new='Others' then subord=5;
	
	value= cat(count,'(',round(pct_row, .1),'%',')');
	rename race_new=stat;
	drop count percent pct_row pct_col;
run;

/*appending all stats together*/
data allstats;
	set agestats groupstats genderstats racestats;
run;


/* transposing data by treatment groups*/

proc sort data=allstats;
by ord subord stat;
run;

proc transpose data=allstats out=t_allstats prefix=trt_;
var value;
id trt;
by ord subord stat;
run;

data final;
	length stat $50;
	set t_allstats;
	by ord subord;
	output;
	if first.ord then do;
		if ord=1 then stat='Age (years)';
		if ord=2 then stat='Age Groups';
		if ord=3 then stat='Gender';
		if ord=4 then stat='Race';
		subord=0;
		trt_0='';
		trt_1='';
		trt_2='';
		output;	
	end;
run; 

/* sort final data */
proc sort data=final;
by ord subord;
run;

	

proc sql noprint;
	select count(*) into :placebo from project1 where trt=0;
	select count(*) into :active  from project1 where trt=1;
	select count(*) into :total   from project1 where trt=2;
quit;


/* constructing the final report*/

title "Table 1.1";
title2 "Demographic and Baseline Characteristics by Treatment Group";
title3 "Randomized Population";
footnote "Note: Percentages are based on the non-missing values in each treatment group.";


proc report data=final split='|';
	columns ord subord stat trt_0 trt_1 trt_2;
	
	define ord / noprint order;
	define subord / noprint order;
	define stat / display width=80 " ";
	define trt_0 / display width=30 "Placebo| (N=&placebo)";
	define trt_1 / display width=30 "Active Treatment| (N=&active)";
	define trt_2 / display width=30 "All patients| (N=&total)";
run;


%web_open_table(WORK.project);