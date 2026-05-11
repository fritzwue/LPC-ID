///////////////////////////////////////////////////////////////////////////////
// For information as to what this class does, see the Javadoc, below.       //
// Copyright (C) 2005 by Peter Spirtes, Richard Scheines, Joseph Ramsey,     //
// and Clark Glymour.                                                        //
//                                                                           //
// This program is free software; you can redistribute it and/or modify      //
// it under the terms of the GNU General Public License as published by      //
// the Free Software Foundation; either version 2 of the License, or         //
// (at your option) any later version.                                       //
//                                                                           //
// This program is distributed in the hope that it will be useful,           //
// but WITHOUT ANY WARRANTY; without even the implied warranty of            //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             //
// GNU General Public License for more details.                              //
//                                                                           //
// You should have received a copy of the GNU General Public License         //
// along with this program; if not, write to the Free Software               //
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA //
///////////////////////////////////////////////////////////////////////////////

package edu.cmu.tetradapp;

import edu.cmu.tetrad.data.DataReader;
import edu.cmu.tetrad.data.DataSet;
import edu.cmu.tetrad.graph.GraphConverter;
import edu.cmu.tetrad.graph.Graph;
import edu.cmu.tetrad.graph.GraphUtils;
import edu.cmu.tetrad.graph.Dag;
import edu.cmu.tetrad.data.Knowledge;
import edu.cmu.tetrad.search.IndTestDSep;
import edu.cmu.tetrad.search.IndTestFisherZ;
import edu.cmu.tetrad.search.IndTestGSquare;
import edu.cmu.tetrad.search.Cfci;
import edu.cmu.tetrad.search.*;
import edu.cmu.tetrad.util.TetradLogger;
import edu.cmu.tetrad.bayes.MlBayesEstimator;
import edu.cmu.tetrad.bayes.BayesPm;
import edu.cmu.tetrad.bayes.BayesIm;
import edu.cmu.tetradapp.editor.BayesEstimatorEditor;

import java.io.*;
import java.util.logging.Level;
import java.util.StringTokenizer;

/**
 * Runs PC and FCI from the command line.
 *
 * @author Joseph Ramsey
 */
public final class TetradCmd {

    private String graphFileName;
    private Graph graph;

    private String dataFileName;
    private String dataTypeName;
    private double significance = 0.05;
    private DataSet data;

    private String algorithmName;
    private String knowledgeFileName;
    private Knowledge knowledge;
    private int depth = -1;
    private boolean completeRuleSetUsed = true;
    private boolean possibleDsepSearchDone = true;
    private String outputStreamPath;
    private PrintStream out = System.out;
    private String seed;

    public TetradCmd(String[] argv) {

        readArguments(new StringArrayTokenizer(argv));
        setOutputStream();
        runAlgorithm();

        if (out != System.out) {
            out.close();
        }
    }

    private void setOutputStream() {
        if (outputStreamPath == null) {
            return;
        }

        File file = new File(outputStreamPath);

        try {
            out = new PrintStream(new FileOutputStream(file));
        }
        catch (FileNotFoundException e) {
            throw new IllegalStateException(
                    "Could not create a logfile at location " +
                            file.getAbsolutePath());
        }
    }

