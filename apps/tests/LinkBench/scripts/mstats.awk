function line_filter() { 
  gsub(/[^0-9]/," "); 
  gsub(/ +/," "); 
  sub(/^ /,"");
}

BEGIN { FS="[<|>| ]"; skip=1; cnt=0; }
/<benchidx>/ { 
  if ($3 == benchmark) {
    bidx=$3;
    statstr=profstr=timerstr="";
    skip = 0;
  } else 
    skip = 1;
}

/<pre_runtime>/ { pre_runtime = $3; }
/<runtime>/ { runtime = $3; }
/<post_runtime>/ { post_runtime = $3; }
/<ack>On<\/ack>/ { ack=1; }
/<ack>Off<\/ack>/ { ack=0; }
/<bcast>On<\/bcast>/ { bcast=1; }
/<bcast>Off<\/bcast>/ { bcast=0; }

/<timer.*oneshot="yes"/ { if (!skip) { line_filter(); timerstr=sprintf("%s;[ %d %d %d]",timerstr,1,$2,$3);} }
/<timer.*oneshot="no"/ { if (!skip) { line_filter(); timerstr=sprintf("%s;[ %d %d %d]",timerstr,0,$2,$3);} }

/<stat idx/ { if (!skip) { line_filter(); statstr=sprintf("%s;%s",statstr,$0); } }
/<profile idx/ { if (!skip) { line_filter(); profstr=sprintf("%s;%s",profstr,$0); } }
/<error>/ { if ($3!="") skip=1; }

/<\/testresult>/ { if (!skip) {
  if (svn) {
    printf "RES.stats(:,:,%d,%d) = [%s];\n",++cnt,svn,statstr;
    printf "RES.profiles(:,:,%d,%d) = [%s];\n",cnt,svn,profstr;
    printf "RES.timers(:,:,%d,%d) = [%s];\n",cnt,svn,timerstr;
  } else {
    printf "RES.stats(:,:,%d) = [%s];\n",++cnt,statstr;
    printf "RES.profiles(:,:,%d) = [%s];\n",cnt,profstr;
    printf "RES.timers(:,:,%d) = [%s];\n",cnt,timerstr;
  }
}}

END {
  printf "RES.config.bidx = %d;\n",bidx;
  printf "RES.config.pre_runtime = %d;\n",pre_runtime;
  printf "RES.config.runtime = %d;\n",runtime;
  printf "RES.config.post_runtime = %d;\n",post_runtime;
  printf "RES.config.bcast = %d;\n",bcast;
  printf "RES.config.ack = %d;\n",ack;
  printf "RES.name = 'RES';\n";
}
