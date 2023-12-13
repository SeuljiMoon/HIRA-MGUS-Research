/***********************Multi state model ********************/

data mgus_final; set aa.mgus_outcci_death;
mgus=1;
run;
proc sort data=mgus_final; by jid; run;

data smm_final; set aa.smm_outcci_death;
smm=1;
run;
proc sort data=smm_final; by jid; run;

data mgus_smm_final; 
merge mgus_final smm_final;
by jid;
run;

data a; set mgus_smm_final;
format first_c90_date yymmdd8.;
keep jid first_c90_date c90_medi_date total_mm_outcome mm_outcome mgus mgus_index_date smm smm_index_date death_yn death_date; run;

/*cohort definition*/
data multi_state; set mgus_smm_final;
format first_c90_date yymmdd8.;
if mgus=1 and smm=. then cohort=1; 
else if smm=1 and mgus=. then cohort=2;
else if mgus=1 and smm=1 and mgus_index_date < smm_index_date then cohort=3 ;

run;

proc freq data=multi_state; table cohort; run;
/*1 = 5,869 
	2= 6,808  (1&2, Áï mgus¿¡¼­ smm => 206¸í)*/ 


/*outcome definition*/
data multi_state2; set a;
format event_date yymmdd8.;
format event_type $8.;
outcome = 0;  /*mm ¹ß»ý or death ¹ß»ý È®ÀÎ*/

if mgus_index_date ne . then do ;
	event_date = mgus_index_date;
	event_type ='mgus';
	output;
end; 

if smm_index_date ne . then do ;
	event_date = smm_index_date;
	event_type = 'smm' ;
	output;
end;

if c90_medi_date ne . then do ;
	event_date = c90_medi_date;
	event_type = 'mm' ;
	outcome = 1; 
	output;
end;

if death_date ne . then do;
	event_date = death_date;
	event_type = 'death';
	outcome = 2; 
	output;
end;

if outcome = 0 then do ;
	event_date = mdy(11,30,2022) ;
	event_type = 'censor' ;
	output;
end;
run;

data aa.multi_state_model; set multi_state2;
by jid; 

retain first_event_date;
if first.jid then first_event_date = event_date; 

if event_type = 'mgus' then state=1;
else if event_type='smm' then state=2;
else if event_type='mm' then state=3;
else if event_type='death' then state=4;
else if event_type='censor' then state=5;

if event_date ne . then time = (event_date - first_event_date);
else time = . ;

keep jid event_type state time;
run;

/* End state point : Death */
proc sql;
create table multi_model_max as
select *, max(state) as max_state
from aa.multi_state_model
group by jid;
quit;

data aa.multi_state_model3; set multi_model_max;
status = state;
if state=0 then status=max_state; 
run;

proc sort data=aa.multi_state_model3; by jid time; run;

/*Check time from death to else state */
data a; set aa.multi_state_model3;
lag_time=lag(time);
by jid;
retain lag_time;
if first.jid then lag_time=lag(time); 
run;

data b; set a;
where time < lag_time ; run;

proc sql; 
create table check_df as
select a.jid, b.* 
from a as a 
left join multi_state2 as b on a.jid=b.jid; 
quit;





