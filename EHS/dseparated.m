function val = dseparated(B, x, y, Z)

  % returns true if x is d-separated from y given the set Z in the graph B
  % 
  % B ... connection matrix of the DAG, hidden variables in last rows/columns
  % x ... integer
  % y ... integer
  % Z ... column vector of integer

  if ~exist('Z')
    Z = [];
  end  

  % replace all non-zero entries in B with ones
  B(B~=0) = 1;

  % if x not d-connected to y given Z in B, then d-separated
  val = ~dconnected(B, x, y, Z);



function val = dconnected(B, x, y, Z, incomeX, mypath, ancestorZ)

  % B ... connection matrix in B, all entries in B are 1 (effect) or 0

  if ~exist('Z')
    Z = [];
  end
  if ~exist('incomeX')
    incomeX = 0;
  end
  if ~exist('mypath')
    mypath = [];
  end
  if ~exist('ancestorZ')
    ancestorZ = ancestors(B,Z);
  end


  % reached x from y through a d-connecting path
  if (x == y)
    val = 1;
%      fprintf('return true because x=y \n')
    return
  end

  % visited x already and couldn't find d-connecting path
  if (ismember(x, mypath)) 
    val = 0;
%      fprintf('return false because x in path \n')
    return
  end

  mypath = [mypath, x];

  paX = find(B(x,:)==1)'; % parents of x
  chX = find(B(:,x)==1); % children of x

  % edges into and out of x
  edgesX = zeros(length(paX)+length(chX),2);
  edgesX(:,1) = [paX; chX];
  edgesX(:,2) = [ repmat(1,length(paX),1); repmat(0,length(chX),1) ];



  for i = 1:size(edgesX,1)

%      x
%      edgesX(i,1)

    if (edgesX(i,2) == 1)
      incomeFromNeigh = 1;
      % where 1 = TRUE means that edge is pointing towards x
    else
      incomeFromNeigh = 0;
    end

    % check if there is a collider on the path: comefrom -> x <- neighbour
    isCollider = incomeX & incomeFromNeigh;
    % if there is collider, check if path is d-connected
    passAsCollider = isCollider & ismember(x, ancestorZ);
    % if there is no collider, check if path is d-connected
    passAsNonCollider = ~isCollider & ~ismember(x, Z);

    if (passAsCollider | passAsNonCollider) % ie. dconnected so far
      newX = edgesX(i,1); % second node in edge besides x
      % get endpoint of edge: f. ex. if x -> newX, than income.newX = TRUE
      if (edgesX(i,2) == 1)
        incomeNewX = 0;
      else
        incomeNewX = 1;
      end

      if (dconnected(B, newX, y, Z, incomeNewX, mypath, ancestorZ))
        val = 1;
%          fprintf('return true because dconnected was true \n')
        return
      end

    end % if (passAsCollider | passAsNonCollider)

  end % for i

%    mypath
  mypath = mypath(1:length(mypath)-1);
%    mypath

  val = 0;
%    fprintf('return false because used all edges')
  return




% #############################################################################

function anc = ancestors(B, Z, anc)

  % recursive function to get all ancestors of the set Z in B

  if ~exist('anc')
    anc = Z;
  end

  paZ = [];

  for i=1:length(Z)
    paZi = find(B(Z(i),:) == 1);
    paZ = [paZ paZi];
  end

  anc = union(anc,paZ);

  if (length(paZ)~=0)
    anc = ancestors(B, paZ, anc);
  else
    return
  end
