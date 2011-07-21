/*
* Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author:Miklos Maroti
*/

import java.util.*;

import Jama.*;

/**
 * This class solves systems of linear equations.
 * @author mmaroti
 */
public class LinearEquations
{
	/**
	 * Holds a map from variable names to variable indices
	 */
	protected TreeMap<String, Integer> variables = new TreeMap<String, Integer>();

	/**
	 * Get the index of a variable with this method.
	 */
	protected int getVariable(String name)
	{
		if( variables.containsKey(name) )
			return ((Integer)variables.get(name)).intValue();

		int n = variables.size();
		variables.put(name, new Integer(n));
		return n;
	}
	protected String getVariableName(int id){
		Set<String> set=variables.keySet();
		for(String key:set){
			if(getVariable(key)==id)
				return key;
		}
		return "no variable";
	}
	

	/**
	 * Returns the set of variable names in the system. 
	 */
	public Set<String> getVariables()
	{
		return variables.keySet();
	}

	/**
	 * Represents one equation of the system.
	 * Create the equation, set the coefficient of
	 * specific elements and then set the constant.
	 */	
	public class Equation
	{
		protected Equation()
		{
			coefficients = new double[LinearEquations.this.variables.size() + 10];
		}

		protected int getVariableIndex(String name)
		{
			int n = LinearEquations.this.getVariable(name);
			if( coefficients.length <= n )
			{
				double[] c = new double[n + 10];
				System.arraycopy(coefficients, 0, c, 0, coefficients.length);
				coefficients = c;
			}
			return n;
		}

		public double getCoefficient(String name)
		{
			int n = getVariableIndex(name);
			return coefficients[n];
		}

		public void setCoefficient(String name, double value)
		{
			int n = getVariableIndex(name);
			coefficients[n] = value;
		}
		
		public void addCoefficient(String name, double value)
		{
			int n = getVariableIndex(name);
			coefficients[n] += value;
		}
		
		public void subCoefficient(String name, double value)
		{
			int n = getVariableIndex(name);
			coefficients[n] -= value; 
		}
		
		public double getConstant()
		{
			return constant;
		}
		
		public void setConstant(double value)
		{
			constant = value; 
		}

		public void addConstant(double value)
		{
			constant += value;
		}

		public void subConstant(double value)
		{
			constant -= value;
		}

		/**
		 * Multiplies each coefficient and the constant with this value.
		 * The new equation will hold if and only if the originial does,
		 * but with the multiplied version can count with different strength
		 * in a least square solutions.
		 */
		public void multiply(double value)
		{
			for(int i = 0; i < coefficients.length; ++i)
				coefficients[i] *= value;
			
			constant *= value;
		}

		/**
		 * Returns the difference of the constant and the left hand side
		 * containing the variables.
		 */
		public double getSignedError(Solution solution)
		{
			double values[] = solution.values;
			double e = constant;

			int i = coefficients.length;
			if( values.length < i )
				i = values.length;
				
			while( --i >= 0 )
				e -= coefficients[i] * values[i];

			return e;				
		}

		public double getAbsoluteError(Solution solution)
		{
			return Math.abs(getSignedError(solution));
		}

		/**
		 * Returns the value of the left hand side. This
		 * value does not depend on the constant.
		 */
		public double getLeftHandSide(Solution solution)
		{
			return constant - getSignedError(solution);
		}
		
		protected double[] coefficients;
		protected double constant;
	}

	/**
	 * Returns a new empty equation
	 */
	public Equation createEquation()
	{
		return new Equation();
	}

	/**
	 * Holds the list of equations.
	 */
	protected List<Equation> equations = new ArrayList<Equation>();

	/**
	 * Returns the list of equations in the system.
	 */
	public List<Equation> getEquations()
	{
		return equations;
	}
	
	public void printEquations(){
		for(int i=0;i<equations.size();i++){
			String equ=i+". ";
			Equation eq=(Equation)equations.get(i);
			for(int j=0;j<eq.coefficients.length;j++)
				if(eq.coefficients[j]!=0){
					equ+=eq.coefficients[j]+"*"+getVariableName(j)+" ";
				}					
			System.out.println(equ+"="+eq.constant); 
		}
	}


	/**
	 * Creates equations first, then add them to the system
	 * using this method.
	 */
	public void addEquation(Equation equation)
	{
		equations.add(equation);
	}

	/**
	 * Removes one equation from the set of equations. Be careful,
	 * as the number of variables will not decrease and can result
	 * in underdetermined system
	 */
	public void removeEquation(Equation equation)
	{
		equations.remove(equation);
	}

