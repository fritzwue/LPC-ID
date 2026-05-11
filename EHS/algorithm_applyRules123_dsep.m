function [output] = algorithm_applyRules123_dsep(B, nobs, K, stop_allowed)

  % Find the causal effect by using R1, R2 and R3 with independence oracle
  % (d-seapration in the graph B)

  % INPUT
  % B ... connectionmatrix (first come n-2 observed covariates, then variable x,
  %       then y, then the hidden variables)
  % nobs ... number of observed variables
  % K (otpional) ... maximal size of conditioning set in independence test
  % stop_allowed (optional) ... if 1, allow to stop in the middle of the tests
  %                             as soon as we found a set Z (and w) fulfilling
  %                             R1, R2 or R3, and return 1 if R3 holds, 2 if
  %                             R1 or R2 holds, or 3 if non of them hold.
  %                             default = 0 = calculate for all sets Z and w
  %                             
  % 
  % OUTPUT
  % a strucutre

  x = nobs - 1; % treatment
  y = nobs; % outcome
  W = 1:nobs-2; % covariates

  if ~exist('K')
    K = nobs-2;
  end
  if ~exist('stop_allowed')
    stop_allowed = 0;
  end

  % counter for each rule
  cnt_R1 = 0;
  cnt_R2 = 0;
  cnt_R3 = 0;

  % save Z and w, and p-values, and decision for given p-values
  n_max_1 = getMaxNumberOfCondSets(nobs-2,K);
          % in R1 can have subsets of nobs-2 variables in conditioning set Z
          % if K=nobs-2, n_max_1 = 2^(nobs-2)
  Z_R1 = cell(n_max_1,1);
  p_R1 = zeros(n_max_1,1); % like p-value, 1 if d-sep holds, 0 if not

  n_max_23 = getMaxNumberOfCondSets(nobs-3,K); 
           % in R2 and R3 can have subsets of nobs-3 variables in Z, i.e. one 
           % less than covariates since I also need a w, if K=>nobs-3, n_max_23
           % = 2^(nobs-2-1), for each w have that many conditioning sets
  w_R23 = zeros(n_max_23*(nobs-2),1); % nobs-2 different w's, n_max_23 Z's
  Z_R23 = cell(n_max_23*(nobs-2),1); 

  p_R2 = zeros(n_max_23*(nobs-2),2); % test 2 indep.

  p_R3 = zeros(n_max_23*(nobs-2),3);  % test 3 indep.


  if (stop_allowed)
    % all we want to know if D1, D2, or D3 is correct
    % know if there is an effect from x on y, and a latent confounder between
    % x and y, that we have to say D3
    if (B(y,x) == 1) % non-zero effect
      Bxy_hid = B([x,y],[nobs+1:end]);
      temp = all(Bxy_hid == 1); % has one of the columns two ones = latent conf
      if ( any(temp) )
        output = 3;
        return
      end
    end
  end


  % go through conditioning sets with increasing cardinality
  for cardZ = 0:K
  
    % test R1, x indep y given Z
    allZs = getZsOfSizeCardZ(W,cardZ); % cell arry containing conditioning sets

    for i = 1:size(allZs,1)
      Z = allZs{i};

      % condition: x indep y given Z
      cond = dseparated(B, x, y, Z'); 

      cnt_R1 = cnt_R1 + 1;
      Z_R1{cnt_R1} = Z;
      p_R1(cnt_R1) = cond;

      if (cond && stop_allowed) % R1 holds
	output = 2;
	return
      end
    end %for i

    if (cardZ == nobs-2)
      continue
    end

    for w = 1:nobs-2
    
      % test R2 and R3
      allZs = getZsOfSizeCardZ(setdiff(W,w),cardZ);
      
      for i=1:size(allZs,1)
        Z = allZs{i};

	% condition 1 of R2 and R3: w not indep x given Z
        cond1 = ~dseparated(B, w, x, Z'); 
	
	if (~cond1 && stop_allowed)
	  % R2 and R3 cannot hold, continue
	  continue
	end
        
	% condition 2 of R2: w indep y given Z
        cond2_R2 = dseparated(B, w, y, Z'); 

	% remember w and Z, and whether R2 was true
	cnt_R2 = cnt_R2 + 1;
	p_R2(cnt_R2,:) = [~cond1, cond2_R2];

	if (cond1 && cond2_R2 && stop_allowed) % R2 holds
	  output = 2;
	  return
	end

	% condition 2 of R3: w indep y given Z and x
        cond2_R3 = dseparated(B, w, y, [Z,x]'); 
        % condition 3 of R3: w not indep y given Z
        cond3_R3 = ~cond2_R2;

	cnt_R3 = cnt_R3 + 1;
	p_R3(cnt_R3,:) = [~cond1, cond2_R3, cond2_R2];

	if (cond1 && cond2_R3 && cond3_R3 && stop_allowed) % R3 holds
	  output = 1;
	  return
	end

	w_R23(cnt_R3) = w;
	Z_R23{cnt_R3} = Z;

      end % for i
    
    end % for w
  
  end % for cardZ

  if (stop_allowed)
    % non of the rules applied, so we make decision D3 (and that's all we
    % want to know when "stop_allowed = 1")
    output = 3;
    return
  else
    % return which indep. tests did hold and not hold
    output = struct;

    output.R1_Z = Z_R1;
    output.R1_p = p_R1;

    output.R23_w = w_R23;
    output.R23_Z = Z_R23;

    output.R2_p = p_R2;

    output.R3_p = p_R3;

    output.K = K;
  end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -----------------------------------------------------------------------------
function n_max = getMaxNumberOfCondSets(n,K)

  % when having n covariates that could be in conditioning set and using
  % conditioning sets of up to size K, n_max is number of many conditioning 
  % sets I get when going through all of them
  
  if (K > n)
    K = n;
  end
  
  n_max = 1; % empty conditioning set
  
  for cardZ=1:K % size of conditioning set
    n_max = n_max + nchoosek(n,cardZ);
  end


% -----------------------------------------------------------------------------
function allZs = getZsOfSizeCardZ(W,cardZ)

  if (cardZ==0)
    allZs = cell(1);
  else
    allZs = nchoosek(W,cardZ);
    allZs = mat2cell(allZs, ones(size(allZs,1),1));
  end
