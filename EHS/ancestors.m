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
