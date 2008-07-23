%load file written out by FtspDataLogger.java class
%arg0 - filename, e.g. '1205543689171.report'
function FTSPDataAnalyzer(file, varargin)
[c1 c2 c3 c4 c5]= textread(file, '%u %u %u %u %u', 'commentstyle', 'shell');
data = [c2 c3 c4 c5]; %skipping the first column (java time)
data1 = sortrows(sortrows(data,1),2);
newdata = [];

row=1;
newrow=1;
unsynced=0;
while (row<=size(data1,1))

    seqnum=data1(row,2);

    data2=[];
    row2=1;
    tmprow1=row;
    while (row <= size(data1,1) && data1(row,2)==seqnum)
        if (data1(row,4)==0)
            data2(row2,1)=data1(row,3);
            row2= row2+ 1;
        else
            unsynced=unsynced+1;
        end
        row = row + 1;
    end
    
    if (row2>1)
        row2size=row2-1;
        rcvdsize=row-tmprow1;
        newdata(newrow,1) = seqnum;
        newdata(newrow,2) = mad(data2(1:row2size,1));
        newdata(newrow,3) = mean(data2(1:row2size,1));
        newdata(newrow,4) = row2size/rcvdsize;
        newrow = newrow + 1;
    end
end

if (length(newdata)==0)
    disp('no data found (at least one data point from a synchronized mote is required)!');
else
    newsize=newrow-1;
    subplot(3,1,1);
    plot(newdata(1:newsize,1),newdata(1:newsize,2));
    title(sprintf('TimeSync Errors'));
    subplot(3,1,2);
    plot(newdata(1:newsize,1),newdata(1:newsize,3));
    title(sprintf('Avg Glob Time'));
    subplot(3,1,3);
    plot(newdata(1:newsize,1),newdata(1:newsize,4),'b-');
    title(sprintf('%% Synced Motes'));

    disp(sprintf('total unsycned num %d (all %d)',unsynced,newsize));
    disp(sprintf('avg %0.3f',mean(newdata(1:newsize,2))));
    disp(sprintf('max %d',max(newdata(1:newsize,2))));
    savedata = newdata(1:newsize,:);
    save data.out savedata -ASCII;
end
    