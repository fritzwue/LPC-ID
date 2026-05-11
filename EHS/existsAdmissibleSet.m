function [bool, Z] = existsAdmissibleSet(B,nobs)

  % test by d-separation whether there exists an admissible set among the
  % nobs-2 observed covariates to identify the effect of x=nobs-1 on y=nobs
  % using the back-door criterion
  % 
  % INPUT
  % B ... connection matrix (skeleton, entries all 0 or 1), causal order:
  %       first nobs-2 covariates, then x and y, and finally the latent vars
  % nobs ... number of observed variables

  % 
  % OUTPUT
  % bool ... 1 if there exists an admissible set; 0 otherwise
  % Z ... an admissible set, if one exists; NaN otherwise

  W = 1:nobs-2;
  n = nobs-2;
  x = nobs-1;
  y = nobs;

  % if there is a latent confounder between x and y, then no admis set exists
  Bxy_hid = B([x,y],[nobs+1:end]);
  temp = all(Bxy_hid == 1); % has one of the columns two ones = latent conf
  if ( any(temp) )
    bool = 0;
    Z = NaN;
    return
  end


  B(y,x) = 0; % cut out edge and search for Z d-separating x and y
  
  bool = NaN;

  % cardZ = 0 (Z = empty set)
  Z = [];
  bool = dseparated(B, x, y, Z); 
  
  if (bool)
    % empty set is separating set, stop function and return true
    return
  end

  % if empty set not separating, start going through all sets
  for cardZ = 1:n

    Zs = nchoosek(W,cardZ);
    Zs_temp = NaN(size(Zs,1),cardZ);
    cnt = 0;
  
    for i=1:size(Zs,1)

      Z = Zs(i,:);
      bool = dseparated(B, x, y, Z');

      if (bool)
	% found one separating set, stop function and return true
	return
      end

    end
  end

  Z = NaN;
