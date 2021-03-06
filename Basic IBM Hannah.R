#Basic IBM
#rm(list=ls())

#USED INDIC######
#   replication -r
#   loci/traitv.-x,y,z    
#   genertion   -t
#   partner     -u
#   gentics     -o,p
#   survival    -v
#   gender loop -g

##### PARAMETERS #####
replic<-1 #replicates
Nt<-1 #generations
mig <- 0.05 #migrationfactor
max.Age<-1 # age limit

#fecundity
a <-  0.49649467
b  <-  1.47718931
c1    <-  0.72415095
c2    <- -0.24464625
c3    <-  0.99490196
c4    <- -1.31337296
c5    <- -0.06855583
c6    <-  0.32833236
c7    <--20.88383990
c8    <- -0.66263785
c9    <-  2.39334027
c10   <-  0.11670283

##### FUNCTIONS #####
w<-function(a,b,z,N,Np){
  y=a+b*plogis(c1+c2*N+c3*z+c4*(0.5*N-Np)+c5*N^2+c6*z^2+c7*(0.5*N-Np)^2+c8*z*N+c9*z*(0.5*N-Np)+c10*N*(0.5*N-Np))
  return(y)
}


##### PATCHES #####
N1<-abs(round(rnorm(1, mean=250, sd=10))) #patch 1 is drawn 
N2<-abs(round(rnorm(1, mean=250, sd=10))) #patch 2 is drawn
N1.m<-round(runif(1,N1/4,3*N1/4)) #males in patch 1
N2.m<-round(runif(1,N1/4,3*N1/4)) #males in patch 2

ID <- c(1:(N1+N2)) #vector ID: gives each individual an ID
patch<-c(rep(1,N1),rep(2,N2)) #vector patch: is filled with patch 1 (=1) and patch 2 (=2)
gender<-c(rep("male",N1.m),rep("female",N1-N1.m),rep("male",N2.m),rep("female",N2-N2.m)) #vector gender: is filled with males and females
trait<-c(rep(0.5,N1),rep(0.5,N2)) #vector trait: is for all individuals from both patches set as 5
survival<-c(rep(max.Age,N1),rep(max.Age,N2)) #vector survival: is for all new individuals of both patches 1

pop<-data.frame(ID,patch,gender,trait,survival) #data frame including all individuals out of both patches with the columns: patch, trait & survival


##### VECTORS #####
pop.N1.vector <- rep(0,Nt) #empty vector for the populationsize of each generation in patch 1
pop.N2.vector <- rep(0,Nt) #empty vector for the populationsize of each generation in patch 2
trait.N1.vector <- rep(0,Nt) #empty vector for the average trait-value of each generation in patch 1
trait.N2.vector <- rep(0,Nt) #empty vector for the average trait-value of each generation in patch 2

pop.N1.vector[1] <- N1 #populationsize for the first generation of patch 1
pop.N2.vector[1] <- N2 #populationsize for the first generation of patch 2
trait.N1.vector <- mean(pop$trait[pop$patch==1]) #average trait-value for the first generation of patch 1
trait.N2.vector <- mean(pop$trait[pop$patch==2]) #average trait-value for the first generation of patch 2


##### REPLICATION LOOP START#####

