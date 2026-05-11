function [B,errstd] = randnetbalanced_skeleton(B_skel, parminmax, errminmax )
% randnetbalanced - create a more balanced random network, from a given matrix B
%
% INPUT:
%
% B_skel     - skeleton of the graph (connection matrix with 0's and 1's),
%              lower triangular matrix
% parminmax  - [min max] standard deviation owing to parents 
% errminmax  - [min max] standard deviation owing to error variable
%
% OUTPUT:
% 
% B      - the strictly lower triangular network matrix
% errstd - the vector of error (disturbance) standard deviations

% Number of variables
nvar = size(B_skel,1);

% Number of samples used to estimate covariance structure
samples = 10000; 
    
% First, generate errstd
errstd = rand(nvar,1)*(errminmax(2)-errminmax(1)) + errminmax(1);

% Initializations
X = [];
B = zeros(nvar,nvar);

% Go trough each node in turn:
for i=1:nvar,

    % parents of node i
    par = find(B_skel(i,:)~=0);
   
    % If node has parents, do the following
    if ~isempty(par),
	
	% Randomly pick weights
%  	w = randn(length(par),1); % around 0
	w = zeros(length(par),1); % coefficients less around 0 - use bimodel distribution
	for j = 1:length(par)
	  temp = rand(1);
	  if (temp < 0.5)
	    w(j,1) = -3+randn(1);
	  else
	    w(j,1) = 3+randn(1);
	  end
	end
	wfull = zeros(i-1,1); wfull(par) = w;

	% Calculate contribution of parents
	X(i,:) = wfull'*X;
		
	% Randomly select a 'parents std' 
	parstd = rand*(parminmax(2)-parminmax(1)) + parminmax(1);
	
	% Scale w so that the combination of parents has 'parstd' std
	scaling = parstd/sqrt(mean(X(i,:).^2));
	w = w*scaling;

	% Recalculate contribution of parents
	wfull = zeros(i-1,1); wfull(par) = w;	
	X(i,:) = wfull'*X(1:(i-1),:);
	
	% Fill in B
	B(i,par) = w';
	
    % if node has no parents
    else
	
	% Increase errstd to get it to roughly same variance
	parstd = rand*(parminmax(2)-parminmax(1)) + parminmax(1);
	errstd(i) = sqrt(errstd(i)^2 + parstd^2);
	
	% Set data matrix to empty
	X(i,:) = zeros(1,samples);
	
    end
	
    % Update data matrix
    X(i,:) = X(i,:) + randn(1,samples)*errstd(i);
    
end
