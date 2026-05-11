function [output] = algorithm_applyRules123(D, datatype, para_alg)

  % Find the causal effect by using R1, R2 and R3. If data are Gaussian, use 
  % partial correlation as independence test, if data are binary, use g-square
  % as independence test

  % INPUT
  % D ... datamatrix (variables in rows, observations in columns; first come n-2
  %       observed covariates, then variable x, then y)
  % datatype ... string: 'Gauss' if data are Gaussain
  %                      'discrete' if data are discrete
  % para_alg ... structure containing the fields
  %   K (otpional) ... maximal size of conditioning set in independence test
  %   states (mandatory if datatype = 'discrete') ... contains the number of
  %                                      states for each variable in a vector
  % 
  % OUTPUT
  % a strucutre

  nobs = size(D,1); % number of observed variables
  nsamp = size(D,2); % number of samples
  x = nobs - 1; % treatment
  y = nobs; % outcome
  W = 1:nobs-2; % covariates

  if ~exist('para_alg')
    para_alg = struct;
  end
  if ~isfield(para_alg,'K')
    para_alg.K = nobs-2;
  end
  if (para_alg.K > nobs-2)
    para_alg.K = nobs-2;
  end

  switch datatype
    case 'Gauss'
      itest = 'partialCorr'; % use partial correlation as indepence test
      DataCov = cov(D');
      para_alg.states = NaN;
    case 'discrete'
      itest = 'gsquare'; % use g-square as independence test
      DataCov = D;
  end

  % counter for each rule
  cnt_R1 = 0;
  cnt_R2 = 0;
  cnt_R3 = 0;

  % save Z and w, and p-values
  n_max_1 = getMaxNumberOfCondSets(nobs-2,para_alg.K);
          % in R1 can have subsets of nobs-2 variables in conditioning set Z
          % if K=nobs-2, n_max_1 = 2^(nobs-2)
  Z_R1 = cell(n_max_1,1);
  p_R1 = zeros(n_max_1,1);

  n_max_23 = getMaxNumberOfCondSets(nobs-3,para_alg.K); 
           % in R2 and R3 can have subsets of nobs-3 variables in Z, i.e. one 
           % less than covariates since I also need a w, if K=>nobs-3, n_max_23
           % = 2^(nobs-2-1), for each w have that many conditioning sets
  w_R23 = zeros(n_max_23*(nobs-2),1); % nobs-2 different w's, n_max_23 Z's
  Z_R23 = cell(n_max_23*(nobs-2),1); 

  p_R2 = zeros(n_max_23*(nobs-2),2); % test 2 indep.

  p_R3 = zeros(n_max_23*(nobs-2),3); 


  % go through conditioning sets with increasing cardinality
  for cardZ = 0:para_alg.K
  
    % test R1, x indep y given Z
    allZs = getZsOfSizeCardZ(W,cardZ); % cell arry containing conditioning sets

    for i = 1:size(allZs,1)
      Z = allZs{i};

      % condition: x indep y given Z
      pval = indepTest(x, y, Z, nsamp, DataCov, itest, para_alg.states);

      cnt_R1 = cnt_R1 + 1;
      Z_R1{cnt_R1} = Z;
      p_R1(cnt_R1) = pval;

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
	pval1 = indepTest(w, x, Z, nsamp, DataCov, itest, para_alg.states);
        
	% condition 2 of R2: w indep y given Z
	pval2_R2 = indepTest(w, y, Z, nsamp, DataCov, itest, para_alg.states);

	cnt_R2 = cnt_R2 + 1;
	p_R2(cnt_R2,:) = [pval1, pval2_R2];

	% condition 2 of R3: w indep y given Z and x
	pval2_R3 = indepTest(w, y, [Z,x], nsamp, DataCov, itest, para_alg.states);
%  	cond2_R3 = pval2_R3 > thresh_accept;
	
	% condition 3 of R3: w not indep y given Z (neg. of cond. 2 of R2)

	cnt_R3 = cnt_R3 + 1;
	p_R3(cnt_R3,:) = [pval1, pval2_R3, pval2_R2];

	% remember w and Z, same for R2 and R3
	w_R23(cnt_R3) = w;
	Z_R23{cnt_R3} = Z;

      end % for i
    
    end % for w
  
  end % for cardZ


  output = struct;

  output.R1_Z = Z_R1;
  output.R1_p = p_R1;

  output.R23_w = w_R23;
  output.R23_Z = Z_R23;

  output.R2_p = p_R2;

  output.R3_p = p_R3;

  output.K = para_alg.K;






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
