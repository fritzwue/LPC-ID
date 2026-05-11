function pag = readFCIoutput(filename)

  if ~exist('filename')
    filename = './Tetrad/resultFCI.txt';
  end
  
  fileID = fopen(filename,'r');
  numNodes = str2num(fscanf(fileID, '%s', 1));
  numEdges = str2num(fscanf(fileID, '%s', 1));
  dummy = fgets(fileID); % empty line
  Nodes = fgets(fileID); % do i actually need this?
  Edges = fgets(fileID);
  fclose(fileID);

  Edges = Edges(2:end-2)

  pag = zeros(numNodes);

  for i=1:numEdges
  
    temp = Edges(1:13);
    Edges = Edges(16:end);

    node1 = str2num(temp(2:4));
    node2 = str2num(temp(11:13));
    
    mark1 = temp(6);
    mark2 = temp(8);

    if (strcmp(mark1,'-'))
      pag(node2,node1) = 1;
    elseif (strcmp(mark1,'<'))
      pag(node2,node1) = 2;
    elseif (strcmp(mark1,'o'))
      pag(node2,node1) = 3;
    end

    if (strcmp(mark2,'-'))
      pag(node1,node2) = 1;
    elseif (strcmp(mark2,'>'))
      pag(node1,node2) = 2;
    elseif (strcmp(mark2,'o'))
      pag(node1,node2) = 3;
    end

  end

  