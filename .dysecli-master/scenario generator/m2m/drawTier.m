function cellCenters = drawTier( center, iValue, jValue, cellRadius )

cellLabel = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
N = iValue^2 + iValue*jValue + jValue^2;

% Draw primary cluster
cellCenters(1,1) = center;
drawCell( center, cellRadius, strcat(cellLabel(1),'_1')  );
for index = 2:N
   cellCenters(index,1) = center + cellRadius*sqrt(3)*exp(j*(2*index-3)*pi/6);
   drawCell( cellCenters(index,1) , cellRadius, strcat(cellLabel(index),'_1') ); 
end

% Draw first tier of interfering cells
for tier = 1:6
   for index = 1:N
        cellCenters(index, tier+1) = cellCenters(index,1)+iValue*sqrt(3)*cellRadius*exp(j*(2*(tier-1)+1)*pi/6)+jValue*sqrt(3)*cellRadius*exp(j*((2*(tier-1)+1)*pi/6 + pi/3));
        drawCell( cellCenters(index, tier+1), cellRadius, strcat(cellLabel(index),'_',num2str(tier+1)) );  
   end
end