    private void readArguments(StringArrayTokenizer tokenizer) {
        while (tokenizer.hasToken()) {
            String token = tokenizer.nextToken();

            if ("-graph".equalsIgnoreCase(token)) {
                String argument = tokenizer.nextToken();

                if (argument.startsWith("-") || argument == null) {
                    throw new IllegalArgumentException(
                            "'-graph' tag must be followed " +
                                    "by an argument indicating the path to the graph " +
                                    "file.");
                }

                graphFileName = argument;
                loadGraph();
            } else if ("-data".equalsIgnoreCase(token)) {
                String argument = tokenizer.nextToken();

                if (argument.startsWith("-") || argument == null) {
                    throw new IllegalArgumentException(
                            "'-data' tag must be followed " +
                                    "by an argument indicating the path to the data " +
                                    "file.");
                }

                dataFileName = argument;
            } else if ("-datatype".equalsIgnoreCase(token)) {
                String argument = tokenizer.nextToken();

                if (argument.startsWith("-") || argument == null) {
                    throw new IllegalArgumentException(
                            "'-datatype' tag must be followed " +
                                    "by either 'discrete' or 'continuous'.");
                }

                dataTypeName = argument;
                loadData();
            } else if ("-knowledge".equalsIgnoreCase(token)) {
                String argument = tokenizer.nextToken();

                if (argument.startsWith("-") || argument == null) {
                    throw new IllegalArgumentException(
                            "'-knowledge' tag must be followed " +
                                    "by an argument indicating the path to the knowledge " +
                                    "file.");
                }

                knowledgeFileName = argument;
                loadKnowledge();

            } else if ("-algorithm".equalsIgnoreCase(token)) {
                String argument = tokenizer.nextToken();

                if (argument.startsWith("-") || argument == null) {
                    throw new IllegalArgumentException(
                            "'-algorithm' tag must be followed " +
                                    "by an algorithm name.");
                }

                algorithmName = argument;
            } else if ("-depth".equalsIgnoreCase(token)) {
                try {
                    String argument = tokenizer.nextToken();

                    if (argument.startsWith("-") || argument == null) {
                        throw new NumberFormatException();
                    }

                    this.depth = Integer.parseInt(argument);
                }
                catch (NumberFormatException e) {
                    throw new IllegalArgumentException(
                            "'depth' must be followed " +
                                    "by an integer >= -1 (-1 means unlimited).");
                }
            } else if ("-completeRuleSet".equalsIgnoreCase(token)) {
                    String argument = tokenizer.nextToken();

                    if (argument.startsWith("-") || argument == null) {
                        throw new NumberFormatException();
                    }
                    this.completeRuleSetUsed = Boolean.parseBoolean(argument);
            } else if ("-PossDsepSearch".equalsIgnoreCase(token)) {
                    String argument = tokenizer.nextToken();

                    if (argument.startsWith("-") || argument == null) {
                        throw new NumberFormatException();
                    }
                    this.possibleDsepSearchDone = Boolean.parseBoolean(argument);
            } else if ("-significance".equalsIgnoreCase(token)) {
                try {
                    String argument = tokenizer.nextToken();

                    if (argument.startsWith("-") || argument == null) {
                        throw new NumberFormatException();
                    }

                    this.significance = Double.parseDouble(argument);
                }
                catch (NumberFormatException e) {
                    throw new IllegalArgumentException(
                            "'-significance' must be " +
                                    "followed by a number in the range [0.0, 1.0].");
                }
            } else if ("-level".equalsIgnoreCase(token)) {
                String argument = tokenizer.nextToken();

                if (argument.startsWith("-") || argument == null) {
                    throw new NumberFormatException();
                }

            } else if ("-outfile".equalsIgnoreCase(token)) {
                String argument = tokenizer.nextToken();

                if (argument.startsWith("-") || argument == null) {
                    throw new IllegalArgumentException(
                            "'-outfile' tag must be " +
                                    "followed  by an argument indicating the path to the " +
                                    "data file.");
                }

                outputStreamPath = argument;
            } else if ("-seed".equalsIgnoreCase(token)) {
                String argument = tokenizer.nextToken();

                if (argument.startsWith("-") || argument == null) {
                    throw new IllegalArgumentException(
                            "-seed must be followed by an integer (long) value."
                    );
                }

                seed = argument;
            } else {
                throw new IllegalArgumentException(
                        "Unexpected argument: " + token);
            }
        }
    }

    private void loadGraph() {
        try {
            String inputFileName = graphFileName;

            FileReader inputFileReader = new FileReader(inputFileName);
            BufferedReader inputStream = new BufferedReader(inputFileReader);

            String graph1;
            graph1 = inputStream.readLine(); // this works since in file is only 1 line.
            //System.out.println(graph1);

            Graph graph;
            graph = GraphConverter.convert(graph1);
            System.out.println(graph);
            this.graph = graph;
        }
        catch (IOException e) {
            System.out.println("IOException:");
            e.printStackTrace();
        }
    }

