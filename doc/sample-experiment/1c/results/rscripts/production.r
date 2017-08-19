theme_set(theme_bw(18))
setwd("~/Dropbox/Tuebingen17SS/RA/woq/experiments/1c/results")
setwd("~/cogsci/projects/stanford/projects/woq/experiments/1c/results")
source("rscripts/helpers.r")

d = read.table(file="data/production.csv",sep=",", header=T)
head(d)
nrow(d)
summary(d)
totalnrow = nrow(d)
d$Trial = d$slide_number_in_experiment - 1
d$Half = as.factor(ifelse(d$Trial < 14, "first","second"))
length(unique(d$workerid))

# look at turker comments
unique(d$comments)

ggplot(d, aes(rt)) +
  geom_histogram() +
  scale_x_continuous(limits=c(0,50000))

ggplot(d, aes(log(rt))) +
  geom_histogram() 

summary(d$Answer.time_in_minutes)
ggplot(d, aes(Answer.time_in_minutes)) +
  geom_histogram()

ggplot(d, aes(gender)) +
  stat_count()

ggplot(d, aes(asses)) +
  stat_count()

ggplot(d, aes(age)) +
  geom_histogram()

ggplot(d, aes(education)) +
  geom_histogram()

ggplot(d, aes(language)) +
  stat_count()

ggplot(d, aes(languages)) +
  stat_count()

ggplot(d, aes(count)) +
  stat_count()

ggplot(d, aes(colorblind)) +
  stat_count()

ggplot(d, aes(enjoyment)) +
  geom_histogram()

d$response = tolower(d$response)
d$response1 = sapply(strsplit(as.character(d$response),", "), "[", 1)
d$response1 = gsub("\\[u''","NA",as.character(d$response1))
d$response1 = gsub("\\[u'","",as.character(d$response1))
d$response1 = as.factor(as.character(gsub("'","",as.character(d$response1))))

d$response2 = sapply(strsplit(as.character(d$response),", "), "[", 2)
d$response2 = gsub("u''","NA",as.character(d$response2))
d$response2 = gsub("u'","",as.character(d$response2))
d$response2 = as.factor(as.character(gsub("'","",as.character(d$response2))))

d$response3 = sapply(strsplit(as.character(d$response),", "), "[", 3)
d$response3 = gsub("u''\\]","NA",as.character(d$response3))
d$response3 = gsub("u'","",as.character(d$response3))
d$response3 = as.factor(as.character(gsub("'\\]","",as.character(d$response3))))

d$proportion = d$n_target/d$n_total
d$proportion_binned = cut(d$proportion,c(-.0001,.0001,.1,.2,.3,.4,.499,.501,.6,.7,.8,.9,.999,1))
summary(d)
table(d$proportion)
table(d$proportion_binned)

nums = d %>%
  select(proportion,proportion_binned) %>%
  group_by(proportion_binned) %>%
  summarise(Count=length(proportion))
nums = as.data.frame(nums)

ggplot(d, aes(x=proportion)) +
  geom_histogram(binwidth=.01) +
  facet_wrap(~proportion_binned) +
  geom_text(data=nums,aes(label=Count,x=.5,y=30))
ggsave("graphs/proportion_dist.pdf")

gathered = d %>% 
  select(response1,response2,response3,proportion_binned,n_total) %>%
  gather(Order,Utterance,response1:response3,-proportion_binned,-n_total) 
head(gathered)
#gathered = as.factor(as.character(gathered))
#gathered = gathered[order(gathered[,c("Count")],decreasing=T),]
gathered$n_total = as.factor(as.character(gathered$n_total))
gathered$Utterance = gsub("(^ +| +$)","",gathered$Utterance,perl=T)
length(unique(gathered$Utterance))

utts_describe = unique(gathered$Utterance)

# This part of code seems to be a comparison betwen 1a and 1b, which I'm not sure if can be carried out here.
# length(c(utts_describe,utts_howmany))
# length(unique(c(utts_describe,utts_howmany)))
# unique_utts_total = unique(c(utts_describe,utts_howmany))
# common_utts = intersect(utts_describe,utts_howmany)
# write.table(unique_utts_total,file="data/unique_utts_exps1a1b.txt",row.names=F,quote=F,col.names=F)
# write.table(utts_describe,file="data/unique_utts_exp1b_describe.txt",row.names=F,quote=F,col.names=F)
# write.table(utts_howmany,file="data/unique_utts_exp1a_howmany.txt",row.names=F,quote=F,col.names=F)
# write.table(sort(common_utts),file="data/utts_common_to_exps1a1b.txt",row.names=F,quote=F,col.names=F)


ggplot(gathered, aes(x=Utterance,fill=n_total)) +
  stat_count(position="dodge") +
  facet_wrap(~proportion_binned,scales="free_x") +
  theme(axis.text.x=element_text(angle=45,vjust=1,hjust=1))
ggsave("graphs/utterance_dist_bytotal.pdf",height=25,width=25)

ggplot(gathered, aes(x=Utterance)) +
  stat_count() +
  facet_wrap(~proportion_binned,scales="free_x") +
  theme(axis.text.x=element_text(angle=45,vjust=1,hjust=1))
ggsave("graphs/utterance_dist.pdf",height=25,width=25)

ggplot(gathered, aes(x=Utterance)) +
  stat_count() +
  facet_grid(n_total~proportion_binned,scales="free_x") +
  theme(axis.text.x=element_text(angle=45,vjust=1,hjust=1,size=6))
ggsave("graphs/utterance_dist_total.pdf",height=15,width=45)


## MF: trying to inspect choices for particular conditions

table(droplevels(filter(d, n_total == 10, n_target == 3)$response1))

## JD : trying to get sense for the most frequently produced utterances (out of the 357 uniquely produced ones)
gathered = d %>% 
  select(response1,response2,response3,proportion,n_total) %>%
  gather(Order,Utterance,response1:response3,-proportion,-n_total) 
gathered$Utterance = gsub("(^ +| +$)","",gathered$Utterance,perl=T)
length(unique(gathered$Utterance))
sorted = as.data.frame(sort(table(gathered$Utterance),decreasing=T))
head(sorted,60)
top_alts = as.character(sorted$Var1[2:31])
top_alts

top = droplevels(gathered[gathered$Utterance %in% top_alts,])
top$Utterance = factor(x=as.character(top$Utterance, levels=top_alts))
nrow(top)
ggplot(top, aes(x=proportion,fill=factor(n_total))) +
  stat_count(width=.05) +
  facet_wrap(~Utterance)
ggsave("graphs/top30.pdf",height=10,width=15)
