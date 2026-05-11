Codepackage to article

                     Data-driven covariate selection 
               for nonparametric estimation of causal effects

                     D. Entner, P.O. Hoyer, P. Spirtes
 
                               AISTATS-2013

-------------------------------------------------------------------------------

The content of the readme file is as follows:

1. Getting started
2. Reproducing the figures
3. Applying the inference rules to own data
4. Contact information

-------------------------------------------------------------------------------
1. GETTING STARTED
-------------------------------------------------------------------------------

To run the code, open matlab and change the working directory to the
codepackage. Add the Tetrad folder using
> addpath ./Tetrad/


-------------------------------------------------------------------------------
2. REPRODUCING THE FIGURES
-------------------------------------------------------------------------------

To reproduce Figures 2 and 3, call
> simulationCalls(1)
> simulationCalls_DecisionsEffects(12,5)

NOTE: this takes a bit of time. Results are saved in the folder 'Results',
and figures are saved in the folder 'Results/figures/' in the codepackage.

To reproduce the Figure in the Supplementary Material, call
> simulationCalls(2)
> simulationCalls_DecisionsEffects(102,20)

NOTE: this takes quite a while. Results and figures saved as above.

NOTE: in the comments of the code, the rule numbers do not match the ones in
      the paper. (We changed themw later on in the article, apologies for any 
      inconveniences.) Here is the correspondence between the rules:

      article               code
      R1 (i) + (ii)         R3 (iii) + (ii) (Note R3(i) in code is not used)
      R2 (i)                R1
      R2 (ii) + (iii)       R2


-------------------------------------------------------------------------------
3. APPLYING THE INFERENCE RULES TO OWN DATA
-------------------------------------------------------------------------------

To run the method on own data, using the brute force approach, call

> output = algorithm_applyRules123(D, 'Gauss');
> output1 = cell(1); output1{1} = output;
> [est, Dec, post_prob, counts, counts_trans] = makeDecisionAndEstimateEffect_3classes(D, 'Gauss', [], output1(1), output1{1}.R23_Z, [], 1);

where D is your data set, containing the variables in rows, observations in
columns, so should have many more columns than rows. Note that the current 
implementation only supports Gaussian data. The first function runs the brute
force algorithm with our infernce rules. The second function outputs in text
how often R1 and R2 were tested, and how often they applied, what the suggested
decision by our trained Bayes classifier is (and with what posterior
probabilities), and what the estimated effect is. If the suggested
decision is D4, then the classifier suggested D1, however the estimates were
not similar enough, so we decide to output D3.

NOTE: in the output of this function R1 and R2 are used as in the paper
NOTE: D1 stands for decision '+-'
      D2                     '0'
      D3                     '?'

To run the method on own data, using the random sampling approach, call

> para_alg = struct('K', 5, 'n', 10000);
> output = algorithm_applyRules123_random(D, 'Gauss', para_alg)
> output1 = cell(1); output1{1} = output;
> [est, Dec, post_prob, counts, counts_trans] = makeDecisionAndEstimateEffect_3classes(D, 'Gauss', [], output1(1), output1{1}.R3_Z, [], 1);

where para_alg contains the maximum size 'K' the conditioning sets Z can have,
as well as the number 'n' of how many times we randomly sample a set Z or a
pair (w,Z) and apply one of our rules. Other input and output same as above.


-------------------------------------------------------------------------------
4. CONTACT INFORMATION
-------------------------------------------------------------------------------

E-Mail: doris.entner[at]cs.helsinki.fi
Homepage: http://www.cs.helsinki.fi/u/entner/


