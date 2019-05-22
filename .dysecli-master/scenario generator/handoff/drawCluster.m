function cellCenters = drawCluster( center, iValue, jValue, cellRadius )

cellLabel = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
N = iValue^2 + iValue*jValue + jValue^2;

% Draw primary cluster
cellCenters(1,1) = center;
drawCell( center, cellRadius, strcat(cellLabel(1),'_1')  );
for index = 2:N
   cellCenters(index,1) = center + cellRadius*sqrt(3)*exp(j*(2*index-3)*pi/6);
   drawCell( cellCenters(index,1) , cellRadius, strcat(cellLabel(index),'_1') ); 
end

