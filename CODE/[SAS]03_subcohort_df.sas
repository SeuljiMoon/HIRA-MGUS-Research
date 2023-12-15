libname aa '/vol/userdata13/sta_room417' ;
libname bb '/vol/userdata13/sta_room417/MSJ' ;

/********************************************************************************
****************** Sub cohort 1: MGUS -> SMM -> MM **********************
*********************************************************************************
Dataset: aa.mgus_drug_df
Definition : total_mm_outcome =1 and mm_outcome = 1
*********************************************************************************
*********************************************************************************/
data aa.mgus_sub; set aa.mgus_drug_df;
where total_mm_outcome =1 and mm_outcome =1 ;
run;



/********************************************************************************
****************** Sub cohort 2: SMM -> MM (D472 X)  **********************
*********************************************************************************
*********************************************************************************
*********************************************************************************/


/************ SMM Patients*************/
/* 1. SMM 주상병 진단
proc sql;
create table smm as
select *, count(*) as cnt_smm_main
from aa.T200_2023Q4_18
where substr(main_sick,1,3) = 'C90'
group by jid
order by jid, RECU_FR_DD; 
quit;
proc sort data=smm nodupkey out=smm_once; by jid; run; /*n=31,769*/

/* 2. SMM only once 제외
proc freq data= smm_once; table cnt_smm_main; run; /*cnt_smm_main=1 n=4,406*/
/*data smm_once_ex; set smm_once;
where cnt_smm_main >=2 ; run; /*n=27,363*/


/* 3. 2007년, 2008년 diagnosis 제외
data smm_wash; set smm_once_ex;
if substr(RECU_FR_DD,1,4) in ('2007', '2008') then ex_smm_wash=1; else ex_smm_wash=0; run;
proc freq data= smm_wash; table ex_smm_wash; run;*/ /*ex_smm_wash=1 n=3,767*/
/*
data aa.smm_wash_ex; set smm_wash;
where ex_smm_wash=0; 
smm_index_date = mdy(substr(RECU_FR_DD,5,2), substr(RECU_FR_DD,7,2), substr(RECU_FR_DD,1,4)); format smm_index_date yymmdd8. ;
drop ex_smm_wash ; run; n=23,596*/

/* 4. C90 진단 후 60일 이내 약 처방 제외*/

/* SMM + 처방 
proc sql;
create table aa.smm_drug as
select a.jid, a.smm_index_date, b.* 	  
from aa.smm_wash_ex  as a 
left join aa.T530_T300_mm as b
on a.jid=b.jid; 
quit;

proc sort data=aa.smm_drug; by jid drug_date; run;

proc sql;
create table smm_drug_yes as
select *,
	(drug_date - smm_index_date) as drug_diff,
	case when
		calculated  drug_diff <=60 
			and div_cd in ('189901ATB', '463301BIJ', '463302BIJ', '463303BIJ', '485701ACH', '485702ACH',
				   '588201ACH', '588201ATB', '588202ACH', '588202ATB', '588203ACH', '588203ATB', 
				   '588204ACH', '588204ATB', '588205ACH', '588205ATB', '588206ACH', '588206ATB',
				   '588207ACH', '588207ATB') then 1
	when drug_date=. then . else 0 
				   end as drug_yes
from aa.smm_drug;
quit; 

proc sort data=smm_drug_yes; by jid descending drug_yes drug_diff; run;
proc sort data=smm_drug_yes nodupkey out=smm_drug_yes2; by jid ; run; 
proc freq data=smm_drug_yes2; table drug_yes; run;

data aa.smm_drug_ex; set smm_drug_yes2;
where drug_yes^=1;
keep jid smm_index_date;
run; /*n=8,474*/

/* SMM + 상병내역 
proc sql;
create table smm_cohort_dig as
select a.jid, a.smm_index_date, b.SEX_TP_CD, b.PAT_AGE, b.YID,
		  b.FOM_TP_CD, b.MAIN_SICK, b.SUB_SICK, b.RECU_FR_DD, b.RECU_TO_DD, b.DGRSLT_TP_CD, b.PRCL_SYM_TP_CD
from aa.smm_drug_ex  as a 
left join aa.t200_2023q4_18 as b
on a.jid=b.jid; 
quit;*/

/* + 처방
proc sql;
create table aa.smm_dig_drug as
select a.*, b.drug_date, b.DIV_CD 
from smm_cohort_dig  as a 
left join aa.T530_T300_mm as b
on a.jid=b.jid; 
quit;

data aa.smm_dig_drug; set aa.smm_dig_drug;
dig_date = mdy(substr(RECU_FR_DD,5,2), substr(RECU_FR_DD,7,2), substr(RECU_FR_DD,1,4)); format dig_date yymmdd8.;
dig_end_date = mdy(substr(RECU_TO_DD,5,2), substr(RECU_TO_DD,7,2), substr(RECU_TO_DD,1,4)); format dig_end_date yymmdd8.;
drop recu_fr_dd; run;*/

/* (추가) 5. C90 진단 이전 D472 진단 제외 -> 여기서 ID 뽑고, aa.smm_drug_df 이 데이터셋에서 대상자만 추출*/
proc sql;
create table d472_before as
select jid,smm_index_date, dig_date, main_sick, 
		max(case when substr(main_sick,1,4) = 'D472' and (dig_date-smm_index_date) <= 0 then 1 else 0 end) as d472_before 
from aa.smm_dig_drug
group by jid
order by jid, dig_date;
quit;

proc sort data=d472_before nodupkey out=d472_before_id; by jid; run; 
proc freq data=d472_before_id; table d472_before; run;

proc sql;
create table smm_d472 as
select b.jid, b.d472_before, a.*
from aa.smm_drug_df as a
left join d472_before_id as b on b.jid=a.jid;
quit;

proc freq data=smm_d472; table d472_before; run;

data aa.smm_sub; set smm_d472;
where d472_before =0 ; run;

proc freq data=aa.smm_sub; table mm_outcome; run;

