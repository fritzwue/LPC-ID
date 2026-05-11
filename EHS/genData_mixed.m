function [X, Bp, cp, disturbancestdp] = genData_mixed(B, c, disturbancestd, k, samples,errordistr)

% Generates randomly non-Gaussian and Gaussian data

% input
% B ... connection matrix, permuted to strictly lower triangluar
% c ... constant terms, permuted accordingly to B
% disturbancestd ... standard deviations of error terms, permuted acc. to B
% k ... causal order (to permute back)
% samples ... % Number of data vectors
% errordistr ... string: 'mixed' (generate sub and super-Gaussian, possible
%                                close to Gaussian, default)
%                        'Gauss' (generate Gaussian errors)
%                        'superGauss' (generate only super-gaussians)

if ~exist('errordistr')
  errordistr = 'mixed';
end

dims = size(B,1); % number of variables

% Nonlinearity exponent
% (<1 gives subgaussian, >1 gives supergaussian, ~1 gives Gaussian)
if (strcmp(errordistr,'mixed'))
  q = rand(dims,1)*1.5+0.5; %between 0.5 and 2
elseif (strcmp(errordistr,'superGauss'))
  q = rand(dims,1)*(2-1.2)+1.2; % only supergaussian disturbances
elseif (strcmp(errordistr,'Gauss'))
  q = ones(dims,1); % all Gauss
else
  fprintf('wrong specification for error distribution')
end

% This generates the disturbance variables, which are mutually 
% independent, and non-gaussian
S = randn(dims,samples);
S = sign(S).*(abs(S).^(q*ones(1,samples)));

% This normalizes the disturbance variables to have the 
% appropriate scales
S = S./((sqrt(mean((S').^2)')./disturbancestd)*ones(1,samples));

%  plotmatrix(S')

% Now we generate the data one component at a time
Xorig = zeros(dims,samples);
for i=1:dims,
    Xorig(i,:) = B(i,:)*Xorig + S(i,:) + c(i);
end

X = Xorig;

% Use the permuation to get original order back
p = k;

% Permute the rows of the data matrix, to give us the observed data
X = Xorig(p,:);

% Permute the rows and columns of the original generating matrix B 
% so that they correspond to the actual data
Bp = B(p,p);

% Permute the generating disturbance stds so that they correspond to
% the actual data
disturbancestdp = disturbancestd(p);

% Permute the generating constants so that they correspond to
% the actual data
cp = c(p);