	/**
	 * Remove all equations and variables.
	 */
	public void clear()
	{
		variables.clear();
		equations.clear();
	}
	
	/**
	 * Prints some statistics on the list of equations and variables.
	 */
	public void printStatistics()
	{
		System.out.println("unknowns: " + variables.size() + ", equations: " + equations.size());
	}

	/**
	 * This class represents a solution to the system of linear equations.
	 */
	public class Solution
	{
		public double[] values;

		/**
		 * Use this method to get the value of a variable in the solution,
		 * or returns <code>NaN</code> if the variable does not occur in
		 * the solution.
		 */		
		public double getValue(String name)
		{
			if( variables.containsKey(name) )
				return values[((Integer)variables.get(name)).intValue()];
				
			return Double.NaN;
		}

		protected Solution(Matrix X)
		{
			this.values = new double[variables.size()];

			if( X.getColumnDimension() != 1 || X.getRowDimension() != values.length )
				throw new IllegalArgumentException();
			
			for(int i = 0; i < values.length; ++i)
				values[i] = X.get(i,0);
		}

		/**
		 * Prints out the solution and some statistics on the errors.
		 */		
		public void print()
		{
			Iterator<String> iter = variables.keySet().iterator();
			while( iter.hasNext() )
			{
				String name = (String)iter.next();
				int index = ((Integer)variables.get(name)).intValue();
				System.out.println(name + " = " + values[index]);
			}
			System.out.println("Average Error " + getAverageError());
			System.out.println("Maximum Error " + getMaximumError());
		}

		/**
		 * Returns the average error in the system of equations.
		 */	
		public double getAverageError()
		{
			double d = 0.0;
		
			Iterator<Equation> iter = equations.iterator();
			while( iter.hasNext() )
			{
				Equation equation = (Equation)iter.next();
				d += equation.getAbsoluteError(this);
			}
		
			return d / equations.size();
		}

		/**
		 * Returns the maximum error in the system of equations.
		 */	
		public double getMaximumError()
		{
			double d = 0.0;
		
			Iterator<Equation> iter = equations.iterator();
			while( iter.hasNext() )
			{
				Equation equation = (Equation)iter.next();
				double e = equation.getAbsoluteError(this);
				if( e > d )
					d = e;
			}
		
			return d;
		}
		
		public Equation getMaximumErrorEquation()
		{
			double d = -1.0;
			Equation a = null;
		
			Iterator<Equation> iter = equations.iterator();
			while( iter.hasNext() )
			{
				Equation equation = (Equation)iter.next();
				double e = equation.getAbsoluteError(this);
				if( e > d )
				{
					d = e;
					a = equation;
				}
			}
		
			return a;
		}
	}
	
	/**
	 * Returns the solution where the least squares of errors 
	 * of the equations is the smallest. 
	 */
	public Solution solveLeastSquares()
	{
		Matrix A = new Matrix(equations.size(), variables.size());
		Matrix B = new Matrix(equations.size(), 1);
		
		for(int i = 0; i < equations.size(); ++i)
		{
			Equation equation = (Equation)equations.get(i);

			int j = equation.coefficients.length;
			if( j > variables.size() )
				j = variables.size();
			while( --j >= 0 )
				A.set(i, j, equation.coefficients[j]);

			B.set(i, 0, equation.constant);
		}

		Matrix X = A.solve(B);
		
		return new Solution(X);
	}

	/**
	 * Returns a solution of a system of equations where the equations 
	 * are (almost) linearly dependent. Normalize singular values
	 * that are larger than <code>alpha</code>.
	 */
	public Solution solveWithSVD(double alpha)
	{
		int M = equations.size();
		int N = variables.size();
		
		Matrix A = new Matrix(M,N);
		Matrix B = new Matrix(M,1);
		
		for(int i = 0; i < M; ++i)
		{
			Equation equation = (Equation)equations.get(i);

			int j = equation.coefficients.length;
			if( j > N )
				j = N;
			while( --j >= 0 )
				A.set(i, j, equation.coefficients[j]);

			B.set(i, 0, equation.constant);
		}

		SingularValueDecomposition svd = A.svd();

		Matrix V = svd.getV();

		double[] singularValues = svd.getSingularValues();
		alpha *= singularValues[0];

		Matrix X = new Matrix(N,N);
		for(int j = 0; j < N && singularValues[j] > alpha; ++j)
		{
			double a = 1.0 / singularValues[j];
			for(int i = 0; i < N; ++i)
				X.set(i,j, V.get(i,j) * a);
		}
		
		X = X.times(svd.getU().transpose().times(B));
				
		return new Solution(X);
	}
}