for(r in 1:replic){
  
  population <- round(N1) + round(N2) #number of individuals
  loci <- matrix(NA,nrow=population,ncol=20+1) #empty matrix for the locis
  for(x in 1:population){ #for each individual
    loci[x,] <- round(runif(21,1,10)) #each individual has 20 random numbers (first 10:row //last 10:column)
    loci[x,21] <- x
  }
  
  values <- matrix(NA,nrow=population,ncol=10) #empty matrix for the trait values for each loci
  for(y in 1:population){ #for each individual
    for(z in 1:10){ 
      values[y,z] <- gen_phen_map[z,loci[y,z],loci[y,10+z]]
    }
    pop[y,4] <- abs(sum(values[y,])) ##### USE OF COLUMN.NR
  }
  
  
  ##### GENERATION LOOP START #####  
  for(t in 2:Nt){
    N1<-nrow(subset(pop,pop$patch==1)) #N1 is every generation overwritten to keep updated 
    N2<-nrow(subset(pop,pop$patch==2)) #N2 is every generation overwritten to keep updated
    N<-c(nrow(pop)) #how many individuals there are in both patches
    
    
    ##### MATRICES #####
    N.w <- subset(pop,pop$gender=="female") #female individuals in total
    N1.w <- subset(pop,pop$gender=="female"&pop$patch==1) #female individuals from patch 1
    N2.w <- subset(pop,pop$gender=="female"&pop$patch==2) #female individuals from patch 2
    N1.m <- subset(pop,pop$gender=="male"&pop$patch==1) #male individuals from patch 1
    N2.m <- subset(pop,pop$gender=="male"&pop$patch==2) #male individuals from patch 
    
    
    ##### OFFSPRING #####
    N.0<-N/500
    N.l <- c(N1/500,N2/500) # vector of local population sizes
    
    if(nrow(N.w)>0){ #number of offspring per female
      Nchild <- rpois(nrow(N.w),w(a,b,N.w$trait,N.0,N.l[N.w$patch])) #each female gets a random number of offspring
    }
    
    ID.children <- c(rep(0,sum(Nchild))) #empty vector for the ID
    patch.children <- c(rep(0,sum(Nchild))) #empty vector for the patch
    gender.children <- c(rep(0,sum(Nchild))) #empty vector for the gender
    trait.children <- c(rep(0,sum(Nchild))) #empty vector for the trait
    survival.children <- c(rep(max.Age,sum(Nchild))) #each child gets the survival of the maximum age
    pop.new <- data.frame(ID.children,patch.children,gender.children,trait.children,survival.children)
    
    loci.new <- c() #empty vector: children locis
    
    #### START LOOP PARTNERFINDING #####
    patchbook <- c()
    gendergram <- c()
    
    for(u in 1:nrow(N.w)){ #loop mother 
      if(Nchild[u]>0){ #just if the mother becomes offspring
        mother<-N.w$ID[u] #gives the ID of the mother
        
        ###FATHER####
        if(N.w[u,2]<2){ ###==1    #USE OF COLUMN.NR
          father <- sample(N1.m$ID,size=1) #samples one ID out of patch 1
        }else{
          father <- sample(N2.m$ID,size=1) #samples one ID out of patch 2
        }
        
        #GENETICS:
        loci.mother <- subset(loci,loci[,21]==mother) #vector of locis of the mother
        loci.father <- subset(loci,loci[,21]==father) #vector of locis of the father
        loci.child <- rep(0,ncol(loci)) #empty vector with fixed length
        
        for(o in 1:Nchild[u]){ #for loop for the number of children per female
          for(p in 1:(10)){ #loop over the 10 locis
            if(runif(1,0,1)>0.5){ #if the random number is higher then 0.5:
              loci.child[p] <- loci.mother[p] #child gets the top allel (spot p) from mother
            } else{
              loci.child[p] <- loci.mother[10+p] #child gets the bottom allel (spot 10+p) from mother
            }
            if(runif(1,0,1)>0.5){ #if the random number is higher then 0.5:
              loci.child[10+p] <- loci.father[p] #child gets the top allel (spot p) from father
            } else{
              loci.child[10+p] <- loci.father[10+p] #child gets the bottom allel (spot 10+p) from mother
            }
          } #end loop 10 locis
          loci.new <-  rbind(loci.new,loci.child) #connects loci of the child to the matrix of the other children
          
          if(runif(1,0,1)>0.5){ #if random number is higher als 0.5, child is female
            gendergram <- c(gendergram,"female")  
          } else{ #it is male
            gendergram <- c(gendergram,"male")     
          }
        } #END LOOP NUMBER CHILDREN
        patchbook <- c(patchbook, rep(subset(pop,pop$ID==mother)[2],Nchild[u])) #each kid gets the patch of the mother
      }
    } #END LOOP PARTNERFINDING/mother
    
    pop.new$gender.children <- gendergram #gender of the children are written into the matrix
    pop.new$patch.children <- patchbook #patches of children are written into the matrix
    colnames(pop.new)<-c("ID","patch","gender","trait","survival") #colum names
    
    values.new <- matrix(NA,nrow=sum(Nchild),ncol=10) #empty matrix for the trait values for each loci
    for(d in 1:sum(Nchild)){ #for each individual offspring
      for(f in 1:10){ 
        values.new[d,f] <- gen_phen_map[f,loci[d,f],loci[d,10+f]]
      }
      pop.new[d,4] <- abs(sum(values.new[d,])) ##### USE OF COLUMN.NR
    }
    
    
    pop<-rbind(pop,pop.new)
    rownames(pop) <- 1:nrow(pop)
    loci<-rbind(loci,loci.new)
    
    ##### DEATH START #####
    pop$survival[1:N]<-pop$survival[1:N]-1 #every adult loses one survival counter
    for(v in 1:nrow(pop)){ #for each individual
      if(pop[v,5]==0){ #if the survival is 0, it replaces the first loci with -2
        loci[v,1] <- -2
      }
    }
    
    loci <- subset(loci,loci[,1]>(-2 )) #all rows with a -2 in the beginning are deleted
    pop <-subset(pop,pop$survival>0) #Individuals which have a survival higher then 0 stay alive in the dataframe
    ##### END DEATH #####
    
    
    ##### MIGRATION START #####
    mig.N1 <- runif(nrow((subset(pop,pop$patch==1))),0,1) #draws so many uniformmly distributed numbers as there are individuals in patch 1
    mig.N2 <- runif(nrow((subset(pop,pop$patch==2))),0,1) #draws so many uniformmly distributed numbers as there are individuals in patch 2
    
    mig.N1 <- ifelse(mig.N1>mig,1,2) #the individuals with a random number lower then the migration rate get the value 2 (migrates to patch 2) & and the ones higher as the migration rate get the value 1 (dont migrate, stay in patch 1)
    mig.N2 <- ifelse(mig.N2>mig,2,1) #the individuals with a random number lower then the migration rate get the value 1 (migrate to patch 1) & and the ones higher as the migration rate get the value 2 (dont migrate,stay in patch 2)
    
    migration<-c(mig.N1,mig.N2)
    pop$patch<-migration
    
    pop$ID<-c(1:nrow(pop))#new ID for the population
    rownames(pop) <- 1:nrow(pop) #re-indexing the population to prevent 1.1.3.2.4.....
    loci[,21]<-c(1:nrow(pop))#new ID for the loci
    chaos<-order(pop$patch) #vector of indices to orderd after patches
    pop<-pop[chaos,] #order the pop matrix
    
    
    sorting <- c() #
    for(h in 1:nrow(pop)){
      sorting <- rbind(sorting, subset(loci,loci[21]==pop[h,1]))
    }
    loci <- sorting
    
    rownames(pop) <- 1:nrow(pop) #re-indexing the population to prevent 1.1.3.2.4.....
    pop$ID<-c(1:nrow(pop))#new ID for the population
    loci[,21]<-c(1:nrow(pop))#new ID for the loci
    ##### MIGRATION END #####
    
    
    #pop.N1.vector[t] <-sum(pop$patch==1) #overwrites the populationsizes for each generation in the empty vector (patch 1)
    #pop.N2.vector[t] <-sum(pop$patch==2) #overwrites the average trait-value for each generation in the empty vector (patch 2)
    #trait.N1.vector[t] <- mean(pop$trait[pop$patch==1]) #overwrites the average trait-value for each generation in the empty vector (patch 1)
    #trait.N2.vector[t] <- mean(pop$trait[pop$patch==2]) #overwrites the average trait-value for each generation in the empty vector (patch 2)
  } ##### GENERATION LOOP END #####
  
  #pdf(paste("graph",r,".pdf",sep=""))
  #plot(pop.N1.vector, main="populationsize over the generations",xlab="generations",ylab="populationsize",type="l",col="darkorange3") #plot populationsize
  #lines(pop.N2.vector,type="l",col="green") #includes the populationsize of patch 2
  #legend("topright",legend=c("patch 1","patch 2"),lty=1,col=c("darkorange3","green"))
  #dev.off()
  #  print(r)
}
##### REPLICATION LOOP END#####


##### PLOTS #####

#plot(trait.N1.vector,main="average trait-value over the generations", xlab="generations",ylab="average trait-value",type="l",col="red") #plot traitvalue
#lines(trait.N2.vector,type="l",col="blue") #includes the average trait-value of patch 2
#legend("topright",legend=c("patch 1","patch 2"),lty=1,col=c("red","blue"))

