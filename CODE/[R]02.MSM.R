install.packages("msm")
library(msm)
library(haven)
library(dplyr)
library(survival)
library(survminer)

## getting sas data in
setwd("/vol/userdata13/sta_room417/")
multi_df <- read_sas("multi_state_model3.sas7bdat")

max(multi_df$time)
# if event_type = 'mgus' then state=1;
# else if event_type='smm' then state=2;
# else if event_type='mm' then state=3;
# else if event_type='death' then state=4;

# str(multi_df)
# multi_df$status <- as.factor(multi_df$status)
# statetable.msm(status, JID, data=multi_df)

## Specifying a model
q <- 0.25
Q <- rbind(c(0,q,0,q),
           c(0,0,q,q),
           c(0,0,0,q),
           c(0,0,0,0))
qnames <- c("q12", "q14", "q23", "q24", "q34")

Q.crude <- crudeinits.msm(status ~ time, JID, data=multi_df, qmatrix= Q)


# Initial modeling
cav.msm <- msm(status ~ time, subject=JID, data=multi_df, qmatrix = Q.crude, deathexact = 4)
cav.msm
plot(cav.msm)
plot.prevalence.msm(cav.msm)

# Intensity matrix
qmatrix.msm(cav.msm)


# Ratio of transition intensity calcualtion
qratio.msm(cav.msm, ind1 = c(3,4), ind2 = c(2,3))

# Total length of stay
totlos.msm(cav.msm)

# Stacked plot
stacked.plot.msm(model=cav.msm, tstart = 0, tforward= 5000, tseqn = 6) +
  scale_fill_manual(
    values = c("salmon", "Yellow Green", "Deep Sky Blue", "Medium purple"),
    labels = c("MGUS", "SMM", "MM", "Death")
  ) + 
  ggtitle("Stacke plot of MM Progression") +
  theme_bw()


