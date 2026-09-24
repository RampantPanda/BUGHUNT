uptime | awk 'NR==1 {printf "UPTIME %s %s\n",$3,$4}'|sed "s/[,]//g"
