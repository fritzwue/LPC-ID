function [output] = algorithm_applyRules123_random(D, datatype, para_alg)

  % Find the causal effect by using R1, R2 and R3. If data are Gaussian, use 
  % partial correlation as independence test, if data are binary, use g-square
  % as independence test

  % INPUT
  % D ... datamatrix (variables in rows, observations in columns; first come n-2
  %       observed covariates, then variable x, then y)
  % datatype ... string: 'Gauss' if data are Gaussain
  %                      'discrete' if data are discrete
  % para_alg ... structure containing the fields
  %   K (mandatory) ... maximal size of conditioning set in independence test
  %   n (mandatory) ... how many tests are performed, i.e. how often do we
  %                     select a random set Z (and w) and perform test R1,
  %                     R2 or R3
  %   states (mandatory if datatype = 'discrete') ... contains the number of
  %                                      states for each variable in a vector
  % 
  % OUTPUT
  % a strucutre

  nobs = size(D,1); % number of observed variables
  nsamp = size(D,2); % number of samples
  x = nobs - 1; % treatment
  y = nobs; % outcome
  ncov = nobs-2; % number of covariates
  W = 1:ncov; % covariates
  
  
  nrep = para_alg.n;
  K = para_alg.K;

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

  % save results
  Z_R1 = cell(nrep,1);
  p_R1 = zeros(nrep,1);

  w_R2 = zeros(nrep,1);
  Z_R2 = cell(nrep,1);
  p_R2 = zeros(nrep,2); 

  w_R3 = zeros(nrep,1);
  Z_R3 = cell(nrep,1);
  p_R3 = zeros(nrep,3); 

  % R1
  n_R1_cardZ = zeros(K+1,1); % how many sets of each conditioning size up to K
  for i = 0:K
    n_R1_cardZ(i+1) = nchoosek(ncov,i);
  end
  n_R1 = sum(n_R1_cardZ); % total number of conditioning set up to size K
  % cumulative proportions of conditioning sets of size 0,...,K
  cumprop_R1 = cumsum(n_R1_cardZ) /n_R1;

  % R2 and R3
  n_R23_cardZ = zeros(min(ncov,K+1),1); % how many sets of each conditioning size up to K
  for i = 0:min(ncov-1,K)
    n_R23_cardZ(i+1) = nchoosek(ncov-1,i);
  end
  % total number of combinations of w's and conditioning sets Z up to size K
  n_R23 = ncov * sum(n_R23_cardZ); 
  % cumulative proportions of conditioing sets of size 0,...,K, for one w
  cumprop_R23 =  cumsum(n_R23_cardZ) / sum(n_R23_cardZ); 

  % total number of how often all rules could be applied
  n_total = n_R1 + 2 * n_R23;
  % cumulative proportions of how often each rule could be applied
  cumprop_Rs = cumsum([n_R1,n_R23,n_R23]) / n_total; 


  % apply R1, R2, or R3 nrep times (in total, not per rule)
  for n = 1:nrep
    
    % choose which rule we apply
    r = rand;
    if (r < cumprop_Rs(1))
      % apply R1 (zero effect, with Z only)
      apply_rule = 'R1';
    elseif (r < cumprop_Rs(2))
      % apply R2 (zero effect with Z and w)
      apply_rule = 'R2';
    else
      % apply R3 (non-zero effect)
      apply_rule = 'R3';
    end
    
    % apply rule
    switch apply_rule
      case 'R1'
	
	% select randomly a conditioning set Z among all up to size K
	% (i) select cardinality of Z proportional to all sets up to size K
	r = rand;
	% pick the index of the first 0 entry where cumulative proportion is
	% smaller then the random number. F.ex. if all are smaller, this index
	% is one, and size of conditioning set would be 0. If only first one is
	% smaller, then we get index 2, and conditioning set of cardinality 1,
	% and so on. Last element in cumprop_R1 is 1, which is always larger
	% than the random number, so if all but the last one are smaller, then
	% the index with the first 0 K+1 = length(cumprop_R1), and we get a
	% conditioning set of size K.
	[dummy, cardZ] = min(cumprop_R1 < r); 
	cardZ = cardZ - 1; % size of conditioning st
	
	% (ii) get a random set Z by taking the first cardZ elements of a random
	% permutaion of the covariates
	temp = randperm(ncov); 
	Z = sort(temp(1:cardZ));
	
	% condition: x indep y given Z
	pval = indepTest(x, y, Z, nsamp, DataCov, itest, para_alg.states);

	cnt_R1 = cnt_R1 + 1;
	Z_R1{cnt_R1} = Z;
	p_R1(cnt_R1) = pval;
      
      case 'R2'

        % select a w
        w = randi(ncov,1);

	% select a conditioning set Z among all from W\w up to size K as above
	r = rand;
	[dummy, cardZ] = min(cumprop_R23 < r); 
	cardZ = cardZ - 1; % size of conditioning st
	temp = randperm(ncov-1); 
	Ww = setdiff(W,w);
	Z = sort(Ww(temp(1:cardZ)));
	
	% condition 1 of R2 and R3: w not indep x given Z
	pval1 = indepTest(w, x, Z, nsamp, DataCov, itest, para_alg.states);
        
	% condition 2 of R2: w indep y given Z
	pval2_R2 = indepTest(w, y, Z, nsamp, DataCov, itest, para_alg.states);

	cnt_R2 = cnt_R2 + 1;
	w_R2(cnt_R2) = w;
	Z_R2{cnt_R2} = Z;
	p_R2(cnt_R2,:) = [pval1, pval2_R2];

      case 'R3'
      
        % select a w
        w = randi(ncov,1);

	% select a conditioning set Z among all from W\w up to size K as above
	r = rand;
	[dummy, cardZ] = min(cumprop_R23 < r); 
	cardZ = cardZ - 1; % size of conditioning st
	temp = randperm(ncov-1); 
	Ww = setdiff(W,w);
	Z = sort(Ww(temp(1:cardZ)));
	

	% condition 1 of R2 and R3: w not indep x given Z
	pval1 = indepTest(w, x, Z, nsamp, DataCov, itest, para_alg.states);

	% condition 2 of R3: w indep y given Z and x
	pval2_R3 = indepTest(w, y, [Z,x], nsamp, DataCov, itest, para_alg.states);
        
	% condition 3 of R3: w not indep y given Z
	pval3_R3 = indepTest(w, y, Z, nsamp, DataCov, itest, para_alg.states);

	cnt_R3 = cnt_R3 + 1;
	w_R3(cnt_R3) = w;
	Z_R3{cnt_R3} = Z;
	p_R3(cnt_R3,:) = [pval1, pval2_R3, pval3_R3];

    end % switch
    
  end % for n


  output = struct;

  output.R1_Z = Z_R1(1:cnt_R1);
  output.R1_p = p_R1(1:cnt_R1);

  output.R2_w = w_R2(1:cnt_R2);
  output.R2_Z = Z_R2(1:cnt_R2);
  output.R2_p = p_R2(1:cnt_R2,:);

  output.R3_w = w_R3(1:cnt_R3);
  output.R3_Z = Z_R3(1:cnt_R3);
  output.R3_p = p_R3(1:cnt_R3,:);

  output.K = para_alg.K;


