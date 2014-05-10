#-----------------------------------------------------------------------------------
# Copyright (c) 2013 Stephen J. Lovell
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#-----------------------------------------------------------------------------------

module Chess
  module Analytics

    class SearchRecord
      attr_accessor :depth, :score, :passes, :m_nodes, :q_nodes,
                    :evals, :memory, :eff_branching, :avg_eff_branching

      def initialize(depth, score, passes, m_nodes, q_nodes, evals, memory, previous_total=0.0, first_total=0.0)
        @depth, @score, @passes, @m_nodes = depth, score, passes, m_nodes
        @q_nodes, @evals, @memory = q_nodes, evals, memory
        @eff_branching = previous_total == 0.0 ? 0.0 : all_nodes.to_f/previous_total
        @avg_eff_branching = depth == 1 ? 0.0 : (all_nodes.to_f/first_total)**(1r/(depth-1)) 
      end

      def merge!(other)
        @passes += other.passes
        @m_nodes += other.m_nodes
        @q_nodes += other.q_nodes
        @evals += other.evals
        @memory += other.memory
        @score, @eff_branching, @avg_eff_branching = nil, 0.0, 0.0
      end

      def all_nodes
        @m_nodes + @q_nodes
      end

    end

    class Aggregator
      def initialize(max_depth)
        @data = (1..max_depth).collect { |d| SearchRecord.new(d, nil, 0, 0, 0, 0, 0, 0.0) }
      end

      def aggregate(record)
        @data[record.depth-1].merge!(record)
      end

      def refresh # recalculates branching factor statistics.
        previous_total = 0.0
        initial = @data[0].all_nodes
        @data.each do |rec|
          rec.eff_branching = previous_total == 0.0 ? 0.0 : rec.all_nodes.to_f/previous_total
          rec.avg_eff_branching = rec.depth == 1 ? 0.0 : (rec.all_nodes.to_f/initial)**(1r/(rec.depth-1))   
          previous_total = rec.all_nodes
        end
      end

      def print     
        refresh
        puts "\n\n------ Aggregate Search Performance -------\n\n"
        tp @data
      end

      def print_summary(accuracy=nil, time=nil)
        refresh
        str = time ? "#{all_nodes/time} NPS\n" : ""
        str += "N: #{all_nodes}; E: #{all_evals}; B: #{all_branching}; Efficiency: #{accuracy/all_branching}"
      end

      def all_nodes
        @data.inject(0){ |total, record| total += record.all_nodes }
      end

      def all_evals
        @data.inject(0){ |total, record| total += record.evals }
      end

      def all_branching
        @data.last.avg_eff_branching
      end

    end


  end
end













