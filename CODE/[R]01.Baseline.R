install.packages("sas7bdat")
install.packages("moonBook")
install.packages("haven")
install.packages("officer")
install.packages("ReporteRs")
library(sas7bdat)
library(dplyr)
library(moonBook)
library(haven)
library(data.table)
library(survival)
library(ggplot2)
library(RColorBrewer)

library(scales) ; 
library(rvg);
library(officer)

library(survminer)
library(cmprsk)
library(survminer)
library(rlang)

R.version

#### Read dataset
setwd("/vol/userdata13/sta_room417/")
mgus <- read_sas("mgus_outcci_death.sas7bdat")
smm <- read_sas("smm_outcci_death.sas7bdat")

colnames(mgus)

mgus$ageg4 <- ifelse(mgus$index_age<60,1,ifelse(mgus$index_age<70,2,ifelse(mgus$index_age<80,3,4)))
mgus$index_year <- substr(mgus$mgus_index_date,1,4)
mytable(mm_outcome~SEX_TP_CD+index_age+ageg4+mi_yes+chf_yes+pvd_yes+cvd_yes+dem_yes+cpd_yes+rhe_yes
                    +pud_yes+mld_yes+dwoc_yes+dwcc_yes+hp_yes+rd_yes+cancer_yes+sld_yes+mst_yes+aids_yes+
          death_yn+index_year+DIV_CD,data=mgus)
mytable(total_mm_outcome~SEX_TP_CD+index_age+ageg4+mi_yes+chf_yes+pvd_yes+cvd_yes+dem_yes+cpd_yes+rhe_yes
        +pud_yes+mld_yes+dwoc_yes+dwcc_yes+hp_yes+rd_yes+cancer_yes+sld_yes+mst_yes+aids_yes+
          death_yn+index_year+DIV_CD,data=mgus)


smm$ageg4 <- ifelse(smm$index_age<60,1,ifelse(smm$index_age<70,2,ifelse(smm$index_age<80,3,4)))
smm$index_year <- substr(smm$smm_index_date,1,4)
mytable(mm_outcome~SEX_TP_CD+index_age+ageg4+mi_yes+chf_yes+pvd_yes+cvd_yes+dem_yes+cpd_yes+rhe_yes
        +pud_yes+mld_yes+dwoc_yes+dwcc_yes+hp_yes+rd_yes+cancer_yes+sld_yes+mst_yes+aids_yes+
          death_yn+index_year+DIV_CD,data=smm)



####### surv ##########
mgus_surv <- read_sas("mgus_surv.sas7bdat")

mgus_surv$event<-factor(mgus_surv$death_yn,levels=c(0,1))
mgus_surv$group <-factor(ifelse(mgus_surv$mm_outcome==0,2,1),levels=c(1,2)) # 1: case, 2:control

fit_entire <- survfit(Surv(death_year,event==1)~group, data=mgus_surv)


a <- jskm(fit_entire, ci = T,cumhaz = F, mark = F,ystrataname = "Group", surv.scale = "percent", table = T,pval =T,showpercent=T,
     legendposition=c(0.2,0.3),xlims=c(0,10),timeby=1, main="Survival curve - mgus")
a
editable_graph <- rvg::dml(ggobj=a)
doc<-read_pptx()
doc<-add_slide(doc)
doc<-ph_with(x=doc, editable_graph,
             location=ph_location_type(type="body"))
print(doc, target="/vol/userdata13/sta_room417/1204_surv_mgus_jskm_plot.pptx")



smm_surv <- read_sas("smm_surv.sas7bdat")

smm_surv$event<-factor(smm_surv$death_yn,levels=c(0,1))
smm_surv$group <-factor(ifelse(smm_surv$mm_outcome==0,2,1),levels=c(1,2)) # 1: case, 2:control

fit_entire <- survfit(Surv(death_year,event==1)~group, data=smm_surv)


a <- jskm(fit_entire, ci = T,cumhaz = F, mark = F,ystrataname = "Group", surv.scale = "percent", table = T,pval =T,showpercent=T,
          legendposition=c(0.2,0.3),xlims=c(0,10),timeby=1, main="Survival curve - smm")
a






####### C90 ##########
c90_surv <- read_sas("c90_death_df.sas7bdat")
as.data.table(c90_surv)

c90_surv$event<-factor(c90_surv$death_yn,levels=c(0,1))
c90_surv$surv<-as.numeric(c90_surv$death_year)
# c90_surv$group <-factor(ifelse(c90_surv$mm_outcome==0,2,1),levels=c(1,2)) # 1: case, 2:control

attach(c90_surv)
surv_object <- Surv(time=death_year, event = event==1)
fit <- survfit(surv_object ~ 1)


a <- jskm(fit, ci = T,cumhaz = F, mark = F,ystrataname = "Group", surv.scale = "percent", table = T,pval =T,showpercent=T,
          legendposition=c(0.2,0.3),xlims=c(0,14),timeby=1, main="Survival curve (cut 10 years)")

a







