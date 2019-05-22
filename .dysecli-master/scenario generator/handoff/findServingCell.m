function [cellNumber, tierNumber, center] = findServingCell( mobileLocation, cellCenters )
   distance = abs( mobileLocation - cellCenters );
   [cellNumber, tierNumber] = find( distance == min(min(distance)) );
   center = cellCenters(cellNumber, tierNumber );
  
         