    private void loadData() {
        if (dataFileName == null) {
            throw new IllegalStateException("No data file was specified.");
        }

        if (dataTypeName == null) {
            throw new IllegalStateException(
                    "No data type (continuous/discrete) " + "was specified.");
        }

        out.println("Loading data from " + dataFileName + ".");

        if ("continuous".equalsIgnoreCase(dataTypeName)) {
            out.println("Data type = continuous.");
        } else if ("discrete".equalsIgnoreCase(dataTypeName)) {
            out.println("Data type = discrete.");
        } else {
            throw new IllegalStateException(
                    "Data type was expected to be either " +
                            "'continuous' or 'discrete'.");
        }

        File file = new File(dataFileName);

        try {
            try {
                DataReader reader = new DataReader();
                reader.setMaxIntegralDiscrete(Integer.MAX_VALUE);
                DataSet data = reader.parseTabular(file);

                out.println("# variables = " + data.getNumColumns() +
                        ", # cases = " + data.getNumRows());
                this.data = data;
            }
            catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
        catch (RuntimeException e) {
            throw new IllegalStateException(
                    "Could not load file at " + file.getAbsolutePath());
        }
    }

    private void loadKnowledge() {
        try {
            String inputFileName = knowledgeFileName;

            FileReader inputFileReader = new FileReader(inputFileName);
            BufferedReader inputStream = new BufferedReader(inputFileReader);

            Knowledge knowledge = new Knowledge();

            String str;
            while ((str = inputStream.readLine()) != null) {
                //System.out.println(str);
                StringTokenizer str1 = new StringTokenizer(str);
                int tier = Integer.parseInt(str1.nextToken());
                String var = str1.nextToken();
                //System.out.println(tier);
                //System.out.println(var);

                knowledge.addToTier(tier, var);

            }
            System.out.println(knowledge);
            this.knowledge = knowledge;
        }
        catch (IOException e) {
            System.out.println("IOException:");
            e.printStackTrace();
        }
    }

    private void runAlgorithm() {
        try {
            // LogUtils.getInstance().add(System.out, Level.FINER);
            TetradLogger.getInstance().addOutputStream(System.out);
            TetradLogger.getInstance().setForceLog(true);
        }
        catch (SecurityException e) {
            // Do nothing. If you rethrow an exception, applets won't work.
        }

        if ("pc".equalsIgnoreCase(algorithmName)) {
            runPc();
        } else if ("cpc".equalsIgnoreCase(algorithmName)) {
            runCpc();
        } else if ("fci".equalsIgnoreCase(algorithmName)) {
            runFci();
        } else if ("cfci".equalsIgnoreCase(algorithmName)) {
            runCfci();
        } else if ("ccd".equalsIgnoreCase(algorithmName)) {
            runCcd();
        } else if ("bayes_est".equalsIgnoreCase(algorithmName)) {
            runBayesEst();
        } else {
            TetradLogger.getInstance().reset();
            TetradLogger.getInstance().removeOutputStream(System.out);
            throw new IllegalStateException("No algorithm was specified.");
        }
        TetradLogger.getInstance().setForceLog(false);
        TetradLogger.getInstance().removeOutputStream(System.out);

    }

    private void runPc() {
        if (this.data == null & this.graph == null) {
            throw new IllegalStateException("Data did not load correctly.");
        }

        IndependenceTest independence;

        if (this.graph!=null) {
            independence = new IndTestDSep(graph);
        } else if (this.data.isDiscrete()) {
            independence = new IndTestGSquare(data, significance);
        } else if (this.data.isContinuous()) {
            independence = new IndTestFisherZ(data, significance);
        } else {
            throw new IllegalStateException(
                    "Data must be either continuous or " + "discrete.");
        }

        Pc pc = new Pc(independence);
        pc.setDepth(this.depth);
        if (knowledge!=null) {
            pc.setKnowledge(knowledge);
        }

        // Convert back to Graph..
        Graph resultGraph = pc.search();

        // PrintUtil outputStreamPath problem and graphs.
//        out.println("\nResult graph:");
//        out.println(resultGraph);

        // write output to file
        out.println(resultGraph.getNumNodes());
        out.println(resultGraph.getNumEdges());
        out.println(resultGraph.getNodes());
        out.println(resultGraph.getEdges());
    }

    private void runCpc() {
        if (this.data == null & this.graph == null) {
            throw new IllegalStateException("Data did not load correctly.");
        }

        IndependenceTest independence;

        if (this.graph!=null) {
            independence = new IndTestDSep(graph);
        } else if (this.data.isDiscrete()) {
            independence = new IndTestGSquare(data, significance);
        } else if (this.data.isContinuous()) {
            independence = new IndTestFisherZ(data, significance);
        } else {
            throw new IllegalStateException(
                    "Data must be either continuous or " + "discrete.");
        }

        Cpc pc = new Cpc(independence);
        pc.setDepth(this.depth);
        if (knowledge!=null) {
            pc.setKnowledge(knowledge);
        }

        // Convert back to Graph..
        Graph resultGraph = pc.search();

        // PrintUtil outputStreamPath problem and graphs.
//        out.println("\nResult graph:");
//        out.println(resultGraph);

        // write output to file
        out.println(resultGraph.getNumNodes());
        out.println(resultGraph.getNumEdges());
        out.println(resultGraph.getNodes());
        out.println(resultGraph.getEdges());
    }

    private void runFci() {
        if (this.data == null & this.graph == null) {
            throw new IllegalStateException("Data did not load correctly.");
        }

        IndependenceTest independence;

        if (this.graph!=null) {
            independence = new IndTestDSep(graph);
        } else if (this.data.isDiscrete()) {
            independence = new IndTestGSquare(data, significance);
        } else if (this.data.isContinuous()) {
            independence = new IndTestFisherZ(data, significance);
        } else {
            throw new IllegalStateException(
                    "Data must be either continuous or " + "discrete.");
        }

        Fci fci = new Fci(independence);
        if (knowledge!=null) {
            fci.setKnowledge(knowledge);
        }

        // Convert back to Graph..
        Graph resultGraph = fci.search();

        // PrintUtil outputStreamPath problem and graphs.
//        out.println("\nResult graph:");
//        out.println(resultGraph);

        // write output to file
        out.println(resultGraph.getNumNodes());
        out.println(resultGraph.getNumEdges());
        out.println(resultGraph.getNodes());
        out.println(resultGraph.getEdges());
    }

    private void runCfci() {
        if (this.data == null & this.graph == null) {
            throw new IllegalStateException("Data did not load correctly.");
        }

        IndependenceTest independence;

        if (this.graph!=null) {
            independence = new IndTestDSep(graph);
        } else if (this.data.isDiscrete()) {
            independence = new IndTestGSquare(data, significance);
        } else if (this.data.isContinuous()) {
            independence = new IndTestFisherZ(data, significance);
        } else {
            throw new IllegalStateException(
                    "Data must be either continuous or " + "discrete.");
        }

        Cfci fci = new Cfci(independence);
        if (knowledge!=null) {
            fci.setKnowledge(knowledge);
        }
        fci.setCompleteRuleSetUsed(completeRuleSetUsed);
        fci.setPossibleDsepSearchDone(possibleDsepSearchDone);
        // Convert back to Graph..
        Graph resultGraph = fci.search();

        // PrintUtil outputStreamPath problem and graphs.
//        out.println("\nResult graph:");
//        out.println(resultGraph);

        // write output to file
        out.println(resultGraph.getNumNodes());
        out.println(resultGraph.getNumEdges());
        out.println(resultGraph.getNodes());
        out.println(resultGraph.getEdges());
    }

    private void runCcd() {
        if (this.data == null & this.graph == null) {
            throw new IllegalStateException("Data did not load correctly.");
        }

        IndependenceTest independence;

        if (this.graph!=null) {
            independence = new IndTestDSep(graph);
        } else if (this.data.isDiscrete()) {
            independence = new IndTestGSquare(data, significance);
        } else if (this.data.isContinuous()) {
            independence = new IndTestFisherZ(data, significance);
        } else {
            throw new IllegalStateException(
                    "Data must be either continuous or " + "discrete.");
        }

        Ccd ccd = new Ccd(independence);

        // Convert back to Graph..
        Graph resultGraph = ccd.search();

        // PrintUtil outputStreamPath problem and graphs.
//        out.println("\nResult graph:");
//        out.println(resultGraph);

        // write output to file
        out.println(resultGraph.getNumNodes());
        out.println(resultGraph.getNumEdges());
        out.println(resultGraph.getNodes());
        out.println(resultGraph.getEdges());
    }

    private void runBayesEst() {
        if (this.data == null) {
            throw new IllegalStateException("Data did not load correctly.");
        }

        if (!this.data.isDiscrete()) {
            out.println("Please supply discrete data.");
        }

        IndependenceTest independence = new IndTestGSquare(data, significance);

        Cpc cpc = new Cpc(independence);
        Graph pattern = cpc.search();

        out.println("Found this pattern: " + pattern);

        Dag dag = new Dag(SearchGraphUtils.dagFromPattern(pattern));

        out.println("Chose this DAG: " + dag);

        BayesPm pm = new BayesPm(dag);

        MlBayesEstimator est = new MlBayesEstimator();
        BayesIm im = est.estimate(pm, data);

        out.println("Estimated IM: " + im);
    }


    private Level convertToLevel(String level) {
        if ("severe".equalsIgnoreCase(level)) {
            return Level.SEVERE;
        } else if ("warning".equalsIgnoreCase(level)) {
            return Level.WARNING;
        } else if ("info".equalsIgnoreCase(level)) {
            return Level.INFO;
        } else if ("config".equalsIgnoreCase(level)) {
            return Level.CONFIG;
        } else if ("fine".equalsIgnoreCase(level)) {
            return Level.FINE;
        } else if ("finer".equalsIgnoreCase(level)) {
            return Level.FINER;
        } else if ("finest".equalsIgnoreCase(level)) {
            return Level.FINEST;
        }

        throw new IllegalArgumentException("Level must be one of 'Severe', " +
                "'Warning', 'Info', 'Config', 'Fine', 'Finer', 'Finest'.");
    }

    public static void main(final String[] argv) {
        new TetradCmd(argv);
    }

    /**
     * Allows an array of strings to be treated as a tokenizer.
     */
    private static class StringArrayTokenizer {
        String[] tokens;
        int i = -1;

        public StringArrayTokenizer(String[] tokens) {
            this.tokens = tokens;
        }

        public boolean hasToken() {
            return i < tokens.length - 1;
        }

        public String nextToken() {
            return tokens[++i];
        }
    }
}


