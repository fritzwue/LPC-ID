function [D, Bp, cp, ep] = genData_gauss(B_skel, k, nobs, nhid, samples, parminmax, errminmax, randseed)

  % B_skel ... the skeleton of the generating graph, arranged in order k
  % k ... causal order of the variables
  % nobs ... number of observed variables
  % nhid ... number of hidden variables
  % samples ... number of samples to generate
  % parminmax ... 2x1 vector containing the range of standard deviation owing
  %               to parents
  % errminmax ... 2x1 vector containing the range of the standard deviation of
  %               the disturbances  
  % randseed ... a random seed to reproduce results

  mystream = RandStream.create('mt19937ar','Seed',randseed);
  RandStream.setDefaultStream(mystream);
  savedState = mystream.State;

  nvar = nobs + nhid;

  B_skel_tri = B_skel(k,k);
  p = k(nhid+1:nvar);
  k1 = [iperm(p)+nhid,1:nhid]; % to permute B_skel_tri to B_skel

  % generate balanced edge coefficients
  [B_tri,e_tri] = randnetbalanced_skeleton(B_skel_tri, parminmax, errminmax);
%    B_tri = B_skel_tri.*(0.3 + (0.9-0.3)*rand(nvar)) ... 
%                      .*reshape(randsample([-1,1],nvar^2,true),nvar,nvar);
%    e_tri = 0.8 + (2-0.8)*rand(nvar,1);
  c_tri = zeros(nvar,1); % zero mean random variables

  % generate data from model, with Gaussian disturbances
  [D, Bp, cp, ep] = genData_mixed(B_tri, c_tri, e_tri, k1, samples, 'Gauss');

  B = B_tri(k1,k1);
  if (~all(all(Bp==B))) %ep==e
    fprintf('Warning: something wrong with data generating process! - keyboard\n')
    keyboard
  end

%  	% covariance matrix - sanity check if data generation is right
%  	A = (eye(size(Bp,1))-Bp)^(-1);
%  	A(abs(A)<1e-10) = 0; % rounding effects
%  	cov_true = A*diag(ep.^2)*A';
%  	cov_est = cov(D');
%  	sanity_cov = abs(cov_est-cov_true)
